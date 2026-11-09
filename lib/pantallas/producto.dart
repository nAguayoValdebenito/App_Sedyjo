import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/componentes.dart';

class ProductoPantalla extends StatefulWidget {
  const ProductoPantalla(this.p, {super.key});
  final Producto p;

  @override
  State<ProductoPantalla> createState() => _ProductoPantallaState();
}

class _ProductoPantallaState extends State<ProductoPantalla> {
  int _cantidad = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final relacionados = Catalogo.deCategoria(p.categoria)
        .where((e) => e.id != p.id)
        .take(5)
        .toList();
    final arriba = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(height: arriba, color: p.fondo),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          color: p.fondo,
                          padding: EdgeInsets.fromLTRB(36, 72, 36, p.fotoUso != null ? 54 : 30),
                          child: _Galeria(p),
                        ),
                        if (p.enOferta)
                          Positioned(
                            left: 0,
                            bottom: p.fotoUso != null ? 58 : 14,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(16, 8, 18, 8),
                              decoration: const BoxDecoration(
                                color: C.rojo,
                                borderRadius: BorderRadius.horizontal(
                                  right: Radius.circular(14),
                                ),
                              ),
                              child: Text(
                                '-${p.descuento}% de descuento',
                                style: T.etiqueta.copyWith(
                                  color: C.superficie,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.categoria,
                            style: T.apoyo.copyWith(
                              color: C.verdeOscuro,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Semantics(
                            header: true,
                            child: Text(
                              p.nombre,
                              style: T.titulo1.copyWith(fontSize: 28),
                            ),
                          ),
                          if (p.descripcion.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              p.descripcion,
                              style: T.cuerpo.copyWith(color: C.grisMedio),
                            ),
                          ],
                          const SizedBox(height: 16),
                          PrecioProducto(p, grande: true),
                          if (p.enOferta)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Ahorras ${clp(p.precio - p.precioFinal)} por unidad',
                                style: T.apoyo.copyWith(
                                  color: C.verdeOscuro,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.circleCheck,
                                size: 20,
                                color: C.verde,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.agotado ? 'Agotado por ahora. Te avisamos cuando vuelva.' : 'Disponible, lo despachamos en 24 a 48 horas',
                                  style: T.apoyo.copyWith(color: C.tinta),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          Text('Cantidad', style: T.titulo3),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Cantidad(
                                valor: _cantidad,
                                minimo: 1,
                                tam: 58,
                                cambia: (v) => setState(() => _cantidad = v),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Subtotal\n${clp(p.precioFinal * _cantidad)}',
                                  style: T.cuerpoFuerte.copyWith(fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Panel(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Column(
                              children: const [
                                _FilaInfo(
                                  LucideIcons.truck,
                                  'Despacho a domicilio',
                                  'Gratis desde \$49.990 en compras',
                                ),
                                Divider(height: 1),
                                _FilaInfo(
                                  LucideIcons.shieldCheck,
                                  'Pago seguro',
                                  'Con Webpay, débito o crédito',
                                ),
                                Divider(height: 1),
                                _FilaInfo(
                                  LucideIcons.refreshCw,
                                  'Cambios y devoluciones',
                                  'Si algo llega mal, lo resolvemos',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (relacionados.isNotEmpty) ...[
                      const TituloSeccion('También te puede gustar'),
                      FilaHorizontal(hijos: [
                for (final r in relacionados)
                  SizedBox(
                    width: 188,
                    child: TarjetaProducto(r, abrir: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ProductoPantalla(r)));
                    }),
                  ),
              ]),
                    ],
                    const SizedBox(height: 28),
                  ],
                ),
              ),
              // Barra de compra fija
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: BoxDecoration(
                  color: C.superficie,
                  border: Border(top: BorderSide(color: C.borde)),
                ),
                child: SafeArea(
                  top: false,
                  child: p.agotado
                      ? Boton('Avisarme cuando llegue', icono: LucideIcons.bellRing, estilo: EstiloBoton.contorno, alto: 62, onTap: () => avisoGeneral(context, 'Listo, te avisaremos cuando vuelva ${p.nombre}'))
                      : Boton(
                    'Agregar · ${clp(p.precioFinal * _cantidad)}',
                    icono: LucideIcons.shoppingCart,
                    alto: 62,
                    onTap: () {
                      estado.agregar(p, _cantidad);
                      avisoAgregado(context, p);
                    },
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            top: arriba + 8,
            child: BotonIcono(
              LucideIcons.arrowLeft,
              'Volver',
              fondo: C.superficie,
              color: C.tinta,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaInfo extends StatelessWidget {
  const _FilaInfo(this.icono, this.titulo, this.texto);
  final IconData icono;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icono, size: 26, color: C.verdeOscuro),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: T.cuerpoFuerte.copyWith(fontSize: 17)),
                Text(texto, style: T.apoyo),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Galería de la ficha: el producto recortado y, si existe, una foto "en uso" para provocar el antojo.
class _Galeria extends StatefulWidget {
  const _Galeria(this.p);
  final Producto p;

  @override
  State<_Galeria> createState() => _GaleriaState();
}

class _GaleriaState extends State<_Galeria> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final imagenes = [if (p.ruta != null) p.ruta!, if (p.fotoUso != null) p.fotoUso!];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AspectRatio(
        aspectRatio: 1.15,
        child: Stack(children: [
          PageView.builder(
            itemCount: imagenes.isEmpty ? 1 : imagenes.length,
            onPageChanged: (v) => setState(() => _i = v),
            itemBuilder: (_, k) => imagenes.isEmpty
                ? Center(child: Icon(LucideIcons.package, size: 56, color: C.grisTexto))
                : Opacity(
                    opacity: p.agotado ? .5 : 1,
                    child: Padding(
                      padding: EdgeInsets.all(k == 0 ? 0 : 4),
                      child: Image.asset(imagenes[k], fit: BoxFit.contain, semanticLabel: k == 0 ? p.nombre : 'Foto de ${p.nombre} para servir'),
                    ),
                  ),
          ),
          if (p.agotado) const Positioned(right: 0, top: 0, child: Insignia('Agotado', fondo: C.carbon)),
        ]),
      ),
      if (imagenes.length > 1) ...[
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var k = 0; k < imagenes.length; k++)
            AnimatedContainer(
              duration: dur(context, 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: k == _i ? 24 : 9,
              height: 9,
              decoration: BoxDecoration(color: k == _i ? C.verde : C.bordeControl, borderRadius: BorderRadius.circular(6)),
            ),
          const SizedBox(width: 10),
          Text(_i == 0 ? 'Desliza: así se disfruta' : 'Desliza: el producto', style: T.apoyo.copyWith(fontSize: 14)),
        ]),
      ],
    ]);
  }
}
