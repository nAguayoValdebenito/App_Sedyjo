import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/componentes.dart';
import 'shell.dart';

void _terminarAuth(BuildContext context, bool desdeBienvenida) {
  estado.marcarVisitado();
  estado.pestana = 0;
  if (desdeBienvenida) {
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const Shell()), (r) => false);
  } else {
    Navigator.of(context).popUntil((r) => r.settings.name == null ? r.isFirst || r.settings is! MaterialPageRoute : true);
  }
}

class _MarcoAuth extends StatelessWidget {
  const _MarcoAuth({required this.titulo, required this.sub, required this.children, this.controlador});
  final ScrollController? controlador;
  final String titulo;
  final String sub;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const BarraSuperior('', atras: true),
          Expanded(
            child: AutofillGroup(
              child: ListView(controller: controlador, padding: const EdgeInsets.fromLTRB(24, 0, 24, 32), children: [
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.borde, width: 1.5)),
                  child: ClipOval(child: Image.asset('assets/img/logo.webp', fit: BoxFit.cover, semanticLabel: 'Comercial Sedyjo')),
                ),
              ),
              const SizedBox(height: 18),
              Semantics(header: true, child: Text(titulo, textAlign: TextAlign.center, style: T.titulo1)),
              const SizedBox(height: 8),
              Text(sub, textAlign: TextAlign.center, style: T.cuerpo.copyWith(color: C.grisMedio)),
              const SizedBox(height: 28),
              ...children,
            ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class IngresarPantalla extends StatefulWidget {
  const IngresarPantalla({super.key, this.desdeBienvenida = false});
  final bool desdeBienvenida;

  @override
  State<IngresarPantalla> createState() => _IngresarPantallaState();
}

class _IngresarPantallaState extends State<IngresarPantalla> {
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _intentado = false;
  bool _cargando = false;

  String? get _errCorreo {
    if (!_intentado) return null;
    final t = _correo.text.trim();
    if (t.isEmpty) return 'Escribe tu correo.';
    if (!t.contains('@')) return 'Falta la @. Ejemplo: nombre@correo.cl';
    return null;
  }

  String? get _errClave => _intentado && _clave.text.isEmpty ? 'Escribe tu contraseña.' : null;

  Future<void> _entrar() async {
    setState(() => _intentado = true);
    if (_errCorreo != null || _errClave != null) return;
    setState(() => _cargando = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    estado.iniciarSesion('María González', _correo.text.trim());
    if (widget.desdeBienvenida) {
      _terminarAuth(context, true);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MarcoAuth(
      titulo: 'Ingresar',
      sub: 'Entra para ver tus pedidos y usar tus direcciones guardadas.',
      children: [
        Campo('Correo electrónico', controlador: _correo, autofill: const [AutofillHints.email], teclado: TextInputType.emailAddress, icono: LucideIcons.mail, error: _errCorreo, alCambiar: (_) => setState(() {})),
        const SizedBox(height: 18),
        Campo('Contraseña', controlador: _clave, autofill: const [AutofillHints.password], accion: TextInputAction.done, clave: true, icono: LucideIcons.lock, error: _errClave, alCambiar: (_) => setState(() {})),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Tocable(
            etiqueta: 'Recuperar contraseña',
            onTap: () => irA(context, const RecuperarPantalla()),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('¿Olvidaste tu contraseña?', style: T.cuerpoFuerte.copyWith(color: C.azulEnlace, decoration: TextDecoration.underline, fontSize: 17)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Boton(_cargando ? 'Ingresando…' : 'Ingresar', alto: 62, onTap: _cargando ? null : _entrar),
        const SizedBox(height: 22),
        Row(children: [
          const Expanded(child: Divider()),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('o', style: T.apoyo)),
          const Expanded(child: Divider()),
        ]),
        const SizedBox(height: 22),
        Boton('Crear una cuenta nueva', estilo: EstiloBoton.contorno, onTap: () {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => RegistroPantalla(desdeBienvenida: widget.desdeBienvenida)));
        }),
        if (widget.desdeBienvenida) ...[
          const SizedBox(height: 10),
          Boton('Comprar sin cuenta', estilo: EstiloBoton.suave, onTap: () => _terminarAuth(context, true)),
        ],
      ],
    );
  }
}

class RegistroPantalla extends StatefulWidget {
  const RegistroPantalla({super.key, this.desdeBienvenida = false});
  final bool desdeBienvenida;

  @override
  State<RegistroPantalla> createState() => _RegistroPantallaState();
}

class _RegistroPantallaState extends State<RegistroPantalla> {
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _tel = TextEditingController();
  final _clave = TextEditingController();
  final _clave2 = TextEditingController();
  bool _intentado = false;
  bool _acepto = false;
  bool _cargando = false;
  final _scroll = ScrollController();

  List<String> get _faltan => !_intentado
      ? const []
      : [
          if (_nombre.text.trim().isEmpty) 'Tu nombre y apellido',
          if (_errCorreo != null) 'Un correo válido, como nombre@correo.cl',
          if (_errClave != null) 'Una contraseña de al menos 8 caracteres',
          if (_errClave2 != null) 'Repetir la misma contraseña',
          if (!_acepto) 'Marcar que aceptas los términos',
        ];

  String? _vacio(TextEditingController c, String m) => _intentado && c.text.trim().isEmpty ? m : null;
  String? get _errClave => !_intentado ? null : (_clave.text.length < 8 ? 'Usa al menos 8 caracteres.' : null);
  String? get _errClave2 => !_intentado ? null : (_clave2.text != _clave.text ? 'Las contraseñas no son iguales.' : null);
  String? get _errCorreo => !_intentado ? null : (!_correo.text.contains('@') ? 'Escribe un correo válido. Ejemplo: nombre@correo.cl' : null);

  Future<void> _crear() async {
    setState(() => _intentado = true);
    if (_nombre.text.trim().isEmpty || _errCorreo != null || _errClave != null || _errClave2 != null || !_acepto) {
      if (_scroll.hasClients) _scroll.animateTo(0, duration: dur(context, 350), curve: Curves.easeOutCubic);
      return;
    }
    setState(() => _cargando = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    estado.iniciarSesion(_nombre.text.trim(), _correo.text.trim());
    if (widget.desdeBienvenida) {
      _terminarAuth(context, true);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [_nombre, _correo, _tel, _clave, _clave2]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MarcoAuth(
      titulo: 'Crear mi cuenta',
      sub: 'Guarda tus direcciones y revisa tus pedidos cuando quieras.',
      controlador: _scroll,
      children: [
        ResumenErrores(_faltan),
        Campo('Nombre y apellido', controlador: _nombre, autofill: const [AutofillHints.name], mayusculas: TextCapitalization.words, icono: LucideIcons.user, error: _vacio(_nombre, 'Escribe tu nombre.'), alCambiar: (_) => setState(() {})),
        const SizedBox(height: 16),
        Campo('Correo electrónico', controlador: _correo, autofill: const [AutofillHints.email], teclado: TextInputType.emailAddress, icono: LucideIcons.mail, error: _errCorreo, alCambiar: (_) => setState(() {})),
        const SizedBox(height: 16),
        Campo('Teléfono (opcional)', controlador: _tel, autofill: const [AutofillHints.telephoneNumber], teclado: TextInputType.phone, icono: LucideIcons.phone),
        const SizedBox(height: 16),
        Campo('Contraseña', controlador: _clave, autofill: const [AutofillHints.newPassword], clave: true, icono: LucideIcons.lock, ayuda: 'Mínimo 8 caracteres.', error: _errClave, alCambiar: (_) => setState(() {})),
        const SizedBox(height: 16),
        Campo('Repite la contraseña', controlador: _clave2, autofill: const [AutofillHints.newPassword], accion: TextInputAction.done, clave: true, icono: LucideIcons.lockKeyhole, error: _errClave2, alCambiar: (_) => setState(() {})),
        const SizedBox(height: 18),
        Tocable(
          etiqueta: 'Acepto los términos y la política de privacidad',
          onTap: () => setState(() => _acepto = !_acepto),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.superficie,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _intentado && !_acepto ? C.error : C.borde, width: _intentado && !_acepto ? 2 : 1.5),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedContainer(
                duration: dur(context, 150),
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: _acepto ? C.verde : C.superficie, borderRadius: BorderRadius.circular(9), border: Border.all(color: _acepto ? C.verde : C.bordeControl, width: 2)),
                child: _acepto ? const Icon(LucideIcons.check, size: 22, color: Colors.white) : null,
              ),
              const SizedBox(width: 14),
              Expanded(child: Text('Acepto los términos y condiciones y la política de privacidad.', style: T.cuerpo.copyWith(fontSize: 16))),
            ]),
          ),
        ),
        if (_intentado && !_acepto)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              Icon(LucideIcons.circleAlert, size: 18, color: C.error),
              const SizedBox(width: 6),
              Expanded(child: Text('Marca la casilla para crear tu cuenta.', style: T.apoyo.copyWith(color: C.error, fontWeight: FontWeight.w600))),
            ]),
          ),
        const SizedBox(height: 22),
        Boton(_cargando ? 'Creando cuenta…' : 'Crear mi cuenta', alto: 62, onTap: _cargando ? null : _crear),
        const SizedBox(height: 12),
        Boton('Ya tengo cuenta', estilo: EstiloBoton.suave, onTap: () {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => IngresarPantalla(desdeBienvenida: widget.desdeBienvenida)));
        }),
      ],
    );
  }
}

class RecuperarPantalla extends StatefulWidget {
  const RecuperarPantalla({super.key});

  @override
  State<RecuperarPantalla> createState() => _RecuperarPantallaState();
}

class _RecuperarPantallaState extends State<RecuperarPantalla> {
  final _correo = TextEditingController();
  bool _enviado = false;
  bool _intentado = false;

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_enviado) {
      return _MarcoAuth(
        titulo: 'Revisa tu correo',
        sub: 'Si ${_correo.text.trim()} tiene una cuenta, te enviamos un enlace para crear una contraseña nueva.',
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: C.verdeSuave, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Icon(LucideIcons.mail, size: 30, color: C.verdeOscuro),
              const SizedBox(width: 14),
              Expanded(child: Text('Puede tardar unos minutos. Mira también en la carpeta de spam.', style: T.cuerpo.copyWith(color: C.verdeProfundo, fontSize: 16))),
            ]),
          ),
          const SizedBox(height: 24),
          Boton('Volver a ingresar', onTap: () => Navigator.of(context).pop()),
        ],
      );
    }
    return _MarcoAuth(
      titulo: 'Recuperar contraseña',
      sub: 'Escribe tu correo y te enviamos un enlace para elegir una contraseña nueva.',
      children: [
        Campo('Correo electrónico', controlador: _correo, autofill: const [AutofillHints.email], accion: TextInputAction.done, teclado: TextInputType.emailAddress, icono: LucideIcons.mail, error: _intentado && !_correo.text.contains('@') ? 'Escribe un correo válido. Ejemplo: nombre@correo.cl' : null, alCambiar: (_) => setState(() {})),
        const SizedBox(height: 22),
        Boton('Enviar enlace', alto: 62, onTap: () {
          setState(() => _intentado = true);
          if (_correo.text.contains('@')) setState(() => _enviado = true);
        }),
      ],
    );
  }
}
