import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/carga.dart';
import '../ui/componentes.dart';
import 'avisos.dart';
import 'inicio.dart' show abrirProducto;

class OfertasPestana extends StatefulWidget {
  const OfertasPestana({super.key});

  @override
  State<OfertasPestana> createState() => _OfertasPestanaState();
}

class _OfertasPestanaState extends State<OfertasPestana> {
  String? _categoria;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Carga>(
      valueListenable: Catalogo.carga,
      builder: (context, carga, _) {
        final sinDatos = Catalogo.productos.isEmpty || Catalogo.forzarVacio;
        final todas = sinDatos ? <Producto>[] : Catalogo.enOferta();
        final lista = todas.where((p) => _categoria == null || p.categoria == _categoria).toList();
        final cats = todas.map((p) => p.categoria).toSet().toList();
        return SafeArea(
          bottom: false,
          child: Refrescar(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x3, Esp.x5, 0),
                      child: Text('Ofertas', style: T.titulo1),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x1, Esp.x5, Esp.x4),
                      child: Text('Precios rebajados por tiempo limitado.', style: T.cuerpo.copyWith(color: C.grisMedio)),
                    ),
                    if (carga == Carga.error)
                      const ErrorSeccion()
                    else if (sinDatos)
                      const Padding(padding: EdgeInsets.symmetric(horizontal: Esp.x5), child: BrilloCarga(child: BloqueEsqueleto(alto: 330, radio: R.xl)))
                    else
                      _HeroOferta(todas.firstWhere((p) => p.id == 4, orElse: () => todas.first)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x4, Esp.x5, 0),
                      child: Tocable(
                        etiqueta: 'Configurar avisos de ofertas',
                        onTap: () => irA(context, const AvisosPantalla()),
                        radio: R.l,
                        child: Container(
                          padding: const EdgeInsets.all(Esp.x4),
                          decoration: BoxDecoration(color: C.verdeSuave, borderRadius: BorderRadius.circular(R.l)),
                          child: Row(children: [
                            Icon(LucideIcons.bellRing, color: C.verdeOscuro, size: Ico.l),
                            const SizedBox(width: Esp.x3),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Avisos de ofertas', style: T.cuerpoFuerte.copyWith(color: C.verdeProfundo)),
                                Text(estado.minutosOfertas == 0 ? 'Desactivados' : 'Cada ${estado.minutosOfertas} minutos dentro de la app', style: T.apoyo.copyWith(color: C.verdeOscuro)),
                              ]),
                            ),
                            Icon(LucideIcons.chevronRight, color: C.verdeOscuro),
                          ]),
                        ),
                      ),
                    ),
                    const TituloSeccion('Todas las ofertas'),
                    if (!sinDatos)
                      SizedBox(
                        height: 62,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: Esp.x5, vertical: Esp.x2),
                          children: [
                            for (final c in [null, ...cats]) ...[
                              _Chip(c ?? 'Todas', _categoria == c, () => setState(() => _categoria = c)),
                              const SizedBox(width: Esp.x3),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: Esp.x3),
                    if (sinDatos && carga != Carga.error) const Padding(padding: EdgeInsets.symmetric(horizontal: Esp.x5), child: EsqueletoGrilla(n: 4)),
                  ]),
                ),
                if (!sinDatos) SliverPadding(padding: const EdgeInsets.fromLTRB(Esp.x5, 0, Esp.x5, Esp.x8), sliver: SliverGrillaProductos(lista)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Oferta del día: bloque negro con dorado. Es el único lugar donde vive este producto como protagonista.
class _HeroOferta extends StatelessWidget {
  const _HeroOferta(this.destacada);
  final Producto destacada;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Esp.x5),
      child: Container(
        decoration: BoxDecoration(color: C.negro, borderRadius: BorderRadius.circular(R.xl), border: Border.all(color: C.carbonBorde)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x5, Esp.x5, 0),
            child: Row(children: [
              const Icon(LucideIcons.zap, color: C.oro, size: Ico.m),
              const SizedBox(width: Esp.x2),
              Expanded(child: Text('Oferta del día', style: T.titulo2.copyWith(color: C.oro, fontSize: 22))),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(Esp.x5, Esp.x3, Esp.x5, 0),
            child: _Contador(),
          ),
          const SizedBox(height: Esp.x4),
          Tocable(
            etiqueta: 'Ver ${destacada.nombre}',
            onTap: () => abrirProducto(context, destacada),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Esp.x3),
              child: Container(
                constraints: const BoxConstraints(minHeight: 172),
                width: double.infinity,
                child: Stack(children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 118,
                    child: Stack(fit: StackFit.expand, children: [
                      DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(colors: [C.oro.withValues(alpha: .26), C.oro.withValues(alpha: 0)]))),
                      Image.asset('assets/img/oferta/crush.webp', fit: BoxFit.contain, alignment: Alignment.centerRight, cacheWidth: 360, semanticLabel: ''),
                    ]),
                  ),
                  SizedBox(
                    width: 150,
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(destacada.nombre, style: T.cuerpoFuerte.copyWith(color: Colors.white), maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: Esp.x2),
                      Text(clp(destacada.precioFinal), style: T.precio.copyWith(color: C.oro, fontSize: 28)),
                      Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        Text(clp(destacada.precio), style: T.apoyo.copyWith(color: const Color(0xFFC9C9D4), decoration: TextDecoration.lineThrough)),
                        Insignia('-${destacada.descuento}%'),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Esp.x4),
            child: Boton('Aprovechar oferta', estilo: EstiloBoton.dorado, icono: LucideIcons.plus, alTocarEn: (ctx) => agregarAlCarrito(ctx, destacada, oscuro: true)),
          ),
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.texto, this.activo, this.alTocar);
  final String texto;
  final bool activo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Tocable(
      etiqueta: 'Filtrar: $texto',
      onTap: alTocar,
      radio: R.l,
      child: AnimatedContainer(
        duration: dur(context, 160),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: Esp.x4),
        decoration: BoxDecoration(
          color: activo ? C.verde : C.superficie,
          borderRadius: BorderRadius.circular(R.l),
          border: Border.all(color: activo ? C.verde : C.bordeControl, width: 1.5),
        ),
        child: Row(children: [
          if (activo) ...[const Icon(LucideIcons.check, size: Ico.s, color: Colors.white), const SizedBox(width: Esp.x2)],
          Text(texto, style: T.cuerpoMFuerte.copyWith(color: activo ? Colors.white : C.tinta)),
        ]),
      ),
    );
  }
}

/// "Termina hoy · quedan 22 h 14 min": se actualiza cada 30 s y solo reconstruye este texto.
class _Contador extends StatefulWidget {
  const _Contador();

  @override
  State<_Contador> createState() => _ContadorState();
}

class _ContadorState extends State<_Contador> {
  Timer? _t;
  Duration _resta = Duration.zero;

  void _calcular() {
    final ahora = DateTime.now();
    _resta = DateTime(ahora.year, ahora.month, ahora.day + 1).difference(ahora);
  }

  @override
  void initState() {
    super.initState();
    _calcular();
    _t = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(_calcular);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horas = _resta.inHours;
    final minutos = _resta.inMinutes % 60;
    return Row(children: [
      const Icon(LucideIcons.timer, color: Colors.white, size: Ico.s),
      const SizedBox(width: Esp.x2),
      Expanded(
        child: Text('Termina hoy · quedan $horas h $minutos min', style: T.cuerpo.copyWith(color: Colors.white, fontSize: 16)),
      ),
    ]);
  }
}
