import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/banners.dart';
import '../ui/componentes.dart';
import 'auth.dart';
import 'avisos.dart';
import 'ayuda.dart';
import 'favoritos.dart';
import 'pedidos.dart';

class CuentaPestana extends StatelessWidget {
  const CuentaPestana({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) => SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x3, Esp.x5, Esp.x8),
          children: [
            Text('Mi cuenta', style: T.titulo1),
            const SizedBox(height: Esp.x4),
            if (estado.conSesion) _Perfil() else const _SinSesion(),
            const SizedBox(height: Esp.x6),
            if (estado.conSesion) ...[
              _Grupo(children: [
                _Fila(LucideIcons.package, 'Mis pedidos', '${estado.pedidos.length} pedidos', () => irA(context, const PedidosPantalla())),
                _Fila(LucideIcons.mapPin, 'Mis direcciones', '${estado.direcciones.length} guardadas', () => irA(context, const DireccionesPantalla())),
                _Fila(LucideIcons.user, 'Mis datos', 'Nombre, correo y contraseña', () => irA(context, const PerfilPantalla())),
              ]),
              const SizedBox(height: Esp.x4),
            ] else ...[
              _Grupo(children: [
                _Fila(LucideIcons.packageSearch, 'Seguir un pedido', 'Con el número, sin cuenta', () => irA(context, const SeguimientoPantalla())),
              ]),
              const SizedBox(height: Esp.x4),
            ],
            _Grupo(children: [
              _Fila(LucideIcons.heart, 'Mis favoritos', estado.favoritos.isEmpty ? 'Guarda lo que más te gusta' : '${estado.favoritos.length} guardados', () => irA(context, const FavoritosPantalla())),
              _Fila(LucideIcons.bellRing, 'Avisos y ofertas', estado.minutosOfertas == 0 ? 'Desactivados' : 'Ofertas cada ${estado.minutosOfertas} min', () => irA(context, const AvisosPantalla())),
              _Fila(LucideIcons.circleHelp, 'Ayuda y contacto', 'Llámanos o escríbenos', () => irA(context, const AyudaPantalla())),
            ]),
            const SizedBox(height: Esp.x6),
            const _Apariencia(),
            const SizedBox(height: Esp.x4),
            const _TamanoLetra(),
            if (estado.conSesion) ...[
              const SizedBox(height: Esp.x6),
              Boton('Cerrar sesión', estilo: EstiloBoton.peligro, icono: LucideIcons.logOut, onTap: () => estado.cerrarSesion()),
            ],
            const SizedBox(height: Esp.x5),
            Center(child: Text('Comercial Sedyjo · versión de diseño 0.1', style: T.apoyo.copyWith(fontSize: 14))),
          ],
        ),
      ),
    );
  }
}

class _Perfil extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Esp.x4),
      decoration: BoxDecoration(color: C.verde, borderRadius: BorderRadius.circular(R.l)),
      child: Row(children: [
        Container(
          width: 66,
          height: 66,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Text(estado.iniciales, style: T.titulo2.copyWith(color: C.verdeBanner)),
        ),
        const SizedBox(width: Esp.x4),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(estado.nombre ?? '', style: T.titulo3.copyWith(color: Colors.white, fontSize: 22)),
            const SizedBox(height: 2),
            Text(estado.correo ?? '', style: T.apoyo.copyWith(color: C.verdePalido, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }
}

class _SinSesion extends StatelessWidget {
  const _SinSesion();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(R.l),
      child: Stack(children: [
        Positioned.fill(child: Container(color: C.verdeSuave)),
        Positioned.fill(child: Image.asset('assets/img/patrones/${C.oscuro ? 'oscuro' : 'claro'}-v2.webp', fit: BoxFit.cover, opacity: AlwaysStoppedAnimation(C.oscuro ? .22 : .5))),
        Container(
      padding: const EdgeInsets.all(Esp.x5),
      decoration: BoxDecoration(color: C.verdeSuave, borderRadius: BorderRadius.circular(R.l)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Compras como invitado', style: T.titulo3.copyWith(color: C.verdeProfundo)),
        const SizedBox(height: Esp.x2),
        Text('Crea una cuenta gratis para guardar tus direcciones y ver tus pedidos.', style: T.cuerpo.copyWith(color: C.verdeOscuro, fontSize: 17)),
        const SizedBox(height: Esp.x4),
        Boton('Ingresar', onTap: () => irA(context, const IngresarPantalla())),
        const SizedBox(height: Esp.x3),
        Boton('Crear mi cuenta', estilo: EstiloBoton.contorno, onTap: () => irA(context, const RegistroPantalla())),
      ]),
    ),
      ]),
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      ]),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.icono, this.titulo, this.sub, this.alTocar);
  final IconData icono;
  final String titulo;
  final String sub;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Tocable(
      etiqueta: '$titulo. $sub',
      onTap: alTocar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Esp.x4, vertical: Esp.x4),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: C.verdeSuave, shape: BoxShape.circle),
            child: Icon(icono, color: C.verdeOscuro, size: Ico.m),
          ),
          const SizedBox(width: Esp.x3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: T.cuerpoFuerte),
              Text(sub, style: T.apoyo),
            ]),
          ),
          Icon(LucideIcons.chevronRight, color: C.grisMedio),
        ]),
      ),
    );
  }
}

/// Tema claro / oscuro / automático (sigue al celular).
class _Apariencia extends StatelessWidget {
  const _Apariencia();

  @override
  Widget build(BuildContext context) {
    final opciones = [
      (ModoTema.auto, 'Automático', LucideIcons.smartphone),
      (ModoTema.claro, 'Claro', LucideIcons.sun),
      (ModoTema.oscuro, 'Oscuro', LucideIcons.moon),
    ];
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(C.oscuro ? LucideIcons.moon : LucideIcons.sun, color: C.verdeOscuro, size: Ico.m),
          const SizedBox(width: Esp.x3),
          Expanded(child: Text('Apariencia', style: T.titulo3)),
        ]),
        const SizedBox(height: Esp.x1),
        Text('Automático sigue la configuración de tu celular.', style: T.apoyo),
        const SizedBox(height: Esp.x4),
        for (final (i, o) in opciones.indexed) ...[
          if (i > 0) const SizedBox(height: Esp.x2),
          OpcionFila(texto: o.$2, icono: o.$3, activo: estado.modoTema == o.$1, alTocar: () => estado.cambiarModoTema(o.$1)),
        ],
        const SizedBox(height: Esp.x4),
        const Divider(height: 1),
        const SizedBox(height: Esp.x2),
        // Entrar más rápido: la pantalla de carga muestra solo el logo.
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Carga breve', style: T.cuerpoFuerte),
              Text('Entrar más rápido: solo el logo, sin la canasta.', style: T.apoyo),
            ]),
          ),
          Switch(value: estado.cargaBreve, onChanged: estado.cambiarCargaBreve, activeThumbColor: Colors.white, activeTrackColor: C.verde),
        ]),
      ]),
    );
  }
}

/// Control de tamaño de letra: afecta toda la app al instante.
class _TamanoLetra extends StatelessWidget {
  const _TamanoLetra();

  @override
  Widget build(BuildContext context) {
    const opciones = [(1.0, 'Normal'), (1.15, 'Grande'), (1.3, 'Muy grande')];
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.type, color: C.verdeOscuro, size: Ico.m),
          const SizedBox(width: Esp.x3),
          Expanded(child: Text('Tamaño de letra', style: T.titulo3)),
        ]),
        const SizedBox(height: Esp.x1),
        Text('Elige el que veas mejor. Se aplica en toda la app.', style: T.apoyo),
        const SizedBox(height: Esp.x4),
        for (final (i, o) in opciones.indexed) ...[
          if (i > 0) const SizedBox(height: Esp.x2),
          OpcionFila(texto: o.$2, muestra: 16 + i * 4.0, activo: estado.escalaTexto == o.$1, alTocar: () => estado.cambiarEscala(o.$1)),
        ],
        const SizedBox(height: Esp.x3),
        Tocable(
          etiqueta: 'Reducir movimiento y animaciones',
          onTap: () => estado.cambiarReducirMovimiento(!estado.reducirMovimiento),
          child: Row(children: [
            Expanded(child: Text('Reducir animaciones', style: T.cuerpoFuerte)),
            Switch(value: estado.reducirMovimiento, onChanged: estado.cambiarReducirMovimiento, activeThumbColor: Colors.white, activeTrackColor: C.verde),
          ]),
        ),
      ]),
    );
  }
}

class DireccionesPantalla extends StatelessWidget {
  const DireccionesPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            const BarraSuperior('Mis direcciones'),
            Expanded(
              child: estado.direcciones.isEmpty
                  ? ListView(padding: const EdgeInsets.fromLTRB(Esp.x8, Esp.x6, Esp.x8, Esp.x4), children: [
                      const IconoEstado('sin-direcciones-guardadas', lado: 200),
                      const SizedBox(height: Esp.x6),
                      Text('Aún no guardas direcciones', textAlign: TextAlign.center, style: T.titulo2),
                      const SizedBox(height: Esp.x2),
                      Text('Guarda tu casa para pagar más rápido la próxima vez.', textAlign: TextAlign.center, style: T.cuerpo.copyWith(color: C.grisMedio)),
                    ])
                  : ListView(padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x2, Esp.x5, Esp.x5), children: [
                for (final (i, d) in estado.direcciones.indexed) ...[
                  Panel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(LucideIcons.house, color: C.verdeOscuro),
                        const SizedBox(width: Esp.x3),
                        Expanded(child: Text(d.alias, style: T.titulo3)),
                        if (d.principal) Insignia('Principal', fondo: C.verdeSuave, color: C.verdeProfundo),
                      ]),
                      const SizedBox(height: Esp.x3),
                      Text(d.calle, style: T.cuerpo),
                      Text(d.comuna, style: T.apoyo),
                      if (d.referencia.isNotEmpty) Text('Referencia: ${d.referencia}', style: T.apoyo),
                      const SizedBox(height: Esp.x3),
                      Row(children: [
                        Expanded(child: Boton('Editar', icono: LucideIcons.pencil, estilo: EstiloBoton.suave, alto: 50, onTap: () => _formulario(context, i))),
                        const SizedBox(width: Esp.x3),
                        Expanded(
                          child: Boton('Quitar',
                              etiqueta: 'Quitar la dirección ${d.alias}',
                              icono: LucideIcons.trash2,
                              estilo: EstiloBoton.texto,
                              alto: 50,
                              onTap: () => _confirmarQuitar(context, i)),
                        ),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: Esp.x3),
                ],
              ]),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x3, Esp.x5, Esp.x3),
              decoration: BoxDecoration(color: C.superficie, border: Border(top: BorderSide(color: C.borde))),
              child: SafeArea(top: false, child: Boton('Agregar una dirección', icono: LucideIcons.plus, alto: 60, onTap: () => _formulario(context, null))),
            ),
          ]),
        ),
      ),
    );
  }

  void _confirmarQuitar(BuildContext context, int i) {
    final d = estado.direcciones[i];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(Esp.x6, Esp.x6, Esp.x6, Esp.x8),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('¿Quitar esta dirección?', style: T.titulo2),
          const SizedBox(height: Esp.x2),
          Text('${d.alias}: ${d.calle}, ${d.comuna}', style: T.cuerpo.copyWith(color: C.grisMedio)),
          const SizedBox(height: Esp.x6),
          Boton('Sí, quitar dirección', estilo: EstiloBoton.peligro, onTap: () {
            final copia = d;
            estado.direcciones.removeAt(i);
            estado.refrescar();
            Navigator.pop(ctx);
            avisoGeneral(context, 'Quitaste la dirección ${copia.alias}', accion: 'Deshacer', alAccion: () {
              estado.direcciones.insert(i.clamp(0, estado.direcciones.length), copia);
              estado.refrescar();
            });
          }),
          const SizedBox(height: Esp.x3),
          Boton('No, conservarla', estilo: EstiloBoton.suave, onTap: () => Navigator.pop(ctx)),
        ]),
      ),
    );
  }

  void _formulario(BuildContext context, int? indice) {
    final d = indice == null ? null : estado.direcciones[indice];
    final alias = TextEditingController(text: d?.alias ?? '');
    final calle = TextEditingController(text: d?.calle ?? '');
    final ref = TextEditingController(text: d?.referencia ?? '');
    final comuna = TextEditingController(text: d?.comuna ?? '');
    var intentado = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.superficie,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setHoja) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d == null ? 'Nueva dirección' : 'Editar dirección', style: T.titulo2),
              const SizedBox(height: Esp.x4),
              Campo('Nombre (Casa, Trabajo…)', controlador: alias, icono: LucideIcons.tag),
              const SizedBox(height: Esp.x3),
              Campo('Calle y número', controlador: calle, icono: LucideIcons.mapPin, error: intentado && calle.text.trim().isEmpty ? 'Escribe la calle y el número.' : null, alCambiar: (_) => setHoja(() {})),
              const SizedBox(height: Esp.x3),
              Campo('Comuna', controlador: comuna, mayusculas: TextCapitalization.words, icono: LucideIcons.map, error: intentado && comuna.text.trim().isEmpty ? 'Escribe tu comuna.' : null, alCambiar: (_) => setHoja(() {})),
              const SizedBox(height: Esp.x3),
              Campo('Referencia (opcional)', controlador: ref),
              const SizedBox(height: Esp.x6),
              Boton('Guardar dirección', onTap: () {
                setHoja(() => intentado = true);
                if (calle.text.trim().isEmpty || comuna.text.trim().isEmpty) return;
                final nombre = alias.text.trim().isEmpty ? 'Casa' : alias.text.trim();
                if (d == null) {
                  estado.direcciones.add(Direccion(nombre, calle.text.trim(), comuna.text.trim(), ref.text.trim(), principal: estado.direcciones.isEmpty));
                } else {
                  d.alias = nombre;
                  d.calle = calle.text.trim();
                  d.comuna = comuna.text.trim();
                  d.referencia = ref.text.trim();
                }
                estado.refrescar();
                Navigator.pop(ctx);
              }),
            ]),
          ),
        ),
      ),
    );
  }
}

class PerfilPantalla extends StatefulWidget {
  const PerfilPantalla({super.key});

  @override
  State<PerfilPantalla> createState() => _PerfilPantallaState();
}

class _PerfilPantallaState extends State<PerfilPantalla> {
  late final _nombre = TextEditingController(text: estado.nombre ?? '');
  late final _correo = TextEditingController(text: estado.correo ?? '');
  late final _telefono = TextEditingController(text: estado.telefono ?? '');
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  bool _intentoDatos = false;
  bool _intentoClave = false;

  @override
  void dispose() {
    for (final c in [_nombre, _correo, _telefono, _actual, _nueva]) {
      c.dispose();
    }
    super.dispose();
  }

  String? get _errNombre => _intentoDatos && _nombre.text.trim().isEmpty ? 'Escribe tu nombre y apellido.' : null;
  String? get _errCorreo {
    if (!_intentoDatos) return null;
    final t = _correo.text.trim();
    if (t.isEmpty) return 'Escribe tu correo.';
    if (!t.contains('@') || !t.contains('.')) return 'Revisa el correo: debe verse como nombre@correo.cl';
    return null;
  }

  String? get _errTelefono {
    if (!_intentoDatos || _telefono.text.trim().isEmpty) return null;
    return _telefono.text.replaceAll(RegExp(r'[^0-9]'), '').length < 8 ? 'Revisa el teléfono: faltan números.' : null;
  }

  String? get _errActual => _intentoClave && _actual.text.isEmpty ? 'Escribe tu contraseña actual.' : null;
  String? get _errNueva => _intentoClave && _nueva.text.length < 8 ? 'Usa al menos 8 caracteres.' : null;

  void _guardarDatos() {
    setState(() => _intentoDatos = true);
    if (_errNombre != null || _errCorreo != null || _errTelefono != null) return;
    estado.actualizarPerfil(nombre: _nombre.text.trim(), correo: _correo.text.trim(), telefono: _telefono.text);
    Navigator.of(context).maybePop();
    avisoGeneral(context, 'Guardamos tus cambios');
  }

  void _cambiarClave() {
    setState(() => _intentoClave = true);
    if (_errActual != null || _errNueva != null) return;
    setState(() {
      _actual.clear();
      _nueva.clear();
      _intentoClave = false;
    });
    avisoGeneral(context, 'Tu contraseña se actualizó');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const BarraSuperior('Mis datos'),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x2, Esp.x5, Esp.x8), children: [
              Campo('Nombre y apellido', controlador: _nombre, icono: LucideIcons.user, mayusculas: TextCapitalization.words, error: _errNombre, alCambiar: (_) => setState(() {})),
              const SizedBox(height: Esp.x4),
              Campo('Correo electrónico', controlador: _correo, icono: LucideIcons.mail, teclado: TextInputType.emailAddress, error: _errCorreo, alCambiar: (_) => setState(() {})),
              const SizedBox(height: Esp.x4),
              Campo('Teléfono (opcional)', controlador: _telefono, icono: LucideIcons.phone, teclado: TextInputType.phone, ayuda: 'Lo usamos para avisarte del despacho.', error: _errTelefono, alCambiar: (_) => setState(() {})),
              const SizedBox(height: Esp.x6),
              Boton('Guardar cambios', onTap: _guardarDatos),
              const SizedBox(height: Esp.x8),
              Text('Cambiar contraseña', style: T.titulo3),
              const SizedBox(height: Esp.x3),
              Campo('Contraseña actual', controlador: _actual, clave: true, icono: LucideIcons.lock, error: _errActual, alCambiar: (_) => setState(() {})),
              const SizedBox(height: Esp.x4),
              Campo('Contraseña nueva', controlador: _nueva, clave: true, icono: LucideIcons.lockKeyhole, ayuda: 'Mínimo 8 caracteres.', error: _errNueva, alCambiar: (_) => setState(() {})),
              const SizedBox(height: Esp.x6),
              Boton('Cambiar contraseña', estilo: EstiloBoton.contorno, onTap: _cambiarClave),
            ]),
          ),
        ]),
      ),
    );
  }
}
