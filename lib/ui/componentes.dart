import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../pantallas/carrito.dart' show CarritoPestana;
import '../pantallas/producto.dart';
import 'boton_favorito.dart';
import 'movimiento.dart';
import 'revelar.dart';
import 'vuelo_carrito.dart';

// `dur`, `sinMovimiento`, la vibración y las animaciones de apoyo viven en movimiento.dart;
// se reexportan aquí para que las pantallas sigan importando solo este archivo.
export 'movimiento.dart';
export 'revelar.dart';
export 'vuelo_carrito.dart';

part 'componentes_producto.dart';
part 'componentes_formularios.dart';

/// Cualquier cosa tocable: ondulación de Material encima del contenido, se hunde un poco al presionar,
/// se puede enfocar con teclado o control (anillo azul) y expone semántica de botón.
class Tocable extends StatefulWidget {
  const Tocable({super.key, required this.child, this.onTap, this.etiqueta, this.radio = R.m});
  final Widget child;
  final VoidCallback? onTap;
  final String? etiqueta;
  final double radio;

  @override
  State<Tocable> createState() => _TocableState();
}

class _TocableState extends State<Tocable> {
  bool _abajo = false;
  bool _foco = false;

  @override
  Widget build(BuildContext context) {
    final forma = BorderRadius.circular(widget.radio);
    return Semantics(
      button: true,
      label: widget.etiqueta,
      enabled: widget.onTap != null,
      onTap: widget.onTap,
      // Con etiqueta explícita, el lector no repite el texto interno ("Agregar, Agregar").
      excludeSemantics: widget.etiqueta != null,
      child: AnimatedScale(
        scale: _abajo && !sinMovimiento(context) ? .97 : 1,
        duration: Mov.toque,
        curve: Mov.entra,
        child: Stack(fit: StackFit.passthrough, children: [
          widget.child,
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: forma,
                onTap: widget.onTap,
                excludeFromSemantics: true,
                onHighlightChanged: (v) => setState(() => _abajo = v),
                onFocusChange: (v) => setState(() => _foco = v),
                splashColor: C.verde.withValues(alpha: .14),
                highlightColor: Colors.transparent,
                hoverColor: C.verde.withValues(alpha: .06),
                focusColor: C.azulEnlace.withValues(alpha: .10),
              ),
            ),
          ),
          if (_foco)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(decoration: BoxDecoration(borderRadius: forma, border: Border.all(color: C.azulEnlace, width: 3))),
              ),
            ),
        ]),
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
      this.etiqueta,
      this.alTocarEn});
  final String texto;
  final VoidCallback? onTap;
  final IconData? icono;
  final EstiloBoton estilo;
  final double alto;
  final bool expandido;
  final bool iconoDerecha;
  final String? etiqueta;

  /// Alternativa a [onTap] cuando la acción necesita el contexto del propio botón (por ejemplo, para que una burbuja salga de él).
  final void Function(BuildContext contexto)? alTocarEn;

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
      if (icono != null && !iconoDerecha) ...[Icon(icono, size: Ico.m, color: color), const SizedBox(width: Esp.x3)],
      // Una sola palabra se achica para caber (nunca se parte a la mitad); una frase se reparte en líneas.
      Flexible(
        child: texto.contains(' ')
            ? Text(texto, textAlign: TextAlign.center, style: T.boton.copyWith(color: color, fontSize: 18))
            : FittedBox(fit: BoxFit.scaleDown, child: Text(texto, maxLines: 1, style: T.boton.copyWith(color: color, fontSize: 18))),
      ),
      if (icono != null && iconoDerecha) ...[const SizedBox(width: Esp.x3), Icon(icono, size: Ico.m, color: color)],
    ];
    final activo = onTap != null || alTocarEn != null;
    return Tocable(
      etiqueta: etiqueta ?? texto,
      onTap: !activo ? null : () => alTocarEn != null ? alTocarEn!(context) : onTap!(),
      child: Opacity(
        opacity: !activo ? .5 : 1,
        child: Container(
          constraints: BoxConstraints(minHeight: alto),
          width: expandido ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: Esp.x3, vertical: Esp.x3),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(R.m),
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
      padding: const EdgeInsets.fromLTRB(Esp.x4, Esp.x2, Esp.x4, Esp.x2),
      child: Row(
        children: [
          if (atras) ...[
            BotonIcono(LucideIcons.arrowLeft, 'Volver', onTap: () => Navigator.of(context).maybePop()),
            const SizedBox(width: Esp.x3),
          ],
          Expanded(child: Semantics(header: true, child: Text(titulo, style: T.titulo2, maxLines: 2))),
          ?accion,
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
      padding: const EdgeInsets.symmetric(horizontal: Esp.x3, vertical: 5),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(R.s)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icono != null) ...[Icon(icono, size: 15, color: color), const SizedBox(width: 5)],
        Text(texto, style: T.etiqueta.copyWith(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

/// Selector de cantidad con botones de 52 dp.
class Cantidad extends StatelessWidget {
  const Cantidad({super.key, required this.valor, required this.cambia, this.tam = 52, this.minimo = 0, this.producto, this.vuela = false, this.oscuro = false});
  final int valor;
  final String? producto;
  final ValueChanged<int> cambia;
  final double tam;
  final int minimo;

  /// Si el "+" agrega al carrito de verdad, una burbuja sale de él hacia el carrito (no en el selector de la ficha, que aún no agrega).
  final bool vuela;
  final bool oscuro;

  @override
  Widget build(BuildContext context) {
    // Jerarquía: solo el "+" es verde sólido (es la acción que se repite); el "−" es de contorno.
    // Deshabilitado se ve gris con contorno suave: se entiende que no se puede, pero se lee.
    Widget boton(IconData i, String et, void Function(BuildContext) f, {bool activo = true, bool principal = false}) => Builder(
        builder: (ctx) => Tocable(
          etiqueta: activo ? et : '$et, no disponible',
          onTap: activo ? () => f(ctx) : null,
          child: Container(
            width: tam,
            height: tam,
            decoration: BoxDecoration(
              color: principal && activo ? C.verde : Colors.transparent,
              borderRadius: BorderRadius.circular(R.s),
              border: Border.all(color: principal && activo ? C.verde : (activo ? C.bordeControl : C.borde), width: 1.5),
            ),
            child: Icon(i, size: Ico.m, color: principal && activo ? Colors.white : (activo ? C.tinta : C.grisTexto.withValues(alpha: .7))),
          ),
        ));
    return Row(mainAxisSize: MainAxisSize.min, children: [
      boton(LucideIcons.minus, 'Quitar una unidad${producto == null ? '' : ' de $producto'}', (_) => cambia((valor - 1).clamp(minimo, 99)), activo: valor > minimo),
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
      boton(LucideIcons.plus, 'Agregar una unidad${producto == null ? '' : ' de $producto'}', (ctx) {
        vibracionLeve();
        cambia((valor + 1).clamp(minimo, 99));
        if (vuela) volarAlCarrito(ctx, oscuro: oscuro);
      }, principal: true),
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
              // Aparece con un fundido corto sobre el color de su categoría (con red real, al llegar la foto).
              frameBuilder: (ctx, hijo, cuadro, sincrona) => sincrona
                  ? hijo
                  : AnimatedOpacity(opacity: cuadro == null ? 0 : 1, duration: dur(ctx, 180), curve: Mov.entra, child: hijo),
              errorBuilder: (_, _, _) => Center(child: Icon(LucideIcons.package, size: 40, color: C.grisTexto))),
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
        child: Flota(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(R.l),
            child: SizedBox(width: ancho, child: AspectRatio(aspectRatio: 600 / 340, child: Image.asset('assets/img/estados/$archivo', fit: BoxFit.cover, cacheWidth: 700))),
          ),
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

class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key, this.accion, this.alAccion, this.oscuro = false});
  final String texto;
  final String? accion;
  final VoidCallback? alAccion;
  final bool oscuro;

  @override
  Widget build(BuildContext context) {
    return Revelar(
      child: Padding(
      padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x8, Esp.x5, Esp.x3),
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
              padding: const EdgeInsets.symmetric(vertical: Esp.x3, horizontal: Esp.x1),
              child: Row(children: [
                Text(accion!, style: T.cuerpoFuerte.copyWith(color: oscuro ? C.oro : C.azulEnlace, fontSize: 16)),
                Icon(LucideIcons.chevronRight, size: Ico.s, color: oscuro ? C.oro : C.azulEnlace),
              ]),
            ),
          ),
      ]),
    ));
  }
}

/// Barra de progreso hacia despacho gratis. Al lograrlo, el camión se vuelve una marca, la barra late una vez
/// y vibra (solo si la pestaña se está viendo). La versión compacta ocupa una línea: es la del inicio.
class BarraDespacho extends StatefulWidget {
  const BarraDespacho({super.key, this.compacta = false});
  final bool compacta;

  @override
  State<BarraDespacho> createState() => _BarraDespachoState();
}

class _BarraDespachoState extends State<BarraDespacho> with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(vsync: this, duration: Mov.enfasis);
  late final Animation<double> _escala = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.035).chain(CurveTween(curve: Mov.entra)), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.035, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 60),
  ]).animate(_pulso);
  late bool _antes = estado.despachoGratis;

  @override
  void initState() {
    super.initState();
    estado.addListener(_alCambiar);
  }

  void _alCambiar() {
    final ahora = estado.despachoGratis;
    if (ahora && !_antes && mounted && TickerMode.valuesOf(context).enabled && !sinMovimiento(context)) {
      _pulso.forward(from: 0);
      vibracionLogro();
    }
    _antes = ahora;
  }

  @override
  void dispose() {
    estado.removeListener(_alCambiar);
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        final lograda = estado.despachoGratis;
        final fraccion = (estado.subtotal / despachoGratisDesde).clamp(0.0, 1.0);
        final vacio = estado.subtotal == 0;
        final compacta = widget.compacta;
        final texto = lograda
            ? '¡Tu despacho es gratis!'
            : vacio
                ? 'Despacho gratis desde ${clp(despachoGratisDesde)}'
                : 'Te faltan ${clp(estado.faltaParaGratis)} para el despacho gratis';
        return ScaleTransition(
          scale: _escala,
          child: Container(
            padding: compacta ? const EdgeInsets.fromLTRB(Esp.x3, Esp.x3, Esp.x3, Esp.x3) : const EdgeInsets.all(Esp.x4),
            decoration: BoxDecoration(color: C.verdeSuave, borderRadius: BorderRadius.circular(compacta ? R.m : R.l)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                AnimatedSwitcher(
                  duration: dur(context, 200),
                  transitionBuilder: (h, a) => ScaleTransition(scale: a, child: h),
                  child: Icon(lograda ? LucideIcons.circleCheck : LucideIcons.truck, key: ValueKey(lograda), color: C.verdeOscuro, size: compacta ? 22 : 24),
                ),
                const SizedBox(width: Esp.x3),
                Expanded(child: Text(texto, style: (compacta ? T.cuerpoMFuerte.copyWith(fontSize: 15) : T.cuerpoMFuerte).copyWith(color: C.verdeProfundo))),
              ]),
              SizedBox(height: compacta ? 8 : 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(R.s),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: fraccion),
                  duration: dur(context, 500),
                  curve: Mov.entra,
                  builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: compacta ? 8 : 12, backgroundColor: C.superficie, color: C.verde),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

/// Separador visual de pantallas: tarjeta plana blanca con borde.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(Esp.x4), this.fondo, this.borde});
  final Widget child;
  final EdgeInsets padding;
  final Color? fondo;
  final Color? borde;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(color: fondo ?? C.superficie, borderRadius: BorderRadius.circular(R.l), border: Border.all(color: borde ?? C.borde)),
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
        margin: const EdgeInsets.only(bottom: Esp.x5),
        padding: const EdgeInsets.all(Esp.x4),
        decoration: BoxDecoration(
          color: C.error.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(R.m),
          border: Border.all(color: C.error, width: 2),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(LucideIcons.circleAlert, color: C.error, size: Ico.m),
            const SizedBox(width: Esp.x3),
            Expanded(child: Text(n == 1 ? 'Falta 1 dato para continuar' : 'Faltan $n datos para continuar', style: T.cuerpoFuerte.copyWith(color: C.error))),
          ]),
          const SizedBox(height: Esp.x2),
          for (final m in mensajes)
            Padding(
              padding: const EdgeInsets.only(top: Esp.x1, left: 34),
              child: Text(m, style: T.cuerpoM),
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
      padding: const EdgeInsets.symmetric(horizontal: Esp.x5),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < hijos.length; i++) ...[if (i > 0) SizedBox(width: separacion), Revelar(indice: i, child: hijos[i])],
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
        padding: const EdgeInsets.symmetric(horizontal: Esp.x4, vertical: Esp.x3),
        decoration: BoxDecoration(
          color: activo ? C.verde : C.superficie,
          borderRadius: BorderRadius.circular(R.m),
          border: Border.all(color: activo ? C.verde : C.bordeControl, width: 1.5),
        ),
        child: Row(children: [
          SizedBox(
            width: 52,
            child: Center(
              child: muestra != null
                  ? FittedBox(fit: BoxFit.scaleDown, child: Text('Aa', maxLines: 1, style: T.titulo3.copyWith(fontSize: muestra, color: color, height: 1)))
                  : Icon(icono, size: Ico.m, color: color),
            ),
          ),
          const SizedBox(width: Esp.x3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(texto, style: T.cuerpoFuerte.copyWith(color: color, fontSize: 17)),
              if (detalle != null) Text(detalle!, style: T.apoyo.copyWith(color: activo ? Colors.white.withValues(alpha: .9) : C.grisTexto)),
            ]),
          ),
          if (activo) const Icon(LucideIcons.check, size: Ico.m, color: Colors.white),
        ]),
      ),
    );
  }
}
