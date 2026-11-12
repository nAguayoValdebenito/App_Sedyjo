import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/componentes.dart';

/// Los productos guardados con el corazón, del más nuevo al más antiguo.
class FavoritosPantalla extends StatelessWidget {
  const FavoritosPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const BarraSuperior('Mis favoritos', accion: BotonCarritoMini()),
          Expanded(
            child: ListenableBuilder(
              listenable: estado,
              builder: (context, _) {
                final lista = [for (final id in estado.favoritos) if (Catalogo.productos.any((p) => p.id == id)) Catalogo.porId(id)];
                if (lista.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Esp.x8),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const IlustracionEstado('sin-resultados.webp'),
                        const SizedBox(height: Esp.x6),
                        Text('Aún no tienes favoritos', textAlign: TextAlign.center, style: T.titulo2),
                        const SizedBox(height: Esp.x2),
                        Text('Toca el corazón de un producto para guardarlo aquí.', textAlign: TextAlign.center, style: T.cuerpo.copyWith(color: C.grisMedio)),
                        const SizedBox(height: Esp.x6),
                        Boton('Ver ofertas', icono: LucideIcons.percent, onTap: () {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                          estado.irAPestana(2);
                        }),
                      ]),
                    ),
                  );
                }
                return CustomScrollView(slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x1, Esp.x5, Esp.x3),
                    sliver: SliverToBoxAdapter(child: Text('${lista.length} ${lista.length == 1 ? 'producto guardado' : 'productos guardados'}', style: T.apoyo)),
                  ),
                  SliverPadding(padding: const EdgeInsets.fromLTRB(Esp.x5, 0, Esp.x5, Esp.x8), sliver: SliverGrillaProductos(lista)),
                ]);
              },
            ),
          ),
        ]),
      ),
    );
  }
}
