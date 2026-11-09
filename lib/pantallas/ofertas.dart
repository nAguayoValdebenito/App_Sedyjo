import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
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
    final todas = Catalogo.enOferta();
    final destacada = todas.firstWhere((p) => p.id == 4, orElse: () => todas.first);
    final lista = todas.where((p) => _categoria == null || p.categoria == _categoria).toList();
    final cats = todas.map((p) => p.categoria).toSet().toList();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Text('Ofertas', style: T.titulo1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text('Precios rebajados por tiempo limitado.', style: T.cuerpo.copyWith(color: C.grisMedio)),
          ),
          // Oferta del día
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(color: C.negro, borderRadius: BorderRadius.circular(26), border: Border.all(color: C.carbonBorde)),
              clipBehavior: Clip.antiAlias,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(children: [
                    const Icon(LucideIcons.zap, color: C.oro, size: 24),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Oferta del día', style: T.titulo2.copyWith(color: C.oro, fontSize: 22))),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: const _Contador(),
                ),
                const SizedBox(height: 16),
                Tocable(
                  etiqueta: 'Ver ${destacada.nombre}',
                  onTap: () => abrirProducto(context, destacada),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
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
                            Image.asset('assets/img/oferta/crush.webp', fit: BoxFit.contain, alignment: Alignment.centerRight, semanticLabel: ''),
                          ]),
                        ),
                        SizedBox(
                          width: 150,
                          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(destacada.nombre, style: T.cuerpoFuerte.copyWith(color: Colors.white, fontSize: 17), maxLines: 3, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
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
                  padding: const EdgeInsets.all(16),
                  child: Boton('Aprovechar oferta', estilo: EstiloBoton.dorado, icono: LucideIcons.plus, onTap: () {
                    estado.agregar(destacada);
                    avisoAgregado(context, destacada);
                  }),
                ),
              ]),
            ),
          ),
          // Avisos
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Tocable(
              etiqueta: 'Configurar avisos de ofertas',
              onTap: () => irA(context, const AvisosPantalla()),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: C.verdeSuave, borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  Icon(LucideIcons.bellRing, color: C.verdeOscuro, size: 28),
                  const SizedBox(width: 14),
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
          SizedBox(
            height: 62,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              children: [
                for (final c in [null, ...cats]) ...[
                  _Chip(c ?? 'Todas', _categoria == c, () => setState(() => _categoria = c)),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GrillaProductos(lista, abrir: (p) => abrirProducto(context, p)),
          ),
        ],
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
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: activo ? C.verde : C.superficie,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: activo ? C.verde : C.bordeControl, width: 1.5),
        ),
        child: Row(children: [
          if (activo) ...[const Icon(LucideIcons.check, size: 18, color: Colors.white), const SizedBox(width: 6)],
          Text(texto, style: T.etiqueta.copyWith(fontSize: 16, color: activo ? Colors.white : C.tinta)),
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
      const Icon(LucideIcons.timer, color: Colors.white, size: 20),
      const SizedBox(width: 8),
      Expanded(
        child: Text('Termina hoy · quedan $horas h $minutos min', style: T.cuerpo.copyWith(color: Colors.white, fontSize: 16)),
      ),
    ]);
  }
}
