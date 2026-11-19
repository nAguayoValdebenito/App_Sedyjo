// Reglas de navegación de la página de Webpay. Es la única puerta por la que pasa
// cada dirección que el WebView quiere abrir: aquí se decide si se deja pasar, si
// el pago terminó o si se bloquea. No imprime ni registra direcciones (llevan token).

import 'dart:convert';
import 'dart:typed_data';

/// Qué hacer con una dirección que el WebView quiere abrir.
enum DecisionNavegacion { permitir, terminar, bloquear }

/// Decide qué hacer con [destino].
///
/// 1. Si apunta a [urlFin] (mismo host y ruta; se ignora la query) el pago terminó:
///    se devuelve [DecisionNavegacion.terminar] y esa página NO se carga. Se evalúa primero.
/// 2. `https` se permite. `http` solo con [permitirHttp] (desarrollo); si no, se bloquea.
/// 3. `about:blank` se permite.
/// 4. Cualquier otro esquema (`intent`, `market`, `file`, `javascript`, `data`, `tel`…) se bloquea.
DecisionNavegacion decidirNavegacion(Uri destino, Uri urlFin, {bool permitirHttp = false}) {
  final esquema = destino.scheme.toLowerCase();
  final esWeb = esquema == 'https' || esquema == 'http';

  // Solo una dirección web puede ser la de fin: un esquema raro con el mismo host no cuenta.
  if (esWeb && _mismoLugar(destino, urlFin)) return DecisionNavegacion.terminar;

  if (esquema == 'https') return DecisionNavegacion.permitir;
  if (esquema == 'http') return permitirHttp ? DecisionNavegacion.permitir : DecisionNavegacion.bloquear;
  if (esquema == 'about' && destino.path == 'blank') return DecisionNavegacion.permitir;
  return DecisionNavegacion.bloquear;
}

/// Mismo host y misma ruta (sin importar esquema, query ni barra final).
bool _mismoLugar(Uri a, Uri b) {
  if (a.host.isEmpty || a.host.toLowerCase() != b.host.toLowerCase()) return false;
  return _sinBarraFinal(a.path) == _sinBarraFinal(b.path);
}

String _sinBarraFinal(String ruta) {
  var r = ruta;
  while (r.length > 1 && r.endsWith('/')) {
    r = r.substring(0, r.length - 1);
  }
  return r;
}

/// Cuerpo `application/x-www-form-urlencoded` con el token, tal como lo pide Webpay: `token_ws=<token>`.
Uint8List cuerpoFormulario(String token) => Uint8List.fromList(utf8.encode('token_ws=${Uri.encodeQueryComponent(token)}'));
