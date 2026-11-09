import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/componentes.dart';
import 'auth.dart';
import 'direccion.dart';
import 'pedidos.dart';

class CheckoutPantalla extends StatefulWidget {
  const CheckoutPantalla({super.key});

  @override
  State<CheckoutPantalla> createState() => _CheckoutPantallaState();
}

class _CheckoutPantallaState extends State<CheckoutPantalla> {
  int _paso = 0;
  Direccion? _dir = estado.conSesion && estado.direcciones.isNotEmpty ? estado.direcciones.firstWhere((d) => d.principal, orElse: () => estado.direcciones.first) : null;
  bool _intentado = false;
  bool _pagando = false;
  final _scroll = ScrollController();

  late final _nombre = TextEditingController(text: estado.nombre ?? '');
  late final _correo = TextEditingController(text: estado.correo ?? '');
  final _telefono = TextEditingController();

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [_nombre, _correo, _telefono]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(TextEditingController c, String mensaje) => _intentado && c.text.trim().isEmpty ? mensaje : null;
  String? get _errCorreo {
    if (!_intentado) return null;
    final t = _correo.text.trim();
    if (t.isEmpty) return 'Escribe tu correo para enviarte el comprobante.';
    if (!t.contains('@') || !t.contains('.')) return 'Revisa el correo: debe verse como nombre@correo.cl';
    return null;
  }

  bool get _valido {
    if (_nombre.text.trim().isEmpty || _errCorreo != null || _telefono.text.trim().isEmpty) return false;
    if (_dir == null) return false;
    return true;
  }

  /// Qué falta, en lenguaje simple (se muestra arriba y junto a cada campo).
  List<String> get _faltan {
    if (!_intentado) return const [];
    return [
      if (_nombre.text.trim().isEmpty) 'Tu nombre y apellido',
      if (_errCorreo != null) 'Tu correo, con el formato nombre@correo.cl',
      if (_telefono.text.trim().isEmpty) 'Un teléfono de contacto',
      if (_dir == null) 'La dirección donde recibirás tu compra',
    ];
  }

  Future<void> _elegirDireccion() async {
    final r = await Navigator.of(context).push<Direccion>(MaterialPageRoute(builder: (_) => ElegirDireccionPantalla(actual: _dir)));
    if (r != null && mounted) setState(() => _dir = r);
  }

  void _subir() {
    if (_scroll.hasClients) _scroll.animateTo(0, duration: dur(context, 350), curve: Curves.easeOutCubic);
  }

  void _continuar() {
    setState(() => _intentado = true);
    if (_valido) {
      setState(() => _paso = 1);
    }
    _subir(); // si falta algo, el resumen de arriba queda a la vista
  }

  Future<void> _pagar() async {
    setState(() => _pagando = true);
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    final total = estado.subtotal;
    final numero = 'SED-${1043 + estado.pedidos.length - 3}';
    estado.vaciarCarrito();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ExitoPantalla(numero: numero, total: total, correo: _correo.text.trim())));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _paso == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _paso == 1) setState(() => _paso = 0);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            BarraSuperior(_paso == 0 ? 'Tus datos' : 'Pagar', atras: true),
            Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: _Pasos(_paso)),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: _paso == 0 ? _datos(context) : _pago(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(color: C.superficie, border: Border(top: BorderSide(color: C.borde))),
              child: SafeArea(
                top: false,
                child: _paso == 0
                    ? Row(children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Text('Total', style: T.apoyo),
                          Text(clp(estado.subtotal), style: T.titulo2),
                        ]),
                        const SizedBox(width: 18),
                        Expanded(child: Boton('Continuar', iconoDerecha: true, icono: LucideIcons.chevronRight, alto: 62, onTap: _continuar)),
                      ])
                    : Boton(_pagando ? 'Conectando con Webpay…' : 'Pagar ${clp(estado.subtotal)} con Webpay',
                        icono: _pagando ? null : LucideIcons.lock, alto: 62, onTap: _pagando ? null : _pagar),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  List<Widget> _datos(BuildContext context) {
    return [
      ResumenErrores(_faltan),
      if (!estado.conSesion)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: C.verdeSuave, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(LucideIcons.badgeCheck, color: C.verdeOscuro, size: 26),
              const SizedBox(width: 10),
              Expanded(child: Text('Estás comprando como invitado', style: T.cuerpoFuerte.copyWith(color: C.verdeProfundo))),
            ]),
            const SizedBox(height: 6),
            Text('No necesitas cuenta. Si tienes una, ingresa para usar tus direcciones guardadas.', style: T.apoyo.copyWith(color: C.verdeOscuro)),
            const SizedBox(height: 14),
            Boton('Ingresar a mi cuenta', estilo: EstiloBoton.contorno, alto: 52, onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IngresarPantalla()));
              if (!mounted) return;
              setState(() {
                _nombre.text = estado.nombre ?? _nombre.text;
                _correo.text = estado.correo ?? _correo.text;
              });
            }),
          ]),
        ),
      if (!estado.conSesion) const SizedBox(height: 22),
      Text('Contacto', style: T.titulo3),
      const SizedBox(height: 14),
      Campo('Nombre y apellido', controlador: _nombre, autofill: const [AutofillHints.name], mayusculas: TextCapitalization.words, icono: LucideIcons.user, error: _req(_nombre, 'Escribe tu nombre.')),
      const SizedBox(height: 16),
      Campo('Correo electrónico', controlador: _correo, autofill: const [AutofillHints.email], teclado: TextInputType.emailAddress, icono: LucideIcons.mail, error: _errCorreo, ayuda: 'Aquí te enviamos el comprobante.'),
      const SizedBox(height: 16),
      Campo('Teléfono celular', controlador: _telefono, autofill: const [AutofillHints.telephoneNumber], teclado: TextInputType.phone, icono: LucideIcons.phone, error: _req(_telefono, 'Escribe un teléfono por si necesitamos llamarte.'), ayuda: 'Ejemplo: +56 9 1234 5678'),
      const SizedBox(height: 28),
      Text('Entrega a domicilio', style: T.titulo3),
      const SizedBox(height: 6),
      Row(children: [
        Icon(LucideIcons.truck, size: 20, color: C.verdeOscuro),
        const SizedBox(width: 8),
        Expanded(child: Text('Llega en 24 a 48 horas', style: T.apoyo)),
      ]),
      const SizedBox(height: 14),
      if (_dir == null)
        Panel(
          borde: _intentado ? C.error : null,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Aún no eliges dónde recibir tu compra.', style: T.cuerpo),
            const SizedBox(height: 14),
            Boton('Agregar dirección de entrega', icono: LucideIcons.mapPin, onTap: _elegirDireccion),
          ]),
        )
      else
        Panel(
          fondo: C.verdeSuave,
          borde: C.verde,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.mapPin, size: 26, color: C.verdeOscuro),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_dir!.alias, style: T.cuerpoFuerte.copyWith(color: C.verdeProfundo)),
                  Text('${_dir!.calle}, ${_dir!.comuna}', style: T.cuerpo.copyWith(color: C.verdeProfundo, fontSize: 16)),
                  if (_dir!.referencia.isNotEmpty) Text('Referencia: ${_dir!.referencia}', style: T.apoyo.copyWith(color: C.verdeOscuro)),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Boton('Cambiar dirección', estilo: EstiloBoton.contorno, alto: 52, onTap: _elegirDireccion),
          ]),
        ),
    ];
  }

  List<Widget> _pago(BuildContext context) {
    final lineas = estado.carrito.entries.map((e) => (Catalogo.porId(e.key), e.value)).toList();
    return [
      Text('Tu pedido', style: T.titulo3),
      const SizedBox(height: 12),
      Panel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(children: [
          for (final (i, l) in lineas.indexed) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 52, height: 52, child: FotoProducto(l.$1))),
                const SizedBox(width: 12),
                Expanded(child: Text('${l.$2} × ${l.$1.nombre}', maxLines: 2, overflow: TextOverflow.ellipsis, style: T.cuerpo.copyWith(fontSize: 16))),
                const SizedBox(width: 8),
                Text(clp(l.$1.precioFinal * l.$2), style: T.cuerpoFuerte.copyWith(fontSize: 16)),
              ]),
            ),
            if (i < lineas.length - 1) const Divider(height: 1),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      Panel(
        fondo: C.grisFondo,
        borde: C.grisFondo,
        child: Column(children: [
          _FilaTotal('Productos', clp(estado.subtotal + estado.ahorro)),
          if (estado.ahorro > 0) _FilaTotal('Ahorro en ofertas', '-${clp(estado.ahorro)}', color: C.verdeOscuro),
          _FilaTotal('Entrega', estado.despachoGratis ? 'Despacho gratis' : 'Despacho: se confirma al pagar'),
          if (_dir != null) _FilaTotal('Dirección', '${_dir!.calle}, ${_dir!.comuna}'),
          const Divider(height: 22),
          _FilaTotal('Total a pagar', clp(estado.subtotal), fuerte: true),
        ]),
      ),
      const SizedBox(height: 26),
      Text('Forma de pago', style: T.titulo3),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: C.verdeSuave, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.verde, width: 2)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(LucideIcons.circleCheck, color: C.verde, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Webpay', style: T.cuerpoFuerte),
              const SizedBox(height: 2),
              Text('Pagas con tarjeta de débito o crédito en el sitio seguro de Transbank. No guardamos los datos de tu tarjeta.', style: T.apoyo.copyWith(color: C.verdeProfundo)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      Row(children: [
        const Icon(LucideIcons.shieldCheck, size: 20, color: C.verde),
        const SizedBox(width: 8),
        Expanded(child: Text('Pago protegido. Podrás volver si algo falla.', style: T.apoyo)),
      ]),
    ];
  }
}

class _FilaTotal extends StatelessWidget {
  const _FilaTotal(this.a, this.b, {this.fuerte = false, this.color});
  final String a;
  final String b;
  final bool fuerte;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(a, style: fuerte ? T.titulo3 : T.cuerpo)),
          const SizedBox(width: 10),
          Flexible(child: Text(b, textAlign: TextAlign.right, style: (fuerte ? T.titulo3 : T.cuerpoFuerte).copyWith(color: color))),
        ]),
      );
}

class _Pasos extends StatelessWidget {
  const _Pasos(this.paso);
  final int paso;

  @override
  Widget build(BuildContext context) {
    Widget punto(int i, String t) {
      final hecho = paso > i;
      final activo = paso == i;
      return Expanded(
        child: Semantics(
          label: 'Paso ${i + 1} de 2: $t${activo ? ', actual' : hecho ? ', completado' : ''}',
          child: Column(children: [
            AnimatedContainer(
              duration: dur(context, 250),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hecho || activo ? C.verde : C.superficie,
                shape: BoxShape.circle,
                border: Border.all(color: hecho || activo ? C.verde : C.bordeControl, width: 2),
              ),
              child: Center(
                child: hecho
                    ? const Icon(LucideIcons.check, color: Colors.white, size: 22)
                    : Text('${i + 1}', style: T.cuerpoFuerte.copyWith(color: activo ? Colors.white : C.grisMedio)),
              ),
            ),
            const SizedBox(height: 6),
            Text(t, style: T.etiqueta.copyWith(fontSize: 15, color: activo || hecho ? C.verdeOscuro : C.grisMedio)),
          ]),
        ),
      );
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      punto(0, 'Tus datos'),
      Expanded(child: Padding(padding: const EdgeInsets.only(top: 19), child: Container(height: 3, color: paso > 0 ? C.verde : C.borde))),
      punto(1, 'Pago'),
    ]);
  }
}

class ExitoPantalla extends StatefulWidget {
  const ExitoPantalla({super.key, required this.numero, required this.total, required this.correo});
  final String numero;
  final int total;
  final String correo;

  @override
  State<ExitoPantalla> createState() => _ExitoPantallaState();
}

class _ExitoPantallaState extends State<ExitoPantalla> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (sinMovimiento(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(24, 36, 24, 16), children: [
          ScaleTransition(scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut), child: const IlustracionEstado('compra-exitosa.webp', ancho: 280)),
          const SizedBox(height: 28),
          Semantics(liveRegion: true, child: Text('¡Tu compra está lista!', textAlign: TextAlign.center, style: T.titulo1)),
          const SizedBox(height: 10),
          Text('Pagaste ${clp(widget.total)}. Te enviamos el comprobante a ${widget.correo.isEmpty ? 'tu correo' : widget.correo}.',
              textAlign: TextAlign.center, style: T.cuerpo.copyWith(color: C.grisMedio)),
          const SizedBox(height: 24),
          Panel(
            fondo: C.verdeSuave,
            borde: C.verdeSuave,
            child: Column(children: [
              Text('Número de pedido', style: T.apoyo.copyWith(color: C.verdeOscuro)),
              const SizedBox(height: 4),
              Text(widget.numero, style: T.titulo1.copyWith(color: C.verdeProfundo, fontSize: 32, letterSpacing: .5)),
              const SizedBox(height: 6),
              Text('Anótalo: con él puedes seguir tu pedido sin cuenta.', textAlign: TextAlign.center, style: T.apoyo.copyWith(color: C.verdeOscuro)),
            ]),
          ),
          const SizedBox(height: 18),
          Row(children: [
            const Icon(LucideIcons.truck, color: C.verde),
            const SizedBox(width: 10),
            Expanded(child: Text('Llegará en 24 a 48 horas.', style: T.cuerpoFuerte)),
          ]),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 20), child: Column(children: [
          Boton('Seguir mi pedido', icono: LucideIcons.packageCheck, onTap: () {
            Navigator.of(context).popUntil((r) => r.isFirst);
            irA(context, SeguimientoPantalla(numero: widget.numero));
          }),
          const SizedBox(height: 10),
          Boton('Volver al inicio', estilo: EstiloBoton.suave, onTap: () {
            Navigator.of(context).popUntil((r) => r.isFirst);
            estado.irAPestana(0);
          }),
        ])),
        ]),
      ),
    );
  }
}

class ErrorPagoPantalla extends StatelessWidget {
  const ErrorPagoPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(24, 48, 24, 16), children: [
          const IlustracionEstado('pago-no-completado.webp', ancho: 280),
          const SizedBox(height: 26),
          Text('El pago no se completó', textAlign: TextAlign.center, style: T.titulo1),
          const SizedBox(height: 10),
          Text('No te cobramos nada y tus productos siguen en el carrito. Puedes intentarlo de nuevo.', textAlign: TextAlign.center, style: T.cuerpo.copyWith(color: C.grisMedio)),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 20), child: Column(children: [
          Boton('Intentar de nuevo', icono: LucideIcons.refreshCw, onTap: () => Navigator.of(context).maybePop()),
          const SizedBox(height: 10),
          Boton('Llamar para recibir ayuda', estilo: EstiloBoton.contorno, icono: LucideIcons.phone, onTap: () => mostrarContacto(context)),
        ])),
        ]),
      ),
    );
  }
}
