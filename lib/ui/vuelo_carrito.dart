import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/tema.dart';

/// Clave del ícono del carrito en la barra de navegación (o en el riel lateral). Solo existe uno a la vez.
/// Con ella, [volarAlCarrito] sabe dónde aterrizar.
final GlobalKey claveCarrito = GlobalKey(debugLabel: 'iconoCarrito');

/// Todos los íconos de carrito que existen ahora (el de la barra de navegación y los carritos pequeños de las pantallas
/// que la tapan). La burbuja aterriza en el de la pantalla que se está viendo.
final Set<BuildContext> _carritosRegistrados = {};

/// Sube cada vez que una burbuja llega al carrito. El ícono del carrito lo escucha para hacer su pulso.
final ValueNotifier<int> llegadasCarrito = ValueNotifier<int>(0);

int _entradasActivas = 0;

/// Cuántas capas de animación (burbujas y abanicos) siguen en el overlay. Debe volver a 0 al terminar todo.
int get entradasDeVueloActivas => _entradasActivas;

const Duration _duracionVuelo = Duration(milliseconds: 560);
const Duration _duracionAbanico = Duration(milliseconds: 480);
const Curve _curvaVuelo = Cubic(0.4, 0, 0.2, 1);
const double _diametro = 22;

/// Una burbuja sale del botón [origen], viaja en arco hasta el ícono del carrito y, al llegar, el carrito
/// hace un pulso, el contador rebota y salen seis burbujitas. En tarjetas oscuras la burbuja es dorada ([oscuro]).
///
/// Si el carrito no se ve (por ejemplo, en la ficha de un producto que lo tapa), la burbuja termina en el borde
/// superior de la pantalla. Cada llamada lanza su propia burbuja: tocar muchas veces seguidas no bloquea las anteriores.
/// La animación es decorativa (sin semántica) y no recibe toques.
void volarAlCarrito(BuildContext origen, {bool oscuro = false}) {
  final overlay = Overlay.maybeOf(origen, rootOverlay: true);
  final cajaOrigen = origen.findRenderObject();
  if (overlay == null || cajaOrigen is! RenderBox || !cajaOrigen.attached || !cajaOrigen.hasSize) return;
  final cajaOverlay = overlay.context.findRenderObject();
  if (cajaOverlay is! RenderBox || !cajaOverlay.hasSize) return;

  final inicio = cajaOverlay.globalToLocal(cajaOrigen.localToGlobal(cajaOrigen.size.center(Offset.zero)));
  final carrito = _centroDelCarrito(cajaOverlay);
  // Si el carrito no está a la vista, la burbuja termina en el borde superior de la pantalla.
  final fin = carrito ?? Offset(inicio.dx, 0);

  late final OverlayEntry entrada;
  entrada = OverlayEntry(
    builder: (_) => BurbujaVuelo(
      inicio: inicio,
      fin: fin,
      oscuro: oscuro,
      alCancelar: () => _quitar(entrada),
      alLlegar: () {
        _quitar(entrada);
        if (carrito != null) {
          llegadasCarrito.value++;
          _lanzarAbanico(overlay, carrito, oscuro);
        }
      },
    ),
  );
  _insertar(overlay, entrada);
}

void _insertar(OverlayState overlay, OverlayEntry entrada) {
  _entradasActivas++;
  overlay.insert(entrada);
}

/// Centro del ícono del carrito en coordenadas del overlay, o `null` si no está a la vista.
Offset? _centroDelCarrito(RenderBox cajaOverlay) {
  // El carrito de la pantalla que se está viendo (el de la barra de navegación o el pequeño de una pantalla que la tapa).
  for (final ctx in _carritosRegistrados) {
    if (!ctx.mounted) continue;
    final caja = ctx.findRenderObject();
    if (caja is! RenderBox || !caja.attached || !caja.hasSize) continue;
    // Si hay otra pantalla encima de la que tiene este carrito, no se ve.
    final ruta = ModalRoute.of(ctx);
    if (ruta != null && !ruta.isCurrent) continue;
    final centro = cajaOverlay.globalToLocal(caja.localToGlobal(caja.size.center(Offset.zero)));
    if ((Offset.zero & cajaOverlay.size).contains(centro)) return centro;
  }
  return null;
}

void _quitar(OverlayEntry entrada) {
  // Se quita después del cuadro actual: nunca durante la animación que la está llamando.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (entrada.mounted) entrada.remove();
    entrada.dispose();
    _entradasActivas--;
  });
}

void _lanzarAbanico(OverlayState overlay, Offset centro, bool oscuro) {
  late final OverlayEntry entrada;
  entrada = OverlayEntry(builder: (_) => _Abanico(centro: centro, oscuro: oscuro, alTerminar: () => _quitar(entrada)));
  _insertar(overlay, entrada);
}

/// La burbuja que vuela. Pública para poder comprobarla en pruebas.
class BurbujaVuelo extends StatefulWidget {
  const BurbujaVuelo({super.key, required this.inicio, required this.fin, required this.oscuro, required this.alLlegar, this.alCancelar});
  final Offset inicio;
  final Offset fin;
  final bool oscuro;
  final VoidCallback alLlegar;

  /// Se llama si la burbuja se destruye antes de llegar (por ejemplo, el overlay se desarma): la capa se retira igual.
  final VoidCallback? alCancelar;

  @override
  State<BurbujaVuelo> createState() => _BurbujaVueloState();
}

class _BurbujaVueloState extends State<BurbujaVuelo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: _duracionVuelo);
  bool _llego = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_llego) {
        _llego = true;
        widget.alLlegar();
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    if (!_llego) widget.alCancelar?.call();
    _c.dispose();
    super.dispose();
  }

  /// Curva cuadrática: el punto de control está a mitad de camino y 70 px más arriba que la recta.
  Offset _posicion(double e) {
    final a = widget.inicio;
    final b = widget.fin;
    final control = Offset.lerp(a, b, .5)! + const Offset(0, -70);
    final u = 1 - e;
    return a * (u * u) + control * (2 * u * e) + b * (e * e);
  }

  /// 1 → 1,15 hacia el 45 % del tiempo → 0,4 al llegar.
  double _escala(double t) => t < .45 ? 1 + .15 * (t / .45) : 1.15 + (.4 - 1.15) * ((t - .45) / .55);

  @override
  Widget build(BuildContext context) {
    final inicio = widget.inicio;
    return Positioned.fill(
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: Stack(children: [
            Positioned(
              left: inicio.dx - _diametro / 2,
              top: inicio.dy - _diametro / 2,
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, hijo) {
                  final e = _curvaVuelo.transform(_c.value);
                  return Transform.translate(
                    offset: _posicion(e) - inicio,
                    child: Transform.scale(
                      scale: _escala(_c.value),
                      // La transparencia va dentro de los colores de la burbuja: sin capa de opacidad aparte.
                      child: _Burbuja(diametro: _diametro, oscuro: widget.oscuro, alfa: 1 - .1 * _c.value),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Las seis burbujitas que salen del carrito en abanico (cada 60° + 30°, a 26 y 34 px alternando).
class _Abanico extends StatefulWidget {
  const _Abanico({required this.centro, required this.oscuro, required this.alTerminar});
  final Offset centro;
  final bool oscuro;
  final VoidCallback alTerminar;

  @override
  State<_Abanico> createState() => _AbanicoState();
}

class _AbanicoState extends State<_Abanico> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: _duracionAbanico);
  static const _tamanos = [7.0, 9.0, 11.0, 8.0, 10.0, 9.0];

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.alTerminar();
    });
    _c.forward();
  }

  @override
  void dispose() {
    if (_c.status != AnimationStatus.completed) widget.alTerminar();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final salida = Curves.easeOutCubic.transform(_c.value);
              return Stack(children: [
                for (var i = 0; i < 6; i++)
                  () {
                    final angulo = (i * 60 + 30) * math.pi / 180;
                    final distancia = (i.isEven ? 26.0 : 34.0) * salida;
                    final d = _tamanos[i];
                    final p = widget.centro + Offset(math.cos(angulo), math.sin(angulo)) * distancia;
                    return Positioned(
                      left: p.dx - d / 2,
                      top: p.dy - d / 2,
                      child: Transform.scale(scale: .6 + .4 * _c.value, child: _Burbuja(diametro: d, oscuro: widget.oscuro, alfa: .95 * (1 - _c.value))),
                    );
                  }(),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

/// Círculo con brillo: verde menta con borde verde de marca; dorado sobre tarjetas oscuras.
class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.diametro, required this.oscuro, this.alfa = 1});
  final double diametro;
  final bool oscuro;

  /// Transparencia general (0 a 1), aplicada a cada color.
  final double alfa;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: oscuro
            ? RadialGradient(
                center: const Alignment(-0.4, -0.44),
                colors: [C.oro.withValues(alpha: .70 * alfa), C.oro.withValues(alpha: .25 * alfa)],
              )
            : RadialGradient(
                center: const Alignment(-0.4, -0.44),
                colors: [Colors.white.withValues(alpha: .95 * alfa), C.verdeMenta.withValues(alpha: .34 * alfa), C.verdeMenta.withValues(alpha: .10 * alfa)],
                stops: const [0, .62, 1],
              ),
        border: Border.all(color: oscuro ? C.oro.withValues(alpha: .60 * alfa) : C.verde.withValues(alpha: .24 * alfa)),
      ),
    );
  }
}

/// Ícono del carrito con su contador. Al llegar una burbuja, el ícono hace un pulso (1 → 1,1 → 1 en 340 ms)
/// y el contador rebota (1 → 1,4 → 1 en 380 ms). Solo anima transformaciones, dentro de este widget.
class IconoCarritoAnimado extends StatefulWidget {
  const IconoCarritoAnimado({super.key, required this.icono, required this.cantidad});
  final IconData icono;
  final int cantidad;

  @override
  State<IconoCarritoAnimado> createState() => _IconoCarritoAnimadoState();
}

class _IconoCarritoAnimadoState extends State<IconoCarritoAnimado> with TickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(vsync: this, duration: const Duration(milliseconds: 340));
  late final AnimationController _rebote = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

  late final Animation<double> _escalaIcono = _ida(_pulso, 1.1);
  late final Animation<double> _escalaContador = _ida(_rebote, 1.4);

  /// 1 → [pico] → 1 con desaceleración exponencial en cada tramo.
  static Animation<double> _ida(AnimationController c, double pico) => TweenSequence<double>([
        TweenSequenceItem(tween: Tween<double>(begin: 1, end: pico).chain(CurveTween(curve: Curves.easeOutExpo)), weight: 40),
        TweenSequenceItem(tween: Tween<double>(begin: pico, end: 1).chain(CurveTween(curve: Curves.easeOutExpo)), weight: 60),
      ]).animate(c);

  @override
  void initState() {
    super.initState();
    _carritosRegistrados.add(context);
    llegadasCarrito.addListener(_alLlegar);
  }

  void _alLlegar() {
    _pulso.forward(from: 0);
    _rebote.forward(from: 0);
  }

  @override
  void dispose() {
    _carritosRegistrados.remove(context);
    llegadasCarrito.removeListener(_alLlegar);
    _pulso.dispose();
    _rebote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.cantidad;
    return ScaleTransition(
      scale: _escalaIcono,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        Icon(widget.icono),
        if (n > 0)
          Positioned(
            right: -12,
            top: -10,
            child: ScaleTransition(
              scale: _escalaContador,
              child: Container(
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: C.azul, borderRadius: BorderRadius.circular(R.s), border: Border.all(color: C.superficie, width: 2)),
                child: Text('$n', style: T.etiqueta.copyWith(color: Colors.white, fontSize: 14, height: 1)),
              ),
            ),
          ),
      ]),
    );
  }
}
