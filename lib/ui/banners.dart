import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../pantallas/auth.dart';
import '../pantallas/direccion.dart';
import '../pantallas/shell.dart';
import '../pantallas/tienda.dart';
import 'componentes.dart';

/// Banner de campaña sobre negro: título en dorado o morado, texto real (nunca dentro de la imagen).
/// El dorado y el morado viven solo sobre fondo negro, igual que en la web.
class BannerPromo extends StatelessWidget {
  const BannerPromo({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.imagen,
    required this.alTocar,
    this.acento = C.oro,
    this.boton = 'Ver oferta',
    this.precio,
    this.descuento,
    this.etiqueta,
    this.ancho = 330,
  });

  final String titulo;
  final String subtitulo;
  final String imagen;
  final VoidCallback alTocar;
  final Color acento;
  final String boton;
  final String? precio;
  final int? descuento;
  final String? etiqueta;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    return Tocable(
      etiqueta: etiqueta ?? '$titulo. $subtitulo${precio == null ? '' : '. $precio'}. $boton',
      onTap: alTocar,
      child: Container(
        width: ancho,
        constraints: const BoxConstraints(minHeight: 178),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          // Negro con un resplandor del color de la campaña detrás del producto
          gradient: RadialGradient(
            center: const Alignment(.8, 0),
            radius: .9,
            colors: [Color.alphaBlend(acento.withValues(alpha: .28), C.negro), C.negro],
          ),
          borderRadius: BorderRadius.circular(R.l),
          border: Border.all(color: acento.withValues(alpha: .55), width: 1.5),
        ),
        // Texto a la izquierda y producto a la derecha en una fila: el alto lo decide el texto,
        // así la tarjeta crece con la letra en vez de recortarse.
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Esp.x4, Esp.x4, Esp.x1, Esp.x4),
              child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titulo, style: T.titulo3.copyWith(color: acento, fontSize: 22, height: 1.1)),
                const SizedBox(height: Esp.x1),
                Text(subtitulo, style: T.apoyo.copyWith(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                if (precio != null) ...[
                  const SizedBox(height: Esp.x2),
                  Text(precio!, style: T.precio.copyWith(color: Colors.white, fontSize: 20)),
                  if (descuento != null) Padding(padding: const EdgeInsets.only(top: Esp.x1), child: Insignia('-$descuento%')),
                ],
                const SizedBox(height: Esp.x3),
                Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: Esp.x3, vertical: Esp.x2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: acento, borderRadius: BorderRadius.circular(R.s)),
                  child: Text(boton, textAlign: TextAlign.center, style: T.boton.copyWith(color: C.negro, fontSize: 16)),
                ),
              ]),
            ),
          ),
          SizedBox(
            width: 124,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, Esp.x2, Esp.x2, Esp.x2),
              child: Image.asset(imagen, fit: BoxFit.contain, alignment: Alignment.center, cacheWidth: 360, semanticLabel: ''),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Fila deslizable de banners. No cambia sola: quien quiere mirar, mira.
class TiraPromos extends StatelessWidget {
  const TiraPromos({super.key, required this.banners});
  final List<BannerPromo> banners;

  @override
  Widget build(BuildContext context) => FilaHorizontal(hijos: banners);
}

/// "Ideas para tu mesa": inspiración con foto grande que lleva a una categoría real.
class IdeaMesa extends StatelessWidget {
  const IdeaMesa({super.key, required this.titulo, required this.sub, required this.imagen, required this.fondo, required this.alTocar});
  final String titulo;
  final String sub;
  final String imagen;
  final Color fondo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Tocable(
      etiqueta: '$titulo. $sub',
      onTap: alTocar,
      child: Container(
        width: 210,
        decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(R.l)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.x3, Esp.x3, Esp.x3, 0),
            child: AspectRatio(aspectRatio: 1.45, child: Image.asset(imagen, fit: BoxFit.contain, cacheWidth: 520, semanticLabel: '')),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.x3, Esp.x2, Esp.x3, Esp.x3),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(titulo, style: T.cuerpoFuerte.copyWith(fontSize: 18)),
                  Text(sub, style: T.apoyo.copyWith(color: C.grisMedio), maxLines: 2),
                ]),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: C.superficie, shape: BoxShape.circle),
                child: Icon(LucideIcons.chevronRight, size: Ico.m, color: C.verdeOscuro),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Estado vacío o de error con ilustración plana (versión clara u oscura según el modo).
class IconoEstado extends StatelessWidget {
  const IconoEstado(this.nombre, {super.key, this.lado = 180});
  final String nombre;
  final double lado;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ExcludeSemantics(
        child: Flota(child: Image.asset('assets/img/estados2/$nombre${C.oscuro ? '-oscuro' : ''}.webp', width: lado, height: lado, cacheWidth: 600, fit: BoxFit.contain)),
      ),
    );
  }
}

/// Pantalla de estado completa: ilustración, título, explicación y acciones abajo.
class PantallaEstado extends StatelessWidget {
  const PantallaEstado({super.key, required this.icono, required this.titulo, required this.texto, required this.acciones, this.atras = true});
  final String icono;
  final String titulo;
  final String texto;
  final List<Widget> acciones;
  final bool atras;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          if (atras) const BarraSuperior(''),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(Esp.x8, Esp.x6, Esp.x8, Esp.x4), children: [
              IconoEstado(icono, lado: 200),
              const SizedBox(height: Esp.x6),
              Semantics(header: true, child: Text(titulo, textAlign: TextAlign.center, style: T.titulo1)),
              const SizedBox(height: Esp.x3),
              Text(texto, textAlign: TextAlign.center, style: T.cuerpo.copyWith(color: C.grisMedio)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.x6, Esp.x2, Esp.x6, Esp.x5),
            child: Column(children: [for (var i = 0; i < acciones.length; i++) ...[if (i > 0) const SizedBox(height: Esp.x3), acciones[i]]]),
          ),
        ]),
      ),
    );
  }
}

class SinConexionPantalla extends StatelessWidget {
  const SinConexionPantalla({super.key});

  @override
  Widget build(BuildContext context) => PantallaEstado(
        icono: 'sin-conexion',
        titulo: 'Sin conexión a internet',
        texto: 'Revisa tu señal o el wifi. Tu carrito está guardado y no perderás nada.',
        acciones: [
          Boton('Intentar de nuevo', icono: LucideIcons.refreshCw, onTap: () => Navigator.of(context).maybePop()),
          Boton('Llamar a Sedyjo', estilo: EstiloBoton.contorno, icono: LucideIcons.phone, onTap: () => mostrarContacto(context)),
        ],
      );
}

class SesionExpiradaPantalla extends StatelessWidget {
  const SesionExpiradaPantalla({super.key});

  @override
  Widget build(BuildContext context) => PantallaEstado(
        icono: 'sesion-expirada',
        titulo: 'Tu sesión se cerró',
        texto: 'Por seguridad la cerramos después de un rato. Vuelve a ingresar y seguimos donde quedaste.',
        acciones: [
          Boton('Ingresar de nuevo', icono: LucideIcons.lockKeyhole, onTap: () {
            estado.cerrarSesion();
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const IngresarPantalla()));
          }),
          Boton('Seguir como invitado', estilo: EstiloBoton.suave, onTap: () {
            estado.cerrarSesion();
            estado.pestana = 0;
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const Shell()), (r) => false);
          }),
        ],
      );
}

class FueraDeZonaPantalla extends StatelessWidget {
  const FueraDeZonaPantalla({super.key, this.vieneDeElegir = false});

  /// Si se llegó desde la vista de dirección, "Elegir otra dirección" simplemente vuelve a ella.
  final bool vieneDeElegir;

  @override
  Widget build(BuildContext context) => PantallaEstado(
        icono: 'fuera-zona-despacho',
        titulo: 'Aún no llegamos a esa dirección',
        texto: 'No pudimos confirmar el despacho a esa dirección. Puedes elegir otra dirección, retirar tu compra en nuestra tienda o consultarnos por teléfono.',
        acciones: [
          Boton('Elegir otra dirección', icono: LucideIcons.mapPin, onTap: () {
            if (vieneDeElegir) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ElegirDireccionPantalla()));
            }
          }),
          Boton('Retirar en nuestra tienda', estilo: EstiloBoton.suave, icono: LucideIcons.store, onTap: () => irA(context, const TiendaPantalla())),
          Boton('Consultar por teléfono', estilo: EstiloBoton.contorno, icono: LucideIcons.phone, onTap: () => mostrarContacto(context)),
        ],
      );
}
