import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Paleta de Comercial Sedyjo, tomada de `src/styles/tokens.css` de la web.
///
/// Dos grupos:
/// - **Marca fija** (`verde`, `rojo`, `oro`…): iguales en claro y oscuro.
/// - **Roles** (`fondo`, `superficie`, `tinta`, `verdeOscuro`…): cambian con el modo. Usar siempre el rol,
///   nunca el hex, para que el modo oscuro funcione en todas las pantallas.
///
/// Dorado y morado solo sobre fondo negro (banners secundarios, oferta relámpago).
class C {
  /// `true` cuando la app está en modo oscuro (lo decide `SedyjoApp` según el ajuste del usuario o el sistema).
  static bool oscuro = false;
  static Color _m(Color claro, Color noche) => oscuro ? noche : claro;

  // ── Marca fija ──────────────────────────────────────────────
  static const verde = Color(0xFF2E7D5B); // botones, activos: 5,0:1 con texto blanco
  static const verdeBanner = Color(0xFF1F5C42); // relleno de banners
  static const verdeFondo = Color(0xFF12372A); // pantalla de carga, avisos
  static const verdeClaro = Color(0xFF9CC9B3);
  static const verdeMenta = Color(0xFF7FD1A8);
  static const verdePalido = Color(0xFFCFE8DB);
  static const azul = Color(0xFF1E4B8F); // rellenos (tarjeta de ayuda, insignia del carrito)
  static const azulOscuro = Color(0xFF16386D);
  static const rojo = Color(0xFFC73B3B); // solo descuentos
  static const oro = Color(0xFFFFC83D);
  static const morado = Color(0xFFD15BFF);
  static const negro = Color(0xFF0B0B0F);
  static const carbon = Color(0xFF17171F);
  static const carbonBorde = Color(0xFF2A2A36);

  // ── Roles que cambian con el modo ───────────────────────────
  static Color get fondo => _m(const Color(0xFFFFFFFF), const Color(0xFF0F1613));
  static Color get superficie => _m(const Color(0xFFFFFFFF), const Color(0xFF17211C));
  static Color get verdeSuave => _m(const Color(0xFFE8F4EE), const Color(0xFF1D2C25));
  static Color get grisFondo => _m(const Color(0xFFF3F5F4), const Color(0xFF1B2620));
  static Color get verdeOscuro => _m(const Color(0xFF1F5C42), const Color(0xFF8FD9B3)); // texto/íconos de acento
  static Color get verdeProfundo => _m(const Color(0xFF12372A), const Color(0xFFCFE8DB)); // texto fuerte sobre verdeSuave
  static Color get azulEnlace => _m(const Color(0xFF1E4B8F), const Color(0xFF9DBDF5));
  static Color get error => _m(const Color(0xFFB42318), const Color(0xFFFF9C93));
  static Color get tinta => _m(const Color(0xFF1F2933), const Color(0xFFE9F0EC));
  static Color get grisMedio => _m(const Color(0xFF4B5563), const Color(0xFFBAC7C0));
  static Color get grisTexto => _m(const Color(0xFF566070), const Color(0xFFA3B2AA));
  static Color get borde => _m(const Color(0xFFD9DEE3), const Color(0xFF2C3A33));
  static Color get bordeControl => _m(const Color(0xFF8A949E), const Color(0xFF7F8F87)); // ≥3:1 (controles)
}

/// Fondos pastel por categoría (en la web vienen de los datos del producto).
Color fondoCategoria(String categoria) {
  const claro = {
    'Abarrotes': Color(0xFFFBEFD5),
    'Bebidas': Color(0xFFDCEBF7),
    'Confitería': Color(0xFFF6DCE4),
    'Galletas y Snacks': Color(0xFFF3E3CC),
    'Té e Infusiones': Color(0xFFDDEFDF),
  };
  const noche = {
    'Abarrotes': Color(0xFF2E2819),
    'Bebidas': Color(0xFF1B2B38),
    'Confitería': Color(0xFF35212B),
    'Galletas y Snacks': Color(0xFF31281A),
    'Té e Infusiones': Color(0xFF1E3024),
  };
  return (C.oscuro ? noche : claro)[categoria] ?? C.verdeSuave;
}

const String fuenteTitulos = 'Bricolage';
const String fuenteTexto = 'Figtree';

/// Escala tipográfica: el cuerpo parte en 17 y los textos de apoyo nunca bajan de 14.
/// Roles: titulo1 30 · titulo2 24 · titulo3 20 · cuerpo 17 · apoyo 15 · etiqueta 14 · precio 22.
class T {
  static TextStyle get titulo1 =>
      TextStyle(fontFamily: fuenteTitulos, fontSize: 30, height: 1.12, fontWeight: FontWeight.w800, color: C.tinta);
  static TextStyle get titulo2 =>
      TextStyle(fontFamily: fuenteTitulos, fontSize: 24, height: 1.18, fontWeight: FontWeight.w800, color: C.tinta);
  static TextStyle get titulo3 =>
      TextStyle(fontFamily: fuenteTitulos, fontSize: 20, height: 1.2, fontWeight: FontWeight.w700, color: C.tinta);
  static TextStyle get cuerpo =>
      TextStyle(fontFamily: fuenteTexto, fontSize: 17, height: 1.45, fontWeight: FontWeight.w400, color: C.tinta);
  static TextStyle get cuerpoFuerte =>
      TextStyle(fontFamily: fuenteTexto, fontSize: 17, height: 1.35, fontWeight: FontWeight.w700, color: C.tinta);
  static TextStyle get apoyo =>
      TextStyle(fontFamily: fuenteTexto, fontSize: 15, height: 1.4, fontWeight: FontWeight.w500, color: C.grisTexto);
  static TextStyle get etiqueta =>
      TextStyle(fontFamily: fuenteTexto, fontSize: 14, height: 1.2, fontWeight: FontWeight.w700, color: C.tinta);
  static TextStyle get boton => const TextStyle(
      fontFamily: fuenteTexto, fontSize: 18, height: 1.2, fontWeight: FontWeight.w800, color: Colors.white);
  static TextStyle get precio =>
      TextStyle(fontFamily: fuenteTitulos, fontSize: 22, height: 1.1, fontWeight: FontWeight.w800, color: C.tinta);
}

ThemeData construirTema() {
  final noche = C.oscuro;
  final esquema = ColorScheme.fromSeed(
    seedColor: C.verde,
    brightness: noche ? Brightness.dark : Brightness.light,
    primary: noche ? C.verdeMenta : C.verde,
    surface: C.superficie,
    error: C.error,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: noche ? Brightness.dark : Brightness.light,
    colorScheme: esquema,
    scaffoldBackgroundColor: C.fondo,
    canvasColor: C.fondo,
    fontFamily: fuenteTexto,
    splashFactory: InkSparkle.splashFactory,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: fuenteTexto, bodyColor: C.tinta, displayColor: C.tinta),
    dividerColor: C.borde,
    focusColor: C.azulEnlace.withValues(alpha: .25),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: C.superficie, surfaceTintColor: Colors.transparent),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.transparent : C.bordeControl),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.verde : C.grisFondo),
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : C.bordeControl),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: noche ? C.verdeMenta : C.verde,
      selectionColor: C.verdeMenta.withValues(alpha: .45),
      selectionHandleColor: noche ? C.verdeMenta : C.verde,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}

/// Marca todos los widgets para reconstruirse (al cambiar de modo claro/oscuro sin perder la navegación).
void reconstruirTodo() {
  void visita(Element e) {
    e.markNeedsBuild();
    e.visitChildren(visita);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visita);
}
