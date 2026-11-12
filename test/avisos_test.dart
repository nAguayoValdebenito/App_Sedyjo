import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedyjo_app/app/datos.dart';
import 'package:sedyjo_app/app/tema.dart';
import 'package:sedyjo_app/pantallas/categorias.dart';
import 'package:sedyjo_app/pantallas/favoritos.dart';
import 'package:sedyjo_app/pantallas/producto.dart';
import 'package:sedyjo_app/pantallas/shell.dart';
import 'package:sedyjo_app/ui/componentes.dart';

/// Los avisos ("Agregaste…", "Quitaste…") deben verse igual en todas las pantallas: abajo, pegados a lo que cierra la
/// pantalla (la barra de pestañas, la barra de compra o el borde), nunca flotando a media altura.
const alto = 840.0;

void telefono(WidgetTester t) {
  t.view.physicalSize = const Size(400, alto);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> esperar(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<double> mostrarAviso(WidgetTester t, Widget pantalla) async {
  await t.pumpWidget(MaterialApp(theme: construirTema(), home: pantalla));
  await esperar(t, 700);
  avisoGeneral(t.element(find.byType(Scaffold).first), 'Agregaste Bebida Crush Orange Lata 350 ml', accion: 'Ver carrito');
  await esperar(t, 700);
  expect(find.byType(SnackBar), findsOneWidget);
  return t.getBottomLeft(find.byType(SnackBar)).dy;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Catalogo.cargar();
  });

  setUp(() {
    estado.relampagoSilenciadoHoy = true;
    estado.consejoInicioVisto = true;
    estado.cargarCarritoDeEjemplo();
    estado.irAPestana(0);
  });

  testWidgets('en la tienda (con barra de pestañas) el aviso queda pegado a la barra', (t) async {
    telefono(t);
    final abajo = await mostrarAviso(t, const Shell());
    final barra = t.getTopLeft(find.byType(NavigationBar)).dy;
    expect(barra - abajo, lessThan(24));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('en la ficha de producto el aviso queda pegado a la barra de compra', (t) async {
    telefono(t);
    final abajo = await mostrarAviso(t, ProductoPantalla(Catalogo.porId(7)));
    final barra = t.getTopLeft(find.textContaining('Agregar ·')).dy; // el botón vive dentro de la barra de compra
    expect(barra - abajo, lessThan(48));
    await t.pumpWidget(const SizedBox());
  });

  for (final e in {
    'el catálogo': () => const CategoriaPantalla(null),
    'la búsqueda': () => const BuscarPantalla(),
    'favoritos': () => const FavoritosPantalla(),
  }.entries) {
    testWidgets('en ${e.key} el aviso queda abajo, junto al borde de la pantalla', (t) async {
      telefono(t);
      final abajo = await mostrarAviso(t, e.value());
      expect(alto - abajo, lessThan(24));
      await t.pumpWidget(const SizedBox());
    });
  }

  testWidgets('todos los avisos miden lo mismo, con acción corta o larga', (t) async {
    telefono(t);
    await t.pumpWidget(MaterialApp(theme: construirTema(), home: const Scaffold(body: SizedBox())));
    final ctx = t.element(find.byType(Scaffold));
    avisoGeneral(ctx, 'Quitaste Arvejas Wasil', accion: 'Deshacer');
    await esperar(t, 700);
    final corto = t.getSize(find.byType(SnackBar)).height;
    avisoGeneral(ctx, 'Agregaste Arvejas Wasil', accion: 'Ver carrito');
    await esperar(t, 900);
    final largo = t.getSize(find.byType(SnackBar)).height;
    expect(largo, corto, reason: 'la acción larga no debe bajar a una segunda línea');
    await t.pumpWidget(const SizedBox());
  });
}
