#!/usr/bin/env python3
"""Servidor FALSO de Webpay Plus, solo para desarrollo local.

*** SOLO DESARROLLO. NUNCA DESPLEGAR NI EXPONER A INTERNET. ***
No cobra nada, no habla con Transbank, no valida nada de verdad, no tiene
autenticación y guarda todo en memoria. Existe para probar la app móvil sin el
backend real: imita el contrato de `docs/backend-webpay.md` §4.

No forma parte de `api/` (el backend real). Es seguro dejarlo en el repositorio
justamente porque es inofensivo: solo biblioteca estándar y sin estado en disco.

Uso:
    python tools/webpay_falso.py [--puerto 8080] [--precios-cambian]

    --puerto N          puerto de escucha (por defecto 8080).
    --precios-cambian   la PRIMERA creación de pago responde 409
                        `precios_cambiaron` con total = totalVisto + 500; las
                        siguientes funcionan normal.

Desde el emulador de Android el equipo anfitrión es 10.0.2.2:
    flutter run --dart-define=PAGO_MODO=webpay \\
                --dart-define=API_URL=http://10.0.2.2:8080/api/v1

Endpoints:
    POST /api/v1/pagos/webpay             crear pago (cabecera Idempotency-Key)
    POST /falso/webpay                    página falsa de Webpay (recibe token_ws)
    GET|POST /api/v1/pagos/webpay/retorno vuelta desde Webpay -> 302 a urlFin
    GET  /api/v1/pagos/webpay/fin         página mínima
    GET  /api/v1/pagos/webpay/{numero}    estado (cabecera X-Token-Pago)
"""

import argparse
import html
import json
import secrets
import threading
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, quote, urlsplit

RAIZ = '/api/v1/pagos/webpay'

_cerrojo = threading.Lock()
_pedidos = {}        # numero -> dict con el estado del pedido
_por_token = {}      # token -> numero
_por_clave = {}      # Idempotency-Key -> (codigo, cuerpo) ya respondido
_siguiente = [90001]
_opciones = {'precios_cambian': False, 'ya_cambio': False}


def _ahora_utc():
    return datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')


class Manejador(BaseHTTPRequestHandler):
    server_version = 'WebpayFalso/1.0'

    # ───────────────────────────── utilidades ─────────────────────────────

    def log_message(self, formato, *args):
        # Sin tokens ni cabeceras: solo método y ruta sin query.
        ruta = urlsplit(self.path).path
        print(f'[{self.log_date_time_string()}] {self.command} {ruta} -> {args[1] if len(args) > 1 else ""}')

    def _base(self):
        return f'http://{self.headers.get("Host") or "127.0.0.1"}'

    def _enviar(self, codigo, cuerpo, tipo='application/json; charset=utf-8', extra=None):
        datos = cuerpo if isinstance(cuerpo, bytes) else cuerpo.encode('utf-8')
        self.send_response(codigo)
        self.send_header('Content-Type', tipo)
        self.send_header('Content-Length', str(len(datos)))
        self.send_header('Cache-Control', 'no-store')
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(datos)

    def _json(self, codigo, objeto):
        self._enviar(codigo, json.dumps(objeto, ensure_ascii=False))

    def _error(self, codigo, texto, code, **extra):
        self._json(codigo, {'error': texto, 'code': code, **extra})

    def _leer_cuerpo(self):
        try:
            largo = int(self.headers.get('Content-Length') or 0)
        except ValueError:
            largo = 0
        return self.rfile.read(largo) if largo > 0 else b''

    @staticmethod
    def _formulario(crudo):
        campos = parse_qs(crudo.decode('utf-8', 'replace'), keep_blank_values=True)
        return {k: v[0] for k, v in campos.items()}

    # ─────────────────────────────── rutas ────────────────────────────────

    def do_GET(self):
        partes = urlsplit(self.path)
        ruta = partes.path.rstrip('/') or '/'
        if ruta == RAIZ + '/retorno':
            return self._retorno(self._formulario(partes.query.encode()))
        if ruta == RAIZ + '/fin':
            return self._pagina_fin()
        if ruta == '/falso/webpay':
            return self._pagina_falsa(self._formulario(partes.query.encode()))
        if ruta.startswith(RAIZ + '/'):
            return self._estado(ruta[len(RAIZ) + 1:])
        self._error(404, 'No encontrado.', 'no_encontrado')

    def do_POST(self):
        partes = urlsplit(self.path)
        ruta = partes.path.rstrip('/') or '/'
        cuerpo = self._leer_cuerpo()
        if ruta == RAIZ:
            return self._crear(cuerpo)
        if ruta == RAIZ + '/retorno':
            return self._retorno(self._formulario(cuerpo))
        if ruta == '/falso/webpay':
            return self._pagina_falsa(self._formulario(cuerpo))
        self._error(404, 'No encontrado.', 'no_encontrado')

    # ───────────────────────────── 4.1 crear ──────────────────────────────

    def _crear(self, cuerpo):
        clave = (self.headers.get('Idempotency-Key') or '').strip()
        if not clave:
            return self._error(400, 'Falta la cabecera Idempotency-Key.', 'solicitud_invalida')
        try:
            datos = json.loads(cuerpo.decode('utf-8'))
            total_visto = datos['totalVisto']
            if isinstance(total_visto, bool) or not isinstance(total_visto, int) or total_visto < 0:
                raise ValueError('totalVisto')
        except (ValueError, KeyError, TypeError):
            return self._error(400, 'La solicitud no es válida.', 'solicitud_invalida')

        with _cerrojo:
            if clave in _por_clave:
                codigo, respuesta = _por_clave[clave]
                print(f'  (clave {clave[:8]}... repetida: misma respuesta)')
                return self._json(codigo, respuesta)

            if _opciones['precios_cambian'] and not _opciones['ya_cambio']:
                _opciones['ya_cambio'] = True
                nuevo = total_visto + 500
                print(f'  precios_cambiaron: visto {total_visto}, real {nuevo}')
                respuesta = {
                    'error': 'Los precios cambiaron. Revisa el nuevo total.',
                    'code': 'precios_cambiaron',
                    'total': nuevo,
                }
                _por_clave[clave] = (409, respuesta)
                return self._json(409, respuesta)

            numero = f'SED-{_siguiente[0]}'
            _siguiente[0] += 1
            token = secrets.token_hex(32)  # 64 caracteres hexadecimales
            cliente = datos.get('cliente') if isinstance(datos.get('cliente'), dict) else {}
            entrega = datos.get('entrega') if isinstance(datos.get('entrega'), dict) else {}
            _pedidos[numero] = {
                'numero': numero,
                'token': token,
                'estado': 'pendiente',
                'total': total_visto,
                'correo': cliente.get('correo') or '',
                'retiro': entrega.get('tipo') == 'retiro',
                'comprobante': None,
            }
            _por_token[token] = numero
            base = self._base()
            respuesta = {'data': {
                'numero': numero,
                'token': token,
                'url': f'{base}/falso/webpay',
                'urlFin': f'{base}{RAIZ}/fin',
                'total': total_visto,
            }}
            _por_clave[clave] = (201, respuesta)
            print(f'  pedido creado {numero} por ${total_visto}')
            self._json(201, respuesta)

    # ───────────────────────── página falsa de Webpay ─────────────────────

    def _pagina_falsa(self, campos):
        token = campos.get('token_ws', '')
        with _cerrojo:
            numero = _por_token.get(token)
            pedido = _pedidos.get(numero) if numero else None
        if not pedido:
            return self._enviar(400, '<h1>Token no valido</h1>', 'text/html; charset=utf-8')
        accion = f'{RAIZ}/retorno'

        def formulario(etiqueta, ocultos, color):
            campos_html = ''.join(
                f'<input type="hidden" name="{html.escape(k, quote=True)}" value="{html.escape(v, quote=True)}">'
                for k, v in ocultos.items()
            )
            return (f'<form method="POST" action="{accion}">{campos_html}'
                    f'<button type="submit" style="background:{color}">{html.escape(etiqueta)}</button></form>')

        pagina = f"""<!doctype html>
<html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Webpay (falso)</title>
<style>
 body{{font-family:sans-serif;margin:0;padding:24px;background:#f4f4f6;color:#222}}
 .caja{{max-width:420px;margin:0 auto;background:#fff;border-radius:12px;padding:24px}}
 .aviso{{background:#fff3cd;border-radius:8px;padding:8px 12px;font-size:13px}}
 button{{display:block;width:100%;margin-top:12px;padding:14px;border:0;border-radius:8px;
        color:#fff;font-size:16px}}
</style></head><body><div class="caja">
<p class="aviso">Página FALSA de pruebas. No se cobra nada.</p>
<h2>Webpay</h2>
<p>Pedido <b>{html.escape(numero)}</b><br>Total <b>${pedido['total']}</b></p>
{formulario('Aprobar (VISA 6623)', {'token_ws': token, 'resultado': 'aprobar'}, '#1b8a3a')}
{formulario('Rechazar', {'token_ws': token, 'resultado': 'rechazar'}, '#b3261e')}
{formulario('Cancelar', {'TBK_TOKEN': token, 'TBK_ORDEN_COMPRA': numero, 'TBK_ID_SESION': 'falso-' + numero}, '#666')}
</div></body></html>"""
        self._enviar(200, pagina, 'text/html; charset=utf-8')

    # ───────────────────────────── 4.2 retorno ────────────────────────────

    def _retorno(self, campos):
        token_ws = campos.get('token_ws')
        tbk_token = campos.get('TBK_TOKEN')
        orden = campos.get('TBK_ORDEN_COMPRA')
        with _cerrojo:
            numero = _por_token.get(token_ws or tbk_token or '') or (orden if orden in _pedidos else None)
            if numero:
                pedido = _pedidos[numero]
                if pedido['estado'] == 'pendiente':  # idempotente: no se pisa un estado final
                    if token_ws and tbk_token:
                        pedido['estado'] = 'rechazado'
                    elif token_ws:
                        if campos.get('resultado') == 'rechazar':
                            pedido['estado'] = 'rechazado'
                        else:
                            pedido['estado'] = 'aprobado'
                            pedido['comprobante'] = {
                                'codigoAutorizacion': '1213',
                                'tarjetaUltimos4': '6623',
                                'tipoPago': 'Crédito',
                                'cuotas': 0,
                                'fecha': _ahora_utc(),
                            }
                    elif tbk_token:
                        pedido['estado'] = 'cancelado'
                    else:
                        pedido['estado'] = 'expirado'
                print(f'  retorno {numero}: {pedido["estado"]}')
            else:
                print('  retorno de un pedido desconocido')
        destino = f'{self._base()}{RAIZ}/fin'
        if numero:
            destino += f'?numero={quote(numero)}'
        self._enviar(302, b'', 'text/plain; charset=utf-8', {'Location': destino})

    # ─────────────────────────────── 4.3 fin ──────────────────────────────

    def _pagina_fin(self):
        self._enviar(200, '<!doctype html><html lang="es"><meta charset="utf-8">'
                          '<meta name="viewport" content="width=device-width, initial-scale=1">'
                          '<title>Sedyjo</title><body style="font-family:sans-serif;padding:24px">'
                          '<p>Volviendo a la tienda…</p></body></html>', 'text/html; charset=utf-8')

    # ────────────────────────────── 4.4 estado ────────────────────────────

    def _estado(self, numero):
        token = self.headers.get('X-Token-Pago') or ''
        with _cerrojo:
            pedido = _pedidos.get(numero)
            if not pedido or not token or not secrets.compare_digest(token.encode(), pedido['token'].encode()):
                return self._error(404, 'Pedido no encontrado.', 'no_encontrado')
            datos = {k: pedido[k] for k in ('numero', 'estado', 'total', 'correo', 'retiro')}
            if pedido['estado'] == 'aprobado' and pedido['comprobante']:
                datos['comprobante'] = pedido['comprobante']
        self._json(200, {'data': datos})


def main():
    ap = argparse.ArgumentParser(description='Servidor FALSO de Webpay (solo desarrollo, nunca desplegar).')
    ap.add_argument('--puerto', type=int, default=8080)
    ap.add_argument('--precios-cambian', action='store_true',
                    help='la primera creación responde 409 precios_cambiaron (total = visto + 500)')
    args = ap.parse_args()
    _opciones['precios_cambian'] = args.precios_cambian

    servidor = ThreadingHTTPServer(('0.0.0.0', args.puerto), Manejador)
    print('=' * 64)
    print(' WEBPAY FALSO: solo desarrollo. No cobra nada. NO DESPLEGAR.')
    print(f' Escuchando en 0.0.0.0:{args.puerto}  (emulador Android: http://10.0.2.2:{args.puerto}/api/v1)')
    if args.precios_cambian:
        print(' Modo --precios-cambian: la primera creacion responde 409.')
    print(' Ctrl+C para detener.')
    print('=' * 64)
    try:
        servidor.serve_forever()
    except KeyboardInterrupt:
        print('\nDetenido.')
    finally:
        servidor.server_close()


if __name__ == '__main__':
    main()
