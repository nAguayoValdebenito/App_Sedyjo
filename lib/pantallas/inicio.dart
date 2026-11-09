import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/banners.dart';
import '../ui/componentes.dart';
import 'avisos.dart';
import 'categorias.dart';
import 'producto.dart';

void abrirProducto(BuildContext context, Producto p) => irA(context, ProductoPantalla(p));

class InicioPestana extends StatelessWidget {
  const InicioPestana({super.key});

  @override
  Widget build(BuildContext context) {
    final ofertas = Catalogo.enOferta();
    final recomendados = Catalogo.productos.where((p) => !p.enOferta && p.imagen != null).take(4).toList();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const _Cabecera(),
          const _Saludo(),
          const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 0), child: _CajaBusqueda()),
          const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 0), child: BarraDespacho(compacta: true)),
          const SizedBox(height: 16),
          const _CarruselPrincipal(),
          TituloSeccion('Ofertas de la semana', accion: 'Ver todas', alAccion: () => estado.irAPestana(2)),
          FilaHorizontal(hijos: [for (final p in ofertas) SizedBox(width: 188, child: TarjetaProducto(p, abrir: () => abrirProducto(context, p)))]),
          const TituloSeccion('Destacados de hoy'),
          TiraPromos(banners: [
            BannerPromo(
              titulo: 'Oferta del día',
              subtitulo: Catalogo.porId(4).nombre,
              imagen: 'assets/img/oferta/crush.webp',
              precio: clp(Catalogo.porId(4).precioFinal),
              descuento: Catalogo.porId(4).descuento,
              boton: 'Aprovechar',
              alTocar: () => abrirProducto(context, Catalogo.porId(4)),
            ),
            BannerPromo(
              titulo: 'Dulce oferta',
              subtitulo: Catalogo.porId(12).nombre,
              imagen: 'assets/img/oferta/mecano.webp',
              acento: C.morado,
              precio: clp(Catalogo.porId(12).precioFinal),
              descuento: Catalogo.porId(12).descuento,
              boton: 'Lo quiero',
              alTocar: () => abrirProducto(context, Catalogo.porId(12)),
            ),
            BannerPromo(
              titulo: 'Para refrescarte',
              subtitulo: Catalogo.porId(2).nombre,
              imagen: 'assets/img/oferta/cola.webp',
              precio: clp(Catalogo.porId(2).precioFinal),
              descuento: Catalogo.porId(2).descuento,
              boton: 'Ver oferta',
              alTocar: () => abrirProducto(context, Catalogo.porId(2)),
            ),
            BannerPromo(
              titulo: 'Prepara tu Navidad',
              subtitulo: 'Ofertas para tu mesa de fiestas',
              imagen: 'assets/img/campanas/navidad.webp',
              acento: C.morado,
              boton: 'Ver ofertas',
              alTocar: () => estado.irAPestana(2),
            ),
          ]),
          TituloSeccion('Categorías', accion: 'Ver todas', alAccion: () => estado.irAPestana(1)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _GrillaCategorias()),
          const TituloSeccion('Ideas para tu mesa'),
          FilaHorizontal(hijos: [
            IdeaMesa(titulo: 'Para el desayuno', sub: 'Mermeladas y más', imagen: 'assets/img/combos/desayuno.webp', fondo: fondoCategoria('Abarrotes'), alTocar: () => irA(context, const CategoriaPantalla('Abarrotes'))),
            IdeaMesa(titulo: 'La once', sub: 'Té y galletas', imagen: 'assets/img/combos/once.webp', fondo: fondoCategoria('Té e Infusiones'), alTocar: () => irA(context, const CategoriaPantalla('Té e Infusiones'))),
            IdeaMesa(titulo: 'Para compartir', sub: 'Bebidas y snacks', imagen: 'assets/img/combos/bebidas-snacks.webp', fondo: fondoCategoria('Bebidas'), alTocar: () => irA(context, const CategoriaPantalla('Bebidas'))),
          ]),
          const SizedBox(height: 8),
          const _SeccionExclusivo(),
          const TituloSeccion('Recomendados para ti'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GrillaProductos(recomendados, abrir: (p) => abrirProducto(context, p)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Boton('Ver todo el catálogo', estilo: EstiloBoton.contorno, icono: LucideIcons.layoutGrid, onTap: () => irA(context, const CategoriaPantalla(null))),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(20, 22, 20, 0), child: _Beneficios()),
          const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 0), child: _AyudaTarjeta()),
        ],
      ),
    );
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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              decoration: BoxDecoration(color: C.verdeSuave, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.verde, width: 1.5)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(LucideIcons.handHelping, color: C.verdeOscuro, size: 28),
                const SizedBox(width: 12),
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
        padding: const EdgeInsets.fromLTRB(20, 10, 14, 0),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.borde, width: 1.5)),
            child: ClipOval(child: Image.asset('assets/img/logo.webp', fit: BoxFit.cover, semanticLabel: 'Comercial Sedyjo')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(estado.conSesion ? 'Hola, ${estado.nombre!.split(' ').first}' : '¡Hola! ¿Qué necesitas hoy?',
                  style: T.titulo3.copyWith(fontSize: 20), maxLines: 2),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(LucideIcons.mapPin, size: 16, color: C.verde),
                const SizedBox(width: 4),
                Flexible(child: Text('Despacho a domicilio', style: T.apoyo.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: C.superficie,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: C.bordeControl, width: 1.5),
        ),
        child: Row(children: [
          const Icon(LucideIcons.search, size: 24, color: C.verde),
          const SizedBox(width: 12),
          Expanded(child: Text('Buscar arroz, bebidas, galletas…', style: T.cuerpo.copyWith(color: C.grisTexto, fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
  final _ctl = PageController(viewportFraction: .92);
  int _i = 0;
  Timer? _t;
  bool _pausa = false;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted || !_ctl.hasClients || _pausa || sinMovimiento(context)) return;
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
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: s.fondo, borderRadius: BorderRadius.circular(26)),
                child: Stack(children: [
                  Positioned(right: -6, bottom: 4, child: Image.asset('assets/img/${s.imagen}', width: escala > 1.15 ? 130 : 215, height: escala > 1.15 ? 78 : 180, fit: BoxFit.contain, alignment: Alignment.bottomRight, semanticLabel: '')),
                  // Un velo del mismo color del banner deja el texto siempre legible sobre la foto.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [s.fondo, s.fondo, s.fondo.withValues(alpha: 0)], stops: const [0, .40, .62]),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 0, 18),
                    child: SizedBox(
                      width: escala > 1.15 ? 290 : 185,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.titulo, style: T.titulo2.copyWith(color: Colors.white, fontSize: 24), maxLines: 3),
                      const SizedBox(height: 6),
                      Text(s.sub, style: T.apoyo.copyWith(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Tocable(
                        etiqueta: s.cta,
                        onTap: () => irA(context, CategoriaPantalla(s.categoria)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Flexible(child: Text(s.cta, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.boton.copyWith(color: C.verdeBanner, fontSize: 16))),
                            const SizedBox(width: 6),
                            const Icon(LucideIcons.chevronRight, size: 20, color: C.verdeBanner),
                          ]),
                        ),
                      ),
                    ]),
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
        const SizedBox(width: 4),
        Tocable(
          etiqueta: _pausa ? 'Reanudar el cambio automático de banners' : 'Pausar el cambio automático de banners',
          onTap: () => setState(() => _pausa = !_pausa),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(_pausa ? LucideIcons.play : LucideIcons.pause, size: 22, color: C.grisMedio),
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
    final filas = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      filas.add(Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: tiles[i]),
            const SizedBox(width: 14),
            Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox()),
          ]),
        ),
      ));
    }
    return Column(children: filas);
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(aspectRatio: 1.7, child: Image.asset(c.ruta, fit: BoxFit.contain, cacheWidth: 400, semanticLabel: '')),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(c.icono, size: 22, color: C.tinta.withValues(alpha: .7)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.nombre, style: T.cuerpoFuerte.copyWith(fontSize: 17, height: 1.2)),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: C.verde, borderRadius: BorderRadius.circular(22)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Image.asset('assets/img/cat/todo-el-catalogo.webp', height: 88, fit: BoxFit.contain, alignment: Alignment.centerLeft, semanticLabel: ''),
          const SizedBox(height: 10),
          Text('Todo el catálogo', style: T.titulo3.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text('${Catalogo.productos.length} productos', style: T.apoyo.copyWith(color: C.verdePalido)),
        ]),
      ),
    );
  }
}

/// "Exclusivo online": único lugar de la interfaz donde viven el dorado y el morado, siempre sobre negro.
class _SeccionExclusivo extends StatelessWidget {
  const _SeccionExclusivo();

  @override
  Widget build(BuildContext context) {
    final productos = Catalogo.productos.where((p) => p.categoria == 'Galletas y Snacks' || p.categoria == 'Té e Infusiones').take(6).toList();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.only(bottom: 26),
      color: C.negro,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
          child: Row(children: [
            const Icon(LucideIcons.sparkles, color: C.oro, size: 26),
            const SizedBox(width: 10),
            Expanded(child: Text('Exclusivo online', style: T.titulo2.copyWith(color: C.oro))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text('Selección que solo encuentras en la app y la web.', style: T.cuerpo.copyWith(color: const Color(0xFFD7D7E0), fontSize: 16)),
        ),
        const FilaHorizontal(hijos: [
          _BannerOscuro('Galletas y snacks', 'Para cada antojo', 'hero/galletas.webp', 'Galletas y Snacks', C.oro),
          _BannerOscuro('Té e infusiones', 'Una pausa para ti', 'hero/te.webp', 'Té e Infusiones', C.morado),
        ]),
        const SizedBox(height: 18),
        FilaHorizontal(hijos: [for (final p in productos) SizedBox(width: 180, child: _TarjetaOscura(p))]),
      ]),
    );
  }
}

class _BannerOscuro extends StatelessWidget {
  const _BannerOscuro(this.titulo, this.sub, this.imagen, this.categoria, this.acento);
  final String titulo;
  final String sub;
  final String imagen;
  final String categoria;
  final Color acento;

  @override
  Widget build(BuildContext context) {
    return Tocable(
      etiqueta: '$titulo. $sub',
      onTap: () => irA(context, CategoriaPantalla(categoria)),
      child: Container(
        width: 310,
        constraints: const BoxConstraints(minHeight: 150),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: C.carbon,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: acento.withValues(alpha: .55), width: 1.5),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 4, 18),
              child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titulo, style: T.titulo3.copyWith(color: acento, fontSize: 22)),
                const SizedBox(height: 4),
                Text(sub, style: T.apoyo.copyWith(color: Colors.white, fontSize: 15)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: acento, borderRadius: BorderRadius.circular(12)),
                  child: Text('Comprar', style: T.boton.copyWith(color: C.negro, fontSize: 16)),
                ),
              ]),
            ),
          ),
          SizedBox(width: 130, child: Image.asset('assets/img/$imagen', fit: BoxFit.contain, semanticLabel: '')),
        ]),
      ),
    );
  }
}

class _TarjetaOscura extends StatelessWidget {
  const _TarjetaOscura(this.p);
  final Producto p;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: C.carbon, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.carbonBorde)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: Tocable(
            etiqueta: 'Ver ${p.nombre}',
            onTap: () => abrirProducto(context, p),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AspectRatio(aspectRatio: 1.25, child: FotoProducto(p, fondo: const Color(0xFF22222C))),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.nombre, maxLines: 3, overflow: TextOverflow.ellipsis, style: T.cuerpo.copyWith(color: Colors.white, fontSize: 16, height: 1.25, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(clp(p.precioFinal), style: T.precio.copyWith(color: C.oro)),
                ]),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
          child: Boton('Agregar', icono: LucideIcons.plus, estilo: EstiloBoton.dorado, alto: 50, onTap: () {
            estado.agregar(p);
            avisoAgregado(context, p);
          }),
        ),
      ]),
    );
  }
}

class _Beneficios extends StatelessWidget {
  const _Beneficios();

  @override
  Widget build(BuildContext context) {
    const filas = [
      (LucideIcons.truck, 'Despacho en 24 a 48 horas', 'Gratis desde \$49.990'),
      (LucideIcons.shieldCheck, 'Pago seguro con Webpay', 'Tarjeta de débito o crédito'),
      (LucideIcons.phone, 'Te atendemos por teléfono', 'Llama o escribe por WhatsApp'),
    ];
    return Panel(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Column(children: [
        for (var i = 0; i < filas.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: C.verdeSuave, shape: BoxShape.circle),
                child: Icon(filas[i].$1, color: C.verdeOscuro, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(filas[i].$2, style: T.cuerpoFuerte.copyWith(fontSize: 17)),
                  Text(filas[i].$3, style: T.apoyo),
                ]),
              ),
            ]),
          ),
          if (i < filas.length - 1) const Divider(height: 1),
        ],
      ]),
    );
  }
}

class _AyudaTarjeta extends StatelessWidget {
  const _AyudaTarjeta();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: C.azul, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('¿Necesitas ayuda para comprar?', style: T.titulo3.copyWith(color: Colors.white, fontSize: 22)),
        const SizedBox(height: 6),
        Text('Te acompañamos paso a paso por teléfono.', style: T.cuerpo.copyWith(color: const Color(0xFFDCE6F5), fontSize: 16)),
        const SizedBox(height: 16),
        Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.phone, color: C.azulOscuro, size: 22),
            const SizedBox(width: 10),
            Text('Llamar $telefonoVisible', style: T.boton.copyWith(color: C.azulOscuro, fontSize: 17)),
          ]),
        ),
      ]),
    );
  }
}
