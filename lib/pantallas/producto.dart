import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/boton_favorito.dart';
import '../ui/componentes.dart';
import 'tienda.dart';

class ProductoPantalla extends StatefulWidget {
  const ProductoPantalla(this.p, {super.key});
  final Producto p;

  @override
  State<ProductoPantalla> createState() => _ProductoPantallaState();
}

class _ProductoPantallaState extends State<ProductoPantalla> {
  int _cantidad = 1;

  @override
  void initState() {
    super.initState();
    // Lo que se mira alimenta las sugerencias del buscador (después del primer cuadro, para no avisar durante la construcción).
    WidgetsBinding.instance.addPostFrameCallback((_) => estado.registrarVisto(widget.p.id));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final relacionados = Catalogo.deCategoria(p.categoria)
        .where((e) => e.id != p.id)
        .take(5)
        .toList();
    final arriba = MediaQuery.paddingOf(context).top;
    // La barra de compra va como barra inferior del Scaffold: los avisos ("Agregaste…") flotan encima de ella, no tapándola.
    return Scaffold(
      bottomNavigationBar: Container(
                padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x3, Esp.x5, Esp.x3),
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
                    alTocarEn: (ctx) => agregarAlCarrito(ctx, p, n: _cantidad),
                  ),
                ),
              ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(height: arriba, color: p.fondo),
              Expanded(
                child: LayoutBuilder(builder: (context, caja) {
                  // En tableta o con el teléfono acostado: la foto a la izquierda y el detalle a la derecha.
                  final ancha = caja.maxWidth >= 700;
                  final galeria = Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          color: p.fondo,
                          padding: EdgeInsets.fromLTRB(36, 72, 36, p.fotoUso != null ? 54 : Esp.x8),
                          child: _Galeria(p),
                        ),
                        if (p.enOferta)
                          Positioned(
                            left: 0,
                            bottom: p.fotoUso != null ? 58 : 14,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(Esp.x4, Esp.x2, Esp.x4, Esp.x2),
                              decoration: const BoxDecoration(
                                color: C.rojo,
                                borderRadius: BorderRadius.horizontal(
                                  right: Radius.circular(R.s),
                                ),
                              ),
                              child: Text(
                                '-${p.descuento}% de descuento',
                                style: T.etiqueta.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  final resto = <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x6, Esp.x5, 0),
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
                          const SizedBox(height: Esp.x2),
                          Semantics(
                            header: true,
                            child: Text(
                              p.nombre,
                              style: T.titulo1.copyWith(fontSize: 28),
                            ),
                          ),
                          if (p.descripcion.isNotEmpty) ...[
                            const SizedBox(height: Esp.x2),
                            Text(
                              p.descripcion,
                              style: T.cuerpo.copyWith(color: C.grisMedio),
                            ),
                          ],
                          const SizedBox(height: Esp.x4),
                          PrecioProducto(p, grande: true),
                          if (p.enOferta)
                            Padding(
                              padding: const EdgeInsets.only(top: Esp.x2),
                              child: Text(
                                'Ahorras ${clp(p.precio - p.precioFinal)} por unidad',
                                style: T.apoyo.copyWith(
                                  color: C.verdeOscuro,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          const SizedBox(height: Esp.x3),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.circleCheck,
                                size: 20,
                                color: C.verde,
                              ),
                              const SizedBox(width: Esp.x2),
                              Expanded(
                                child: Text(
                                  p.agotado ? 'Agotado por ahora. Te avisamos cuando vuelva.' : 'Disponible, lo despachamos en 24 a 48 horas',
                                  style: T.apoyo.copyWith(color: C.tinta),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Esp.x6),
                          Text('Cantidad', style: T.titulo3),
                          const SizedBox(height: Esp.x3),
                          Row(
                            children: [
                              Cantidad(
                                valor: _cantidad,
                                minimo: 1,
                                tam: 58,
                                cambia: (v) => setState(() => _cantidad = v),
                              ),
                              const SizedBox(width: Esp.x4),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('Subtotal', style: T.cuerpoFuerte.copyWith(fontSize: 18)),
                                  NumeroAnimado(p.precioFinal * _cantidad, estilo: T.cuerpoFuerte.copyWith(fontSize: 18)),
                                ]),
                              ),
                            ],
                          ),
                          const SizedBox(height: Esp.x8),
                          Panel(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Esp.x4,
                              vertical: Esp.x1,
                            ),
                            child: Column(
                              children: const [
                                _FilaInfo(
                                  LucideIcons.truck,
                                  'Despacho a domicilio',
                                  'Gratis desde \$39.990 en compras',
                                ),
                                Divider(height: 1),
                                _FilaInfo(
                                  LucideIcons.store,
                                  'Retiro en tienda',
                                  'Av. Collao 2480, Concepción · sin costo',
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
                    child: TarjetaProducto(r),
                  ),
              ]),
                    ],
                    const SizedBox(height: Esp.x8),
                  ];
                  if (!ancha) return ListView(padding: EdgeInsets.zero, children: [galeria, ...resto]);
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 5, child: SingleChildScrollView(child: galeria)),
                    Expanded(flex: 6, child: ListView(padding: EdgeInsets.zero, children: resto)),
                  ]);
                }),
              ),
            ],
          ),
          Positioned(right: Esp.x3, top: arriba + 2, child: BotonFavorito(p)),
          Positioned(right: Esp.x3 + 52, top: arriba + 2, child: const BotonCarritoMini()),
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
    // La fila de la tienda abre "Retiro en tienda" (dirección, horario y cómo llegar).
    final esTienda = icono == LucideIcons.store;
    final fila = Padding(
      padding: const EdgeInsets.symmetric(vertical: Esp.x3),
      child: Row(
        children: [
          Icon(icono, size: Ico.m, color: C.verdeOscuro),
          const SizedBox(width: Esp.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: T.cuerpoFuerte),
                Text(texto, style: T.apoyo),
              ],
            ),
          ),
          if (esTienda) Icon(LucideIcons.chevronRight, color: C.verdeOscuro),
        ],
      ),
    );
    if (!esTienda) return fila;
    return Tocable(etiqueta: '$titulo, $texto. Ver cómo llegar', onTap: () => irA(context, const TiendaPantalla()), child: fila);
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
  bool _precargado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // La segunda foto ya está lista cuando la persona desliza.
    final uso = widget.p.fotoUso;
    if (!_precargado && uso != null) {
      _precargado = true;
      precacheImage(AssetImage(uso), context);
    }
  }

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
                      padding: EdgeInsets.all(k == 0 ? 0 : Esp.x1),
                      child: Image.asset(imagenes[k], fit: BoxFit.contain, cacheWidth: 900, semanticLabel: k == 0 ? p.nombre : 'Foto de ${p.nombre} para servir'),
                    ),
                  ),
          ),
          if (p.agotado) const Positioned(right: 0, top: 0, child: Insignia('Agotado', fondo: C.carbon)),
        ]),
      ),
      if (imagenes.length > 1) ...[
        const SizedBox(height: Esp.x2),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var k = 0; k < imagenes.length; k++)
            AnimatedContainer(
              duration: dur(context, 200),
              curve: Mov.entra,
              margin: const EdgeInsets.symmetric(horizontal: Esp.x1),
              width: k == _i ? 24 : 9,
              height: 9,
              decoration: BoxDecoration(color: k == _i ? C.verde : C.bordeControl, borderRadius: BorderRadius.circular(6)),
            ),
          const SizedBox(width: Esp.x3),
          Flexible(child: Text(_i == 0 ? 'Desliza: así se disfruta' : 'Desliza: el producto', maxLines: 1, overflow: TextOverflow.ellipsis, style: T.apoyo.copyWith(fontSize: 14))),
        ]),
      ],
    ]);
  }
}
