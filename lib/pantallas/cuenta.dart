import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/banners.dart';
import '../ui/componentes.dart';
import 'auth.dart';
import 'avisos.dart';
import 'ayuda.dart';
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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          children: [
            Text('Mi cuenta', style: T.titulo1),
            const SizedBox(height: 16),
            if (estado.conSesion) _Perfil() else const _SinSesion(),
            const SizedBox(height: 22),
            if (estado.conSesion) ...[
              _Grupo(children: [
                _Fila(LucideIcons.package, 'Mis pedidos', '${estado.pedidos.length} pedidos', () => irA(context, const PedidosPantalla())),
                _Fila(LucideIcons.mapPin, 'Mis direcciones', '${estado.direcciones.length} guardadas', () => irA(context, const DireccionesPantalla())),
                _Fila(LucideIcons.user, 'Mis datos', 'Nombre, correo y contraseña', () => irA(context, const PerfilPantalla())),
              ]),
              const SizedBox(height: 16),
            ] else ...[
              _Grupo(children: [
                _Fila(LucideIcons.packageSearch, 'Seguir un pedido', 'Con el número, sin cuenta', () => irA(context, const SeguimientoPantalla())),
              ]),
              const SizedBox(height: 16),
            ],
            _Grupo(children: [
              _Fila(LucideIcons.bellRing, 'Avisos y ofertas', estado.minutosOfertas == 0 ? 'Desactivados' : 'Ofertas cada ${estado.minutosOfertas} min', () => irA(context, const AvisosPantalla())),
              _Fila(LucideIcons.circleHelp, 'Ayuda y contacto', 'Llámanos o escríbenos', () => irA(context, const AyudaPantalla())),
            ]),
            const SizedBox(height: 26),
            const _Apariencia(),
            const SizedBox(height: 16),
            const _TamanoLetra(),
            if (estado.conSesion) ...[
              const SizedBox(height: 26),
              Boton('Cerrar sesión', estilo: EstiloBoton.peligro, icono: LucideIcons.logOut, onTap: () => estado.cerrarSesion()),
            ],
            const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: C.verde, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        Container(
          width: 66,
          height: 66,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Text(estado.iniciales, style: T.titulo2.copyWith(color: C.verdeBanner)),
        ),
        const SizedBox(width: 16),
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
      borderRadius: BorderRadius.circular(24),
      child: Stack(children: [
        Positioned.fill(child: Container(color: C.verdeSuave)),
        Positioned.fill(child: Opacity(opacity: C.oscuro ? .22 : .5, child: Image.asset('assets/img/patrones/${C.oscuro ? 'oscuro' : 'claro'}-v2.webp', fit: BoxFit.cover))),
        Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: C.verdeSuave, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Compras como invitado', style: T.titulo3.copyWith(color: C.verdeProfundo)),
        const SizedBox(height: 6),
        Text('Crea una cuenta gratis para guardar tus direcciones y ver tus pedidos.', style: T.cuerpo.copyWith(color: C.verdeOscuro, fontSize: 17)),
        const SizedBox(height: 18),
        Boton('Ingresar', onTap: () => irA(context, const IngresarPantalla())),
        const SizedBox(height: 10),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: C.verdeSuave, shape: BoxShape.circle),
            child: Icon(icono, color: C.verdeOscuro, size: 24),
          ),
          const SizedBox(width: 14),
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
          Icon(C.oscuro ? LucideIcons.moon : LucideIcons.sun, color: C.verdeOscuro, size: 26),
          const SizedBox(width: 12),
          Expanded(child: Text('Apariencia', style: T.titulo3)),
        ]),
        const SizedBox(height: 4),
        Text('Automático sigue la configuración de tu celular.', style: T.apoyo),
        const SizedBox(height: 16),
        for (final (i, o) in opciones.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          OpcionFila(texto: o.$2, icono: o.$3, activo: estado.modoTema == o.$1, alTocar: () => estado.cambiarModoTema(o.$1)),
        ],
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
          Icon(LucideIcons.type, color: C.verdeOscuro, size: 26),
          const SizedBox(width: 12),
          Expanded(child: Text('Tamaño de letra', style: T.titulo3)),
        ]),
        const SizedBox(height: 4),
        Text('Elige el que veas mejor. Se aplica en toda la app.', style: T.apoyo),
        const SizedBox(height: 16),
        for (final (i, o) in opciones.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          OpcionFila(texto: o.$2, muestra: 16 + i * 4.0, activo: estado.escalaTexto == o.$1, alTocar: () => estado.cambiarEscala(o.$1)),
        ],
        const SizedBox(height: 14),
        Tocable(
          etiqueta: 'Reducir movimiento y animaciones',
          onTap: () => estado.cambiarReducirMovimiento(!estado.reducirMovimiento),
          child: Row(children: [
            Expanded(child: Text('Reducir animaciones', style: T.cuerpoFuerte.copyWith(fontSize: 17))),
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
                  ? ListView(padding: const EdgeInsets.fromLTRB(28, 24, 28, 16), children: [
                      const IconoEstado('sin-direcciones-guardadas', lado: 200),
                      const SizedBox(height: 22),
                      Text('Aún no guardas direcciones', textAlign: TextAlign.center, style: T.titulo2),
                      const SizedBox(height: 8),
                      Text('Guarda tu casa para pagar más rápido la próxima vez.', textAlign: TextAlign.center, style: T.cuerpo.copyWith(color: C.grisMedio)),
                    ])
                  : ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), children: [
                for (final (i, d) in estado.direcciones.indexed) ...[
                  Panel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(LucideIcons.house, color: C.verdeOscuro),
                        const SizedBox(width: 10),
                        Expanded(child: Text(d.alias, style: T.titulo3)),
                        if (d.principal) Insignia('Principal', fondo: C.verdeSuave, color: C.verdeProfundo),
                      ]),
                      const SizedBox(height: 10),
                      Text(d.calle, style: T.cuerpo),
                      Text(d.comuna, style: T.apoyo),
                      if (d.referencia.isNotEmpty) Text('Referencia: ${d.referencia}', style: T.apoyo),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: Boton('Editar', icono: LucideIcons.pencil, estilo: EstiloBoton.suave, alto: 50, onTap: () => _formulario(context, i))),
                        const SizedBox(width: 10),
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
                  const SizedBox(height: 14),
                ],
              ]),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('¿Quitar esta dirección?', style: T.titulo2),
          const SizedBox(height: 8),
          Text('${d.alias}: ${d.calle}, ${d.comuna}', style: T.cuerpo.copyWith(color: C.grisMedio)),
          const SizedBox(height: 22),
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
          const SizedBox(height: 10),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.superficie,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d == null ? 'Nueva dirección' : 'Editar dirección', style: T.titulo2),
            const SizedBox(height: 18),
            Campo('Nombre (Casa, Trabajo…)', controlador: alias, icono: LucideIcons.tag),
            const SizedBox(height: 14),
            Campo('Calle y número', controlador: calle, icono: LucideIcons.mapPin),
            const SizedBox(height: 14),
            Campo('Comuna', controlador: comuna, mayusculas: TextCapitalization.words, icono: LucideIcons.map),
            const SizedBox(height: 14),
            Campo('Referencia (opcional)', controlador: ref),
            const SizedBox(height: 22),
            Boton('Guardar dirección', onTap: () {
              if (d == null) {
                estado.direcciones.add(Direccion(alias.text.isEmpty ? 'Casa' : alias.text, calle.text.isEmpty ? 'Sin calle' : calle.text, comuna.text.trim(), ref.text));
              } else {
                d.alias = alias.text;
                d.calle = calle.text;
                d.comuna = comuna.text.trim();
                d.referencia = ref.text;
              }
              estado.refrescar();
              Navigator.pop(ctx);
            }),
          ]),
        ),
      ),
    );
  }
}

class PerfilPantalla extends StatelessWidget {
  const PerfilPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const BarraSuperior('Mis datos'),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
              Campo('Nombre y apellido', valorInicial: estado.nombre, icono: LucideIcons.user),
              const SizedBox(height: 16),
              Campo('Correo electrónico', valorInicial: estado.correo, icono: LucideIcons.mail, teclado: TextInputType.emailAddress),
              const SizedBox(height: 16),
              Campo('Teléfono', valorInicial: '+56 9 1234 5678', icono: LucideIcons.phone, teclado: TextInputType.phone),
              const SizedBox(height: 22),
              Boton('Guardar cambios', onTap: () {
                Navigator.of(context).maybePop();
                avisoGeneral(context, 'Guardamos tus cambios');
              }),
              const SizedBox(height: 30),
              Text('Cambiar contraseña', style: T.titulo3),
              const SizedBox(height: 14),
              const Campo('Contraseña actual', clave: true, icono: LucideIcons.lock),
              const SizedBox(height: 16),
              const Campo('Contraseña nueva', clave: true, icono: LucideIcons.lockKeyhole, ayuda: 'Mínimo 8 caracteres.'),
              const SizedBox(height: 22),
              Boton('Cambiar contraseña', estilo: EstiloBoton.contorno, onTap: () => avisoGeneral(context, 'Tu contraseña se actualizó')),
            ]),
          ),
        ]),
      ),
    );
  }
}
