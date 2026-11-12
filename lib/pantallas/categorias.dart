import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/carga.dart';
import '../ui/componentes.dart';

class CategoriasPestana extends StatelessWidget {
  const CategoriasPestana({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x3, Esp.x5, Esp.x8),
        children: [
          Text('Categorías', style: T.titulo1),
          const SizedBox(height: Esp.x1),
          Text('Elige qué quieres comprar hoy.', style: T.cuerpo.copyWith(color: C.grisMedio)),
          const SizedBox(height: Esp.x4),
          Tocable(
            etiqueta: 'Buscar productos',
            onTap: () => irA(context, const BuscarPantalla()),
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: Esp.x4),
              decoration: BoxDecoration(color: C.superficie, borderRadius: BorderRadius.circular(R.m), border: Border.all(color: C.bordeControl, width: 1.5)),
              child: Row(children: [
                const Icon(LucideIcons.search, size: Ico.m, color: C.verde),
                const SizedBox(width: Esp.x3),
                Expanded(child: Text('Buscar un producto', style: T.cuerpo.copyWith(color: C.grisTexto))),
              ]),
            ),
          ),
          const SizedBox(height: Esp.x4),
          for (final c in categorias) ...[_FilaCategoria(c), const SizedBox(height: Esp.x3)],
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
        padding: const EdgeInsets.all(Esp.x3),
        decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(R.l)),
        child: Row(children: [
          SizedBox(width: 104, height: 104, child: Image.asset(c.ruta, fit: BoxFit.contain, cacheWidth: 300, semanticLabel: '')),
          const SizedBox(width: Esp.x3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.nombre, style: T.titulo3),
              const SizedBox(height: Esp.x1),
              Text('${lista.length} productos', style: T.apoyo.copyWith(color: C.grisMedio)),
            ]),
          ),
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: Esp.x1),
            decoration: BoxDecoration(color: C.superficie, shape: BoxShape.circle),
            child: Icon(LucideIcons.chevronRight, color: C.verdeOscuro, size: Ico.m),
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

enum _OrdenBusqueda { relevancia, menor, mayor, ofertas }

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
    const opciones = [
      (_Orden.relevancia, 'Destacados'),
      (_Orden.ofertas, 'Solo ofertas'),
      (_Orden.menor, 'Menor precio'),
      (_Orden.mayor, 'Mayor precio'),
    ];
    return ValueListenableBuilder<Carga>(
      valueListenable: Catalogo.carga,
      builder: (context, carga, _) {
        final sinDatos = Catalogo.productos.isEmpty || Catalogo.forzarVacio;
        final lista = sinDatos ? <Producto>[] : _lista;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(children: [
              BarraSuperior(widget.nombre ?? 'Todo el catálogo', accion: const BotonCarritoMini()),
              SizedBox(
                height: 62,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Esp.x5, vertical: Esp.x2),
                  itemCount: opciones.length,
                  separatorBuilder: (_, _) => const SizedBox(width: Esp.x3),
                  itemBuilder: (context, i) {
                    final activo = _orden == opciones[i].$1;
                    return Tocable(
                      etiqueta: 'Ordenar: ${opciones[i].$2}',
                      onTap: () => setState(() => _orden = opciones[i].$1),
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
                          Text(opciones[i].$2, style: T.cuerpoMFuerte.copyWith(color: activo ? Colors.white : C.tinta)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x2, Esp.x5, Esp.x3),
                child: Align(alignment: Alignment.centerLeft, child: Text(sinDatos ? 'Cargando…' : '${lista.length} productos', style: T.apoyo)),
              ),
              Expanded(
                child: Refrescar(
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (carga == Carga.error)
                        const SliverToBoxAdapter(child: ErrorSeccion())
                      else if (sinDatos)
                        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(Esp.x5, 0, Esp.x5, Esp.x8), child: EsqueletoGrilla(n: 6)))
                      else if (lista.isEmpty)
                        const SliverFillRemaining(hasScrollBody: false, child: _SinResultados('No hay productos con este filtro.'))
                      else
                        SliverPadding(padding: const EdgeInsets.fromLTRB(Esp.x5, 0, Esp.x5, Esp.x8), sliver: SliverGrillaProductos(lista)),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        );
      },
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
        padding: const EdgeInsets.all(Esp.x8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const IlustracionEstado('sin-resultados.webp'),
          const SizedBox(height: Esp.x6),
          Text(texto, textAlign: TextAlign.center, style: T.titulo3),
          const SizedBox(height: Esp.x2),
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

  _OrdenBusqueda _orden = _OrdenBusqueda.relevancia;
  String? _categoria;

  /// Sin tildes ni mayúsculas: "te" encuentra "Té", "cafe" encuentra "Café".
  static String _norm(String t) {
    const con = 'áàäâéèëêíìïîóòöôúùüûñ';
    const sin = 'aaaaeeeeiiiioooouuuun';
    var r = t.toLowerCase();
    for (var i = 0; i < con.length; i++) {
      r = r.replaceAll(con[i], sin[i]);
    }
    return r;
  }

  /// Productos que contienen todas las palabras escritas (en el nombre, la categoría o la descripción).
  List<Producto> get _coincidencias {
    final palabras = _norm(_q).split(' ').where((e) => e.isNotEmpty).toList();
    if (palabras.isEmpty) return [];
    return Catalogo.productos.where((p) {
      final texto = _norm('${p.nombre} ${p.categoria} ${p.descripcion}');
      return palabras.every(texto.contains);
    }).toList();
  }

  List<Producto> get _resultados {
    var l = _coincidencias.where((p) => _categoria == null || p.categoria == _categoria).toList();
    switch (_orden) {
      case _OrdenBusqueda.menor:
        l.sort((a, b) => a.precioFinal.compareTo(b.precioFinal));
      case _OrdenBusqueda.mayor:
        l.sort((a, b) => b.precioFinal.compareTo(a.precioFinal));
      case _OrdenBusqueda.ofertas:
        l = l.where((p) => p.enOferta).toList();
      case _OrdenBusqueda.relevancia:
        break;
    }
    return l;
  }

  /// Cantidad de resultados, orden y categoría: aparecen cuando hay algo que filtrar.
  Widget _filtros(int n) {
    final categorias = _coincidencias.map((p) => p.categoria).toSet().toList();
    const ordenes = [
      (_OrdenBusqueda.relevancia, 'Más relevantes'),
      (_OrdenBusqueda.ofertas, 'Solo ofertas'),
      (_OrdenBusqueda.menor, 'Menor precio'),
      (_OrdenBusqueda.mayor, 'Mayor precio'),
    ];
    Widget fila(List<Widget> chips) => SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Esp.x5, vertical: Esp.x1),
            itemCount: chips.length,
            separatorBuilder: (_, _) => const SizedBox(width: Esp.x3),
            itemBuilder: (_, i) => chips[i],
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x1, Esp.x5, Esp.x1),
        child: Semantics(liveRegion: true, child: Text('$n ${n == 1 ? 'resultado' : 'resultados'}', style: T.apoyo)),
      ),
      fila([for (final o in ordenes) _ChipSel(o.$2, _orden == o.$1, () => setState(() => _orden = o.$1))]),
      if (categorias.length > 1)
        fila([
          _ChipSel('Todas', _categoria == null, () => setState(() => _categoria = null)),
          for (final c in categorias) _ChipSel(c, _categoria == c, () => setState(() => _categoria = c)),
        ]),
      const SizedBox(height: Esp.x2),
    ]);
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
            padding: const EdgeInsets.fromLTRB(Esp.x4, Esp.x3, Esp.x4, Esp.x2),
            child: Row(children: [
              BotonIcono(LucideIcons.arrowLeft, 'Volver', onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(width: Esp.x3),
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
                    fillColor: C.oscuro ? C.grisFondo : C.superficie,
                    contentPadding: const EdgeInsets.symmetric(horizontal: Esp.x4, vertical: Esp.x4),
                    suffixIcon: _q.isEmpty
                        ? const Icon(LucideIcons.search, color: C.verde)
                        : IconButton(
                            tooltip: 'Borrar búsqueda',
                            onPressed: () => setState(() {
                              _ctl.clear();
                              _q = '';
                            }),
                            icon: Icon(LucideIcons.x, color: C.grisMedio)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.m), borderSide: BorderSide(color: C.bordeControl, width: 1.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(R.m), borderSide: BorderSide(color: C.bordeControl, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(R.m), borderSide: const BorderSide(color: C.verde, width: 2.5)),
                  ),
                ),
              ),
              const BotonCarritoMini(),
            ]),
          ),
          Expanded(
            child: _q.trim().isEmpty
                ? ListView(padding: const EdgeInsets.all(Esp.x5), children: [
                    if (estado.recientes.isNotEmpty) ...[
                      Row(children: [
                        Expanded(child: Text('Tus búsquedas recientes', style: T.titulo3)),
                        Tocable(
                          etiqueta: 'Borrar búsquedas recientes',
                          onTap: () => setState(estado.borrarRecientes),
                          child: Padding(padding: const EdgeInsets.all(Esp.x3), child: Text('Borrar', style: T.cuerpoFuerte.copyWith(color: C.azulEnlace, fontSize: 16))),
                        ),
                      ]),
                      const SizedBox(height: Esp.x2),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        for (final s in estado.recientes)
                          Tocable(
                            etiqueta: 'Buscar $s otra vez',
                            onTap: () => setState(() {
                              _ctl.text = s;
                              _q = s;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: Esp.x4, vertical: Esp.x3),
                              decoration: BoxDecoration(color: C.superficie, borderRadius: BorderRadius.circular(R.l), border: Border.all(color: C.bordeControl, width: 1.5)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(LucideIcons.history, size: Ico.s, color: C.grisMedio),
                                const SizedBox(width: Esp.x2),
                                Text(s, style: T.cuerpoMFuerte),
                              ]),
                            ),
                          ),
                      ]),
                      const SizedBox(height: Esp.x6),
                    ],
                    Text('Búsquedas populares', style: T.titulo3),
                    const SizedBox(height: Esp.x3),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      for (final s in populares)
                        Tocable(
                          etiqueta: 'Buscar $s',
                          onTap: () => setState(() {
                            _ctl.text = s;
                            _q = s;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: Esp.x4, vertical: 13),
                            decoration: BoxDecoration(color: C.verdeSuave, borderRadius: BorderRadius.circular(R.l)),
                            child: Text(s, style: T.cuerpoMFuerte.copyWith(color: C.verdeOscuro)),
                          ),
                        ),
                    ]),
                  ])
                : _coincidencias.isEmpty
                    ? _SinResultados('No encontramos "$_q"')
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(child: _filtros(res.length)),
                          if (res.isEmpty)
                            const SliverFillRemaining(hasScrollBody: false, child: _SinResultados('No hay productos con este filtro.'))
                          else
                            SliverPadding(padding: const EdgeInsets.fromLTRB(Esp.x5, 0, Esp.x5, Esp.x8), sliver: SliverGrillaProductos(res)),
                        ],
                      ),
          ),
        ]),
      ),
    );
  }
}

class _ChipSel extends StatelessWidget {
  const _ChipSel(this.texto, this.activo, this.alTocar);
  final String texto;
  final bool activo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Tocable(
      etiqueta: 'Filtrar: $texto${activo ? ', elegido' : ''}',
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
