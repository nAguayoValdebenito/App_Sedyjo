import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import 'componentes.dart';

/// Colores del esqueleto: un gris apenas distinto del fondo, en claro y en oscuro.
Color _base(BuildContext c) => Color.alphaBlend(c.col.tinta.withValues(alpha: .08), c.col.fondo);
Color _brillo(BuildContext c) => Color.alphaBlend(c.col.tinta.withValues(alpha: .03), c.col.fondo);

/// Hace brillar todos los bloques [BloqueEsqueleto] de su interior con un solo reloj (barato aun con muchas tarjetas).
/// Con "reducir movimiento" los bloques quedan fijos, sin brillo.
class BrilloCarga extends StatefulWidget {
  const BrilloCarga({super.key, required this.child});
  final Widget child;

  @override
  State<BrilloCarga> createState() => _BrilloCargaState();
}

class _BrilloCargaState extends State<BrilloCarga> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    if (!sinMovimiento(context)) _ctl.repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = _base(context);
    final brillo = _brillo(context);
    return Semantics(
      label: 'Cargando productos',
      liveRegion: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ctl,
            child: widget.child,
            builder: (_, hijo) => ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (r) => LinearGradient(
                colors: [base, brillo, base],
                stops: const [.25, .5, .75],
                begin: const Alignment(-1, -.3),
                end: const Alignment(1, .3),
                transform: DeslizarDegradado(-1 + 2 * _ctl.value),
              ).createShader(r),
              child: hijo,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rectángulo gris del esqueleto. Debe ir dentro de [BrilloCarga].
class BloqueEsqueleto extends StatelessWidget {
  const BloqueEsqueleto({super.key, this.ancho, this.alto = 14, this.radio = 8});
  final double? ancho;
  final double alto;
  final double radio;

  @override
  Widget build(BuildContext context) => Container(
        width: ancho,
        height: alto,
        decoration: BoxDecoration(color: _base(context), borderRadius: BorderRadius.circular(radio)),
      );
}

/// Misma geometría que [TarjetaProducto]: foto 1,18:1, dos líneas de nombre, precio y botón. Así, al llegar los datos,
/// nada se mueve.
class EsqueletoProducto extends StatelessWidget {
  const EsqueletoProducto({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.col.superficie,
        borderRadius: BorderRadius.circular(R.l),
        border: Border.all(color: context.col.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AspectRatio(aspectRatio: 1.18, child: Container(color: _base(context))),
        const Padding(
          padding: EdgeInsets.fromLTRB(Esp.x3, Esp.x3, Esp.x3, Esp.x2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            BloqueEsqueleto(alto: 16),
            SizedBox(height: Esp.x2),
            BloqueEsqueleto(ancho: 96, alto: 16),
            SizedBox(height: Esp.x3),
            BloqueEsqueleto(ancho: 72, alto: 22),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(Esp.x3, Esp.x1, Esp.x3, Esp.x3),
          child: BloqueEsqueleto(alto: 50, radio: R.m),
        ),
      ]),
    );
  }
}

/// Esqueleto de una grilla de productos de `n` tarjetas, en las mismas columnas que la real.
class EsqueletoGrilla extends StatelessWidget {
  const EsqueletoGrilla({super.key, this.n = 4});
  final int n;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, caja) {
      final columnas = columnasProductos(caja.maxWidth);
      final filas = <Widget>[];
      for (var i = 0; i < n; i += columnas) {
        filas.add(Padding(
          padding: const EdgeInsets.only(bottom: Esp.x3),
          child: Row(children: [
            for (var k = 0; k < columnas; k++) ...[
              if (k > 0) const SizedBox(width: Esp.x3),
              const Expanded(child: EsqueletoProducto()),
            ],
          ]),
        ));
      }
      return BrilloCarga(child: Column(children: filas));
    });
  }
}

/// Esqueleto de una fila horizontal de tarjetas (carruseles de ofertas).
class EsqueletoFila extends StatelessWidget {
  const EsqueletoFila({super.key, this.n = 3});
  final int n;

  @override
  Widget build(BuildContext context) {
    return BrilloCarga(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: Esp.x5),
        child: Row(children: [
          for (var i = 0; i < n; i++) ...[
            if (i > 0) const SizedBox(width: Esp.x3),
            const SizedBox(width: 188, child: EsqueletoProducto()),
          ],
        ]),
      ),
    );
  }
}

/// Muestra esqueletos mientras llegan los datos por primera vez, el contenido cuando están, y un error con
/// reintento solo en esta sección si falla. Al refrescar con datos ya cargados, el contenido se queda donde está.
class SeccionCarga extends StatelessWidget {
  const SeccionCarga({super.key, required this.listo, required this.cargando, this.errorCompacto = false, this.ocultarEnError = false});
  final WidgetBuilder listo;
  final WidgetBuilder cargando;

  /// Para secciones secundarias: el error ocupa una sola línea en vez de un panel completo.
  final bool errorCompacto;

  /// Para secciones que no aportan nada sin datos: desaparecen si falla (el error ya se ve en otra parte).
  final bool ocultarEnError;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Carga>(
      valueListenable: Catalogo.carga,
      builder: (context, c, _) {
        final sinDatos = Catalogo.productos.isEmpty || Catalogo.forzarVacio;
        final Widget hijo;
        if (c == Carga.error) {
          hijo = ocultarEnError ? const SizedBox.shrink(key: ValueKey('oculto')) : ErrorSeccion(key: const ValueKey('error'), compacta: errorCompacto);
        } else if (c == Carga.cargando && sinDatos) {
          hijo = KeyedSubtree(key: const ValueKey('cargando'), child: cargando(context));
        } else {
          hijo = KeyedSubtree(key: const ValueKey('listo'), child: listo(context));
        }
        return AnimatedSwitcher(
          duration: dur(context, 220),
          switchInCurve: Mov.entra,
          switchOutCurve: Mov.sale,
          layoutBuilder: (actual, anteriores) => Stack(
            fit: StackFit.passthrough,
            alignment: Alignment.topCenter,
            children: [...anteriores.map((w) => Positioned(left: 0, right: 0, top: 0, child: w)), ?actual],
          ),
          child: hijo,
        );
      },
    );
  }
}

/// Error de una sección: se explica, se tranquiliza y se ofrece reintentar. El resto de la pantalla sigue usable.
class ErrorSeccion extends StatelessWidget {
  const ErrorSeccion({super.key, this.compacta = false});

  /// Una línea con "Reintentar", para secciones secundarias de una pantalla.
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    if (compacta) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Esp.x5, vertical: Esp.x1),
        child: Row(children: [
          Icon(LucideIcons.wifiOff, size: Ico.m, color: C.grisMedio),
          const SizedBox(width: Esp.x3),
          Expanded(child: Semantics(liveRegion: true, child: Text('No pudimos cargar esta sección', style: T.apoyo))),
          Tocable(
            etiqueta: 'Reintentar cargar esta sección',
            onTap: Catalogo.recargar,
            child: Padding(padding: const EdgeInsets.all(Esp.x3), child: Text('Reintentar', style: T.cuerpoMFuerte.copyWith(color: C.azulEnlace))),
          ),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Esp.x5, vertical: Esp.x2),
      child: Panel(
        padding: const EdgeInsets.all(Esp.x5),
        child: Column(children: [
          ExcludeSemantics(
            child: Image.asset('assets/img/estados2/sin-conexion${C.oscuro ? '-oscuro' : ''}.webp', width: 120, height: 120, cacheWidth: 240, fit: BoxFit.contain),
          ),
          const SizedBox(height: Esp.x3),
          Semantics(liveRegion: true, child: Text('No pudimos cargar los productos', textAlign: TextAlign.center, style: T.titulo3)),
          const SizedBox(height: Esp.x2),
          Text('Revisa tu conexión e inténtalo de nuevo. Tu carrito está guardado.', textAlign: TextAlign.center, style: T.apoyo),
          const SizedBox(height: Esp.x5),
          Boton('Reintentar', icono: LucideIcons.refreshCw, onTap: Catalogo.recargar),
        ]),
      ),
    );
  }
}

/// Jalar para actualizar con los colores de la marca. Si falla con datos ya cargados, avisa sin quitar nada.
class Refrescar extends StatelessWidget {
  const Refrescar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      color: C.verde,
      backgroundColor: C.superficie,
      onRefresh: () async {
        final ok = await Catalogo.recargar();
        if (!ok && context.mounted) {
          avisoGeneral(context, 'No pudimos actualizar. Revisa tu conexión.', accion: 'Reintentar', alAccion: Catalogo.recargar);
        }
      },
      child: child,
    );
  }
}
