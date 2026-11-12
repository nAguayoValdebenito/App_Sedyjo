import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/componentes.dart';
import 'direccion.dart' show mostrarContacto;

/// Abre la ruta hacia la tienda en Google Maps o Waze (la aplicación, si está instalada; si no, el navegador).
Future<bool> abrirMapa({required bool waze}) async {
  final uri = waze
      ? Uri.parse('https://waze.com/ul?ll=${tienda.latitud},${tienda.longitud}&navigate=yes')
      : Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${tienda.latitud},${tienda.longitud}&travelmode=driving');
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Hoja para elegir con qué aplicación llegar. Explica qué va a pasar antes de abrir nada.
void mostrarComoLlegar(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Esp.x6, Esp.x6, Esp.x6, Esp.x5),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('¿Cómo quieres llegar?', style: T.titulo2),
          const SizedBox(height: Esp.x2),
          Text(tienda.direccionCompleta, style: T.cuerpo.copyWith(color: C.grisMedio)),
          const SizedBox(height: Esp.x5),
          for (final waze in [false, true]) ...[
            Boton(waze ? 'Abrir en Waze' : 'Abrir en Google Maps', icono: waze ? LucideIcons.navigation : LucideIcons.map, estilo: waze ? EstiloBoton.contorno : EstiloBoton.primario, onTap: () async {
              Navigator.pop(ctx);
              final abrio = await abrirMapa(waze: waze);
              // Si el aparato no puede abrirlo, se dice la dirección en vez de fingir que se abrió.
              if (!abrio && context.mounted) {
                avisoGeneral(context, 'No pudimos abrir ${waze ? 'Waze' : 'Google Maps'}. Estamos en ${tienda.direccionCompleta}.');
              }
            }),
            const SizedBox(height: Esp.x3),
          ],
          Boton('Cancelar', estilo: EstiloBoton.suave, onTap: () => Navigator.pop(ctx)),
        ]),
      ),
    ),
  );
}

/// Tarjeta con la dirección de la tienda y el botón "Cómo llegar". Se usa en el pago, el detalle del pedido y la ayuda.
class TarjetaTienda extends StatelessWidget {
  const TarjetaTienda({super.key, this.mostrarBoton = true});
  final bool mostrarBoton;

  @override
  Widget build(BuildContext context) {
    return Panel(
      fondo: C.verdeSuave,
      borde: C.verde,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(LucideIcons.store, size: Ico.m, color: C.verdeOscuro),
          const SizedBox(width: Esp.x3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tienda.nombre, style: T.cuerpoFuerte.copyWith(color: C.verdeProfundo)),
              Text(tienda.direccionCompleta, style: T.cuerpoM.copyWith(color: C.verdeProfundo)),
              const SizedBox(height: 2),
              Text(tienda.horarioCorto, style: T.apoyo.copyWith(color: C.verdeOscuro)),
            ]),
          ),
        ]),
        if (mostrarBoton) ...[
          const SizedBox(height: Esp.x3),
          Boton('Cómo llegar', estilo: EstiloBoton.contorno, icono: LucideIcons.navigation, alto: 52, onTap: () => mostrarComoLlegar(context)),
        ],
      ]),
    );
  }
}

/// Todo sobre retirar en tienda: dónde queda, horario, plazo y cómo llegar.
class TiendaPantalla extends StatelessWidget {
  const TiendaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const BarraSuperior('Retiro en tienda'),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x1, Esp.x5, Esp.x6), children: [
              const TarjetaTienda(mostrarBoton: false),
              const SizedBox(height: Esp.x4),
              Panel(
                child: Column(children: [
                  _Dato(LucideIcons.clock, 'Horario de atención', tienda.horario),
                  const Divider(height: 24),
                  _Dato(LucideIcons.packageCheck, 'Cuándo está listo', '${tienda.plazo}. Te avisamos cuando puedas pasar.'),
                  const Divider(height: 24),
                  _Dato(LucideIcons.mapPin, 'Cómo reconocerlo', tienda.referencia),
                  const Divider(height: 24),
                  _Dato(LucideIcons.idCard, 'Qué llevar', 'El número de tu pedido y tu cédula de identidad.'),
                ]),
              ),
              const SizedBox(height: Esp.x5),
              Boton('Cómo llegar', icono: LucideIcons.navigation, onTap: () => mostrarComoLlegar(context)),
              const SizedBox(height: Esp.x3),
              Boton('Llamar al local', estilo: EstiloBoton.contorno, icono: LucideIcons.phone, onTap: () => mostrarContacto(context)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.icono, this.titulo, this.texto);
  final IconData icono;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icono, size: Ico.m, color: C.verdeOscuro),
      const SizedBox(width: Esp.x3),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: T.cuerpoFuerte),
          Text(texto, style: T.apoyo),
        ]),
      ),
    ]);
  }
}
