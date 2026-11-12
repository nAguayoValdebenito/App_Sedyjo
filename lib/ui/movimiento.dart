import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/datos.dart';
import '../app/tema.dart';

/// Duración respetando "reducir movimiento" (ajuste de la app y del sistema).
Duration dur(BuildContext c, [int ms = 220]) =>
    (MediaQuery.maybeDisableAnimationsOf(c) ?? false) || estado.reducirMovimiento
        ? Duration.zero
        : Duration(milliseconds: ms);

bool sinMovimiento(BuildContext c) =>
    (MediaQuery.maybeDisableAnimationsOf(c) ?? false) || estado.reducirMovimiento;

/// Vibración leve al agregar. Se apaga con "reducir movimiento".
void vibracionLeve() {
  if (estado.reducirMovimiento) return;
  HapticFeedback.lightImpact();
}

/// Vibración doble y firme cuando algo no se pudo (formulario con datos que faltan). Se apaga con "reducir movimiento".
void vibracionError() {
  if (estado.reducirMovimiento) return;
  HapticFeedback.heavyImpact();
  Future<void>.delayed(const Duration(milliseconds: 120), HapticFeedback.heavyImpact);
}

/// Vibración un poco más marcada para logros (despacho gratis, compra lista).
void vibracionLogro() {
  if (estado.reducirMovimiento) return;
  HapticFeedback.mediumImpact();
}

/// Número en pesos que "corre" hasta el nuevo valor (250 ms) en vez de saltar. Se lee entero por el lector de pantalla.
class NumeroAnimado extends StatelessWidget {
  const NumeroAnimado(this.valor, {super.key, required this.estilo, this.formato});
  final int valor;
  final TextStyle estilo;
  final String Function(int)? formato;

  @override
  Widget build(BuildContext context) {
    final f = formato ?? (int v) => clp(v);
    return Semantics(
      label: f(valor),
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: valor.toDouble()),
        duration: dur(context, 250),
        curve: Mov.entra,
        builder: (_, v, _) => Text(f(v.round()), style: estilo),
      ),
    );
  }
}

/// Balanceo mínimo y lento para ilustraciones de estados vacíos. Se detiene solo cuando la pestaña no se ve
/// (usa el reloj del `TickerMode`) y con "reducir movimiento".
class Flota extends StatefulWidget {
  const Flota({super.key, required this.child, this.amplitud = 4});
  final Widget child;
  final double amplitud;

  @override
  State<Flota> createState() => _FlotaState();
}

class _FlotaState extends State<Flota> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    if (!sinMovimiento(context)) _ctl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      child: widget.child,
      builder: (_, hijo) => Transform.translate(
        offset: Offset(0, (Curves.easeInOut.transform(_ctl.value) - .5) * 2 * widget.amplitud),
        child: hijo,
      ),
    );
  }
}

/// Círculo con una marca de verificación que se dibuja (600 ms). Con "reducir movimiento" aparece completa.
class MarcaVerificacion extends StatefulWidget {
  const MarcaVerificacion({super.key, this.tam = 64, required this.color, this.colorMarca = Colors.white});
  final double tam;
  final Color color;
  final Color colorMarca;

  @override
  State<MarcaVerificacion> createState() => _MarcaVerificacionState();
}

class _MarcaVerificacionState extends State<MarcaVerificacion> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    if (sinMovimiento(context)) {
      _ctl.value = 1;
    } else {
      _ctl.forward();
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (_, _) => CustomPaint(
          size: Size.square(widget.tam),
          painter: _PintorMarca(_ctl.value, widget.color, widget.colorMarca),
        ),
      ),
    );
  }
}

class _PintorMarca extends CustomPainter {
  _PintorMarca(this.t, this.color, this.colorMarca);
  final double t;
  final Color color;
  final Color colorMarca;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final disco = Curves.easeOutBack.transform((t / .5).clamp(0.0, 1.0));
    canvas.drawCircle(centro, size.width / 2 * disco, Paint()..color = color);
    final p = Curves.easeOut.transform(((t - .4) / .6).clamp(0.0, 1.0));
    if (p == 0) return;
    final w = size.width;
    final ruta = Path()
      ..moveTo(w * .28, w * .52)
      ..lineTo(w * .44, w * .67)
      ..lineTo(w * .73, w * .36);
    final medida = ruta.computeMetrics().first;
    canvas.drawPath(
      medida.extractPath(0, medida.length * p),
      Paint()
        ..color = colorMarca
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .09
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PintorMarca old) => old.t != t || old.color != color;
}

/// Mismo desplazamiento de un degradado para el brillo del esqueleto.
class DeslizarDegradado extends GradientTransform {
  const DeslizarDegradado(this.porcentaje);
  final double porcentaje;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * porcentaje, 0, 0);
}

