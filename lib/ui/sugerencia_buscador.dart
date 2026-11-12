import 'dart:async';

import 'package:flutter/material.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import 'movimiento.dart';

/// Texto del buscador que va cambiando cada 5 s con ideas según lo que la persona busca, mira y tiene en el carrito.
/// Sube y se desvanece al cambiar; se detiene cuando la pestaña no se ve. La etiqueta de accesibilidad del buscador
/// sigue siendo "Buscar productos", así que el lector de pantalla no repite cada cambio.
class SugerenciaBuscador extends StatefulWidget {
  const SugerenciaBuscador({super.key});

  @override
  State<SugerenciaBuscador> createState() => _SugerenciaBuscadorState();
}

class _SugerenciaBuscadorState extends State<SugerenciaBuscador> {
  Timer? _t;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && TickerMode.valuesOf(context).enabled) setState(() => _i++);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se recalcula en cada cambio: refleja de inmediato lo último que hizo la persona.
    final ideas = estado.sugerenciasBusqueda();
    final texto = 'Buscar ${ideas[_i % ideas.length]}…';
    return ClipRect(
      child: AnimatedSwitcher(
        duration: dur(context, 350),
        switchInCurve: Mov.entra,
        switchOutCurve: Mov.sale,
        transitionBuilder: (hijo, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, .6), end: Offset.zero).animate(a), child: hijo),
        ),
        layoutBuilder: (actual, anteriores) => Stack(alignment: Alignment.centerLeft, children: [...anteriores, ?actual]),
        child: Align(
          key: ValueKey(texto),
          alignment: Alignment.centerLeft,
          child: Text(texto, style: T.cuerpo.copyWith(color: C.grisTexto), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
