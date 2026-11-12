import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/componentes.dart';

/// Vista para elegir o escribir la dirección de entrega. Devuelve la [Direccion] elegida.
class ElegirDireccionPantalla extends StatefulWidget {
  const ElegirDireccionPantalla({super.key, this.actual});
  final Direccion? actual;

  @override
  State<ElegirDireccionPantalla> createState() => _ElegirDireccionPantallaState();
}

class _ElegirDireccionPantallaState extends State<ElegirDireccionPantalla> {
  final _calle = TextEditingController();
  final _numero = TextEditingController();
  final _ref = TextEditingController();
  final _scroll = ScrollController();
  final _comuna = TextEditingController();
  bool _guardar = true;
  bool _intentado = false;

  @override
  void dispose() {
    for (final c in [_calle, _numero, _comuna, _ref]) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  List<String> get _faltan => !_intentado
      ? const []
      : [
          if (_calle.text.trim().isEmpty) 'El nombre de tu calle',
          if (_numero.text.trim().isEmpty) 'El número de tu casa o departamento',
          if (_comuna.text.trim().isEmpty) 'Tu comuna',
        ];

  void _usarNueva() {
    setState(() => _intentado = true);
    if (_calle.text.trim().isEmpty || _numero.text.trim().isEmpty || _comuna.text.trim().isEmpty) {
      if (_scroll.hasClients) _scroll.animateTo(0, duration: dur(context, 300), curve: Curves.easeOutCubic);
      return;
    }
    final d = Direccion('Dirección nueva', '${_calle.text.trim()} ${_numero.text.trim()}', _comuna.text.trim(), _ref.text.trim());
    if (estado.conSesion && _guardar) {
      estado.direcciones.add(d..alias = 'Nueva dirección');
      estado.refrescar();
    }
    Navigator.of(context).pop(d);
  }

  @override
  Widget build(BuildContext context) {
    final guardadas = estado.conSesion ? estado.direcciones : <Direccion>[];
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const BarraSuperior('Dirección de entrega'),
          Expanded(
            child: ListView(controller: _scroll, padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x1, Esp.x5, Esp.x6), children: [
              ResumenErrores(_faltan),
              if (guardadas.isNotEmpty) ...[
                Text('Tus direcciones guardadas', style: T.titulo3),
                const SizedBox(height: Esp.x3),
                for (final d in guardadas) ...[
                  Tocable(
                    etiqueta: '${d.alias}, ${d.calle}, ${d.comuna}. Usar esta dirección',
                    onTap: () => Navigator.of(context).pop(d),
                    child: Container(
                      padding: const EdgeInsets.all(Esp.x4),
                      decoration: BoxDecoration(
                        color: identical(d, widget.actual) ? C.verdeSuave : C.superficie,
                        borderRadius: BorderRadius.circular(R.l),
                        border: Border.all(color: identical(d, widget.actual) ? C.verde : C.borde, width: identical(d, widget.actual) ? 2 : 1.5),
                      ),
                      child: Row(children: [
                        Icon(LucideIcons.mapPin, size: Ico.m, color: C.verdeOscuro),
                        const SizedBox(width: Esp.x3),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(d.alias, style: T.cuerpoFuerte),
                            Text('${d.calle}, ${d.comuna}', style: T.apoyo),
                          ]),
                        ),
                        Icon(LucideIcons.chevronRight, color: C.grisMedio),
                      ]),
                    ),
                  ),
                  const SizedBox(height: Esp.x3),
                ],
                const SizedBox(height: Esp.x4),
              ],
              Text(guardadas.isEmpty ? 'Escribe tu dirección' : 'O entrega en otra dirección', style: T.titulo3),
              const SizedBox(height: Esp.x3),
              Campo('Calle', controlador: _calle, autofill: const [AutofillHints.streetAddressLine1], mayusculas: TextCapitalization.words, icono: LucideIcons.mapPin, error: _intentado && _calle.text.trim().isEmpty ? 'Escribe el nombre de tu calle.' : null, alCambiar: (_) => setState(() {})),
              const SizedBox(height: Esp.x4),
              Campo('Número o departamento', controlador: _numero, autofill: const [AutofillHints.streetAddressLine2], error: _intentado && _numero.text.trim().isEmpty ? 'Escribe el número de tu casa o depto.' : null, alCambiar: (_) => setState(() {})),
              const SizedBox(height: Esp.x4),
              Campo('Comuna', controlador: _comuna, mayusculas: TextCapitalization.words, icono: LucideIcons.map, error: _intentado && _comuna.text.trim().isEmpty ? 'Escribe tu comuna.' : null, alCambiar: (_) => setState(() {})),
              const SizedBox(height: Esp.x4),
              Campo('Referencia (opcional)', controlador: _ref, ayuda: 'Ejemplo: portón verde, tocar el timbre.'),
              if (estado.conSesion) ...[
                const SizedBox(height: Esp.x3),
                Tocable(
                  etiqueta: 'Guardar esta dirección en mi cuenta, ${_guardar ? 'activado' : 'desactivado'}',
                  onTap: () => setState(() => _guardar = !_guardar),
                  child: Row(children: [
                    Expanded(child: Text('Guardar en mis direcciones', style: T.cuerpoMFuerte)),
                    Switch(value: _guardar, onChanged: (v) => setState(() => _guardar = v)),
                  ]),
                ),
              ],
            ]),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x3, Esp.x5, Esp.x3),
            decoration: BoxDecoration(color: C.superficie, border: Border(top: BorderSide(color: C.borde))),
            child: SafeArea(top: false, child: Boton('Usar esta dirección', icono: LucideIcons.check, alto: 60, onTap: _usarNueva)),
          ),
        ]),
      ),
    );
  }
}

/// Abre de verdad la aplicación de teléfono o WhatsApp con el número de Sedyjo. Devuelve si se pudo.
Future<bool> abrirContacto({bool whatsapp = false}) async {
  final numero = telefonoVisible.replaceAll(RegExp(r'[^0-9]'), '');
  final uri = whatsapp ? Uri.parse('https://wa.me/$numero') : Uri(scheme: 'tel', path: '+$numero');
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Hoja de contacto: explica qué va a pasar antes de abrir el teléfono o WhatsApp.
void mostrarContacto(BuildContext context, {bool whatsapp = false}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Esp.x6, Esp.x6, Esp.x6, Esp.x5),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: C.verdeSuave, shape: BoxShape.circle),
              child: Icon(whatsapp ? LucideIcons.messageCircle : LucideIcons.phone, color: C.verdeOscuro, size: Ico.m),
            ),
            const SizedBox(width: Esp.x3),
            Expanded(child: Text(whatsapp ? 'Escribir por WhatsApp' : 'Llamar a Comercial Sedyjo', style: T.titulo2)),
          ]),
          const SizedBox(height: Esp.x3),
          Text(telefonoVisible, style: T.titulo1.copyWith(fontSize: 28)),
          const SizedBox(height: Esp.x2),
          Text(whatsapp ? 'Se abrirá WhatsApp en tu celular con este número.' : 'Se abrirá la aplicación de teléfono de tu celular con este número.', style: T.cuerpo.copyWith(color: C.grisMedio)),
          const SizedBox(height: Esp.x5),
          Boton(whatsapp ? 'Abrir WhatsApp' : 'Llamar ahora', icono: whatsapp ? LucideIcons.messageCircle : LucideIcons.phone, onTap: () async {
            Navigator.pop(ctx);
            final abrio = await abrirContacto(whatsapp: whatsapp);
            // Si el aparato no puede (tableta sin teléfono, navegador), se dice qué hacer en vez de fingir que se abrió.
            if (!abrio && context.mounted) {
              avisoGeneral(context, whatsapp ? 'No pudimos abrir WhatsApp. Escríbenos al $telefonoVisible.' : 'No pudimos abrir el teléfono. Llámanos al $telefonoVisible.');
            }
          }),
          const SizedBox(height: Esp.x3),
          Boton('Cancelar', estilo: EstiloBoton.suave, onTap: () => Navigator.pop(ctx)),
        ]),
      ),
    ),
  );
}

/// Pantalla de lectura para despachos, cambios y términos.
class ContenidoPantalla extends StatelessWidget {
  const ContenidoPantalla({super.key, required this.titulo, required this.icono, required this.secciones, this.nota});
  final String titulo;
  final IconData icono;
  final List<(String, String)> secciones;
  final String? nota;

  factory ContenidoPantalla.despachos() => const ContenidoPantalla(
        titulo: 'Despachos',
        icono: LucideIcons.truck,
        secciones: [
          ('¿Despachan a mi comuna?', 'Al agregar tu dirección confirmamos el despacho. Si tienes dudas, llámanos antes de comprar.'),
          ('¿Cuánto demora?', 'Entre 24 y 48 horas desde que se confirma tu pago.'),
          ('¿Cuánto cuesta?', 'Es gratis desde \$39.990 en productos. Bajo ese monto, el costo se calcula con tu dirección.'),
          ('¿Cómo sigo mi pedido?', 'En Mi cuenta, o en "Seguir un pedido" con tu número de pedido y tu correo, sin necesidad de cuenta.'),
        ],
      );

  factory ContenidoPantalla.cambios() => const ContenidoPantalla(
        titulo: 'Cambios y devoluciones',
        icono: LucideIcons.refreshCw,
        secciones: [
          ('Si algo llega con problemas', 'Llámanos o escríbenos por WhatsApp con tu número de pedido y lo resolvemos con un cambio o una devolución.'),
          ('Qué conviene tener a mano', 'El número de pedido y una foto del producto, si se puede.'),
        ],
        nota: 'Texto de ejemplo para la maqueta: el negocio debe confirmar los plazos y condiciones.',
      );

  factory ContenidoPantalla.privacidad() => const ContenidoPantalla(
        titulo: 'Privacidad y términos',
        icono: LucideIcons.shieldCheck,
        secciones: [
          ('Tus datos', 'Usamos tu nombre, correo, teléfono y dirección solo para tu compra y el despacho.'),
          ('Tu tarjeta', 'El pago se hace en Webpay. En esta app no guardamos los datos de tu tarjeta.'),
          ('Términos de uso', 'Al comprar aceptas los términos de Comercial Sedyjo.'),
        ],
        nota: 'Texto de ejemplo para la maqueta: el texto legal final debe ser revisado por el negocio.',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          BarraSuperior(titulo),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x2, Esp.x5, Esp.x8), children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: C.verdeSuave, shape: BoxShape.circle),
                child: Icon(icono, size: Ico.l, color: C.verdeOscuro),
              ),
              const SizedBox(height: Esp.x4),
              for (final s in secciones) ...[
                Text(s.$1, style: T.titulo3),
                const SizedBox(height: Esp.x2),
                Text(s.$2, style: T.cuerpo.copyWith(color: C.grisMedio)),
                const SizedBox(height: Esp.x6),
              ],
              if (nota != null)
                Panel(
                  fondo: C.grisFondo,
                  borde: C.grisFondo,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(LucideIcons.info, size: Ico.m, color: C.grisMedio),
                    const SizedBox(width: Esp.x3),
                    Expanded(child: Text(nota!, style: T.apoyo)),
                  ]),
                ),
              const SizedBox(height: Esp.x4),
              Boton('¿Dudas? Llámanos', icono: LucideIcons.phone, estilo: EstiloBoton.contorno, onTap: () => mostrarContacto(context)),
            ]),
          ),
        ]),
      ),
    );
  }
}
