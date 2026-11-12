import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app/datos.dart';
import 'app/tema.dart';
import 'pantallas/auth.dart';
import 'pantallas/avisos.dart';
import 'pantallas/ayuda.dart';
import 'pantallas/bienvenida.dart';
import 'pantallas/checkout.dart';
import 'pantallas/pago_resultado.dart';
import 'pantallas/cuenta.dart';
import 'pantallas/direccion.dart';
import 'pantallas/pedidos.dart';
import 'pantallas/producto.dart';
import 'pantallas/shell.dart';
import 'pantallas/splash.dart';
import 'ui/banners.dart';

final navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lo mínimo antes del primer cuadro: saber si es la primera vez (decide qué carga se ve).
  await Memoria.cargar();
  Memoria.empezarAGuardar();
  // El catálogo se lee mientras se ve la pantalla de carga; esta no avanza hasta que termina.
  runApp(SedyjoApp(carga: Catalogo.cargar()));
}

class SedyjoApp extends StatefulWidget {
  const SedyjoApp({super.key, this.carga});

  /// Trabajo real en curso al abrir la app (la pantalla de carga lo espera).
  final Future<void>? carga;

  @override
  State<SedyjoApp> createState() => _SedyjoAppState();
}

class _SedyjoAppState extends State<SedyjoApp> with WidgetsBindingObserver {
  bool _noche = false;

  bool _calcularNoche() {
    final sistema = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    return switch (estado.modoTema) {
      ModoTema.oscuro => true,
      ModoTema.claro => false,
      ModoTema.auto => sistema,
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _noche = _calcularNoche();
    C.oscuro = _noche;
    estado.addListener(_alCambiarEstado);
  }

  @override
  void didChangePlatformBrightness() => _alCambiarEstado();

  /// Al pasar a segundo plano (o cerrarse) se guarda de inmediato lo último que hizo la persona.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estadoCiclo) {
    if (estadoCiclo == AppLifecycleState.paused || estadoCiclo == AppLifecycleState.inactive || estadoCiclo == AppLifecycleState.detached) {
      Memoria.guardarYa();
    }
  }

  /// El modo se resuelve antes de construir las pantallas; si cambia, se reconstruye todo sin perder la navegación.
  void _alCambiarEstado() {
    final nueva = _calcularNoche();
    if (nueva == _noche) return;
    _noche = nueva;
    C.oscuro = nueva;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => reconstruirTodo());
  }

  @override
  void dispose() {
    estado.removeListener(_alCambiarEstado);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comercial Sedyjo',
      debugShowCheckedModeBanner: false,
      navigatorKey: navKey,
      theme: construirTema(),
      home: SplashPantalla(carga: widget.carga),
      builder: (context, child) => ListenableBuilder(
        listenable: estado,
        builder: (context, _) => _MarcoMaqueta(child: child!),
      ),
    );
  }
}

/// En pantallas anchas muestra la app dentro de un celular con un panel para saltar entre vistas;
/// en un celular real ocupa toda la pantalla.
class _MarcoMaqueta extends StatelessWidget {
  const _MarcoMaqueta({required this.child});
  final Widget child;

  static const double _ancho = 400;
  static const double _alto = 840;
  static const double _anchoMaximo = 840;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sistema = mq.textScaler.scale(10) / 10;
    // Teléfono, o tableta/escritorio reales (no la maqueta en un navegador): pantalla completa con un ancho máximo
    // centrado, para que las pantallas no se estiren sin fin.
    if (mq.size.width < 600 || !kIsWeb) {
      final ancho = mq.size.width;
      return MediaQuery(
        data: mq.copyWith(textScaler: TextScaler.linear(sistema * estado.escalaTexto)),
        child: ancho <= _anchoMaximo
            ? child
            : ColoredBox(color: C.fondo, child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: _anchoMaximo), child: child))),
      );
    }
    final telefono = MediaQuery(
      data: mq.copyWith(
        size: const Size(_ancho, _alto),
        padding: const EdgeInsets.only(top: 36, bottom: Esp.x4),
        viewPadding: const EdgeInsets.only(top: 36, bottom: Esp.x4),
        textScaler: TextScaler.linear(estado.escalaTexto),
        disableAnimations: estado.reducirMovimiento,
      ),
      child: Stack(children: [
        Positioned.fill(child: child),
        const Positioned(left: 0, right: 0, top: 0, height: 36, child: IgnorePointer(child: _BarraEstado())),
        Positioned(
          left: 0,
          right: 0,
          bottom: 6,
          child: IgnorePointer(
            child: Center(child: Container(width: 128, height: 5, decoration: BoxDecoration(color: C.tinta.withValues(alpha: .75), borderRadius: BorderRadius.circular(3)))),
          ),
        ),
      ]),
    );

    final carcasa = Container(
      width: _ancho + 20,
      height: _alto + 20,
      padding: const EdgeInsets.all(Esp.x3),
      decoration: BoxDecoration(
        color: C.negro,
        borderRadius: BorderRadius.circular(54),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .28), blurRadius: 40, offset: const Offset(0, 22))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: SizedBox(width: _ancho, height: _alto, child: telefono),
      ),
    );

    // Con ?cliente=1 se oculta el panel de revisión y solo se ve el celular (para mostrar la maqueta).
    final panel = mq.size.width >= 920 && Uri.base.queryParameters['cliente'] != '1';
    return Material(
      color: C.oscuro ? const Color(0xFF0A0F0C) : const Color(0xFFE6EEEA),
      child: Row(children: [
        if (panel) const SizedBox(width: 312, child: _PanelVistas()),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(Esp.x4),
              child: FittedBox(fit: BoxFit.contain, child: carcasa),
            ),
          ),
        ),
        if (panel) const SizedBox(width: Esp.x6),
      ]),
    );
  }
}

class _BarraEstado extends StatelessWidget {
  const _BarraEstado();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Esp.x8, Esp.x2, Esp.x6, 0),
      child: Row(children: [
        Text('9:41', style: T.etiqueta.copyWith(fontSize: 15, color: C.tinta)),
        const Spacer(),
        Icon(LucideIcons.signal, size: 15, color: C.tinta),
        const SizedBox(width: 5),
        Icon(LucideIcons.wifi, size: 15, color: C.tinta),
        const SizedBox(width: 5),
        Icon(LucideIcons.batteryFull, size: Ico.s, color: C.tinta),
      ]),
    );
  }
}

/// Panel de la maqueta: saltar a cualquier vista y probar sesión y tamaño de letra.
class _PanelVistas extends StatelessWidget {
  const _PanelVistas();

  NavigatorState get _nav => navKey.currentState!;

  void _empujar(Widget w) => _nav.push(MaterialPageRoute(builder: (_) => w));

  void _pestana(int i) {
    if (estado.carrito.isEmpty) estado.cargarCarritoDeEjemplo();
    _nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const Shell()), (r) => false);
    estado.irAPestana(i);
  }

  void _requiereSesion() {
    if (!estado.conSesion) estado.iniciarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final grupos = <(String, List<(String, VoidCallback)>)>[
      ('Entrada', [
        ('Pantalla de carga (primera vez, con canasta)', () => _nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SplashPantalla(completa: true)), (r) => false)),
        ('Pantalla de carga (lenta, 16 s)', () => _nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SplashPantalla(duracion: Duration(seconds: 16))), (r) => false)),
        ('Pantalla de carga (regreso, breve)', () => _nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SplashPantalla(completa: false)), (r) => false)),
        ('Bienvenida', () => _nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const BienvenidaPantalla()), (r) => false)),
        ('Ingresar', () => _empujar(const IngresarPantalla())),
        ('Crear cuenta', () => _empujar(const RegistroPantalla())),
        ('Recuperar contraseña', () => _empujar(const RecuperarPantalla())),
        ('Sin conexión', () => _empujar(const SinConexionPantalla())),
        ('Sesión expirada', () => _empujar(const SesionExpiradaPantalla())),
      ]),
      ('Tienda', [
        ('Inicio', () => _pestana(0)),
        ('Categorías', () => _pestana(1)),
        ('Ofertas', () => _pestana(2)),
        ('Ficha de producto', () => _empujar(ProductoPantalla(Catalogo.porId(4)))),
        ('Ficha con foto en uso', () => _empujar(ProductoPantalla(Catalogo.porId(2)))),
        ('Producto agotado', () => _empujar(ProductoPantalla(Catalogo.porId(28)))),
        ('Oferta relámpago', () {
          _pestana(0);
          Future.delayed(const Duration(milliseconds: 400), mostrarRelampago);
        }),
      ]),
      ('Carga de productos', [
        ('Ver esqueletos de carga', () {
          _pestana(0);
          Catalogo.probarCargaInicial();
        }),
        ('Ver error de carga (sin red)', () {
          _pestana(0);
          estado.cambiarSimulacionRed(SimulacionRed.error);
          Catalogo.probarCargaInicial();
        }),
        ('Volver a red normal y reintentar', () {
          estado.cambiarSimulacionRed(SimulacionRed.normal);
          Catalogo.recargar();
        }),
      ]),
      ('Compra', [
        ('Carrito', () => _pestana(3)),
        ('Pagar (datos)', () {
          if (estado.carrito.isEmpty) estado.cargarCarritoDeEjemplo();
          _empujar(const CheckoutPantalla());
        }),
        ('Compra exitosa', () => _empujar(const ExitoPantalla(numero: 'SED-1043', total: 18580, correo: 'maria.gonzalez@correo.cl'))),
        ('Error de pago', () => _empujar(const ErrorPagoPantalla())),
        ('Seguir pedido (invitado)', () => _empujar(const SeguimientoPantalla())),
        ('Elegir dirección de entrega', () => _empujar(const ElegirDireccionPantalla())),
        ('Fuera de zona de despacho', () => _empujar(const FueraDeZonaPantalla())),
      ]),
      ('Mi cuenta', [
        ('Cuenta', () => _pestana(4)),
        ('Mis pedidos', () {
          _requiereSesion();
          _empujar(const PedidosPantalla());
        }),
        ('Detalle de pedido', () {
          _requiereSesion();
          _empujar(DetallePedidoPantalla(estado.pedidos.first));
        }),
        ('Direcciones', () {
          _requiereSesion();
          _empujar(const DireccionesPantalla());
        }),
        ('Mis datos', () {
          _requiereSesion();
          _empujar(const PerfilPantalla());
        }),
        ('Avisos y ofertas', () => _empujar(const AvisosPantalla())),
        ('Ayuda', () => _empujar(const AyudaPantalla())),
      ]),
    ];

    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) => Material(
        color: Colors.transparent,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Esp.x6, Esp.x8, Esp.x3, Esp.x8),
          children: [
            Row(children: [
              ClipOval(child: Image.asset('assets/img/logo.webp', cacheWidth: 130, width: 44, height: 44)),
              const SizedBox(width: Esp.x3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Maqueta de la app', style: T.titulo3.copyWith(fontSize: 18)),
                  Text('Comercial Sedyjo · v0.1', style: T.apoyo.copyWith(fontSize: 14)),
                ]),
              ),
            ]),
            const SizedBox(height: Esp.x4),
            _Interruptor('Sesión iniciada', estado.conSesion, (v) => v ? estado.iniciarSesion() : estado.cerrarSesion()),
            _Interruptor('Primera vez en la app', estado.primeraVez, (v) {
              estado.primeraVez = v;
              estado.refrescar();
            }),
            _Interruptor('Modo oscuro', C.oscuro, (v) => estado.cambiarModoTema(v ? ModoTema.oscuro : ModoTema.claro)),
            _Interruptor('Pago rechazado (simulado)', estado.simulacionPago == SimulacionPago.rechazado, (v) => estado.cambiarSimulacionPago(v ? SimulacionPago.rechazado : SimulacionPago.aprobado)),
            _Interruptor('Red lenta (2,5 s)', estado.simulacionRed == SimulacionRed.lenta, (v) => estado.cambiarSimulacionRed(v ? SimulacionRed.lenta : SimulacionRed.normal)),
            const SizedBox(height: Esp.x2),
            Text('Tamaño de letra', style: T.etiqueta.copyWith(color: C.grisMedio)),
            const SizedBox(height: Esp.x2),
            Row(children: [
              for (final (i, e) in [(1.0, 'Normal'), (1.15, 'Grande'), (1.3, 'Muy grande')].indexed) ...[
                if (i > 0) const SizedBox(width: Esp.x2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => estado.cambiarEscala(e.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: Esp.x2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: estado.escalaTexto == e.$1 ? C.verde : C.superficie,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(e.$2, style: T.etiqueta.copyWith(color: estado.escalaTexto == e.$1 ? Colors.white : C.tinta)),
                    ),
                  ),
                ),
              ],
            ]),
            for (final g in grupos) ...[
              const SizedBox(height: Esp.x4),
              Text(g.$1.toUpperCase(), style: T.etiqueta.copyWith(fontSize: 12, color: C.grisMedio, letterSpacing: .8)),
              const SizedBox(height: Esp.x2),
              for (final v in g.$2)
                GestureDetector(
                  onTap: v.$2,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: Esp.x1),
                    padding: const EdgeInsets.symmetric(horizontal: Esp.x3, vertical: 9),
                    decoration: BoxDecoration(color: C.superficie.withValues(alpha: .7), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Expanded(child: Text(v.$1, style: T.cuerpo.copyWith(fontSize: 15))),
                      Icon(LucideIcons.chevronRight, size: 16, color: C.grisTexto),
                    ]),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Interruptor extends StatelessWidget {
  const _Interruptor(this.texto, this.valor, this.cambia);
  final String texto;
  final bool valor;
  final ValueChanged<bool> cambia;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(texto, style: T.cuerpoFuerte.copyWith(fontSize: 15))),
      Switch(value: valor, onChanged: cambia, activeThumbColor: Colors.white, activeTrackColor: C.verde),
    ]);
  }
}
