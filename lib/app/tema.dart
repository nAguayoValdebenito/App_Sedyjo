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
  static const azul = Color(0xFF1E4B8F); // solo avisos numéricos (insignia del carrito, punto de novedades) y la categoría Bebidas
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

/// Radios de borde: cuatro valores y la píldora. Controles y etiquetas `s`, tarjetas chicas `m`,
/// tarjetas y paneles `l`, bloques grandes `xl`.
class R {
  static const double s = 12;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 28;
  static const double pildora = 999;
}

/// Tamaños de ícono: tres, para que todo el juego de íconos Lucide tenga el mismo ritmo.
class Ico {
  static const double s = 20; // dentro de texto, botones compactos
  static const double m = 24; // el tamaño normal
  static const double l = 28; // protagonistas (estados, encabezados de tarjeta)
}

/// Escala de espacios (múltiplos de 4). Usar estos valores en vez de números sueltos.
class Esp {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
}

/// Movimiento: cuatro duraciones y dos curvas. Todo pasa por `dur()` para respetar "reducir movimiento".
/// Entrar con `entra` (desacelera), salir con `sale` y en ~70 % del tiempo.
class Mov {
  static const Duration toque = Duration(milliseconds: 120); // presión, ripple
  static const Duration cambio = Duration(milliseconds: 200); // cambios de estado pequeños
  static const Duration pantalla = Duration(milliseconds: 300); // pestañas, hojas, contenedor transformado
  static const Duration enfasis = Duration(milliseconds: 450); // logros y entradas destacadas
  static const Curve entra = Curves.easeOutCubic;
  static const Curve sale = Curves.easeInCubic;
}

/// Escala tipográfica: el cuerpo parte en 17 y los textos de apoyo nunca bajan de 14.
/// Roles: titulo1 30 · titulo2 24 · titulo3 20 · cuerpo 17 · cuerpoM 16 · apoyo 15 · etiqueta 14 · boton 18 · precio 22.
/// Pesos: 800 solo en titulares y precio; 700 en botones y subtítulos; 600 para énfasis de cuerpo y etiquetas.
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
      TextStyle(fontFamily: fuenteTexto, fontSize: 17, height: 1.35, fontWeight: FontWeight.w600, color: C.tinta);
  static TextStyle get cuerpoM =>
      TextStyle(fontFamily: fuenteTexto, fontSize: 16, height: 1.4, fontWeight: FontWeight.w400, color: C.tinta);
  static TextStyle get cuerpoMFuerte =>
      TextStyle(fontFamily: fuenteTexto, fontSize: 16, height: 1.35, fontWeight: FontWeight.w600, color: C.tinta);
  static TextStyle get apoyo =>
      TextStyle(fontFamily: fuenteTexto, fontSize: 15, height: 1.4, fontWeight: FontWeight.w500, color: C.grisTexto);
  static TextStyle get etiqueta =>
      TextStyle(fontFamily: fuenteTexto, fontSize: 14, height: 1.2, fontWeight: FontWeight.w600, color: C.tinta);
  static TextStyle get boton => const TextStyle(
      fontFamily: fuenteTexto, fontSize: 18, height: 1.2, fontWeight: FontWeight.w700, color: Colors.white);
  static TextStyle get precio =>
      TextStyle(fontFamily: fuenteTitulos, fontSize: 22, height: 1.1, fontWeight: FontWeight.w800, color: C.tinta);
}

/// Colores de rol como extensión del tema: los componentes nuevos los leen con `context.col`,
/// así cambian con el modo sin depender de la variable global `C.oscuro`.
@immutable
class ColoresSedyjo extends ThemeExtension<ColoresSedyjo> {
  const ColoresSedyjo({
    required this.fondo,
    required this.superficie,
    required this.verdeSuave,
    required this.grisFondo,
    required this.tinta,
    required this.grisTexto,
    required this.borde,
    required this.bordeControl,
    required this.verdeOscuro,
    required this.azulEnlace,
    required this.error,
  });

  final Color fondo, superficie, verdeSuave, grisFondo, tinta, grisTexto, borde, bordeControl, verdeOscuro, azulEnlace, error;

  /// Toma los valores actuales de `C` (única fuente de la paleta).
  factory ColoresSedyjo.actual() => ColoresSedyjo(
        fondo: C.fondo,
        superficie: C.superficie,
        verdeSuave: C.verdeSuave,
        grisFondo: C.grisFondo,
        tinta: C.tinta,
        grisTexto: C.grisTexto,
        borde: C.borde,
        bordeControl: C.bordeControl,
        verdeOscuro: C.verdeOscuro,
        azulEnlace: C.azulEnlace,
        error: C.error,
      );

  @override
  ColoresSedyjo copyWith({Color? fondo, Color? superficie, Color? verdeSuave, Color? grisFondo, Color? tinta, Color? grisTexto, Color? borde, Color? bordeControl, Color? verdeOscuro, Color? azulEnlace, Color? error}) =>
      ColoresSedyjo(
        fondo: fondo ?? this.fondo,
        superficie: superficie ?? this.superficie,
        verdeSuave: verdeSuave ?? this.verdeSuave,
        grisFondo: grisFondo ?? this.grisFondo,
        tinta: tinta ?? this.tinta,
        grisTexto: grisTexto ?? this.grisTexto,
        borde: borde ?? this.borde,
        bordeControl: bordeControl ?? this.bordeControl,
        verdeOscuro: verdeOscuro ?? this.verdeOscuro,
        azulEnlace: azulEnlace ?? this.azulEnlace,
        error: error ?? this.error,
      );

  @override
  ColoresSedyjo lerp(ThemeExtension<ColoresSedyjo>? other, double t) {
    if (other is! ColoresSedyjo) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return ColoresSedyjo(
      fondo: l(fondo, other.fondo),
      superficie: l(superficie, other.superficie),
      verdeSuave: l(verdeSuave, other.verdeSuave),
      grisFondo: l(grisFondo, other.grisFondo),
      tinta: l(tinta, other.tinta),
      grisTexto: l(grisTexto, other.grisTexto),
      borde: l(borde, other.borde),
      bordeControl: l(bordeControl, other.bordeControl),
      verdeOscuro: l(verdeOscuro, other.verdeOscuro),
      azulEnlace: l(azulEnlace, other.azulEnlace),
      error: l(error, other.error),
    );
  }
}

extension ContextoSedyjo on BuildContext {
  /// Colores de rol del tema actual (claro u oscuro).
  ColoresSedyjo get col => Theme.of(this).extension<ColoresSedyjo>() ?? ColoresSedyjo.actual();
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
  final formaBoton = RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.m));
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: fuenteTexto, bodyColor: C.tinta, displayColor: C.tinta),
    extensions: [ColoresSedyjo.actual()],
    dividerColor: C.borde,
    focusColor: C.azulEnlace.withValues(alpha: .25),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: C.superficie, surfaceTintColor: Colors.transparent),
    // Barra inferior de Material 3 con la marca: indicador de píldora verde suave y etiquetas siempre visibles.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.superficie,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      height: 76,
      indicatorColor: C.verdeSuave,
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(size: 25, color: s.contains(WidgetState.selected) ? C.verdeOscuro : C.grisMedio)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => T.etiqueta.copyWith(
          color: s.contains(WidgetState.selected) ? C.verdeOscuro : C.grisMedio,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600)),
    ),
    // Botones, etiquetas y avisos de Material con los mismos tokens que los componentes propios.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(64, 56), shape: formaBoton, textStyle: T.boton, backgroundColor: C.verde, foregroundColor: Colors.white),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 56), shape: formaBoton, textStyle: T.boton, foregroundColor: C.verdeOscuro, side: BorderSide(color: C.verde, width: 2)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48), shape: formaBoton, textStyle: T.cuerpoMFuerte, foregroundColor: C.azulEnlace),
    ),
    chipTheme: ChipThemeData(
      shape: StadiumBorder(side: BorderSide(color: C.bordeControl, width: 1.5)),
      backgroundColor: C.superficie,
      selectedColor: C.verde,
      checkmarkColor: Colors.white,
      labelStyle: T.cuerpoMFuerte,
      padding: const EdgeInsets.symmetric(horizontal: Esp.x2, vertical: Esp.x3),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.verdeFondo,
      contentTextStyle: T.cuerpoM.copyWith(color: Colors.white),
      actionTextColor: C.verdeMenta,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.m)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.oscuro ? C.grisFondo : C.superficie,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.s), borderSide: BorderSide(color: C.bordeControl, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(R.s), borderSide: BorderSide(color: C.bordeControl, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(R.s), borderSide: BorderSide(color: C.verde, width: 2.5)),
    ),
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
      // Volver predictivo de Android (el gesto de volver muestra la pantalla anterior antes de soltar).
      TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
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
