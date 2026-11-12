part of 'componentes.dart';

// Tarjeta de producto, grillas y avisos de agregar o quitar (parte de componentes.dart).

/// Agrega al carrito con vibración leve, una burbuja que vuela desde [context] hasta el carrito y el aviso
/// "Agregaste…" con acceso al carrito. Pasar el contexto del propio botón para que la burbuja salga de él.
void agregarAlCarrito(BuildContext context, Producto p, {int n = 1, bool oscuro = false}) {
  vibracionLeve();
  estado.agregar(p, n);
  volarAlCarrito(context, oscuro: oscuro);
  avisoAgregado(context, p);
}

/// Tarjeta de producto de la grilla / carruseles. Al tocar la foto o el nombre se abre la ficha con una
/// transición de contenedor (la tarjeta se expande hasta ser la pantalla). Cada tarjeta escucha solo la
/// cantidad de su producto, y el botón "Agregar" se transforma en selector de cantidad.
class TarjetaProducto extends StatelessWidget {
  const TarjetaProducto(this.p, {super.key});
  final Producto p;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: OpenContainer<void>(
        tappable: false,
        closedElevation: 0,
        openElevation: 0,
        closedColor: C.superficie,
        openColor: C.fondo,
        middleColor: C.fondo,
        closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.l)),
        transitionDuration: dur(context, 380),
        transitionType: ContainerTransitionType.fade,
        openBuilder: (_, _) => ProductoPantalla(p),
        closedBuilder: (context, abrir) => _contenido(context, abrir),
      ),
    );
  }

  Widget _contenido(BuildContext context, VoidCallback abrir) {
    return Stack(fit: StackFit.passthrough, children: [
      _tarjeta(context, abrir),
      Positioned(top: 2, right: 2, child: BotonFavorito(p)),
    ]);
  }

  Widget _tarjeta(BuildContext context, VoidCallback abrir) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(R.l),
        border: Border.all(color: C.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Tocable(
            etiqueta: '${p.nombre}, ${p.precioFinal} pesos${p.enOferta ? ', antes ${p.precio} pesos, ${p.descuento} por ciento de descuento' : ''}. Ver detalle',
            onTap: abrir,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AspectRatio(
                aspectRatio: 1.18,
                child: Stack(fit: StackFit.expand, children: [
                  Opacity(opacity: p.agotado ? .45 : 1, child: FotoProducto(p)),
                  if (p.agotado)
                    const Positioned(left: 10, top: 10, child: Insignia('Agotado', fondo: C.carbon)),
                  if (p.enOferta && !p.agotado)
                    Positioned(
                        left: 0,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(Esp.x3, 5, Esp.x3, 5),
                          decoration: const BoxDecoration(
                              color: C.rojo,
                              borderRadius: BorderRadius.horizontal(right: Radius.circular(R.s))),
                          child: Text('-${p.descuento}%', style: T.etiqueta.copyWith(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                        )),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Esp.x3, Esp.x3, Esp.x3, Esp.x2),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.nombre, maxLines: 3, overflow: TextOverflow.ellipsis, style: T.cuerpoMFuerte.copyWith(height: 1.25)),
                  const SizedBox(height: Esp.x2),
                  PrecioProducto(p),
                ]),
              ),
            ]),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.x3, Esp.x1, Esp.x3, Esp.x3),
            child: p.agotado
                ? Boton('Agotado por ahora', etiqueta: '${p.nombre}, agotado por ahora', estilo: EstiloBoton.suave, alto: 50, onTap: null)
                : ValueListenableBuilder<int>(
                    valueListenable: estado.cantidadDe(p.id),
                    builder: (context, enCarro, _) => AnimatedSwitcher(
                      duration: dur(context, 200),
                      switchInCurve: Mov.entra,
                      switchOutCurve: Mov.sale,
                      transitionBuilder: (hijo, a) => FadeTransition(
                        opacity: a,
                        child: ScaleTransition(scale: Tween<double>(begin: .92, end: 1).animate(a), child: hijo),
                      ),
                      child: enCarro == 0
                          ? Boton('Agregar',
                              key: const ValueKey('agregar'),
                              etiqueta: 'Agregar ${p.nombre} al carrito',
                              icono: LucideIcons.plus,
                              estilo: EstiloBoton.suave,
                              alto: 50,
                              alTocarEn: (ctx) => agregarAlCarrito(ctx, p))
                          : Row(
                              key: const ValueKey('cantidad'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Cantidad(valor: enCarro, tam: 50, producto: p.nombre, vuela: true, cambia: (v) => v <= 0 ? quitarConDeshacer(context, p) : estado.cambiarCantidad(p, v)),
                              ],
                            ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

void _aviso(BuildContext context, String texto,
    {String? accion, VoidCallback? alAccion, int segundos = 5, IconData icono = LucideIcons.circleCheck}) {
  final m = ScaffoldMessenger.maybeOf(context);
  m?.hideCurrentSnackBar();
  m?.showSnackBar(SnackBar(
    // Cerca del borde de abajo: encima de la barra de navegación o de compra de la pantalla (el Scaffold los respeta).
    // En el carrito, además, se sube sobre su barra "Ir a pagar" (que no es del Scaffold) solo mientras esa barra existe:
    // al quitar el último producto el carrito queda vacío, no hay barra, y el aviso baja igual que en el resto de la app.
    margin: EdgeInsets.fromLTRB(Esp.x4, 0, Esp.x4, (context.findAncestorWidgetOfExactType<CarritoPestana>() != null && estado.carrito.isNotEmpty) ? 92 : Esp.x3),
    // Desde Flutter 3.29 un aviso con acción se queda para siempre salvo que se pida lo contrario: aquí se va solo.
    persist: false,
    duration: Duration(seconds: segundos),
    // Una X para quitarlo de inmediato: no hay que esperar los segundos del aviso.
    showCloseIcon: true,
    // La acción ("Ver carrito", "Deshacer") se queda en la misma línea que el texto: todos los avisos miden lo mismo.
    actionOverflowThreshold: 1,
    closeIconColor: Colors.white,
    // Si la acción ("Deshacer") deja poco espacio —letra muy grande o pantalla angosta— el ícono cede su lugar al texto.
    content: LayoutBuilder(
      builder: (context, caja) => Row(children: [
        if (caja.maxWidth > 120) ...[Icon(icono, color: C.verdeMenta, size: Ico.m), const SizedBox(width: Esp.x3)],
        Expanded(child: Text(texto, maxLines: 3, overflow: TextOverflow.ellipsis, style: T.cuerpoM.copyWith(color: Colors.white))),
      ]),
    ),
    action: accion == null ? null : SnackBarAction(label: accion, textColor: C.verdeMenta, onPressed: alAccion ?? () {}),
  ));
}

void avisoAgregado(BuildContext context, Producto p) {
  _aviso(context, 'Agregaste ${p.nombre}', segundos: 4, accion: 'Ver carrito', alAccion: () {
    Navigator.of(context).popUntil((r) => r.isFirst);
    estado.irAPestana(3);
  });
}

/// Quita un producto del carrito y deja 6 s para deshacer (nunca se borra "en silencio").
void quitarConDeshacer(BuildContext context, Producto p) {
  final n = estado.carrito[p.id] ?? 0;
  if (n == 0) return;
  estado.cambiarCantidad(p, 0);
  _aviso(context, 'Quitaste ${p.nombre}', accion: 'Deshacer', alAccion: () => estado.agregar(p, n), icono: LucideIcons.trash2);
}

void avisoGeneral(BuildContext context, String texto, {String? accion, VoidCallback? alAccion}) =>
    _aviso(context, texto, accion: accion, alAccion: alAccion);

/// Columnas de la grilla según el ancho disponible: 2 en teléfono, 3 o 4 en pantallas anchas.
int columnasProductos(double ancho) => (ancho / 190).floor().clamp(2, 4);

/// Una fila de la grilla: tarjetas de altura pareja, sin alturas fijas (aguantan letra grande).
class FilaProductos extends StatelessWidget {
  const FilaProductos(this.productos, {super.key, required this.columnas});
  final List<Producto> productos;
  final int columnas;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var k = 0; k < columnas; k++) ...[
          if (k > 0) const SizedBox(width: Esp.x3),
          Expanded(child: k < productos.length ? Revelar(indice: k, child: TarjetaProducto(productos[k])) : const SizedBox()),
        ],
      ]),
    );
  }
}

/// Grilla para pocos productos (por ejemplo 4 recomendados). Para listados largos usar [SliverGrillaProductos].
class GrillaProductos extends StatelessWidget {
  const GrillaProductos(this.productos, {super.key});
  final List<Producto> productos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, caja) {
      final cols = columnasProductos(caja.maxWidth);
      return Column(children: [
        for (var i = 0; i < productos.length; i += cols)
          Padding(
            padding: const EdgeInsets.only(bottom: Esp.x3),
            child: FilaProductos(productos.sublist(i, (i + cols).clamp(0, productos.length)), columnas: cols),
          ),
      ]);
    });
  }
}

/// Grilla perezosa para listados largos: arma solo las filas que se ven (cada fila conserva su altura pareja).
/// Va dentro de un `CustomScrollView`; el relleno lateral lo pone quien la usa.
class SliverGrillaProductos extends StatelessWidget {
  const SliverGrillaProductos(this.productos, {super.key});
  final List<Producto> productos;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(builder: (context, sc) {
      final cols = columnasProductos(sc.crossAxisExtent);
      return SliverList.builder(
        itemCount: (productos.length / cols).ceil(),
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: Esp.x3),
          child: FilaProductos(productos.sublist(i * cols, ((i + 1) * cols).clamp(0, productos.length)), columnas: cols),
        ),
      );
    });
  }
}

/// Carrito pequeño para pantallas que tapan la barra de navegación (ficha, catálogo, búsqueda, favoritos):
/// muestra cuántos productos hay, abre el carrito y es donde aterriza la burbuja de "agregar".
class BotonCarritoMini extends StatelessWidget {
  const BotonCarritoMini({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) => Tocable(
        etiqueta: estado.cantidadCarrito == 0 ? 'Ver carrito, vacío' : 'Ver carrito, ${estado.cantidadCarrito} productos',
        onTap: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          estado.irAPestana(3);
        },
        radio: 24,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, color: C.superficie.withValues(alpha: .94), border: Border.all(color: C.borde)),
              child: Center(
                child: IconTheme(
                  data: IconThemeData(size: 20, color: C.grisMedio),
                  child: IconoCarritoAnimado(icono: LucideIcons.shoppingCart, cantidad: estado.cantidadCarrito),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
