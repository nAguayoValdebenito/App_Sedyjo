import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';

/// Duración respetando "reducir movimiento".
Duration dur(BuildContext c, [int ms = 220]) =>
    (MediaQuery.maybeDisableAnimationsOf(c) ?? false) || estado.reducirMovimiento
        ? Duration.zero
        : Duration(milliseconds: ms);

bool sinMovimiento(BuildContext c) =>
    (MediaQuery.maybeDisableAnimationsOf(c) ?? false) || estado.reducirMovimiento;

/// Cualquier cosa tocable: se hunde un poco al presionar y expone semántica de botón.
class Tocable extends StatefulWidget {
  const Tocable({super.key, required this.child, this.onTap, this.etiqueta, this.radio = 16});
  final Widget child;
  final VoidCallback? onTap;
  final String? etiqueta;
  final double radio;

  @override
  State<Tocable> createState() => _TocableState();
}

class _TocableState extends State<Tocable> {
  bool _abajo = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.etiqueta,
      enabled: widget.onTap != null,
      onTap: widget.onTap,
      // Con etiqueta explícita, el lector no repite el texto interno ("Agregar, Agregar").
      excludeSemantics: widget.etiqueta != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _abajo = true),
        onTapCancel: () => setState(() => _abajo = false),
        onTapUp: (_) => setState(() => _abajo = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _abajo && !sinMovimiento(context) ? .97 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

enum EstiloBoton { primario, contorno, suave, dorado, peligro, texto }

/// Botón grande (56 dp de alto): pensado para dedos poco precisos y poca vista.
class Boton extends StatelessWidget {
  const Boton(this.texto,
      {super.key,
      this.onTap,
      this.icono,
      this.estilo = EstiloBoton.primario,
      this.alto = 58,
      this.expandido = true,
      this.iconoDerecha = false,
      this.etiqueta});
  final String texto;
  final VoidCallback? onTap;
  final IconData? icono;
  final EstiloBoton estilo;
  final double alto;
  final bool expandido;
  final bool iconoDerecha;
  final String? etiqueta;

  @override
  Widget build(BuildContext context) {
    final (fondo, color, borde) = switch (estilo) {
      EstiloBoton.primario => (C.verde, Colors.white, C.verde),
      EstiloBoton.contorno => (C.superficie, C.verdeOscuro, C.verde),
      EstiloBoton.suave => (C.verdeSuave, C.verdeOscuro, C.verdeSuave),
      EstiloBoton.dorado => (C.oro, C.negro, C.oro),
      EstiloBoton.peligro => (C.superficie, C.error, C.error),
      EstiloBoton.texto => (Colors.transparent, C.error, Colors.transparent),
    };
    final contenido = <Widget>[
      if (icono != null && !iconoDerecha) ...[Icon(icono, size: 22, color: color), const SizedBox(width: 10)],
      // Una sola palabra se achica para caber (nunca se parte a la mitad); una frase se reparte en líneas.
      Flexible(
        child: texto.contains(' ')
            ? Text(texto, textAlign: TextAlign.center, style: T.boton.copyWith(color: color, fontSize: 18))
            : FittedBox(fit: BoxFit.scaleDown, child: Text(texto, maxLines: 1, style: T.boton.copyWith(color: color, fontSize: 18))),
      ),
      if (icono != null && iconoDerecha) ...[const SizedBox(width: 10), Icon(icono, size: 22, color: color)],
    ];
    return Tocable(
      etiqueta: etiqueta ?? texto,
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? .5 : 1,
        child: Container(
          constraints: BoxConstraints(minHeight: alto),
          width: expandido ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borde, width: 2),
          ),
          child: Row(mainAxisSize: expandido ? MainAxisSize.max : MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: contenido),
        ),
      ),
    );
  }
}

/// Botón redondo solo con ícono (siempre con etiqueta para lectores de pantalla).
class BotonIcono extends StatelessWidget {
  const BotonIcono(this.icono, this.etiqueta,
      {super.key, this.onTap, this.fondo, this.color, this.tam = 48});
  final IconData icono;
  final String etiqueta;
  final VoidCallback? onTap;
  final Color? fondo;
  final Color? color;
  final double tam;

  @override
  Widget build(BuildContext context) {
    return Tocable(
      etiqueta: etiqueta,
      onTap: onTap,
      child: Container(
        width: tam,
        height: tam,
        decoration: BoxDecoration(color: fondo ?? C.verdeSuave, shape: BoxShape.circle),
        child: Icon(icono, size: tam * .46, color: color ?? C.verdeOscuro),
      ),
    );
  }
}

/// Barra superior de pantallas internas: volver con texto + título.
class BarraSuperior extends StatelessWidget {
  const BarraSuperior(this.titulo, {super.key, this.atras = true, this.accion});
  final String titulo;
  final bool atras;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          if (atras) ...[
            BotonIcono(LucideIcons.arrowLeft, 'Volver', onTap: () => Navigator.of(context).maybePop()),
            const SizedBox(width: 12),
          ],
          Expanded(child: Semantics(header: true, child: Text(titulo, style: T.titulo2.copyWith(fontSize: 24), maxLines: 2))),
          if (accion != null) accion!,
        ],
      ),
    );
  }
}

class Insignia extends StatelessWidget {
  const Insignia(this.texto, {super.key, this.fondo = C.rojo, this.color = Colors.white, this.icono});
  final String texto;
  final Color fondo;
  final Color color;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icono != null) ...[Icon(icono, size: 15, color: color), const SizedBox(width: 5)],
        Text(texto, style: T.etiqueta.copyWith(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

/// Selector de cantidad con botones de 52 dp.
class Cantidad extends StatelessWidget {
  const Cantidad({super.key, required this.valor, required this.cambia, this.tam = 52, this.minimo = 0, this.producto});
  final int valor;
  final String? producto;
  final ValueChanged<int> cambia;
  final double tam;
  final int minimo;

  @override
  Widget build(BuildContext context) {
    Widget boton(IconData i, String et, VoidCallback f, {bool activo = true}) => Tocable(
          etiqueta: activo ? et : '$et, no disponible',
          onTap: activo ? f : null,
          child: Opacity(
            opacity: activo ? 1 : .35,
            child: Container(
            width: tam,
            height: tam,
            decoration: BoxDecoration(color: C.verde, borderRadius: BorderRadius.circular(14)),
            child: Icon(i, color: Colors.white, size: 24),
          ),
          ),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      boton(LucideIcons.minus, 'Quitar una unidad${producto == null ? '' : ' de $producto'}', () => cambia((valor - 1).clamp(minimo, 99)), activo: valor > minimo),
      SizedBox(
        width: tam * 1.0,
        child: Semantics(
          liveRegion: true,
          label: '$valor ${valor == 1 ? 'unidad' : 'unidades'}',
          child: ExcludeSemantics(
            child: Text('$valor', textAlign: TextAlign.center, style: T.titulo3.copyWith(fontSize: 22)),
          ),
        ),
      ),
      boton(LucideIcons.plus, 'Agregar una unidad${producto == null ? '' : ' de $producto'}', () => cambia((valor + 1).clamp(minimo, 99))),
    ]);
  }
}

/// Foto de producto: recorte transparente centrado sobre el color pastel de su categoría.
class FotoProducto extends StatelessWidget {
  const FotoProducto(this.p, {super.key, this.fondo, this.relleno = 4});
  final Producto p;

  /// Color de fondo; por defecto el pastel de la categoría (en tarjetas negras se pasa uno oscuro).
  final Color? fondo;
  final double relleno;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: fondo ?? p.fondo,
      padding: EdgeInsets.all(relleno),
      child: p.ruta == null
          ? Center(child: Icon(LucideIcons.package, size: 40, color: C.grisTexto))
          : Image.asset(p.ruta!,
              fit: BoxFit.contain,
              cacheWidth: 520,
              semanticLabel: p.nombre,
              errorBuilder: (_, __, ___) => Center(child: Icon(LucideIcons.package, size: 40, color: C.grisTexto))),
    );
  }
}

/// Ilustración de un estado (carrito vacío, compra exitosa, etc.) en una tarjeta redondeada.
/// El texto va aparte, como texto real, para que escale y lo lea el lector de pantalla.
class IlustracionEstado extends StatelessWidget {
  const IlustracionEstado(this.archivo, {super.key, this.ancho = 300});
  final String archivo;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: SizedBox(width: ancho, child: AspectRatio(aspectRatio: 600 / 340, child: Image.asset('assets/img/estados/$archivo', fit: BoxFit.cover))),
        ),
      ),
    );
  }
}

/// Precio con oferta: grande y legible; el descuento va en rojo (único uso del rojo).
class PrecioProducto extends StatelessWidget {
  const PrecioProducto(this.p, {super.key, this.grande = false, this.oscuro = false});
  final Producto p;
  final bool grande;
  final bool oscuro;

  @override
  Widget build(BuildContext context) {
    final base = oscuro ? Colors.white : C.tinta;
    final etiqueta = p.enOferta ? '${p.precioFinal} pesos, antes ${p.precio} pesos' : '${p.precioFinal} pesos';
    return Semantics(
      label: etiqueta,
      excludeSemantics: true,
      child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 8,
      children: [
        Text(clp(p.precioFinal), style: T.precio.copyWith(fontSize: grande ? 32 : 21, color: base)),
        if (p.enOferta)
          Text(clp(p.precio),
              style: T.apoyo.copyWith(
                  fontSize: grande ? 18 : 15,
                  decoration: TextDecoration.lineThrough,
                  color: oscuro ? C.verdePalido : C.grisTexto)),
      ],
    ));
  }
}

/// Tarjeta de producto de la grilla / carruseles.
class TarjetaProducto extends StatelessWidget {
  const TarjetaProducto(this.p, {super.key, required this.abrir});
  final Producto p;
  final VoidCallback abrir;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        final enCarro = estado.carrito[p.id] ?? 0;
        return Container(
          decoration: BoxDecoration(
            color: C.superficie,
            borderRadius: BorderRadius.circular(20),
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
                              padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
                              decoration: const BoxDecoration(
                                  color: C.rojo,
                                  borderRadius: BorderRadius.horizontal(right: Radius.circular(10))),
                              child: Text('-${p.descuento}%', style: T.etiqueta.copyWith(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                            )),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.nombre,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: T.cuerpo.copyWith(fontSize: 16, height: 1.25, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      PrecioProducto(p),
                    ]),
                  ),
                ]),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                child: p.agotado
                    ? Boton('Agotado por ahora', etiqueta: '${p.nombre}, agotado por ahora', estilo: EstiloBoton.suave, alto: 50, onTap: null)
                    : enCarro == 0
                    ? Boton('Agregar',
                        etiqueta: 'Agregar ${p.nombre} al carrito',
                        icono: LucideIcons.plus,
                        estilo: EstiloBoton.suave,
                        alto: 50,
                        onTap: () {
                          estado.agregar(p);
                          avisoAgregado(context, p);
                        })
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Cantidad(valor: enCarro, tam: 48, producto: p.nombre, cambia: (v) => v <= 0 ? quitarConDeshacer(context, p) : estado.cambiarCantidad(p, v)),
                      ]),
              ),
            ],
          ),
        );
      },
    );
  }
}

void _aviso(BuildContext context, String texto,
    {String? accion, VoidCallback? alAccion, int segundos = 6, IconData icono = LucideIcons.circleCheck}) {
  final m = ScaffoldMessenger.maybeOf(context);
  m?.hideCurrentSnackBar();
  m?.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: C.verdeFondo,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    duration: Duration(seconds: segundos),
    content: Row(children: [
      Icon(icono, color: C.verdeMenta, size: 24),
      const SizedBox(width: 12),
      Expanded(child: Text(texto, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.cuerpo.copyWith(color: Colors.white, fontSize: 16))),
    ]),
    action: accion == null ? null : SnackBarAction(label: accion, textColor: C.verdeMenta, onPressed: alAccion ?? () {}),
  ));
}

void avisoAgregado(BuildContext context, Producto p) {
  _aviso(context, 'Agregaste ${p.nombre}', accion: 'Ver carrito', alAccion: () {
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

/// Dos columnas de altura pareja, sin alturas fijas (aguantan letra grande).
class GrillaProductos extends StatelessWidget {
  const GrillaProductos(this.productos, {super.key, required this.abrir});
  final List<Producto> productos;
  final void Function(Producto) abrir;

  @override
  Widget build(BuildContext context) {
    final filas = <Widget>[];
    for (var i = 0; i < productos.length; i += 2) {
      final a = productos[i];
      final b = i + 1 < productos.length ? productos[i + 1] : null;
      filas.add(Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: TarjetaProducto(a, abrir: () => abrir(a))),
            const SizedBox(width: 14),
            Expanded(child: b == null ? const SizedBox() : TarjetaProducto(b, abrir: () => abrir(b))),
          ]),
        ),
      ));
    }
    return Column(children: filas);
  }
}

class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key, this.accion, this.alAccion, this.oscuro = false});
  final String texto;
  final String? accion;
  final VoidCallback? alAccion;
  final bool oscuro;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(texto, style: T.titulo2.copyWith(color: oscuro ? Colors.white : C.tinta)),
          ),
        ),
        if (accion != null)
          Tocable(
            etiqueta: accion,
            onTap: alAccion,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(children: [
                Text(accion!, style: T.cuerpoFuerte.copyWith(color: oscuro ? C.oro : C.azulEnlace, fontSize: 16)),
                Icon(LucideIcons.chevronRight, size: 20, color: oscuro ? C.oro : C.azulEnlace),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// Campo de texto con etiqueta visible arriba (nunca solo placeholder).
class Campo extends StatefulWidget {
  const Campo(this.etiqueta,
      {super.key,
      this.controlador,
      this.error,
      this.ayuda,
      this.clave = false,
      this.teclado,
      this.icono,
      this.alCambiar,
      this.valorInicial,
      this.accion = TextInputAction.next,
      this.autofill,
      this.mayusculas = TextCapitalization.none});
  final String etiqueta;
  final TextEditingController? controlador;
  final String? error;
  final String? ayuda;
  final bool clave;
  final TextInputType? teclado;
  final IconData? icono;
  final ValueChanged<String>? alCambiar;
  final String? valorInicial;
  final TextInputAction accion;
  final Iterable<String>? autofill;
  final TextCapitalization mayusculas;

  @override
  State<Campo> createState() => _CampoState();
}

class _CampoState extends State<Campo> {
  bool _ver = false;

  @override
  Widget build(BuildContext context) {
    final hayError = widget.error != null;
    OutlineInputBorder borde(Color c, double w) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.etiqueta, style: T.cuerpoFuerte.copyWith(fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controlador,
          initialValue: widget.controlador == null ? widget.valorInicial : null,
          obscureText: widget.clave && !_ver,
          keyboardType: widget.teclado,
          textInputAction: widget.accion,
          autofillHints: widget.autofill,
          textCapitalization: widget.mayusculas,
          enableSuggestions: !widget.clave,
          autocorrect: !widget.clave,
          onChanged: widget.alCambiar,
          style: T.cuerpo.copyWith(fontSize: 18),
          cursorColor: C.verde,
          decoration: InputDecoration(
            filled: true,
            fillColor: C.superficie,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            prefixIcon: widget.icono == null ? null : Icon(widget.icono, size: 22, color: C.grisTexto),
            suffixIcon: widget.clave
                ? Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Tocable(
                        etiqueta: _ver ? 'Ocultar contraseña' : 'Mostrar contraseña',
                        onTap: () => setState(() => _ver = !_ver),
                        child: SizedBox(
                            width: 52,
                            child: Icon(_ver ? LucideIcons.eyeOff : LucideIcons.eye, color: C.grisMedio, size: 22))),
                  )
                : null,
            enabledBorder: borde(hayError ? C.error : C.bordeControl, hayError ? 2 : 1.5),
            focusedBorder: borde(hayError ? C.error : C.verde, 2.5),
            border: borde(C.bordeControl, 1.5),
          ),
        ),
        if (hayError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: EdgeInsets.only(top: 2), child: Icon(LucideIcons.circleAlert, size: 18, color: C.error)),
              const SizedBox(width: 6),
              Expanded(child: Text(widget.error!, style: T.apoyo.copyWith(color: C.error, fontWeight: FontWeight.w600))),
            ]),
          )
        else if (widget.ayuda != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(widget.ayuda!, style: T.apoyo)),
      ],
    );
  }
}

/// Barra de progreso hacia despacho gratis.
class BarraDespacho extends StatelessWidget {
  const BarraDespacho({super.key, this.compacta = false});
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        final lograda = estado.despachoGratis;
        final fraccion = (estado.subtotal / despachoGratisDesde).clamp(0.0, 1.0);
        final vacio = estado.subtotal == 0;
        return Container(
          padding: EdgeInsets.all(compacta ? 14 : 16),
          decoration: BoxDecoration(color: C.verdeSuave, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(LucideIcons.truck, color: C.verdeOscuro, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lograda
                      ? '¡Tu despacho es gratis!'
                      : vacio
                          ? 'Despacho gratis desde ${clp(despachoGratisDesde)}'
                          : 'Te faltan ${clp(estado.faltaParaGratis)} para el despacho gratis',
                  style: T.cuerpoFuerte.copyWith(color: C.verdeProfundo, fontSize: 16),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: fraccion),
                duration: dur(context, 500),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(
                    value: v, minHeight: 12, backgroundColor: C.superficie, color: C.verde),
              ),
            ),
          ]),
        );
      },
    );
  }
}

/// Separador visual de pantallas: tarjeta plana blanca con borde.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.fondo, this.borde});
  final Widget child;
  final EdgeInsets padding;
  final Color? fondo;
  final Color? borde;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(color: fondo ?? C.superficie, borderRadius: BorderRadius.circular(20), border: Border.all(color: borde ?? C.borde)),
        child: child,
      );
}

void irA(BuildContext context, Widget pantalla) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
}

/// Resumen de errores al enviar un formulario: se lee solo (liveRegion) y se muestra arriba,
/// para que quien toca el botón de abajo vea de inmediato qué falta.
class ResumenErrores extends StatelessWidget {
  const ResumenErrores(this.mensajes, {super.key});
  final List<String> mensajes;

  @override
  Widget build(BuildContext context) {
    if (mensajes.isEmpty) return const SizedBox.shrink();
    final n = mensajes.length;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: C.error.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: C.error, width: 2),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(LucideIcons.circleAlert, color: C.error, size: 24),
            const SizedBox(width: 10),
            Expanded(child: Text(n == 1 ? 'Falta 1 dato para continuar' : 'Faltan $n datos para continuar', style: T.cuerpoFuerte.copyWith(color: C.error))),
          ]),
          const SizedBox(height: 8),
          for (final m in mensajes)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 34),
              child: Text(m, style: T.cuerpo.copyWith(fontSize: 16)),
            ),
        ]),
      ),
    );
  }
}

/// Fila deslizable cuyo alto lo decide el contenido: al agrandar la letra las tarjetas crecen
/// en vez de recortarse. Reemplaza a las listas horizontales de alto fijo.
class FilaHorizontal extends StatelessWidget {
  const FilaHorizontal({super.key, required this.hijos, this.separacion = 14});
  final List<Widget> hijos;
  final double separacion;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < hijos.length; i++) ...[if (i > 0) SizedBox(width: separacion), hijos[i]],
        ]),
      ),
    );
  }
}

/// Opción de una lista de elección única: fila completa, con espacio para letra grande.
class OpcionFila extends StatelessWidget {
  const OpcionFila({super.key, required this.texto, required this.activo, required this.alTocar, this.icono, this.muestra, this.detalle});
  final String texto;
  final String? detalle;
  final bool activo;
  final VoidCallback alTocar;
  final IconData? icono;

  /// Tamaño de una "Aa" de ejemplo (para elegir tamaño de letra).
  final double? muestra;

  @override
  Widget build(BuildContext context) {
    final color = activo ? Colors.white : C.tinta;
    return Tocable(
      etiqueta: '$texto${detalle == null ? '' : ', $detalle'}${activo ? ', elegido' : ''}',
      onTap: alTocar,
      child: AnimatedContainer(
        duration: dur(context, 160),
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: activo ? C.verde : C.superficie,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: activo ? C.verde : C.bordeControl, width: 1.5),
        ),
        child: Row(children: [
          SizedBox(
            width: 52,
            child: Center(
              child: muestra != null
                  ? FittedBox(fit: BoxFit.scaleDown, child: Text('Aa', maxLines: 1, style: T.titulo3.copyWith(fontSize: muestra, color: color, height: 1)))
                  : Icon(icono, size: 24, color: color),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(texto, style: T.cuerpoFuerte.copyWith(color: color, fontSize: 17)),
              if (detalle != null) Text(detalle!, style: T.apoyo.copyWith(color: activo ? Colors.white.withValues(alpha: .9) : C.grisTexto)),
            ]),
          ),
          if (activo) const Icon(LucideIcons.check, size: 24, color: Colors.white),
        ]),
      ),
    );
  }
}
