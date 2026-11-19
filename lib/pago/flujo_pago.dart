// El recorrido completo de un pago: iniciar en la pasarela, guardar el pendiente,
// llevar al cliente a Webpay y mostrar cómo terminó.
//
// Reglas (aquí se maneja dinero):
//  - El pedido local solo se crea, y el carrito solo se descuenta, con un resultado
//    `aprobado` de la pasarela; lleva el número del servidor y las líneas pagadas.
//  - El pendiente se guarda en el dispositivo ANTES de abrir Webpay.
//  - Al volver de Webpay siempre se consulta a la pasarela, aunque el cliente haya
//    cerrado o cancelado: decide el servidor.
//  - «Sin confirmar» conserva el pendiente; mientras exista no se inicia otro pago.
//  - Un mismo número de pedido nunca se registra dos veces.

import 'package:flutter/material.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../pantallas/pago_resultado.dart';
import '../pantallas/webpay.dart';
import '../ui/componentes.dart';
import 'modelos_pago.dart';
import 'pasarela_pago.dart';

class FlujoPago {
  FlujoPago({required this.pasarela, Future<RetornoPago> Function(BuildContext, Redireccion)? abrirWebpay})
      : _abrirWebpay = abrirWebpay ?? _abrirWebpayPorDefecto;

  final PasarelaPago pasarela;
  final Future<RetornoPago> Function(BuildContext, Redireccion) _abrirWebpay;

  /// Hay un pago andando en este flujo (pagando o retomando un pendiente, con su pantalla de resultado
  /// incluida): un segundo toque, o el `Shell` al abrir la app, se ignora. Se suelta siempre en un `finally`.
  bool _enCurso = false;

  /// Empuja la página de Webpay; si se cierra sin devolver nada, cuenta como cerrada.
  static Future<RetornoPago> _abrirWebpayPorDefecto(BuildContext context, Redireccion redireccion) async {
    final retorno = await Navigator.of(context).push<RetornoPago>(
      MaterialPageRoute(builder: (_) => WebpayPantalla(redireccion: redireccion)),
    );
    return retorno ?? RetornoPago.cerrado;
  }

  /// Paga [solicitud]. Si ya hay un pago pendiente, en vez de iniciar otro lo retoma.
  Future<void> pagar(BuildContext context, SolicitudPago solicitud) async {
    if (_enCurso) return;
    _enCurso = true;
    try {
      if (estado.pagoPendiente != null) {
        // Sin pasar por `reanudarSiHay`: su guarda vería este mismo pago en curso y no haría nada.
        await _reanudar(context);
        return;
      }
      await _pagar(context, solicitud);
    } finally {
      _enCurso = false;
    }
  }

  /// Si quedó un pago sin resolver, consulta cómo terminó y muestra el resultado. Lo llama el `Shell` al abrir la app.
  /// Sin pendiente no hace nada; si venció (más de 24 h) lo olvida sin consultar ni navegar.
  /// Si ya hay otro flujo en curso, la llamada se ignora.
  Future<void> reanudarSiHay(BuildContext context) async {
    if (_enCurso) return;
    _enCurso = true;
    try {
      await _reanudar(context);
    } finally {
      _enCurso = false;
    }
  }

  /// `reanudarSiHay` sin la guarda: quien llama ya la tiene tomada.
  Future<void> _reanudar(BuildContext context) async {
    final p = estado.pagoPendiente;
    if (p == null) return;
    if (p.vencido(DateTime.now())) {
      estado.limpiarPagoPendiente();
      return;
    }
    if (!context.mounted) return;
    await _mostrarResultado(context, p, RetornoPago.desconocido);
  }

  /// Muestra la pantalla de resultado, que consulta a la pasarela y deja todo en orden.
  /// «Revisar de nuevo» (solo en «sin confirmar») cierra la pantalla y retoma el pendiente otra vez, con una
  /// pantalla nueva. Se hace aquí, dentro del mismo flujo: la guarda sigue tomada y no bloquea el reintento.
  Future<void> _mostrarResultado(BuildContext context, PagoPendiente p, RetornoPago retorno) async {
    late final MaterialPageRoute<bool> ruta;
    ruta = MaterialPageRoute<bool>(
      builder: (_) => ResultadoPagoPantalla(
        procesar: () => _cerrar(p, retorno),
        // Solo si esta pantalla sigue arriba: un doble toque no debe cerrar también la de abajo.
        alRevisarDeNuevo: () {
          if (ruta.isCurrent) ruta.navigator?.pop(true);
        },
      ),
    );
    final revisar = await Navigator.of(context).push(ruta);
    if (revisar == true && context.mounted) await _reanudar(context);
  }

  Future<void> _pagar(BuildContext context, SolicitudPago solicitud) async {
    final inicio = await _iniciar(context, solicitud);
    if (inicio == null || !context.mounted) return;

    // Primero queda guardado en el dispositivo: si la app muere en Webpay, al volver se puede retomar.
    estado.guardarPagoPendiente(inicio.pendiente);
    await Memoria.guardarYa();
    if (!context.mounted) return;

    final redireccion = inicio.redireccion;
    final retorno = redireccion == null ? RetornoPago.completado : await _abrirWebpay(context, redireccion);
    // Sin pantalla donde mostrar el resultado, el pendiente queda guardado para retomarlo después.
    if (!context.mounted) return;

    await _mostrarResultado(context, inicio.pendiente, retorno);
  }

  /// Inicia el pago en la pasarela. Si cambiaron los precios, pregunta y reintenta una vez con el total nuevo.
  /// Devuelve `null` si no se inició (error mostrado o el cliente prefirió volver).
  Future<InicioPago?> _iniciar(BuildContext context, SolicitudPago solicitud) async {
    try {
      return await pasarela.iniciar(solicitud);
    } on ErrorPago catch (e) {
      final totalNuevo = e.totalNuevo;
      if (e.codigo != 'precios_cambiaron' || totalNuevo == null) {
        if (context.mounted) await _avisarError(context, e.mensaje);
        return null;
      }
      if (!context.mounted) return null;
      final continuar = await _preguntarTotalNuevo(context, totalNuevo);
      if (!continuar || !context.mounted) return null;
      try {
        return await pasarela.iniciar(solicitud.conTotal(totalNuevo));
      } on ErrorPago catch (e2) {
        if (context.mounted) await _avisarError(context, e2.mensaje);
        return null;
      }
    }
  }

  /// Consulta cómo terminó el pago y deja todo en orden. Se llama desde la pantalla de resultado.
  Future<ResultadoPago> _cerrar(PagoPendiente p, RetornoPago retorno) async {
    ResultadoPago r;
    try {
      r = await pasarela.resultado(p, retorno);
    } catch (_) {
      // Sin respuesta clara no se puede decir que se pagó ni que no: el pendiente se conserva.
      r = const ResultadoPago.sinConfirmar();
    }
    if (r.aprobado) {
      final numero = r.numero ?? p.numero;
      if (!estado.pedidos.any((x) => x.numero == numero)) {
        final s = p.solicitud;
        estado.registrarPedido(
          numero: numero,
          lineas: s.lineas,
          correo: s.correo,
          direccion: s.direccion,
          franja: s.franja,
          notas: s.notas,
          retiro: s.retiro,
        );
      }
    }
    if (r.aprobado || r.motivo != MotivoNoPago.sinConfirmar) estado.limpiarPagoPendiente();
    return r;
  }

  Future<bool> _preguntarTotalNuevo(BuildContext context, int totalNuevo) async {
    final continuar = await _hoja<bool>(
      context,
      titulo: 'Cambió el total',
      cuerpo: 'Los precios se actualizaron. Tu total ahora es ${clp(totalNuevo)}. ¿Quieres continuar?',
      botones: (ctx) => [
        Boton('Continuar', onTap: () => Navigator.pop(ctx, true)),
        const SizedBox(height: Esp.x3),
        Boton('Volver al carrito', estilo: EstiloBoton.contorno, onTap: () => Navigator.pop(ctx, false)),
      ],
    );
    if (continuar == true) return true;
    // «Volver al carrito»: se cierra la pantalla de pago (en la app, quien llama es el checkout).
    if (continuar == false && context.mounted) {
      final nav = Navigator.of(context);
      if (nav.canPop()) nav.pop();
    }
    return false;
  }

  Future<void> _avisarError(BuildContext context, String mensaje) => _hoja<void>(
        context,
        titulo: 'No pudimos iniciar el pago',
        cuerpo: mensaje,
        botones: (ctx) => [Boton('Entendido', onTap: () => Navigator.pop(ctx))],
      );

  /// Hoja inferior con título, texto y botones, como la de «¿Salir del pago?».
  Future<V?> _hoja<V>(BuildContext context, {required String titulo, required String cuerpo, required List<Widget> Function(BuildContext) botones}) {
    return showModalBottomSheet<V>(
      context: context,
      backgroundColor: C.superficie,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(Esp.x6, Esp.x6, Esp.x6, Esp.x8),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(header: true, child: Text(titulo, style: T.titulo2)),
          const SizedBox(height: Esp.x2),
          Text(cuerpo, style: T.cuerpo.copyWith(color: C.grisMedio)),
          const SizedBox(height: Esp.x6),
          ...botones(ctx),
        ]),
      ),
    );
  }
}
