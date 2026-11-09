import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/componentes.dart';
import 'direccion.dart';

class AyudaPantalla extends StatelessWidget {
  const AyudaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    const preguntas = [
      ('¿Cuánto demora el despacho?', 'Despachamos a domicilio en 24 a 48 horas desde que se confirma tu pago.'),
      ('¿Desde qué monto el despacho es gratis?', 'Desde \$49.990 en productos. Bajo ese monto, el costo se calcula al elegir tu dirección.'),
      ('¿Cómo puedo pagar?', 'Con tarjeta de débito o crédito mediante Webpay. No guardamos los datos de tu tarjeta.'),
      ('¿Necesito una cuenta para comprar?', 'No. Puedes comprar como invitado y seguir tu pedido con el número y tu correo.'),
      ('¿Qué hago si un producto llega con problemas?', 'Llámanos o escríbenos y lo resolvemos con un cambio o devolución.'),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const BarraSuperior('Ayuda y contacto'),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: C.azul, borderRadius: BorderRadius.circular(24)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: 104,
                        height: 118,
                        child: Image.asset('assets/img/escenas/atencion.webp', fit: BoxFit.cover, alignment: const Alignment(-.2, -.6), semanticLabel: 'Persona del equipo de atención con audífonos'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Habla con nosotros', style: T.titulo2.copyWith(color: Colors.white)),
                        const SizedBox(height: 6),
                        Text('Te ayudamos a comprar, paso a paso.', style: T.cuerpo.copyWith(color: const Color(0xFFDCE6F5), fontSize: 16)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 18),
                  Boton('Llamar $telefonoVisible', icono: LucideIcons.phone, estilo: EstiloBoton.suave, onTap: () => mostrarContacto(context)),
                  const SizedBox(height: 10),
                  Boton('Escribir por WhatsApp', icono: LucideIcons.messageCircle, estilo: EstiloBoton.contorno, onTap: () => mostrarContacto(context, whatsapp: true)),
                ]),
              ),
              const SizedBox(height: 26),
              Text('Preguntas frecuentes', style: T.titulo2),
              const SizedBox(height: 14),
              for (final q in preguntas) ...[_Pregunta(q.$1, q.$2), const SizedBox(height: 10)],
              const SizedBox(height: 14),
              Panel(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  _Enlace(LucideIcons.truck, 'Despachos', () => irA(context, ContenidoPantalla.despachos())),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _Enlace(LucideIcons.refreshCw, 'Cambios y devoluciones', () => irA(context, ContenidoPantalla.cambios())),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _Enlace(LucideIcons.shieldCheck, 'Privacidad y términos', () => irA(context, ContenidoPantalla.privacidad())),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Pregunta extends StatefulWidget {
  const _Pregunta(this.q, this.r);
  final String q;
  final String r;

  @override
  State<_Pregunta> createState() => _PreguntaState();
}

class _PreguntaState extends State<_Pregunta> {
  bool _abierta = false;

  @override
  Widget build(BuildContext context) {
    return Tocable(
      etiqueta: '${widget.q}${_abierta ? '. Respuesta: ${widget.r}' : ''}',
      onTap: () => setState(() => _abierta = !_abierta),
      child: AnimatedSize(
        duration: dur(context, 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _abierta ? C.verdeSuave : C.superficie,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _abierta ? C.verde : C.borde, width: _abierta ? 2 : 1.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(widget.q, style: T.cuerpoFuerte.copyWith(fontSize: 17))),
              Icon(_abierta ? LucideIcons.chevronDown : LucideIcons.plus, color: C.verdeOscuro),
            ]),
            if (_abierta) ...[
              const SizedBox(height: 10),
              Text(widget.r, style: T.cuerpo.copyWith(color: C.verdeProfundo, fontSize: 17)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _Enlace extends StatelessWidget {
  const _Enlace(this.icono, this.texto, this.alTocar);
  final IconData icono;
  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Tocable(
      etiqueta: texto,
      onTap: alTocar,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(icono, color: C.verdeOscuro, size: 26),
          const SizedBox(width: 14),
          Expanded(child: Text(texto, style: T.cuerpoFuerte)),
          Icon(LucideIcons.chevronRight, color: C.grisMedio),
        ]),
      ),
    );
  }
}
