import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/banners.dart';
import '../ui/carga.dart';
import '../ui/componentes.dart';
import '../ui/sugerencia_buscador.dart';
import 'avisos.dart';
import 'categorias.dart';
import 'direccion.dart' show mostrarContacto;
import 'tienda.dart';
import 'producto.dart';

part 'inicio_secciones.dart';

void abrirProducto(BuildContext context, Producto p) => irA(context, ProductoPantalla(p));

class InicioPestana extends StatelessWidget {
  const InicioPestana({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Refrescar(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Esp.x8),
          children: [
            const _Cabecera(),
            const _Saludo(),
            const _ConsejoInicio(),
            const Padding(padding: EdgeInsets.fromLTRB(Esp.x5, Esp.x4, Esp.x5, 0), child: _CajaBusqueda()),
            const Padding(padding: EdgeInsets.fromLTRB(Esp.x5, Esp.x3, Esp.x5, 0), child: BarraDespacho(compacta: true)),
            const SizedBox(height: Esp.x4),
            const _CarruselPrincipal(),
            TituloSeccion('Ofertas de la semana', accion: 'Ver todas', alAccion: () => estado.irAPestana(2)),
            SeccionCarga(
              cargando: (_) => const EsqueletoFila(),
              listo: (_) => FilaHorizontal(hijos: [for (final p in Catalogo.enOferta()) SizedBox(width: 188, child: TarjetaProducto(p))]),
            ),
            const TituloSeccion('Destacados de hoy'),
            SeccionCarga(
              cargando: (_) => const EsqueletoFila(n: 2),
              listo: (_) => const _Destacados(),
            ),
            TituloSeccion('Categorías', accion: 'Ver todas', alAccion: () => estado.irAPestana(1)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: Esp.x5), child: _GrillaCategorias()),
            const TituloSeccion('Ideas para tu mesa'),
            FilaHorizontal(hijos: [
              IdeaMesa(titulo: 'Para el desayuno', sub: 'Mermeladas y más', imagen: 'assets/img/combos/desayuno.webp', fondo: fondoCategoria('Abarrotes'), alTocar: () => irA(context, const CategoriaPantalla('Abarrotes'))),
              IdeaMesa(titulo: 'La once', sub: 'Té y galletas', imagen: 'assets/img/combos/once.webp', fondo: fondoCategoria('Té e Infusiones'), alTocar: () => irA(context, const CategoriaPantalla('Té e Infusiones'))),
              IdeaMesa(titulo: 'Para compartir', sub: 'Bebidas y snacks', imagen: 'assets/img/combos/bebidas-snacks.webp', fondo: fondoCategoria('Bebidas'), alTocar: () => irA(context, const CategoriaPantalla('Bebidas'))),
            ]),
            const SizedBox(height: Esp.x2),
            SeccionCarga(
              cargando: (_) => const SizedBox.shrink(),
              listo: (_) => const Revelar(child: _SeccionExclusivo()),
            ),
            const TituloSeccion('Recomendados para ti'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Esp.x5),
              child: SeccionCarga(
                cargando: (_) => const EsqueletoGrilla(n: 4),
                listo: (_) => GrillaProductos(Catalogo.productos.where((p) => !p.enOferta && p.imagen != null).take(4).toList()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Esp.x5),
              child: Boton('Ver todo el catálogo', estilo: EstiloBoton.contorno, icono: LucideIcons.layoutGrid, onTap: () => irA(context, const CategoriaPantalla(null))),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(Esp.x5, Esp.x6, Esp.x5, 0), child: Revelar(child: _Beneficios())),
            const Padding(padding: EdgeInsets.fromLTRB(Esp.x5, Esp.x4, Esp.x5, 0), child: Revelar(child: _AyudaTarjeta())),
          ],
        ),
      ),
    );
  }
}

/// Banners de campaña sobre negro. Cada producto aparece una sola vez en la portada: la oferta del día vive en Ofertas.
class _Destacados extends StatelessWidget {
  const _Destacados();

  @override
  Widget build(BuildContext context) {
    final spaghetti = Catalogo.porId(32);
    final mecano = Catalogo.porId(12);
    final cola = Catalogo.porId(2);
    return TiraPromos(banners: [
      BannerPromo(
        titulo: 'Para tu almuerzo',
        subtitulo: spaghetti.nombre,
        imagen: 'assets/img/oferta/spaghetti.webp',
        precio: clp(spaghetti.precioFinal),
        descuento: spaghetti.descuento,
        boton: 'Aprovechar',
        alTocar: () => abrirProducto(context, spaghetti),
      ),
      BannerPromo(
        titulo: 'Dulce oferta',
        subtitulo: mecano.nombre,
        imagen: 'assets/img/oferta/mecano.webp',
        acento: C.morado,
        precio: clp(mecano.precioFinal),
        descuento: mecano.descuento,
        boton: 'Lo quiero',
        alTocar: () => abrirProducto(context, mecano),
      ),
      BannerPromo(
        titulo: 'Para refrescarte',
        subtitulo: cola.nombre,
        imagen: 'assets/img/oferta/cola.webp',
        precio: clp(cola.precioFinal),
        descuento: cola.descuento,
        boton: 'Ver oferta',
        alTocar: () => abrirProducto(context, cola),
      ),
      BannerPromo(
        titulo: 'Prepara tu Navidad',
        subtitulo: 'Ofertas para tu mesa de fiestas',
        imagen: 'assets/img/campanas/navidad.webp',
        acento: C.morado,
        boton: 'Ver ofertas',
        alTocar: () => estado.irAPestana(2),
      ),
    ]);
  }
}

/// Saludo al ingresar: se muestra una vez por inicio de sesión y se cierra con un toque.
class _Saludo extends StatelessWidget {
  const _Saludo();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        if (!estado.saludoPendiente || !estado.conSesion) return const SizedBox.shrink();
        final nombre = estado.nombre!.split(' ').first;
        final titulo = estado.saludoEsPrimera ? 'Te damos la bienvenida a Comercial Sedyjo, $nombre' : '¡Qué bueno verte de nuevo, $nombre!';
        final texto = estado.saludoEsPrimera
            ? 'Tu cuenta está lista. Aquí verás tus pedidos y direcciones.'
            : 'Tus pedidos y direcciones están guardados. ¡Buenas compras!';
        return Padding(
          padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x3, Esp.x5, 0),
          child: Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(Esp.x4, Esp.x3, Esp.x2, Esp.x3),
              decoration: BoxDecoration(color: C.verdeSuave, borderRadius: BorderRadius.circular(R.l), border: Border.all(color: C.verde, width: 1.5)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(LucideIcons.handHelping, color: C.verdeOscuro, size: Ico.l),
                const SizedBox(width: Esp.x3),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(titulo, style: T.cuerpoFuerte.copyWith(color: C.verdeProfundo)),
                    const SizedBox(height: 2),
                    Text(texto, style: T.apoyo.copyWith(color: C.verdeOscuro)),
                  ]),
                ),
                BotonIcono(LucideIcons.x, 'Cerrar saludo', onTap: estado.consumirSaludo, fondo: Colors.transparent, color: C.verdeOscuro),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x3, Esp.x3, 0),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.borde, width: 1.5)),
            child: ClipOval(child: Image.asset('assets/img/logo.webp', cacheWidth: 260, fit: BoxFit.cover, semanticLabel: 'Comercial Sedyjo')),
          ),
          const SizedBox(width: Esp.x3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(estado.conSesion ? 'Hola, ${estado.nombre!.split(' ').first}' : '¡Hola! ¿Qué necesitas hoy?',
                  style: T.titulo3, maxLines: 2),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(LucideIcons.mapPin, size: 16, color: C.verde),
                const SizedBox(width: Esp.x1),
                Flexible(child: Text('Despacho a domicilio', style: T.apoyo, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ]),
          ),
          Stack(clipBehavior: Clip.none, children: [
            BotonIcono(LucideIcons.bell, estado.avisosSinLeer ? 'Avisos y ofertas, hay novedades' : 'Avisos y ofertas', onTap: () {
              estado.marcarAvisosLeidos();
              irA(context, const AvisosPantalla());
            }, tam: 52),
            if (estado.avisosSinLeer)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: C.azul, shape: BoxShape.circle, border: Border.all(color: C.superficie, width: 2)),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}

class _CajaBusqueda extends StatelessWidget {
  const _CajaBusqueda();

  @override
  Widget build(BuildContext context) {
    return Tocable(
      etiqueta: 'Buscar productos',
      onTap: () => irA(context, const BuscarPantalla()),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: Esp.x4),
        decoration: BoxDecoration(
          color: C.oscuro ? C.grisFondo : C.superficie,
          borderRadius: BorderRadius.circular(R.m),
          border: Border.all(color: C.bordeControl, width: 1.5),
        ),
        child: Row(children: [
          const Icon(LucideIcons.search, size: Ico.m, color: C.verde),
          const SizedBox(width: Esp.x3),
          const Expanded(child: SugerenciaBuscador()),
        ]),
      ),
    );
  }
}

class _Slide {
  const _Slide(this.titulo, this.sub, this.cta, this.imagen, this.categoria, this.fondo);
  final String titulo;
  final String sub;
  final String cta;
  final String imagen;
  final String categoria;
  final Color fondo;
}

const _slides = [
  _Slide('Abarrotes de todos los días', 'Arroz, fideos y conservas al mejor precio', 'Ver abarrotes', 'hero/abarrotes.webp', 'Abarrotes', C.verde),
  _Slide('Dulces y chocolates', 'Tus marcas favoritas en confitería', 'Ver confitería', 'hero/dulces.webp', 'Confitería', C.verdeBanner),
  _Slide('Bebidas para compartir', 'Gaseosas, jugos y aguas', 'Ver bebidas', 'hero/bebidas.webp', 'Bebidas', C.azul),
];

class _CarruselPrincipal extends StatefulWidget {
  const _CarruselPrincipal();

  @override
  State<_CarruselPrincipal> createState() => _CarruselPrincipalState();
}

class _CarruselPrincipalState extends State<_CarruselPrincipal> {
  PageController _ctl = PageController(viewportFraction: .92);
  double _fraccion = .92;
  int _i = 0;
  Timer? _t;
  bool _pausa = false;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted || !_ctl.hasClients || _pausa || sinMovimiento(context) || !TickerMode.valuesOf(context).enabled) return;
      _ctl.animateToPage((_i + 1) % _slides.length, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final escala = MediaQuery.textScalerOf(context).scale(10) / 10;
    // En pantallas anchas se asoma más de un banner a la vez.
    final fraccion = MediaQuery.sizeOf(context).width >= 720 ? .55 : .92;
    if (fraccion != _fraccion) {
      _fraccion = fraccion;
      final pagina = _i;
      _ctl.dispose();
      _ctl = PageController(viewportFraction: fraccion, initialPage: pagina);
    }
    return Column(children: [
      SizedBox(
        height: 222 + (escala - 1) * 230,
        child: NotificationListener<ScrollStartNotification>(
          // Si la persona arrastra el carrusel, deja de moverse solo.
          onNotification: (n) {
            if (n.dragDetails != null && !_pausa) setState(() => _pausa = true);
            return false;
          },
          child: PageView.builder(
          controller: _ctl,
          itemCount: _slides.length,
          onPageChanged: (v) => setState(() => _i = v),
          itemBuilder: (context, i) {
            final s = _slides[i];
            final grande = escala > 1.15;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: Esp.x2),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: s.fondo, borderRadius: BorderRadius.circular(R.l)),
                // Texto y foto en cajas separadas: nunca se pisan, ni con letra grande.
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x5, Esp.x1, Esp.x4),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.titulo, style: T.titulo2.copyWith(color: Colors.white), maxLines: 3),
                        const SizedBox(height: Esp.x2),
                        Text(s.sub, style: T.apoyo.copyWith(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const Spacer(),
                        Tocable(
                          etiqueta: s.cta,
                          onTap: () => irA(context, CategoriaPantalla(s.categoria)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: Esp.x4, vertical: Esp.x3),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(R.s)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Flexible(child: Text(s.cta, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.boton.copyWith(color: C.verdeBanner, fontSize: 16))),
                              const SizedBox(width: Esp.x2),
                              const Icon(LucideIcons.chevronRight, size: Ico.s, color: C.verdeBanner),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  SizedBox(
                    width: grande ? 96 : 120,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, Esp.x3, Esp.x3, Esp.x3),
                      child: Image.asset('assets/img/${s.imagen}', fit: BoxFit.contain, alignment: Alignment.center, cacheWidth: 420, semanticLabel: ''),
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
        ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var k = 0; k < _slides.length; k++)
          Tocable(
            etiqueta: 'Ir al banner ${k + 1} de ${_slides.length}${k == _i ? ', actual' : ''}',
            onTap: () {
              setState(() => _pausa = true);
              _ctl.animateToPage(k, duration: dur(context, 350), curve: Curves.easeOutCubic);
            },
            child: SizedBox(
              width: 44,
              height: 48,
              child: Center(
                child: AnimatedContainer(
                  duration: dur(context, 250),
                  width: k == _i ? 28 : 10,
                  height: 10,
                  decoration: BoxDecoration(color: k == _i ? C.verde : C.bordeControl, borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
          ),
      ]),
    ]);
  }
}

class _GrillaCategorias extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      for (final c in categorias) _TileCategoria(c),
      const _TileTodas(),
    ];
    // 2 columnas en teléfono; 3 o 4 en tableta o con el teléfono acostado.
    return LayoutBuilder(builder: (context, caja) {
      final cols = (caja.maxWidth / 220).floor().clamp(2, 4);
      final filas = <Widget>[];
      for (var i = 0; i < tiles.length; i += cols) {
        filas.add(Padding(
          padding: const EdgeInsets.only(bottom: Esp.x3),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var k = 0; k < cols; k++) ...[
                if (k > 0) const SizedBox(width: Esp.x3),
                Expanded(child: i + k < tiles.length ? Revelar(indice: k, child: tiles[i + k]) : const SizedBox()),
              ],
            ]),
          ),
        ));
      }
      return Column(children: filas);
    });
  }
}

class _TileCategoria extends StatelessWidget {
  const _TileCategoria(this.c);
  final Categoria c;

  @override
  Widget build(BuildContext context) {
    final n = Catalogo.deCategoria(c.nombre).length;
    return Tocable(
      etiqueta: '${c.nombre}, $n productos',
      onTap: () => irA(context, CategoriaPantalla(c.nombre)),
      child: Container(
        padding: const EdgeInsets.all(Esp.x3),
        decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(R.l)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(aspectRatio: 1.7, child: Image.asset(c.ruta, fit: BoxFit.contain, cacheWidth: 400, semanticLabel: '')),
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.x1, Esp.x3, Esp.x1, Esp.x1),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(c.icono, size: Ico.m, color: C.tinta.withValues(alpha: .7)),
              const SizedBox(width: Esp.x2),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.nombre, style: T.cuerpoFuerte.copyWith(height: 1.2)),
                  const SizedBox(height: 2),
                  Text('$n productos', style: T.apoyo.copyWith(color: C.grisMedio, fontSize: 15)),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _TileTodas extends StatelessWidget {
  const _TileTodas();

  @override
  Widget build(BuildContext context) {
    return Tocable(
      etiqueta: 'Ver todo el catálogo',
      onTap: () => irA(context, const CategoriaPantalla(null)),
      child: Container(
        padding: const EdgeInsets.all(Esp.x4),
        decoration: BoxDecoration(color: C.verde, borderRadius: BorderRadius.circular(R.l)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Image.asset('assets/img/cat/todo-el-catalogo.webp', cacheHeight: 264, height: 88, fit: BoxFit.contain, alignment: Alignment.centerLeft, semanticLabel: ''),
          const SizedBox(height: Esp.x3),
          Text('Todo el catálogo', style: T.titulo3.copyWith(color: Colors.white)),
          const SizedBox(height: Esp.x1),
          Text('${Catalogo.productos.length} productos', style: T.apoyo.copyWith(color: C.verdePalido)),
        ]),
      ),
    );
  }
}
