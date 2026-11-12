import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import 'direccion.dart' show mostrarContacto;
import '../ui/componentes.dart';
import 'pedidos.dart';
import 'shell.dart' show BarraInferior;

/// Cómo terminó el pago.
class ResultadoPago {
  const ResultadoPago.aprobado({required String this.numero, required this.total, required this.correo, this.retiro = false}) : aprobado = true;
  const ResultadoPago.rechazado()
      : aprobado = false,
        numero = null,
        total = 0,
        correo = '',
        retiro = false;

  final bool aprobado;
  final String? numero;
  final int total;
  final String correo;
  final bool retiro;
}

/// Estado del sello circular de arriba.
enum Sello { procesando, aprobado, rechazado }

/// Pantalla del resultado del pago, en tres tiempos:
/// 1. Solo un círculo que gira mientras se confirma el pago ("Confirmando tu pago…").
/// 2. El círculo se cierra y se vuelve verde con una marca (aprobado) o rojo con una cruz (rechazado).
/// 3. Recién entonces aparece el mensaje completo: ilustración, título, número de pedido y los botones.
///
/// Con [procesar] hace el trabajo real (registrar el pedido, cobrar); con [resultado] muestra uno ya conocido
/// (también pasa por el círculo, para que la secuencia sea la misma).
class ResultadoPagoPantalla extends StatefulWidget {
  const ResultadoPagoPantalla({super.key, this.procesar, this.resultado}) : assert(procesar != null || resultado != null);
  final Future<ResultadoPago> Function()? procesar;
  final ResultadoPago? resultado;

  @override
  State<ResultadoPagoPantalla> createState() => _ResultadoPagoPantallaState();
}

class _ResultadoPagoPantallaState extends State<ResultadoPagoPantalla> {
  ResultadoPago? _r;
  bool _contenido = false;
  Timer? _tContenido;
  Timer? _tMinimo;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    // El círculo gira al menos un momento: un resultado instantáneo se sentiría falso.
    final minimo = Completer<void>();
    _tMinimo = Timer(const Duration(milliseconds: 1800), minimo.complete);
    final r = widget.resultado ?? await widget.procesar!();
    await minimo.future;
    if (!mounted) return;
    setState(() => _r = r);
    if (r.aprobado) {
      vibracionLogro();
    } else {
      vibracionError();
    }
    // Se deja ver el sello cambiar de color antes de mostrar el mensaje.
    _tContenido = Timer(Duration(milliseconds: sinMovimiento(context) ? 200 : 1100), () {
      if (mounted) setState(() => _contenido = true);
    });
  }

  @override
  void dispose() {
    _tContenido?.cancel();
    _tMinimo?.cancel();
    super.dispose();
  }

  Sello get _sello => _r == null ? Sello.procesando : (_r!.aprobado ? Sello.aprobado : Sello.rechazado);

  @override
  Widget build(BuildContext context) {
    final r = _r;
    return PopScope(
      // Mientras se confirma el pago no se puede salir: evitaría dejar la compra a medias.
      canPop: r != null,
      child: Scaffold(
        // Si el pago se rechazó, la barra de pestañas sigue a la vista para ir a cualquier parte de la tienda.
        bottomNavigationBar: (_contenido && r != null && !r.aprobado)
            ? BarraInferior(alElegir: (i) {
                Navigator.of(context).popUntil((x) => x.isFirst);
                estado.irAPestana(i);
              })
            : null,
        body: SafeArea(
          // Primero solo el círculo; cuando ya cambió de color, se va y entra la pantalla final con el mensaje.
          child: AnimatedSwitcher(
            duration: dur(context, 550),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: (_contenido && r != null) ? _vistaFinal(context, r) : _vistaCirculo(),
          ),
        ),
      ),
    );
  }

  /// El círculo solo, en el centro de la pantalla.
  Widget _vistaCirculo() {
    return SizedBox.expand(
      key: const ValueKey('circulo'),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SelloPago(_sello),
        if (_r == null) ...[
          const SizedBox(height: Esp.x6),
          Semantics(liveRegion: true, child: Text('Confirmando tu pago…', textAlign: TextAlign.center, style: T.titulo3)),
          const SizedBox(height: Esp.x2),
          Text('Un momento, no cierres la aplicación.', textAlign: TextAlign.center, style: T.apoyo),
        ],
      ]),
    );
  }

  /// El mensaje completo del resultado, sin el círculo.
  Widget _vistaFinal(BuildContext context, ResultadoPago r) {
    return Column(key: const ValueKey('final'), children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Esp.x6),
          child: Column(children: r.aprobado ? _aprobado(context, r) : _rechazado(context)),
        ),
      ),
      _botones(context, r),
    ]);
  }

  List<Widget> _aprobado(BuildContext context, ResultadoPago r) => [
        const SizedBox(height: Esp.x8 + Esp.x6),
        Revelar(child: const IlustracionEstado('compra-exitosa.webp', ancho: 260)),
        const SizedBox(height: Esp.x6),
        Revelar(indice: 1, child: Semantics(liveRegion: true, header: true, child: Text('¡Tu compra está lista!', textAlign: TextAlign.center, style: T.titulo1))),
        const SizedBox(height: Esp.x3),
        Revelar(
          indice: 2,
          child: Text('Pagaste ${clp(r.total)}. Te enviamos el comprobante a ${r.correo.isEmpty ? 'tu correo' : r.correo}.', textAlign: TextAlign.center, style: T.cuerpo.copyWith(color: C.grisMedio)),
        ),
        const SizedBox(height: Esp.x6),
        Revelar(
          indice: 3,
          child: Panel(
            fondo: C.verdeSuave,
            borde: C.verdeSuave,
            child: SizedBox(
              width: double.infinity,
              child: Column(children: [
                Text('Número de pedido', style: T.apoyo.copyWith(color: C.verdeOscuro)),
                const SizedBox(height: Esp.x1),
                Text(r.numero ?? '', style: T.titulo1.copyWith(color: C.verdeProfundo, fontSize: 32, letterSpacing: .5)),
                const SizedBox(height: Esp.x2),
                Text('Anótalo: con él puedes seguir tu pedido sin cuenta.', textAlign: TextAlign.center, style: T.apoyo.copyWith(color: C.verdeOscuro)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: Esp.x4),
        Revelar(
          indice: 4,
          child: Row(children: [
            Icon(r.retiro ? LucideIcons.store : LucideIcons.truck, color: C.verde),
            const SizedBox(width: Esp.x3),
            Expanded(child: Text(r.retiro ? 'Estará lista para retirar en ${tienda.calle} en 2 horas hábiles.' : 'Llegará en 24 a 48 horas.', style: T.cuerpoFuerte)),
          ]),
        ),
        const SizedBox(height: Esp.x4),
      ];

  List<Widget> _rechazado(BuildContext context) => [
        const SizedBox(height: Esp.x8 + Esp.x6),
        Revelar(child: const IlustracionEstado('pago-no-completado.webp', ancho: 260)),
        const SizedBox(height: Esp.x6),
        Revelar(indice: 1, child: Semantics(liveRegion: true, header: true, child: Text('El pago no se completó', textAlign: TextAlign.center, style: T.titulo1))),
        const SizedBox(height: Esp.x3),
        Revelar(
          indice: 2,
          child: Text('No te cobramos nada y tus productos siguen en el carrito. Puedes intentarlo de nuevo.', textAlign: TextAlign.center, style: T.cuerpo.copyWith(color: C.grisMedio)),
        ),
        const SizedBox(height: Esp.x4),
      ];

  Widget _botones(BuildContext context, ResultadoPago r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Esp.x6, Esp.x2, Esp.x6, Esp.x5),
      child: Column(children: r.aprobado
          ? [
              Boton('Seguir mi pedido', icono: LucideIcons.packageCheck, onTap: () {
                Navigator.of(context).popUntil((x) => x.isFirst);
                irA(context, SeguimientoPantalla(numero: r.numero));
              }),
              const SizedBox(height: Esp.x3),
              Boton('Volver al inicio', estilo: EstiloBoton.suave, onTap: () {
                Navigator.of(context).popUntil((x) => x.isFirst);
                estado.irAPestana(0);
              }),
            ]
          : [
              Boton('Intentar de nuevo', icono: LucideIcons.refreshCw, onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(height: Esp.x2),
              Boton('Volver al inicio', estilo: EstiloBoton.suave, icono: LucideIcons.house, onTap: () {
                Navigator.of(context).popUntil((x) => x.isFirst);
                estado.irAPestana(0);
              }),
              const SizedBox(height: Esp.x2),
              Boton('Llamar para recibir ayuda', estilo: EstiloBoton.contorno, icono: LucideIcons.phone, alto: 52, onTap: () => mostrarContacto(context)),
            ]),
    );
  }
}

/// Compra exitosa (se usa también desde el panel de la maqueta y las pruebas).
class ExitoPantalla extends StatelessWidget {
  const ExitoPantalla({super.key, required this.numero, required this.total, required this.correo, this.retiro = false});
  final String numero;
  final int total;
  final String correo;
  final bool retiro;

  @override
  Widget build(BuildContext context) =>
      ResultadoPagoPantalla(resultado: ResultadoPago.aprobado(numero: numero, total: total, correo: correo, retiro: retiro));
}

/// Pago rechazado.
class ErrorPagoPantalla extends StatelessWidget {
  const ErrorPagoPantalla({super.key});

  @override
  Widget build(BuildContext context) => const ResultadoPagoPantalla(resultado: ResultadoPago.rechazado());
}

/// El círculo del resultado: gira mientras se confirma; al resolverse el aro se cierra, el disco se llena
/// (verde con una marca, o rojo con una cruz) y la marca se dibuja. Con "reducir movimiento" el cambio es directo.
class SelloPago extends StatefulWidget {
  const SelloPago(this.sello, {super.key, this.tam = 104});
  final Sello sello;
  final double tam;

  @override
  State<SelloPago> createState() => _SelloPagoState();
}

class _SelloPagoState extends State<SelloPago> with TickerProviderStateMixin {
  late final AnimationController _giro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _res = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (widget.sello == Sello.procesando) {
      _giro.repeat();
    } else {
      _res.value = 1;
    }
  }

  @override
  void didUpdateWidget(SelloPago old) {
    super.didUpdateWidget(old);
    if (old.sello == Sello.procesando && widget.sello != Sello.procesando) {
      if (sinMovimiento(context)) {
        _res.value = 1;
        _giro.stop();
      } else {
        _res.forward(from: 0).whenComplete(_giro.stop);
      }
    }
  }

  @override
  void dispose() {
    _giro.dispose();
    _res.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final etiqueta = switch (widget.sello) {
      Sello.procesando => 'Confirmando tu pago',
      Sello.aprobado => 'Pago aprobado',
      Sello.rechazado => 'Pago rechazado',
    };
    return Semantics(
      label: etiqueta,
      liveRegion: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_giro, _res]),
            builder: (_, _) => CustomPaint(
              size: Size.square(widget.tam),
              painter: _PintorSello(
                giro: _giro.value,
                res: widget.sello == Sello.procesando ? 0 : _res.value,
                aprobado: widget.sello == Sello.aprobado,
                pista: C.borde,
                aro: C.verde,
                relleno: widget.sello == Sello.rechazado ? C.rojo : C.verde,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PintorSello extends CustomPainter {
  _PintorSello({required this.giro, required this.res, required this.aprobado, required this.pista, required this.aro, required this.relleno});
  final double giro;
  final double res;
  final bool aprobado;
  final Color pista;
  final Color aro;
  final Color relleno;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 6;
    final grosor = size.width * .07;

    // 1) Aro: una pista suave y un arco que gira; al resolverse el arco se cierra y el aro se desvanece.
    final aroAlfa = 1 - ((res - .25) / .25).clamp(0.0, 1.0);
    if (aroAlfa > 0) {
      canvas.drawCircle(c, r, Paint()..color = pista.withValues(alpha: aroAlfa)..style = PaintingStyle.stroke..strokeWidth = grosor);
      final cierre = Curves.easeOut.transform((res / .25).clamp(0.0, 1.0));
      final barrido = (math.pi * 1.1) + (math.pi * 2 - math.pi * 1.1) * cierre;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        giro * math.pi * 2 - math.pi / 2,
        barrido,
        false,
        Paint()
          ..color = aro.withValues(alpha: aroAlfa)
          ..style = PaintingStyle.stroke
          ..strokeWidth = grosor
          ..strokeCap = StrokeCap.round,
      );
    }

    // 2) Disco de color que crece desde el centro con un pequeño rebote.
    final crece = Curves.easeOutBack.transform(((res - .30) / .35).clamp(0.0, 1.0));
    if (crece > 0) canvas.drawCircle(c, (r + grosor / 2) * crece, Paint()..color = relleno);

    // 3) Marca (visto bueno o cruz) que se dibuja.
    final p = Curves.easeOut.transform(((res - .55) / .45).clamp(0.0, 1.0));
    if (p > 0) {
      final w = size.width;
      final ruta = Path();
      if (aprobado) {
        ruta
          ..moveTo(w * .30, w * .53)
          ..lineTo(w * .44, w * .67)
          ..lineTo(w * .71, w * .37);
      } else {
        ruta
          ..moveTo(w * .36, w * .36)
          ..lineTo(w * .64, w * .64)
          ..moveTo(w * .64, w * .36)
          ..lineTo(w * .36, w * .64);
      }
      final lapiz = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .08
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      var largoTotal = 0.0;
      final tramos = ruta.computeMetrics().toList();
      for (final t in tramos) {
        largoTotal += t.length;
      }
      var restante = largoTotal * p;
      for (final t in tramos) {
        if (restante <= 0) break;
        canvas.drawPath(t.extractPath(0, math.min(t.length, restante)), lapiz);
        restante -= t.length;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PintorSello old) => old.giro != giro || old.res != res || old.aprobado != aprobado || old.relleno != relleno;
}
