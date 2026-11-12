import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedyjo_app/app/datos.dart';
import 'package:sedyjo_app/app/tema.dart';
import 'package:sedyjo_app/ui/revelar.dart';

Widget lista() => MaterialApp(
      theme: construirTema(),
      home: Scaffold(
        body: ListView(children: [
          for (var i = 0; i < 40; i++) Revelar(indice: i % 2, child: SizedBox(height: 100, child: Text('fila $i'))),
        ]),
      ),
    );

/// ¿Sigue envuelto en la animación de aparición (todavía oculto o apareciendo)?
bool envuelto(WidgetTester t, int i) =>
    find.descendant(of: find.byType(Revelar).at(i), matching: find.byType(FadeTransition)).evaluate().isNotEmpty;

void main() {
  setUp(() => estado.reducirMovimiento = false);

  testWidgets('lo que queda fuera de la pantalla espera oculto y aparece al llegar con el desplazamiento', (t) async {
    t.view.physicalSize = const Size(400, 600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(lista());
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));

    // La fila 6 (y = 600) ya está armada por el margen de la lista, pero todavía fuera de la pantalla: oculta.
    int ocultos() => t.allWidgets.whereType<FadeTransition>().where((f) => f.opacity.value == 0).length;
    expect(ocultos(), greaterThan(0), reason: 'lo que está fuera de la pantalla espera oculto');

    await t.drag(find.byType(ListView), const Offset(0, -240));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    // La fila 6 ya entró a la pantalla: se ve entera.
    final alturaPantalla = t.view.physicalSize.height;
    expect(t.getTopLeft(find.text('fila 6')).dy, lessThan(alturaPantalla));
    final visible = find.descendant(of: find.byType(Revelar).at(6), matching: find.byType(FadeTransition));
    expect(visible, findsNothing, reason: 'ya apareció y se dibuja sin envoltura');
    expect(find.text('fila 6'), findsOneWidget);
  });

  testWidgets('con "reducir movimiento" lo que se ve al abrir aparece directo', (t) async {
    t.view.physicalSize = const Size(400, 600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    estado.reducirMovimiento = true;
    await t.pumpWidget(lista());
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(envuelto(t, 0), isFalse);
    expect(envuelto(t, 3), isFalse);
  });

  testWidgets('aparece una sola vez: al volver a subir no se oculta de nuevo', (t) async {
    t.view.physicalSize = const Size(400, 600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(lista());
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.drag(find.byType(ListView), const Offset(0, -900));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.drag(find.byType(ListView), const Offset(0, 900));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    final primero = find.ancestor(of: find.text('fila 0'), matching: find.byType(FadeTransition));
    // Ninguna envoltura de Revelar alrededor de la fila 0 (las que quedan son de la propia pantalla).
    expect(find.descendant(of: find.byType(Revelar).first, matching: find.byType(FadeTransition)), findsNothing);
    expect(primero, findsWidgets);
  });

  testWidgets('el contenido sin desplazamiento se ve de inmediato', (t) async {
    await t.pumpWidget(MaterialApp(theme: construirTema(), home: const Scaffold(body: Revelar(child: Text('suelto')))));
    await t.pump();
    expect(find.descendant(of: find.byType(Revelar), matching: find.byType(FadeTransition)), findsNothing);
    expect(find.text('suelto'), findsOneWidget);
  });
}
