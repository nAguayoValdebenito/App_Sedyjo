import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/componentes.dart';
import 'auth.dart';
import 'direccion.dart';
import 'pago_resultado.dart';
import 'tienda.dart';

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
  final _notas = TextEditingController();
  int _franja = 2;
  bool _retiro = false;
  static const _franjas = ['Por la mañana, de 9:00 a 13:00', 'Por la tarde, de 14:00 a 19:00', 'Cualquier horario'];
  late final _telefono = TextEditingController(text: estado.telefono ?? '');

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [_nombre, _correo, _telefono, _notas]) {
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
    if (!_retiro && _dir == null) return false;
    return true;
  }

  /// Qué falta, en lenguaje simple (se muestra arriba y junto a cada campo).
  List<String> get _faltan {
    if (!_intentado) return const [];
    return [
      if (_nombre.text.trim().isEmpty) 'Tu nombre y apellido',
      if (_errCorreo != null) 'Tu correo, con el formato nombre@correo.cl',
      if (_telefono.text.trim().isEmpty) 'Un teléfono de contacto',
      if (!_retiro && _dir == null) 'La dirección donde recibirás tu compra',
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
    if (!_valido) vibracionError();
    if (_valido) {
      setState(() => _paso = 1);
    }
    _subir(); // si falta algo, el resumen de arriba queda a la vista
  }

  Future<void> _pagar({bool forzarRechazo = false}) async {
    setState(() => _pagando = true);
    final total = estado.subtotal;
    final correo = _correo.text.trim();
    final retiro = _retiro;
    final direccion = retiro ? tienda.direccionCompleta : '${_dir!.calle}, ${_dir!.comuna}';
    final franja = retiro ? tienda.plazo : _franjas[_franja];
    final notas = _notas.text;
    // La pantalla de resultado confirma el pago con un círculo que gira; solo si se aprueba se crea el pedido.
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultadoPagoPantalla(procesar: () async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (forzarRechazo || estado.simulacionPago == SimulacionPago.rechazado) return const ResultadoPago.rechazado();
        final pedido = estado.registrarPedido(correo: correo, direccion: direccion, franja: franja, notas: notas, retiro: retiro);
        return ResultadoPago.aprobado(numero: pedido.numero, total: total, correo: correo, retiro: retiro);
      }),
    ));
    if (mounted) setState(() => _pagando = false);
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
            Padding(padding: const EdgeInsets.fromLTRB(Esp.x5, 0, Esp.x5, Esp.x3), child: _Pasos(_paso)),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x1, Esp.x5, Esp.x6),
                children: _paso == 0 ? _datos(context) : _pago(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x3, Esp.x5, Esp.x3),
              decoration: BoxDecoration(color: C.superficie, border: Border(top: BorderSide(color: C.borde))),
              child: SafeArea(
                top: false,
                child: _paso == 0
                    ? Row(children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Text('Total', style: T.apoyo),
                          Text(clp(estado.subtotal), style: T.titulo2),
                        ]),
                        const SizedBox(width: Esp.x4),
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
      // Resumen corto de lo que se está pagando, para no tener que volver al carrito.
      Padding(
        padding: const EdgeInsets.only(bottom: Esp.x4),
        child: Row(children: [
          Icon(LucideIcons.shoppingBag, size: Ico.s, color: C.verdeOscuro),
          const SizedBox(width: Esp.x2),
          Expanded(
            child: Text(
              '${estado.cantidadCarrito} ${estado.cantidadCarrito == 1 ? 'producto' : 'productos'} · ${estado.despachoGratis ? 'despacho gratis' : 'te faltan ${clp(estado.faltaParaGratis)} para el despacho gratis'}',
              style: T.apoyo,
            ),
          ),
        ]),
      ),
      if (!estado.conSesion)
        Container(
          padding: const EdgeInsets.all(Esp.x4),
          decoration: BoxDecoration(color: C.verdeSuave, borderRadius: BorderRadius.circular(R.l)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(LucideIcons.badgeCheck, color: C.verdeOscuro, size: Ico.m),
              const SizedBox(width: Esp.x3),
              Expanded(child: Text('Estás comprando como invitado', style: T.cuerpoFuerte.copyWith(color: C.verdeProfundo))),
            ]),
            const SizedBox(height: Esp.x2),
            Text('No necesitas cuenta. Si tienes una, ingresa para usar tus direcciones guardadas.', style: T.apoyo.copyWith(color: C.verdeOscuro)),
            const SizedBox(height: Esp.x3),
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
      if (!estado.conSesion) const SizedBox(height: Esp.x6),
      Text('Contacto', style: T.titulo3),
      const SizedBox(height: Esp.x3),
      Campo('Nombre y apellido', controlador: _nombre, autofill: const [AutofillHints.name], mayusculas: TextCapitalization.words, icono: LucideIcons.user, error: _req(_nombre, 'Escribe tu nombre.')),
      const SizedBox(height: Esp.x4),
      Campo('Correo electrónico', controlador: _correo, autofill: const [AutofillHints.email], teclado: TextInputType.emailAddress, icono: LucideIcons.mail, error: _errCorreo, ayuda: 'Aquí te enviamos el comprobante.'),
      const SizedBox(height: Esp.x4),
      Campo('Teléfono celular', controlador: _telefono, autofill: const [AutofillHints.telephoneNumber], teclado: TextInputType.phone, icono: LucideIcons.phone, error: _req(_telefono, 'Escribe un teléfono por si necesitamos llamarte.'), ayuda: 'Ejemplo: +56 9 1234 5678'),
      const SizedBox(height: Esp.x8),
      Text('¿Cómo quieres recibir tu compra?', style: T.titulo3),
      const SizedBox(height: Esp.x3),
      OpcionFila(texto: 'Despacho a domicilio', detalle: 'Llega en 24 a 48 horas', activo: !_retiro, icono: LucideIcons.truck, alTocar: () => setState(() => _retiro = false)),
      const SizedBox(height: Esp.x2),
      OpcionFila(texto: 'Retiro en tienda', detalle: 'Sin costo · ${tienda.plazo.toLowerCase()}', activo: _retiro, icono: LucideIcons.store, alTocar: () => setState(() => _retiro = true)),
      const SizedBox(height: Esp.x4),
      ..._retiro ? _retiroEnTienda() : _domicilio(context),
    ];
  }

  /// Retiro en tienda: dónde es, cuándo está listo y un recado opcional.
  List<Widget> _retiroEnTienda() {
    return [
      const TarjetaTienda(),
      const SizedBox(height: Esp.x4),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(LucideIcons.idCard, size: Ico.s, color: C.verdeOscuro),
        const SizedBox(width: Esp.x2),
        Expanded(child: Text('Al retirar, muestra el número de tu pedido y tu cédula de identidad.', style: T.apoyo)),
      ]),
      const SizedBox(height: Esp.x4),
      Campo('Recado para el local (opcional)', controlador: _notas, icono: LucideIcons.messageSquareText, ayuda: 'Por ejemplo: "Retira mi hermana".', accion: TextInputAction.done),
    ];
  }

  /// Despacho a domicilio: dirección, franja de entrega y recado.
  List<Widget> _domicilio(BuildContext context) {
    return [
      Row(children: [
        Icon(LucideIcons.truck, size: Ico.s, color: C.verdeOscuro),
        const SizedBox(width: Esp.x2),
        Expanded(child: Text('Llega en 24 a 48 horas', style: T.apoyo)),
      ]),
      const SizedBox(height: Esp.x3),
      if (_dir == null)
        Panel(
          borde: _intentado ? C.error : null,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Aún no eliges dónde recibir tu compra.', style: T.cuerpo),
            const SizedBox(height: Esp.x3),
            Boton('Agregar dirección de entrega', icono: LucideIcons.mapPin, onTap: _elegirDireccion),
          ]),
        )
      else
        Panel(
          fondo: C.verdeSuave,
          borde: C.verde,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.mapPin, size: Ico.m, color: C.verdeOscuro),
              const SizedBox(width: Esp.x3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_dir!.alias, style: T.cuerpoFuerte.copyWith(color: C.verdeProfundo)),
                  Text('${_dir!.calle}, ${_dir!.comuna}', style: T.cuerpo.copyWith(color: C.verdeProfundo, fontSize: 16)),
                  if (_dir!.referencia.isNotEmpty) Text('Referencia: ${_dir!.referencia}', style: T.apoyo.copyWith(color: C.verdeOscuro)),
                ]),
              ),
            ]),
            const SizedBox(height: Esp.x3),
            Boton('Cambiar dirección', estilo: EstiloBoton.contorno, alto: 52, onTap: _elegirDireccion),
          ]),
        ),
      const SizedBox(height: Esp.x8),
      Text('¿Cuándo prefieres recibirla?', style: T.titulo3),
      const SizedBox(height: Esp.x3),
      for (final (i, f) in _franjas.indexed) ...[
        OpcionFila(texto: f, activo: _franja == i, icono: i == 2 ? LucideIcons.clock : LucideIcons.calendarClock, alTocar: () => setState(() => _franja = i)),
        const SizedBox(height: Esp.x2),
      ],
      const SizedBox(height: Esp.x3),
      Campo('Recado para quien despacha (opcional)', controlador: _notas, icono: LucideIcons.messageSquareText, ayuda: 'Por ejemplo: "Dejar con el conserje".', accion: TextInputAction.done),
    ];
  }

  List<Widget> _pago(BuildContext context) {
    final lineas = estado.carrito.entries.map((e) => (Catalogo.porId(e.key), e.value)).toList();
    return [
      Text('Tu pedido', style: T.titulo3),
      const SizedBox(height: Esp.x3),
      Panel(
        padding: const EdgeInsets.symmetric(horizontal: Esp.x3, vertical: Esp.x2),
        child: Column(children: [
          for (final (i, l) in lineas.indexed) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Esp.x3),
              child: Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(R.s), child: SizedBox(width: 52, height: 52, child: FotoProducto(l.$1))),
                const SizedBox(width: Esp.x3),
                Expanded(child: Text('${l.$2} × ${l.$1.nombre}', maxLines: 2, overflow: TextOverflow.ellipsis, style: T.cuerpoM)),
                const SizedBox(width: Esp.x2),
                Text(clp(l.$1.precioFinal * l.$2), style: T.cuerpoMFuerte),
              ]),
            ),
            if (i < lineas.length - 1) const Divider(height: 1),
          ],
        ]),
      ),
      const SizedBox(height: Esp.x3),
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
      const SizedBox(height: Esp.x6),
      Text('Forma de pago', style: T.titulo3),
      const SizedBox(height: Esp.x3),
      Container(
        padding: const EdgeInsets.all(Esp.x4),
        decoration: BoxDecoration(color: C.verdeSuave, borderRadius: BorderRadius.circular(R.l), border: Border.all(color: C.verde, width: 2)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(LucideIcons.circleCheck, color: C.verde, size: Ico.l),
          const SizedBox(width: Esp.x3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Webpay', style: T.cuerpoFuerte),
              const SizedBox(height: 2),
              Text('Pagas con tarjeta de débito o crédito en el sitio seguro de Transbank. No guardamos los datos de tu tarjeta.', style: T.apoyo.copyWith(color: C.verdeProfundo)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: Esp.x4),
      Row(children: [
        const Icon(LucideIcons.shieldCheck, size: Ico.s, color: C.verde),
        const SizedBox(width: Esp.x2),
        Expanded(child: Text('Pago protegido. Podrás volver si algo falla.', style: T.apoyo)),
      ]),
      // TEMPORAL: botón solo para probar la pantalla de pago rechazado. Se quita cuando termine la revisión.
      const SizedBox(height: Esp.x6),
      Panel(
        borde: C.bordeControl,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Solo para pruebas', style: T.etiqueta.copyWith(color: C.grisMedio)),
          const SizedBox(height: Esp.x2),
          Boton('Probar pago rechazado', icono: LucideIcons.circleX, estilo: EstiloBoton.peligro, alto: 52, onTap: _pagando ? null : () => _pagar(forzarRechazo: true)),
        ]),
      ),
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
        padding: const EdgeInsets.symmetric(vertical: Esp.x2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(a, style: fuerte ? T.titulo3 : T.cuerpo)),
          const SizedBox(width: Esp.x3),
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
                    ? const Icon(LucideIcons.check, color: Colors.white, size: Ico.m)
                    : Text('${i + 1}', style: T.cuerpoFuerte.copyWith(color: activo ? Colors.white : C.grisMedio)),
              ),
            ),
            const SizedBox(height: Esp.x2),
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
