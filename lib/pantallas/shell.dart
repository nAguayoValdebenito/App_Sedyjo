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
int _giro = 0;

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
    if (estado.carrito.isEmpty) estado.cargarCarritoDeEjemplo();
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
        return Scaffold(
          body: Stack(children: [
            IndexedStack(index: estado.pestana, children: const [
              InicioPestana(),
              CategoriasPestana(),
              OfertasPestana(),
              CarritoPestana(),
              CuentaPestana(),
            ]),
            if (estado.pestana <= 2)
              const Positioned(left: 12, right: 12, top: 0, child: SafeArea(bottom: false, child: _AvisoRelampago())),
          ]),
          bottomNavigationBar: const _BarraInferior(),
        );
      },
    );
  }
}

class _BarraInferior extends StatelessWidget {
  const _BarraInferior();

  @override
  Widget build(BuildContext context) {
    const items = [
      (LucideIcons.house, 'Inicio'),
      (LucideIcons.layoutGrid, 'Categorías'),
      (LucideIcons.percent, 'Ofertas'),
      (LucideIcons.shoppingCart, 'Carrito'),
      (LucideIcons.userRound, 'Cuenta'),
    ];
    return Container(
      decoration: BoxDecoration(color: C.superficie, border: Border(top: BorderSide(color: C.borde))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: 1,
            maxScaleFactor: 1.12,
            child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Tocable(
                    etiqueta: items[i].$2 + (i == 3 && estado.cantidadCarrito > 0 ? ', ${estado.cantidadCarrito} productos' : ''),
                    onTap: () => estado.irAPestana(i),
                    child: _ItemNav(icono: items[i].$1, texto: items[i].$2, activo: estado.pestana == i, contador: i == 3 ? estado.cantidadCarrito : 0),
                  ),
                ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _ItemNav extends StatelessWidget {
  const _ItemNav({required this.icono, required this.texto, required this.activo, required this.contador});
  final IconData icono;
  final String texto;
  final bool activo;
  final int contador;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        AnimatedContainer(
          duration: dur(context, 220),
          curve: Curves.easeOutCubic,
          width: activo ? 62 : 40,
          height: 36,
          decoration: BoxDecoration(color: activo ? C.verdeSuave : Colors.transparent, borderRadius: BorderRadius.circular(18)),
          child: Icon(icono, size: 25, color: activo ? C.verdeOscuro : C.grisMedio),
        ),
        if (contador > 0)
          Positioned(
            right: activo ? 0 : -4,
            top: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: C.azul, borderRadius: BorderRadius.circular(11), border: Border.all(color: C.superficie, width: 2)),
              child: Text('$contador', style: T.etiqueta.copyWith(color: Colors.white, fontSize: 14, height: 1)),
            ),
          ),
      ]),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(texto,
            maxLines: 1,
            style: T.etiqueta.copyWith(fontSize: 14, color: activo ? C.verdeOscuro : C.grisMedio, fontWeight: activo ? FontWeight.w800 : FontWeight.w600)),
      ),
      const SizedBox(height: 4),
    ]);
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
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(
          color: C.negro,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: C.carbonBorde),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 22, offset: const Offset(0, 10))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(LucideIcons.zap, color: C.oro, size: 20),
            const SizedBox(width: 6),
            Text('OFERTA RELÁMPAGO', style: T.etiqueta.copyWith(color: C.oro, fontSize: 14, letterSpacing: .6)),
            const Spacer(),
            BotonIcono(LucideIcons.x, 'Cerrar aviso de oferta', onTap: () => relampago.value = null, fondo: C.carbon, color: Colors.white, tam: 48),
          ]),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(width: 74, height: 74, child: FotoProducto(p))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.cuerpoFuerte.copyWith(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 4),
                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
                    Text(clp(p.precioFinal), style: T.precio.copyWith(color: C.oro, fontSize: 22)),
                    Insignia('-${p.descuento}%'),
                  ]),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Builder(builder: (context) {
              final grande = MediaQuery.textScalerOf(context).scale(10) / 10 > 1.15;
              final ver = Boton('Ver oferta', estilo: EstiloBoton.dorado, alto: 50, onTap: () {
                relampago.value = null;
                irA(context, ProductoPantalla(p));
              });
              final agregar = Boton('Agregar', etiqueta: 'Agregar ${p.nombre} al carrito', icono: LucideIcons.plus, alto: 50, onTap: () {
                estado.agregar(p);
                relampago.value = null;
              });
              return grande
                  ? Column(children: [ver, const SizedBox(height: 8), agregar])
                  : Row(children: [Expanded(child: ver), const SizedBox(width: 8), Expanded(child: agregar)]);
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
