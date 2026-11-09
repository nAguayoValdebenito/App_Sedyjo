import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/componentes.dart';
import 'inicio.dart' show abrirProducto;

class CategoriasPestana extends StatelessWidget {
  const CategoriasPestana({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Text('Categorías', style: T.titulo1),
          const SizedBox(height: 4),
          Text('Elige qué quieres comprar hoy.', style: T.cuerpo.copyWith(color: C.grisMedio)),
          const SizedBox(height: 16),
          Tocable(
            etiqueta: 'Buscar productos',
            onTap: () => irA(context, const BuscarPantalla()),
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(color: C.superficie, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.bordeControl, width: 1.5)),
              child: Row(children: [
                const Icon(LucideIcons.search, size: 24, color: C.verde),
                const SizedBox(width: 12),
                Expanded(child: Text('Buscar un producto', style: T.cuerpo.copyWith(color: C.grisTexto))),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          for (final c in categorias) ...[_FilaCategoria(c), const SizedBox(height: 12)],
          _FilaTodos(),
        ],
      ),
    );
  }
}

class _FilaCategoria extends StatelessWidget {
  const _FilaCategoria(this.c);
  final Categoria c;

  @override
  Widget build(BuildContext context) {
    final lista = Catalogo.deCategoria(c.nombre);
    return Tocable(
      etiqueta: '${c.nombre}, ${lista.length} productos',
      onTap: () => irA(context, CategoriaPantalla(c.nombre)),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          SizedBox(width: 104, height: 104, child: Image.asset(c.ruta, fit: BoxFit.contain, cacheWidth: 300, semanticLabel: '')),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.nombre, style: T.titulo3.copyWith(fontSize: 20)),
              const SizedBox(height: 4),
              Text('${lista.length} productos', style: T.apoyo.copyWith(color: C.grisMedio)),
            ]),
          ),
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(color: C.superficie, shape: BoxShape.circle),
            child: Icon(LucideIcons.chevronRight, color: C.verdeOscuro, size: 24),
          ),
        ]),
      ),
    );
  }
}

class _FilaTodos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Boton('Ver todo el catálogo',
        icono: LucideIcons.layoutGrid, estilo: EstiloBoton.contorno, onTap: () => irA(context, const CategoriaPantalla(null)));
  }
}

enum _Orden { relevancia, menor, mayor, ofertas }

/// Listado de una categoría (o de todo el catálogo si [nombre] es null).
class CategoriaPantalla extends StatefulWidget {
  const CategoriaPantalla(this.nombre, {super.key});
  final String? nombre;

  @override
  State<CategoriaPantalla> createState() => _CategoriaPantallaState();
}

class _CategoriaPantallaState extends State<CategoriaPantalla> {
  _Orden _orden = _Orden.relevancia;

  List<Producto> get _lista {
    var l = widget.nombre == null ? [...Catalogo.productos] : Catalogo.deCategoria(widget.nombre!);
    switch (_orden) {
      case _Orden.menor:
        l.sort((a, b) => a.precioFinal.compareTo(b.precioFinal));
      case _Orden.mayor:
        l.sort((a, b) => b.precioFinal.compareTo(a.precioFinal));
      case _Orden.ofertas:
        l = l.where((p) => p.enOferta).toList();
      case _Orden.relevancia:
        break;
    }
    return l;
  }

  @override
  Widget build(BuildContext context) {
    final lista = _lista;
    const opciones = [
      (_Orden.relevancia, 'Destacados'),
      (_Orden.ofertas, 'Solo ofertas'),
      (_Orden.menor, 'Menor precio'),
      (_Orden.mayor, 'Mayor precio'),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          BarraSuperior(widget.nombre ?? 'Todo el catálogo'),
          SizedBox(
            height: 62,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              itemCount: opciones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final activo = _orden == opciones[i].$1;
                return Tocable(
                  etiqueta: 'Ordenar: ${opciones[i].$2}',
                  onTap: () => setState(() => _orden = opciones[i].$1),
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
                      Text(opciones[i].$2, style: T.etiqueta.copyWith(fontSize: 16, color: activo ? Colors.white : C.tinta)),
                    ]),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: Align(alignment: Alignment.centerLeft, child: Text('${lista.length} productos', style: T.apoyo)),
          ),
          Expanded(
            child: lista.isEmpty
                ? const _SinResultados('No hay productos con este filtro.')
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    children: [GrillaProductos(lista, abrir: (p) => abrirProducto(context, p))],
                  ),
          ),
        ]),
      ),
    );
  }
}

class _SinResultados extends StatelessWidget {
  const _SinResultados(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const IlustracionEstado('sin-resultados.webp'),
          const SizedBox(height: 22),
          Text(texto, textAlign: TextAlign.center, style: T.titulo3),
          const SizedBox(height: 6),
          Text('Prueba con otra palabra o mira las categorías.', textAlign: TextAlign.center, style: T.apoyo),
        ]),
      ),
    );
  }
}

class BuscarPantalla extends StatefulWidget {
  const BuscarPantalla({super.key});

  @override
  State<BuscarPantalla> createState() => _BuscarPantallaState();
}

class _BuscarPantallaState extends State<BuscarPantalla> {
  final _ctl = TextEditingController();
  String _q = '';

  List<Producto> get _resultados {
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) return [];
    return Catalogo.productos.where((p) => p.nombre.toLowerCase().contains(q) || p.categoria.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = _resultados;
    const populares = ['Arroz', 'Coca-Cola', 'Chocolate', 'Galletas', 'Té', 'Spaghetti'];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(children: [
              BotonIcono(LucideIcons.arrowLeft, 'Volver', onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ctl,
                  autofocus: true,
                  onChanged: (v) => setState(() => _q = v),
                  onSubmitted: estado.agregarReciente,
                  style: T.cuerpo.copyWith(fontSize: 18),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Buscar productos',
                    hintStyle: T.cuerpo.copyWith(color: C.grisTexto),
                    filled: true,
                    fillColor: C.superficie,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: _q.isEmpty
                        ? const Icon(LucideIcons.search, color: C.verde)
                        : IconButton(
                            tooltip: 'Borrar búsqueda',
                            onPressed: () => setState(() {
                              _ctl.clear();
                              _q = '';
                            }),
                            icon: Icon(LucideIcons.x, color: C.grisMedio)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: C.bordeControl, width: 1.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: C.bordeControl, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.verde, width: 2.5)),
                  ),
                ),
              ),
            ]),
          ),
          Expanded(
            child: _q.trim().isEmpty
                ? ListView(padding: const EdgeInsets.all(20), children: [
                    if (estado.recientes.isNotEmpty) ...[
                      Row(children: [
                        Expanded(child: Text('Tus búsquedas recientes', style: T.titulo3)),
                        Tocable(
                          etiqueta: 'Borrar búsquedas recientes',
                          onTap: () => setState(estado.borrarRecientes),
                          child: Padding(padding: const EdgeInsets.all(12), child: Text('Borrar', style: T.cuerpoFuerte.copyWith(color: C.azulEnlace, fontSize: 16))),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        for (final s in estado.recientes)
                          Tocable(
                            etiqueta: 'Buscar $s otra vez',
                            onTap: () => setState(() {
                              _ctl.text = s;
                              _q = s;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(color: C.superficie, borderRadius: BorderRadius.circular(24), border: Border.all(color: C.bordeControl, width: 1.5)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(LucideIcons.history, size: 18, color: C.grisMedio),
                                const SizedBox(width: 8),
                                Text(s, style: T.cuerpoFuerte.copyWith(fontSize: 16)),
                              ]),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 26),
                    ],
                    Text('Búsquedas populares', style: T.titulo3),
                    const SizedBox(height: 14),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      for (final s in populares)
                        Tocable(
                          etiqueta: 'Buscar $s',
                          onTap: () => setState(() {
                            _ctl.text = s;
                            _q = s;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                            decoration: BoxDecoration(color: C.verdeSuave, borderRadius: BorderRadius.circular(24)),
                            child: Text(s, style: T.cuerpoFuerte.copyWith(fontSize: 16, color: C.verdeOscuro)),
                          ),
                        ),
                    ]),
                  ])
                : res.isEmpty
                    ? _SinResultados('No encontramos "$_q"')
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                        children: [
                          Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('${res.length} resultados', style: T.apoyo)),
                          GrillaProductos(res, abrir: (p) => abrirProducto(context, p)),
                        ],
                      ),
          ),
        ]),
      ),
    );
  }
}
