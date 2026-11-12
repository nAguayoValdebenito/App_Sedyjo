import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/componentes.dart';
import 'checkout.dart';
import 'inicio.dart' show abrirProducto;

class CarritoPestana extends StatelessWidget {
  const CarritoPestana({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        final lineas = estado.carrito.entries.map((e) => (Catalogo.porId(e.key), e.value)).toList();
        return SafeArea(
          bottom: false,
          child: lineas.isEmpty
              ? const _CarritoVacio()
              : LayoutBuilder(builder: (context, caja) {
                  // En tableta o con el teléfono acostado: las líneas a la izquierda y el resumen con el pago a la derecha.
                  final ancha = caja.maxWidth >= 720;
                  final encabezado = <Widget>[
                    Row(children: [
                      Expanded(child: Text('Mi carrito', style: T.titulo1)),
                      Tocable(
                        etiqueta: 'Vaciar carrito',
                        onTap: () => _confirmarVaciar(context),
                        child: Padding(
                          padding: const EdgeInsets.all(Esp.x3),
                          child: Text('Vaciar', style: T.cuerpoFuerte.copyWith(color: C.error, fontSize: 16)),
                        ),
                      ),
                    ]),
                    Text('${estado.cantidadCarrito} productos', style: T.apoyo),
                    const SizedBox(height: Esp.x4),
                    const BarraDespacho(),
                    const SizedBox(height: Esp.x4),
                    for (final (p, n) in lineas) _LineaCarrito(p, n, key: ValueKey(p.id)),
                  ];
                  final pagar = Row(children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text('Total', style: T.apoyo),
                      NumeroAnimado(estado.subtotal, estilo: T.titulo2),
                    ]),
                    const SizedBox(width: Esp.x4),
                    Expanded(child: Boton('Ir a pagar', iconoDerecha: true, icono: LucideIcons.chevronRight, onTap: () => irA(context, const CheckoutPantalla()), alto: 60)),
                  ]);
                  if (ancha) {
                    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x3, Esp.x3, Esp.x5), children: encabezado)),
                      SizedBox(
                        width: 360,
                        child: ListView(padding: const EdgeInsets.fromLTRB(Esp.x3, Esp.x3, Esp.x5, Esp.x5), children: [const _Resumen(), const SizedBox(height: Esp.x4), pagar]),
                      ),
                    ]);
                  }
                  return Column(children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x3, Esp.x5, Esp.x5),
                        children: [...encabezado, const SizedBox(height: Esp.x2), const _Resumen()],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x3, Esp.x5, Esp.x3),
                      decoration: BoxDecoration(color: C.superficie, border: Border(top: BorderSide(color: C.borde))),
                      child: pagar,
                    ),
                  ]);
                }),
        );
      },
    );
  }

  void _confirmarVaciar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.superficie,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(Esp.x6, Esp.x6, Esp.x6, Esp.x8),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('¿Vaciar el carrito?', style: T.titulo2),
          const SizedBox(height: Esp.x2),
          Text('Se quitarán todos los productos. Esto no se puede deshacer.', style: T.cuerpo.copyWith(color: C.grisMedio)),
          const SizedBox(height: Esp.x6),
          Boton('Sí, vaciar carrito', estilo: EstiloBoton.peligro, onTap: () {
            estado.vaciarCarrito();
            Navigator.pop(ctx);
          }),
          const SizedBox(height: Esp.x3),
          Boton('No, volver', estilo: EstiloBoton.suave, onTap: () => Navigator.pop(ctx)),
        ]),
      ),
    );
  }
}

/// Una línea del carrito. Entra desplegándose (al deshacer un "Quitar") y sale plegándose antes de quitarse,
/// así el resto de la lista baja o sube con suavidad en vez de saltar.
class _LineaCarrito extends StatefulWidget {
  const _LineaCarrito(this.p, this.n, {super.key});
  final Producto p;
  final int n;

  @override
  State<_LineaCarrito> createState() => _LineaCarritoState();
}

class _LineaCarritoState extends State<_LineaCarrito> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(vsync: this, duration: Mov.cambio, value: 0);
  late final Animation<double> _curva = CurvedAnimation(parent: _ctl, curve: Mov.entra, reverseCurve: Mov.sale);
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    if (sinMovimiento(context)) {
      _ctl.value = 1;
    } else {
      _ctl.forward();
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _quitar() async {
    if (!sinMovimiento(context)) await _ctl.reverse();
    if (!mounted) return;
    quitarConDeshacer(context, widget.p);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final n = widget.n;
    return SizeTransition(
      sizeFactor: _curva,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _curva,
        child: Padding(
          padding: const EdgeInsets.only(bottom: Esp.x3),
          // Fila plana con un separador fino: sin una tarjeta con borde alrededor de la foto (cajas dentro de cajas).
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: Esp.x4),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.borde))),
            child: Column(children: [
              Tocable(
                etiqueta: 'Ver ${p.nombre}',
                onTap: () => abrirProducto(context, p),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(borderRadius: BorderRadius.circular(R.s), child: SizedBox(width: 84, height: 84, child: FotoProducto(p))),
                  const SizedBox(width: Esp.x3),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.nombre, style: T.cuerpoFuerte.copyWith(height: 1.25), maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: Esp.x2),
                      PrecioProducto(p),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: Esp.x3),
              Row(children: [
                Cantidad(valor: n, tam: 50, minimo: 1, producto: p.nombre, vuela: true, cambia: (v) => estado.cambiarCantidad(p, v)),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  NumeroAnimado(p.precioFinal * n, estilo: T.titulo3),
                  Tocable(
                    etiqueta: 'Quitar ${p.nombre}',
                    onTap: _quitar,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Esp.x2),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(LucideIcons.trash2, size: Ico.s, color: C.error),
                        const SizedBox(width: Esp.x2),
                        Text('Quitar', style: T.etiqueta.copyWith(color: C.error, fontSize: 15)),
                      ]),
                    ),
                  ),
                ]),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen();

  @override
  Widget build(BuildContext context) {
    Widget fila(String a, String b, {bool fuerte = false, Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(a, style: fuerte ? T.titulo3 : T.cuerpo)),
            const SizedBox(width: Esp.x3),
            Flexible(child: Text(b, textAlign: TextAlign.right, style: (fuerte ? T.titulo3 : T.cuerpoFuerte).copyWith(color: color))),
          ]),
        );
    return Panel(
      fondo: C.grisFondo,
      borde: C.grisFondo,
      padding: const EdgeInsets.fromLTRB(Esp.x4, Esp.x3, Esp.x4, Esp.x3),
      child: Column(children: [
        fila('Productos', clp(estado.subtotal + estado.ahorro)),
        if (estado.ahorro > 0) fila('Ahorro en ofertas', '-${clp(estado.ahorro)}', color: C.verdeOscuro),
        fila('Despacho', estado.despachoGratis ? 'Gratis' : 'Se calcula al elegir tu dirección'),
        const Divider(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Expanded(child: Text('Total', style: T.titulo3)),
            NumeroAnimado(estado.subtotal, estilo: T.titulo3),
          ]),
        ),
      ]),
    );
  }
}

class _CarritoVacio extends StatelessWidget {
  const _CarritoVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Esp.x8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const IlustracionEstado('carrito-vacio.webp'),
          const SizedBox(height: Esp.x6),
          Text('Tu carrito está vacío', style: T.titulo2, textAlign: TextAlign.center),
          const SizedBox(height: Esp.x2),
          Text('Agrega productos y aquí verás tu compra.', textAlign: TextAlign.center, style: T.cuerpo.copyWith(color: C.grisMedio)),
          const SizedBox(height: Esp.x6),
          Boton('Ver ofertas', icono: LucideIcons.percent, onTap: () => estado.irAPestana(2)),
          const SizedBox(height: Esp.x3),
          Boton('Ir al inicio', estilo: EstiloBoton.suave, onTap: () => estado.irAPestana(0)),
        ]),
      ),
    );
  }
}
