import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/componentes.dart';
import 'bienvenida.dart';

/// Pantalla de carga. Siempre se ve la animación completa: una canasta va recibiendo bebidas, frutas, pan y lácteos
/// y al llenarse se transforma en el logo (5 s). Existe una versión breve (solo logo, 1,4 s) para usarla si se decide.
/// En ambos casos corre en paralelo a la carga real ([carga]) y un toque la salta. Con "reducir movimiento"
/// solo se ve el logo.
class SplashPantalla extends StatefulWidget {
  const SplashPantalla({super.key, this.alTerminar, this.duracion, this.completa, this.carga});
  final VoidCallback? alTerminar;

  /// Duración total de la animación. Si no se indica: 4,5 s la versión completa y 1,4 s la breve.
  /// (El panel de la maqueta la lanza más lenta para poder revisarla.)
  final Duration? duracion;

  /// Fuerza la versión completa (`true`) o la breve (`false`). Si no se indica: siempre la completa.
  final bool? completa;

  /// Trabajo real en curso (catálogo, sesión). La pantalla no avanza hasta que termine, aunque la animación acabe antes.
  final Future<void>? carga;

  @override
  State<SplashPantalla> createState() => _SplashPantallaState();
}

class _Item {
  const _Item(this.icono, this.color, this.fondo, this.x, this.y, this.inicio, this.giro);
  final IconData icono;
  final Color color;
  final Color fondo;
  final double x; // desplazamiento horizontal final respecto al centro
  final double y; // posición final (centro) dentro de la escena
  final double inicio; // 0..1 cuándo empieza a caer
  final double giro; // radianes de inclinación final
}

const _items = <_Item>[
  _Item(LucideIcons.cupSoda, C.azul, Color(0xFFDCEBF7), -58, 104, .02, -.18),
  _Item(LucideIcons.apple, C.rojo, Color(0xFFFBE0DE), 56, 108, .14, .16),
  _Item(LucideIcons.milk, C.verdeBanner, Color(0xFFFFFFFF), -4, 82, .26, .05),
  _Item(LucideIcons.croissant, Color(0xFF9A5B13), Color(0xFFFBEFD5), -28, 112, .38, -.08),
  _Item(LucideIcons.carrot, Color(0xFFC25A12), Color(0xFFFCE5D2), 32, 114, .50, .12),
];

class _SplashPantallaState extends State<SplashPantalla> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  bool _iniciado = false;
  bool _ido = false;
  Future<void> _imagenes = Future.value();

  /// Versión completa con canasta (primera vez o pedida) o breve con solo el logo.
  late final bool _completa = widget.completa ?? !estado.cargaBreve;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: widget.duracion ?? (_completa ? const Duration(milliseconds: 5000) : const Duration(milliseconds: 1400)));
    _ctl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _terminar();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    // Mientras se ve la carga, se dejan listas las imágenes de las primeras pantallas (con el mismo tamaño
    // con que se mostrarán), para que no aparezcan "de a poco" al entrar.
    _imagenes = _precargar(context);
    // Modo revisión de diseño: ?splash=0.5 congela la animación en ese instante.
    final fijo = kDebugMode ? double.tryParse(Uri.base.queryParameters['splash'] ?? '') : null;
    if (fijo != null) {
      _ctl.value = fijo.clamp(0.0, 1.0);
      return;
    }
    if (sinMovimiento(context)) {
      _ctl.value = 1;
      Future.delayed(const Duration(milliseconds: 2500), _terminar);
    } else {
      _ctl.forward();
    }
  }

  /// Avanza cuando la carga real terminó (si falla, la tienda muestra el error en cada sección).
  Future<void> _terminar() async {
    if (_ido || !mounted) return;
    _ido = true;
    try {
      await widget.carga;
    } catch (_) {}
    // Espera las imágenes un momento como máximo: nunca retiene la entrada por ellas.
    await _imagenes.timeout(const Duration(seconds: 2), onTimeout: () {});
    if (!mounted) return;
    if (widget.alTerminar != null) {
      widget.alTerminar!();
      return;
    }
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: dur(context, 500),
      pageBuilder: (_, _, _) => const BienvenidaPantalla(),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _precargar(BuildContext context) {
    ImageProvider an(String ruta, {int? ancho, int? alto}) =>
        ancho == null && alto == null ? AssetImage(ruta) : ResizeImage(AssetImage(ruta), width: ancho, height: alto);
    final lista = [
      an('assets/img/logo.webp', ancho: 260),
      an('assets/img/hero/bebidas.webp', alto: 420),
      an('assets/img/hero/abarrotes.webp', alto: 420),
      an('assets/img/patrones/oscuro-v2.webp'),
      an('assets/img/tutorial/elige.webp', ancho: 200),
      an('assets/img/tutorial/paga.webp', ancho: 200),
      an('assets/img/tutorial/recibe.webp', ancho: 200),
      an('assets/img/hero/abarrotes.webp', ancho: 420),
      an('assets/img/hero/dulces.webp', ancho: 420),
      an('assets/img/hero/bebidas.webp', ancho: 420),
    ];
    return Future.wait([for (final i in lista) precacheImage(i, context).catchError((_) {})]).then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final quieto = sinMovimiento(context);
    return Scaffold(
      backgroundColor: C.verdeFondo,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _terminar, // un toque en cualquier parte salta la animación (y espera la carga real)
        child: Semantics(
        hint: 'Toca la pantalla para entrar ahora',
        child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.verdeFondo, Color(0xFF184A37)]),
        ),
        child: Stack(children: [
          Positioned.fill(child: Image.asset('assets/img/patrones/oscuro.webp', fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(.2))),
          if (!quieto && _completa) Positioned.fill(child: _Burbujas(animacion: _ctl)),
          SafeArea(
            child: Column(children: [
              const Spacer(flex: 3),
              Semantics(
                label: 'Comercial Sedyjo, cargando la tienda',
                child: Transform.scale(
                  scale: 1.15,
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: AnimatedBuilder(
                      animation: _ctl,
                      builder: (_, _) => _Escena(t: _ctl.value, completa: _completa),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Esp.x3),
              AnimatedBuilder(
                animation: _ctl,
                builder: (_, _) {
                  final t = _ctl.value;
                  final aparece = Curves.easeOut.transform(((t - (_completa ? .74 : .25)) / (_completa ? .16 : .3)).clamp(0.0, 1.0));
                  return Opacity(
                    opacity: aparece,
                    child: Transform.translate(
                      offset: Offset(0, (1 - aparece) * 12),
                      child: Column(children: [
                        Text('Comercial Sedyjo',
                            style: T.titulo1.copyWith(color: Colors.white, fontSize: 32, letterSpacing: -.3)),
                        const SizedBox(height: Esp.x2),
                        Text('Tu compra, directo a tu casa',
                            style: T.cuerpo.copyWith(color: C.verdePalido, fontSize: 18)),
                      ]),
                    ),
                  );
                },
              ),
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _ctl,
                builder: (_, _) {
                  final t = _ctl.value;
                  final frases = _completa ? ['Abriendo la tienda…', 'Eligiendo tus favoritos…', 'Buscando las ofertas…', '¡Todo listo!'] : ['Abriendo la tienda…', 'Abriendo la tienda…', 'Abriendo la tienda…', '¡Todo listo!'];
                  final fase = (t * 3.99).floor().clamp(0, 3);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56),
                    child: Column(children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(frases[fase], style: T.cuerpo.copyWith(color: Colors.white, fontSize: 17)),
                      ),
                      const SizedBox(height: Esp.x3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: Curves.easeInOut.transform(t),
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: .16),
                          color: C.verdeMenta,
                        ),
                      ),
                      const SizedBox(height: Esp.x3),
                      // Pista para saltar la carga, que aparece después de un momento.
                      Text('Toca para entrar', style: T.apoyo.copyWith(color: Colors.white.withValues(alpha: .7 * Curves.easeOut.transform(((t - .15) / .2).clamp(0.0, 1.0))))),
                    ]),
                  );
                },
              ),
              const SizedBox(height: 56),
            ]),
          ),
        ]),
      ),
      ),
      ),
    );
  }
}

class _Escena extends StatelessWidget {
  const _Escena({required this.t, required this.completa});
  final double t;
  final bool completa;

  @override
  Widget build(BuildContext context) {
    if (!completa) return _LogoBreve(t: t);
    // Fase 1 (0 → .72): caen los productos. Fase 2 (.70 → .86): la canasta se funde con el logo.
    final transicion = Curves.easeInOutCubic.transform(((t - .70) / .16).clamp(0.0, 1.0));
    final logo = Curves.elasticOut.transform(((t - .76) / .22).clamp(0.0, 1.0));

    // Pequeño "golpecito" de la canasta cada vez que cae un producto.
    var golpe = 0.0;
    for (final it in _items) {
      final aterriza = it.inicio + .20;
      final d = t - aterriza;
      if (d >= 0 && d < .07) golpe += math.sin(d / .07 * math.pi);
    }
    final squash = 1 - golpe * .045;
    final entrada = Curves.easeOutBack.transform((t / .08).clamp(0.0, 1.0));

    return Stack(alignment: Alignment.center, children: [
      // Canasta + productos (se desvanece al aparecer el logo)
      Opacity(
        opacity: (1 - transicion).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: (.4 + .6 * entrada) * (1 - transicion * .25),
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.diagonal3Values(1 + golpe * .02, squash, 1),
            child: SizedBox(
              width: 260,
              height: 260,
              // Sin recorte: los íconos nacen por encima de la canasta y no deben cortarse en el borde de la escena.
              child: Stack(clipBehavior: Clip.none, children: [
                const Positioned.fill(child: CustomPaint(painter: _CanastaTrasera())),
                for (final it in _items) _ProductoCayendo(item: it, t: t),
                const Positioned.fill(child: CustomPaint(painter: _CanastaFrontal())),
              ]),
            ),
          ),
        ),
      ),
      // Logo
      if (logo > 0)
        Opacity(
          opacity: logo.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: .55 + .45 * logo,
            child: Container(
              width: 236,
              height: 236,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 30, offset: const Offset(0, 14)),
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/img/logo.webp', fit: BoxFit.cover, cacheWidth: 520, semanticLabel: 'Logo de Comercial Sedyjo'),
              ),
            ),
          ),
        ),
    ]);
  }
}

/// Versión breve (aperturas siguientes): el logo aparece con un asentamiento suave, sin canasta.
class _LogoBreve extends StatelessWidget {
  const _LogoBreve({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final p = Curves.easeOutBack.transform((t / .45).clamp(0.0, 1.0));
    return Center(
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: const Size.square(320), painter: _Estallido((t / .5).clamp(0.0, 1.0))),
        Opacity(
        opacity: (t / .25).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: .55 + .45 * p,
          child: Container(
            width: 236,
            height: 236,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 30, offset: const Offset(0, 14))],
            ),
            child: ClipOval(child: Image.asset('assets/img/logo.webp', fit: BoxFit.cover, cacheWidth: 520, semanticLabel: 'Logo de Comercial Sedyjo')),
          ),
        ),
      ),
      ]),
    );
  }
}

/// Un producto que nace de una burbuja "al revés": en un punto sobre la canasta ocurre el estallido (un aro que se
/// expande y gotitas que salen disparadas) y del centro emerge el ícono, envuelto en una burbuja transparente que se
/// va disolviendo mientras cae suavemente hasta la canasta.
class _ProductoCayendo extends StatelessWidget {
  const _ProductoCayendo({required this.item, required this.t});
  final _Item item;
  final double t;

  @override
  Widget build(BuildContext context) {
    final p = ((t - item.inicio) / .20).clamp(0.0, 1.0);
    if (p == 0) return const SizedBox();
    const alto = 64.0;
    // El ícono emerge del estallido (0 → .28) y recién ahí empieza a caer.
    final emerge = Curves.easeOutBack.transform((p / .30).clamp(0.0, 1.0));
    final caida = Curves.easeInOutSine.transform(((p - .10) / .90).clamp(0.0, 1.0));
    const yNacer = -52.0;
    final yFin = item.y - alto / 2;
    final y = yNacer + (yFin - yNacer) * caida;
    // Nace más cerca del centro y se desliza hacia su lugar final.
    final x = item.x * (.35 + .65 * caida);
    // La burbuja que envuelve al ícono se disuelve entre .30 y .62.
    final membrana = 1 - Curves.easeIn.transform(((p - .30) / .32).clamp(0.0, 1.0));
    // Un balanceo suave mientras cae.
    final giro = item.giro * Curves.easeOut.transform(p) + math.sin(p * math.pi * 2) * .08 * (1 - p);
    const caja = 140.0;
    return Positioned(
      left: 130 + x - caja / 2,
      top: y + alto / 2 - caja / 2,
      child: SizedBox(
        width: caja,
        height: caja,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(size: const Size.square(caja), painter: _Estallido(p)),
          if (membrana > 0)
            Transform.scale(
              scale: .55 + .45 * Curves.easeOut.transform((p / .35).clamp(0.0, 1.0)),
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-.35, -.4),
                    colors: [Colors.white.withValues(alpha: .34 * membrana), Colors.white.withValues(alpha: .06 * membrana)],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: .55 * membrana), width: 1.5),
                ),
              ),
            ),
          Transform.rotate(
            angle: giro,
            child: Transform.scale(
              scale: emerge,
              child: Container(
                width: alto,
                height: alto,
                decoration: BoxDecoration(
                  color: item.fondo,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Icon(item.icono, size: 36, color: item.color),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// El estallido que da origen a la burbuja: un aro que se expande y desvanece, y seis gotitas que salen disparadas.
/// Dura el primer tercio de la aparición ([p] va de 0 a 1 en toda ella).
class _Estallido extends CustomPainter {
  const _Estallido(this.p);
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    final e = (p / .38).clamp(0.0, 1.0);
    if (e >= 1) return;
    final c = size.center(Offset.zero);
    final salida = Curves.easeOutCubic.transform(e);
    final alfa = 1 - Curves.easeIn.transform(e);
    canvas.drawCircle(
      c,
      10 + 46 * salida,
      Paint()
        ..color = Colors.white.withValues(alpha: .75 * alfa)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2 * (1 - e) + .8,
    );
    for (var k = 0; k < 6; k++) {
      final ang = (k * 60 + 18) * math.pi / 180;
      final d = 18 + 38 * salida;
      canvas.drawCircle(c + Offset(math.cos(ang), math.sin(ang)) * d, 4.2 * (1 - e) + 1, Paint()..color = Colors.white.withValues(alpha: .85 * alfa));
    }
  }

  @override
  bool shouldRepaint(covariant _Estallido old) => old.p != p;
}

const _mimbre = Color(0xFFE3B66B);
const _mimbreOscuro = Color(0xFFB9853A);
const _mimbreClaro = Color(0xFFF2CE8E);

/// Parte de atrás de la canasta: asa e interior oscuro.
class _CanastaTrasera extends CustomPainter {
  const _CanastaTrasera();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // Asa
    final asa = Paint()
      ..color = _mimbreOscuro
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    final ruta = Path()
      ..moveTo(cx - 84, 150)
      ..cubicTo(cx - 84, 20, cx + 84, 20, cx + 84, 150);
    canvas.drawPath(ruta, asa);
    final brillo = Paint()
      ..color = _mimbreClaro.withValues(alpha: .7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        Path()
          ..moveTo(cx - 76, 138)
          ..cubicTo(cx - 76, 38, cx + 76, 38, cx + 76, 138),
        brillo);
    // Interior
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, 150), width: 190, height: 34), Paint()..color = const Color(0xFF6B4515));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Frente de la canasta: cuerpo trenzado que tapa la parte baja de los productos.
class _CanastaFrontal extends CustomPainter {
  const _CanastaFrontal();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const arriba = 150.0;
    const abajo = 238.0;
    final cuerpo = Path()
      ..moveTo(cx - 100, arriba)
      ..lineTo(cx + 100, arriba)
      ..lineTo(cx + 74, abajo - 10)
      ..quadraticBezierTo(cx + 72, abajo, cx + 60, abajo)
      ..lineTo(cx - 60, abajo)
      ..quadraticBezierTo(cx - 72, abajo, cx - 74, abajo - 10)
      ..close();
    canvas.drawPath(
        cuerpo,
        Paint()
          ..shader = const LinearGradient(colors: [_mimbreClaro, _mimbre, _mimbreOscuro], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              .createShader(Rect.fromLTWH(0, arriba, size.width, abajo - arriba)));
    // Trenzado
    canvas.save();
    canvas.clipPath(cuerpo);
    final linea = Paint()
      ..color = _mimbreOscuro.withValues(alpha: .55)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (var y = arriba + 22; y < abajo; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linea);
    }
    for (var x = -20.0; x < size.width + 40; x += 26) {
      final desplazar = ((x / 26).round() % 2 == 0) ? 0.0 : 11.0;
      for (var y = arriba + desplazar; y < abajo; y += 22) {
        canvas.drawLine(Offset(x + (y - arriba) * .0, y), Offset(x, y + 11), linea);
      }
    }
    canvas.restore();
    // Borde superior
    final borde = RRect.fromRectAndRadius(Rect.fromLTWH(cx - 108, arriba - 9, 216, 20), const Radius.circular(10));
    canvas.drawRRect(borde, Paint()..color = _mimbreOscuro);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx - 104, arriba - 7, 208, 8), const Radius.circular(5)),
        Paint()..color = _mimbreClaro);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Burbujas suaves que suben por el fondo (mismo recurso decorativo de la web).
class _Burbujas extends StatelessWidget {
  const _Burbujas({required this.animacion});
  final Animation<double> animacion;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animacion,
      builder: (_, _) => CustomPaint(painter: _PintorBurbujas(animacion.value)),
    );
  }
}

class _PintorBurbujas extends CustomPainter {
  _PintorBurbujas(this.t);
  final double t;
  static const _b = [
    [.12, 38.0, .00], [.30, 22.0, .35], [.52, 54.0, .15], [.74, 28.0, .55], [.90, 44.0, .25], [.20, 18.0, .70], [.64, 16.0, .85],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in _b) {
      final fase = (t * 1.2 + b[2]) % 1.0;
      final y = size.height * (1.08 - fase * 1.2);
      final x = size.width * b[0] + math.sin(fase * math.pi * 2) * 10;
      canvas.drawCircle(Offset(x, y), b[1], Paint()..color = Colors.white.withValues(alpha: .05));
      canvas.drawCircle(
          Offset(x, y),
          b[1],
          Paint()
            ..color = Colors.white.withValues(alpha: .08)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant _PintorBurbujas old) => old.t != t;
}
