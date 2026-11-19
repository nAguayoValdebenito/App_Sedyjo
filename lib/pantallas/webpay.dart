import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../app/tema.dart';
import '../pago/modelos_pago.dart';
import '../pago/navegacion_webpay.dart';
import '../ui/componentes.dart';

/// Página de pago de Webpay dentro de la app.
///
/// Se abre con un POST que lleva el token (así lo exige Webpay). Cuando el pago termina, el backend
/// devuelve al cliente a `urlFin`: esa dirección se intercepta (no se carga) y la pantalla se cierra
/// con [RetornoPago.completado]. Si el cliente sale antes, se cierra con [RetornoPago.cerrado].
/// Cada dirección que el WebView quiere abrir pasa por [decidirNavegacion]; el token y las
/// direcciones nunca se escriben en ningún registro.
class WebpayPantalla extends StatefulWidget {
  const WebpayPantalla({super.key, required this.redireccion});
  final Redireccion redireccion;

  @override
  State<WebpayPantalla> createState() => _WebpayPantallaState();
}

class _WebpayPantallaState extends State<WebpayPantalla> {
  late final WebViewController _controlador;
  int _progreso = 0;
  bool _falla = false;

  /// Ya se cerró la pantalla (o se está cerrando): evita devolver dos resultados.
  bool _terminado = false;
  bool _preguntando = false;

  @override
  void initState() {
    super.initState();
    _controlador = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: _alNavegar,
        onProgress: (p) {
          if (mounted) setState(() => _progreso = p);
        },
        onPageStarted: (_) {
          if (mounted && _progreso == 100) setState(() => _progreso = 0);
        },
        onWebResourceError: (e) {
          // Solo importa si falló la página principal; un recurso suelto (imagen, script) no la invalida.
          if (e.isForMainFrame == true && mounted && !_terminado) setState(() => _falla = true);
        },
        // Un certificado dudoso nunca se acepta en una pantalla donde se ingresa la tarjeta.
        onSslAuthError: (e) => e.cancel(),
      ));
    _cargar();
  }

  NavigationDecision _alNavegar(NavigationRequest peticion) {
    final destino = Uri.tryParse(peticion.url);
    if (destino == null) return NavigationDecision.prevent;
    switch (decidirNavegacion(destino, widget.redireccion.urlFin, permitirHttp: kDebugMode)) {
      case DecisionNavegacion.permitir:
        return NavigationDecision.navigate;
      case DecisionNavegacion.terminar:
        _cerrarCon(RetornoPago.completado);
        return NavigationDecision.prevent;
      case DecisionNavegacion.bloquear:
        return NavigationDecision.prevent;
    }
  }

  void _cargar() {
    final url = widget.redireccion.url;
    // La primera carga no pasa por el delegado: se le exige lo mismo que a cualquier otra dirección.
    if (decidirNavegacion(url, widget.redireccion.urlFin, permitirHttp: kDebugMode) != DecisionNavegacion.permitir) {
      setState(() => _falla = true);
      return;
    }
    setState(() {
      _falla = false;
      _progreso = 0;
    });
    _controlador.loadRequest(
      url,
      method: LoadRequestMethod.post,
      headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
      body: cuerpoFormulario(widget.redireccion.token),
    );
  }

  /// Cierra la pantalla devolviendo [retorno], una sola vez. Si hay un diálogo abierto encima, también se cierra.
  void _cerrarCon(RetornoPago retorno) {
    if (_terminado || !mounted) return;
    _terminado = true;
    final nav = Navigator.of(context);
    final ruta = ModalRoute.of(context);
    if (ruta != null) nav.popUntil((r) => r == ruta);
    nav.pop(retorno);
  }

  Future<void> _preguntarSalir() async {
    if (_terminado || _preguntando) return;
    _preguntando = true;
    final salir = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: C.superficie,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(Esp.x6, Esp.x6, Esp.x6, Esp.x8),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(header: true, child: Text('¿Salir del pago?', style: T.titulo2)),
          const SizedBox(height: Esp.x2),
          Text('Si sales ahora no se te cobrará, salvo que ya hayas confirmado en tu banco. Revisaremos cómo quedó.',
              style: T.cuerpo.copyWith(color: C.grisMedio)),
          const SizedBox(height: Esp.x6),
          Boton('Seguir pagando', onTap: () => Navigator.pop(ctx, false)),
          const SizedBox(height: Esp.x3),
          Boton('Salir', estilo: EstiloBoton.contorno, onTap: () => Navigator.pop(ctx, true)),
        ]),
      ),
    );
    _preguntando = false;
    if (salir == true) _cerrarCon(RetornoPago.cerrado);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (seCerro, _) {
        if (!seCerro) _preguntarSalir();
      },
      child: Scaffold(
        backgroundColor: C.fondo,
        body: SafeArea(
          child: Column(children: [
            _barra(),
            _barraProgreso(),
            Expanded(
              child: _falla
                  ? _panelFalla()
                  : WebViewWidget(controller: _controlador),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _barra() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Esp.x4, Esp.x2, Esp.x4, Esp.x2),
      child: Row(children: [
        Icon(LucideIcons.lock, size: Ico.m, color: C.verdeOscuro),
        const SizedBox(width: Esp.x3),
        Expanded(child: Semantics(header: true, child: Text('Pago con Webpay', style: T.titulo2, maxLines: 1, overflow: TextOverflow.ellipsis))),
        BotonIcono(LucideIcons.x, 'Salir del pago', onTap: _preguntarSalir),
      ]),
    );
  }

  Widget _barraProgreso() {
    final cargando = !_falla && _progreso < 100;
    return SizedBox(
      height: 3,
      child: cargando
          ? LinearProgressIndicator(
              value: _progreso == 0 ? null : _progreso / 100,
              minHeight: 3,
              color: C.verde,
              backgroundColor: C.verdeSuave,
              semanticsLabel: 'Cargando la página de pago',
            )
          : null,
    );
  }

  Widget _panelFalla() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Esp.x6),
        child: Panel(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(LucideIcons.wifiOff, size: Ico.l, color: C.error),
            const SizedBox(height: Esp.x3),
            Semantics(liveRegion: true, header: true, child: Text('No pudimos cargar Webpay', style: T.titulo2)),
            const SizedBox(height: Esp.x2),
            Text('No se te cobró nada. Revisa tu conexión e inténtalo otra vez.', style: T.cuerpo.copyWith(color: C.grisMedio)),
            const SizedBox(height: Esp.x6),
            Boton('Reintentar', icono: LucideIcons.refreshCw, onTap: _cargar),
            const SizedBox(height: Esp.x3),
            Boton('Cerrar', estilo: EstiloBoton.suave, onTap: () => _cerrarCon(RetornoPago.cerrado)),
          ]),
        ),
      ),
    );
  }
}
