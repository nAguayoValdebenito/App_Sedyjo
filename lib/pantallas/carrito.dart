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
              : Column(children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                      children: [
                        Row(children: [
                          Expanded(child: Text('Mi carrito', style: T.titulo1)),
                          Tocable(
                            etiqueta: 'Vaciar carrito',
                            onTap: () => _confirmarVaciar(context),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text('Vaciar', style: T.cuerpoFuerte.copyWith(color: C.error, fontSize: 16)),
                            ),
                          ),
                        ]),
                        Text('${estado.cantidadCarrito} productos', style: T.apoyo),
                        const SizedBox(height: 16),
                        const BarraDespacho(),
                        const SizedBox(height: 16),
                        for (final (p, n) in lineas) ...[_LineaCarrito(p, n), const SizedBox(height: 12)],
                        const SizedBox(height: 6),
                        const _Resumen(),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    decoration: BoxDecoration(color: C.superficie, border: Border(top: BorderSide(color: C.borde))),
                    child: Row(children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text('Total', style: T.apoyo),
                        Text(clp(estado.subtotal), style: T.titulo2),
                      ]),
                      const SizedBox(width: 18),
                      Expanded(child: Boton('Ir a pagar', iconoDerecha: true, icono: LucideIcons.chevronRight, onTap: () => irA(context, const CheckoutPantalla()), alto: 60)),
                    ]),
                  ),
                ]),
        );
      },
    );
  }

  void _confirmarVaciar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.superficie,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('¿Vaciar el carrito?', style: T.titulo2),
          const SizedBox(height: 8),
          Text('Se quitarán todos los productos. Esto no se puede deshacer.', style: T.cuerpo.copyWith(color: C.grisMedio)),
          const SizedBox(height: 22),
          Boton('Sí, vaciar carrito', estilo: EstiloBoton.peligro, onTap: () {
            estado.vaciarCarrito();
            Navigator.pop(ctx);
          }),
          const SizedBox(height: 10),
          Boton('No, volver', estilo: EstiloBoton.suave, onTap: () => Navigator.pop(ctx)),
        ]),
      ),
    );
  }
}

class _LineaCarrito extends StatelessWidget {
  const _LineaCarrito(this.p, this.n);
  final Producto p;
  final int n;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Tocable(
          etiqueta: 'Ver ${p.nombre}',
          onTap: () => abrirProducto(context, p),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(width: 84, height: 84, child: FotoProducto(p))),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.nombre, style: T.cuerpoFuerte.copyWith(fontSize: 17, height: 1.25), maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                PrecioProducto(p),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Cantidad(valor: n, tam: 50, minimo: 1, producto: p.nombre, cambia: (v) => estado.cambiarCantidad(p, v)),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(clp(p.precioFinal * n), style: T.titulo3),
            Tocable(
              etiqueta: 'Quitar ${p.nombre}',
              onTap: () => quitarConDeshacer(context, p),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(LucideIcons.trash2, size: 18, color: C.error),
                  const SizedBox(width: 6),
                  Text('Quitar', style: T.etiqueta.copyWith(color: C.error, fontSize: 15)),
                ]),
              ),
            ),
          ]),
        ]),
      ]),
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
            const SizedBox(width: 12),
            Flexible(child: Text(b, textAlign: TextAlign.right, style: (fuerte ? T.titulo3 : T.cuerpoFuerte).copyWith(color: color))),
          ]),
        );
    return Panel(
      fondo: C.grisFondo,
      borde: C.grisFondo,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(children: [
        fila('Productos', clp(estado.subtotal + estado.ahorro)),
        if (estado.ahorro > 0) fila('Ahorro en ofertas', '-${clp(estado.ahorro)}', color: C.verdeOscuro),
        fila('Despacho', estado.despachoGratis ? 'Gratis' : 'Se calcula al elegir tu dirección'),
        const Divider(height: 22),
        fila('Total', clp(estado.subtotal), fuerte: true),
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
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const IlustracionEstado('carrito-vacio.webp'),
          const SizedBox(height: 24),
          Text('Tu carrito está vacío', style: T.titulo2, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Agrega productos y aquí verás tu compra.', textAlign: TextAlign.center, style: T.cuerpo.copyWith(color: C.grisMedio)),
          const SizedBox(height: 26),
          Boton('Ver ofertas', icono: LucideIcons.percent, onTap: () => estado.irAPestana(2)),
          const SizedBox(height: 10),
          Boton('Ir al inicio', estilo: EstiloBoton.suave, onTap: () => estado.irAPestana(0)),
        ]),
      ),
    );
  }
}
