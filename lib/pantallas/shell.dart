import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/componentes.dart';
import 'carrito.dart';
import 'categorias.dart';
import 'cuenta.dart';
import 'inicio.dart';
import 'ofertas.dart';
import 'producto.dart';

/// Oferta relámpago dentro de la app. Viene activa por defecto y se queda hasta que el usuario la cierra.
/// Solo aparece mientras navega la tienda (Inicio, Categorías, Ofertas): nunca sobre Carrito, Cuenta o el pago.
/// La maqueta la dispara a los 20 s y luego según la frecuencia elegida; el panel lateral permite forzarla.
final ValueNotifier<Producto?> relampago = ValueNotifier(null);
int _giro = 4; // arranca lejos de lo primero que se ve en Inicio para no repetir el mismo producto

void mostrarRelampago({bool forzar = false}) {
  if (!forzar && (estado.relampagoSilenciadoHoy || estado.minutosOfertas == 0)) return;
  final ofertas = Catalogo.enOferta();
  if (ofertas.isEmpty) return;
  relampago.value = ofertas[_giro++ % ofertas.length];
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  Timer? _primero;
  Timer? _periodico;

  @override
  void initState() {
    super.initState();
    _primero = Timer(const Duration(seconds: 20), () {
      _intentarMostrar();
      _programarPeriodico();
    });
    estado.addListener(_reprogramar);
  }

  /// Respeta el momento: si el usuario está pagando, mirando su carrito o su cuenta, espera al próximo turno.
  void _intentarMostrar() {
    if (!mounted || relampago.value != null) return;
    final enTienda = estado.pestana <= 2;
    final visible = ModalRoute.of(context)?.isCurrent ?? true;
    if (enTienda && visible) mostrarRelampago();
  }

  int _ultimaFrecuencia = -1;
  void _reprogramar() {
    if (estado.minutosOfertas != _ultimaFrecuencia && _periodico != null) _programarPeriodico();
  }

  void _programarPeriodico() {
    _periodico?.cancel();
    _ultimaFrecuencia = estado.minutosOfertas;
    if (estado.minutosOfertas == 0) return;
    _periodico = Timer.periodic(Duration(minutes: estado.minutosOfertas), (_) => _intentarMostrar());
  }

  @override
  void dispose() {
    _primero?.cancel();
    _periodico?.cancel();
    estado.removeListener(_reprogramar);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        // En pantallas anchas (tableta, horizontal) la navegación pasa a un riel lateral.
        final ancha = MediaQuery.sizeOf(context).width >= 720;
        return Scaffold(
          body: Row(children: [
            if (ancha) const _Riel(),
            Expanded(
              child: Stack(children: [
                _Pestanas(indice: estado.pestana, retoques: estado.retoques),
                if (estado.pestana <= 2)
                  const Positioned(left: 12, right: 12, top: 0, child: SafeArea(bottom: false, child: _AvisoRelampago())),
              ]),
            ),
          ]),
          bottomNavigationBar: ancha ? null : const BarraInferior(),
        );
      },
    );
  }
}

/// Las cinco pestañas siguen vivas (conservan su desplazamiento), pero solo la visible anima: las demás tienen
/// el reloj de animaciones detenido. Al cambiar de pestaña la nueva aparece con un fundido corto; tocar la pestaña
/// activa otra vez la devuelve arriba.
class _Pestanas extends StatefulWidget {
  const _Pestanas({required this.indice, required this.retoques});
  final int indice;
  final int retoques;

  @override
  State<_Pestanas> createState() => _PestanasState();
}

class _PestanasState extends State<_Pestanas> with SingleTickerProviderStateMixin {
  late final AnimationController _entrada = AnimationController(vsync: this, duration: Mov.cambio, value: 1);
  late final Animation<double> _curva = CurvedAnimation(parent: _entrada, curve: Mov.entra);
  final _desplazamientos = List.generate(5, (_) => ScrollController());

  static const _pestanas = <Widget>[InicioPestana(), CategoriasPestana(), OfertasPestana(), CarritoPestana(), CuentaPestana()];

  @override
  void didUpdateWidget(_Pestanas old) {
    super.didUpdateWidget(old);
    if (widget.indice != old.indice && !sinMovimiento(context)) _entrada.forward(from: 0);
    if (widget.retoques != old.retoques && widget.indice == old.indice) {
      final c = _desplazamientos[widget.indice];
      if (c.hasClients) c.animateTo(0, duration: dur(context, 300), curve: Mov.entra);
    }
  }

  @override
  void dispose() {
    _entrada.dispose();
    for (final c in _desplazamientos) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curva,
      child: ScaleTransition(
        scale: Tween<double>(begin: .985, end: 1).animate(_curva),
        child: IndexedStack(index: widget.indice, children: [
          for (var i = 0; i < _pestanas.length; i++)
            TickerMode(
              enabled: i == widget.indice,
              child: PrimaryScrollController(controller: _desplazamientos[i], child: _pestanas[i]),
            ),
        ]),
      ),
    );
  }
}

const _destinos = [
  (LucideIcons.house, 'Inicio'),
  (LucideIcons.layoutGrid, 'Categorías'),
  (LucideIcons.percent, 'Ofertas'),
  (LucideIcons.shoppingCart, 'Carrito'),
  (LucideIcons.userRound, 'Cuenta'),
];

void _elegirPestana(int i) {
  if (i == estado.pestana) {
    estado.retocarPestana();
  } else {
    estado.irAPestana(i);
  }
}

/// Ícono del carrito con la cantidad. Lleva [claveCarrito]: es donde aterrizan las burbujas de "agregar".
/// Al llegar una burbuja, el ícono pulsa y el contador rebota.
Widget _iconoDestino(int i) {
  final icono = _destinos[i].$1;
  if (i != 3) return Icon(icono);
  return IconoCarritoAnimado(key: claveCarrito, icono: icono, cantidad: estado.cantidadCarrito);
}

/// Barra inferior de Material 3 (indicador de píldora, etiquetas siempre visibles, tope de letra para que quepa).
class BarraInferior extends StatelessWidget {
  const BarraInferior({super.key, this.alElegir});

  /// Qué hacer al tocar un destino. Por defecto cambia de pestaña; una pantalla que está encima de la tienda
  /// (como el resultado del pago) pasa su propio comportamiento para volver primero a la tienda.
  final ValueChanged<int>? alElegir;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: C.borde))),
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: 1,
          maxScaleFactor: 1.12,
          child: NavigationBar(
            selectedIndex: estado.pestana,
            onDestinationSelected: alElegir ?? _elegirPestana,
            destinations: [
              for (var i = 0; i < _destinos.length; i++)
                NavigationDestination(
                  icon: _iconoDestino(i),
                  label: _destinos[i].$2,
                  tooltip: _destinos[i].$2 + (i == 3 && estado.cantidadCarrito > 0 ? ', ${estado.cantidadCarrito} productos' : ''),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navegación lateral para pantallas anchas.
class _Riel extends StatelessWidget {
  const _Riel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(right: BorderSide(color: C.borde))),
      child: SafeArea(
        right: false,
        child: NavigationRail(
          backgroundColor: C.superficie,
          selectedIndex: estado.pestana,
          onDestinationSelected: _elegirPestana,
          labelType: NavigationRailLabelType.all,
          indicatorColor: C.verdeSuave,
          selectedIconTheme: IconThemeData(color: C.verdeOscuro, size: 25),
          unselectedIconTheme: IconThemeData(color: C.grisMedio, size: 25),
          selectedLabelTextStyle: T.etiqueta.copyWith(color: C.verdeOscuro, fontWeight: FontWeight.w800),
          unselectedLabelTextStyle: T.etiqueta.copyWith(color: C.grisMedio),
          destinations: [
            for (var i = 0; i < _destinos.length; i++)
              NavigationRailDestination(icon: _iconoDestino(i), label: Text(_destinos[i].$2)),
          ],
        ),
      ),
    );
  }
}

/// Aviso de oferta relámpago dentro de la app: baja desde arriba, se puede cerrar y no tapa la navegación.
class _AvisoRelampago extends StatelessWidget {
  const _AvisoRelampago();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Producto?>(
      valueListenable: relampago,
      builder: (context, p, _) {
        return AnimatedSwitcher(
          duration: dur(context, 420),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => SlideTransition(
            position: Tween(begin: const Offset(0, -1.4), end: Offset.zero).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: p == null ? const SizedBox(key: ValueKey('vacio')) : _TarjetaRelampago(key: ValueKey(p.id), p: p),
        );
      },
    );
  }
}

class _TarjetaRelampago extends StatelessWidget {
  const _TarjetaRelampago({super.key, required this.p});
  final Producto p;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Oferta relámpago: ${p.nombre}, ${p.descuento} por ciento de descuento, ahora ${p.precioFinal} pesos',
      child: Container(
        margin: const EdgeInsets.only(top: Esp.x2),
        padding: const EdgeInsets.fromLTRB(Esp.x3, Esp.x2, Esp.x2, Esp.x2),
        decoration: BoxDecoration(
          color: C.negro,
          borderRadius: BorderRadius.circular(R.l),
          border: Border.all(color: C.carbonBorde),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 22, offset: const Offset(0, 10))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(LucideIcons.zap, color: C.oro, size: Ico.s),
            const SizedBox(width: Esp.x2),
            Text('OFERTA RELÁMPAGO', style: T.etiqueta.copyWith(color: C.oro, fontSize: 14, letterSpacing: .6)),
            const Spacer(),
            BotonIcono(LucideIcons.x, 'Cerrar aviso de oferta', onTap: () => relampago.value = null, fondo: C.carbon, color: Colors.white, tam: 48),
          ]),
          Padding(
            padding: const EdgeInsets.only(right: Esp.x2),
            child: Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(R.s), child: SizedBox(width: 74, height: 74, child: FotoProducto(p))),
              const SizedBox(width: Esp.x3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.cuerpoFuerte.copyWith(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: Esp.x1),
                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
                    Text(clp(p.precioFinal), style: T.precio.copyWith(color: C.oro, fontSize: 22)),
                    Insignia('-${p.descuento}%'),
                  ]),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: Esp.x3),
          Padding(
            padding: const EdgeInsets.only(right: Esp.x2),
            child: Builder(builder: (context) {
              final grande = MediaQuery.textScalerOf(context).scale(10) / 10 > 1.15;
              final ver = Boton('Ver oferta', estilo: EstiloBoton.dorado, alto: 50, onTap: () {
                relampago.value = null;
                irA(context, ProductoPantalla(p));
              });
              final agregar = Boton('Agregar', etiqueta: 'Agregar ${p.nombre} al carrito', icono: LucideIcons.plus, alto: 50, alTocarEn: (ctx) {
                vibracionLeve();
                estado.agregar(p);
                // La burbuja sale del botón antes de que el aviso se cierre; la tarjeta es negra, así que va dorada.
                volarAlCarrito(ctx, oscuro: true);
                relampago.value = null;
              });
              return grande
                  ? Column(children: [ver, const SizedBox(height: Esp.x2), agregar])
                  : Row(children: [Expanded(child: ver), const SizedBox(width: Esp.x2), Expanded(child: agregar)]);
            }),
          ),
          Tocable(
            etiqueta: 'No mostrar más ofertas relámpago hoy',
            onTap: () {
              relampago.value = null;
              estado.silenciarRelampagoHoy();
            },
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: Text('No mostrar más hoy', style: T.cuerpoFuerte.copyWith(color: const Color(0xFFD7D7E0), fontSize: 15, decoration: TextDecoration.underline)),
            ),
          ),
        ]),
      ),
    );
  }
}
