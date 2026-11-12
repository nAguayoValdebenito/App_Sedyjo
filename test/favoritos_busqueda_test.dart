import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedyjo_app/app/datos.dart';
import 'package:sedyjo_app/app/tema.dart';
import 'package:sedyjo_app/pantallas/categorias.dart';
import 'package:sedyjo_app/pantallas/favoritos.dart';
import 'package:sedyjo_app/ui/componentes.dart';

Widget app(Widget home) => MaterialApp(theme: construirTema(), home: home);

void telefono(WidgetTester t) {
  t.view.physicalSize = const Size(400, 840);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Catalogo.cargar();
  });

  setUp(() {
    estado.favoritos.clear();
    estado.recientes.clear();
  });

  testWidgets('el corazón guarda y quita un favorito, y la pantalla de favoritos lo muestra', (t) async {
    telefono(t);
    final p = Catalogo.porId(7);
    await t.pumpWidget(app(Scaffold(body: Center(child: SizedBox(width: 200, height: 400, child: TarjetaProducto(p))))));
    await t.pump(const Duration(milliseconds: 400));
    expect(estado.favoritos, isEmpty);

    await t.tap(find.byIcon(Icons.favorite_border_rounded), warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 300));
    expect(estado.favoritos, [7]);
    expect(estado.favoritoDe(7).value, isTrue);

    await t.pumpWidget(app(const FavoritosPantalla()));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('1 producto guardado'), findsOneWidget);
    expect(find.textContaining('Leche Chocolate'), findsWidgets);

    estado.alternarFavorito(7);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Aún no tienes favoritos'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  test('los favoritos se guardan y se restauran', () {
    estado.alternarFavorito(4);
    estado.alternarFavorito(12);
    final foto = jsonDecode(jsonEncode(estado.aJson())) as Map<String, dynamic>;
    estado.favoritos.clear();
    estado.restaurar(foto);
    expect(estado.favoritos, [12, 4]);
    estado.favoritos.clear();
  });

  testWidgets('la búsqueda ignora tildes y encuentra por varias palabras', (t) async {
    telefono(t);
    await t.pumpWidget(app(const BuscarPantalla()));
    await t.pump(const Duration(milliseconds: 400));
    await t.enterText(find.byType(TextField), 'te verde');
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('1 resultado'), findsOneWidget, reason: '"te verde" encuentra el Té Verde Sabor Limón sin tilde');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('los resultados se pueden ordenar y filtrar por categoría', (t) async {
    telefono(t);
    await t.pumpWidget(app(const BuscarPantalla()));
    await t.pump(const Duration(milliseconds: 400));
    await t.enterText(find.byType(TextField), 'a');
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Más relevantes'), findsOneWidget);
    expect(find.text('Solo ofertas'), findsOneWidget);
    expect(find.text('Abarrotes'), findsOneWidget, reason: 'chips de categoría cuando hay varias');
    await t.tap(find.text('Abarrotes'), warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 600));
    final n = Catalogo.productos.where((p) => p.categoria == 'Abarrotes' && ('${p.nombre} ${p.categoria} ${p.descripcion}').toLowerCase().contains('a')).length;
    expect(find.text('$n resultados'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
