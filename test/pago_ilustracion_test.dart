import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sedyjo_app/app/tema.dart';
import 'package:sedyjo_app/ui/ilustracion_pago.dart';

Widget app(Widget hijo, {bool oscuro = false}) {
  C.oscuro = oscuro;
  return MaterialApp(theme: construirTema(), home: Scaffold(body: Center(child: hijo)));
}

void main() {
  tearDown(() => C.oscuro = false);

  testWidgets('confirmando: tarjeta con un reloj, sin ningún aviso rojo', (t) async {
    await t.pumpWidget(app(const IlustracionPago(TipoIlustracionPago.confirmando)));
    expect(find.byIcon(LucideIcons.clock), findsOneWidget);
    expect(find.byIcon(LucideIcons.x), findsNothing);
    expect(find.byIcon(LucideIcons.triangleAlert), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('cancelado: tarjeta apagada con una cruz gris, sin reloj ni alerta', (t) async {
    await t.pumpWidget(app(const IlustracionPago(TipoIlustracionPago.cancelado)));
    expect(find.byIcon(LucideIcons.x), findsOneWidget);
    expect(find.byIcon(LucideIcons.clock), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('mide lo mismo que las otras ilustraciones de estado (proporción 600:340) y se escala al ancho pedido', (t) async {
    await t.pumpWidget(app(const IlustracionPago(TipoIlustracionPago.confirmando, ancho: 200)));
    final caja = t.getSize(find.descendant(of: find.byType(IlustracionPago), matching: find.byType(ClipRRect)).first);
    expect(caja.width, 200);
    expect(caja.height, closeTo(200 * 340 / 600, .5));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('se arma sin errores en modo oscuro y con letra grande', (t) async {
    await t.pumpWidget(app(const IlustracionPago(TipoIlustracionPago.cancelado), oscuro: true));
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
