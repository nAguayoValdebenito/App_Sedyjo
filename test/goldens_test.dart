import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedyjo_app/app/datos.dart';
import 'package:sedyjo_app/app/tema.dart';
import 'package:sedyjo_app/pantallas/carrito.dart';
import 'package:sedyjo_app/pantallas/checkout.dart';
import 'package:sedyjo_app/pantallas/producto.dart';
import 'package:sedyjo_app/pantallas/shell.dart';

/// Pruebas de imagen (golden): si una pantalla cambia de aspecto, la prueba falla y muestra la diferencia.
/// Para aceptar un cambio a propósito: `flutter test --update-goldens test/goldens_test.dart`.
/// Las imágenes de referencia viven en `test/goldens/` y se generan con las fuentes reales de la app.
Future<void> cargarFuentes() async {
  for (final f in const [('Figtree', 'assets/fonts/Figtree.ttf'), ('Bricolage', 'assets/fonts/Bricolage.ttf')]) {
    final cargador = FontLoader(f.$1)..addFont(rootBundle.load(f.$2));
    await cargador.load();
  }
  // Los íconos Lucide vienen de un paquete: se cargan con el nombre que usa el motor.
  final iconos = FontLoader('packages/lucide_icons_flutter/Lucide')..addFont(rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'));
  await iconos.load();
}

/// En pruebas las imágenes se decodifican aparte: se esperan para que el golden las muestre.
Future<void> esperarImagenes(WidgetTester t) async {
  await t.runAsync(() async {
    for (final e in find.byType(Image).evaluate().toList()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await t.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await cargarFuentes();
    await Catalogo.cargar();
  });

  setUp(() {
    estado.cerrarSesion();
    estado.relampagoSilenciadoHoy = true;
    estado.cargarCarritoDeEjemplo();
    estado.favoritos.clear();
    estado.irAPestana(0);
  });

  final pantallas = <String, Widget Function()>{
    'inicio': () => const Shell(),
    'ficha': () => ProductoPantalla(Catalogo.porId(4)),
    'carrito': () => const _EnShell(pestana: 3),
    'pago': () => const CheckoutPantalla(),
  };

  for (final oscuro in [false, true]) {
    for (final e in pantallas.entries) {
      final nombre = '${e.key}_${oscuro ? 'oscuro' : 'claro'}';
      testWidgets('golden $nombre', (t) async {
        C.oscuro = oscuro;
        addTearDown(() => C.oscuro = false);
        t.view.physicalSize = const Size(400, 840);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, theme: construirTema(), home: e.value()));
        for (var i = 0; i < 8; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        await esperarImagenes(t);
        await esperarImagenes(t);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$nombre.png'));
        await t.pumpWidget(const SizedBox());
      });
    }
  }
}

/// Abre la barra de navegación en una pestaña concreta.
class _EnShell extends StatelessWidget {
  const _EnShell({required this.pestana});
  final int pestana;

  @override
  Widget build(BuildContext context) {
    estado.irAPestana(pestana);
    return const Shell();
  }
}

// Evita un aviso de importación sin uso si la pantalla de carrito se usa directamente en el futuro.
// ignore: unused_element
Widget _carrito() => const CarritoPestana();
