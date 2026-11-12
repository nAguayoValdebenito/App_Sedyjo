import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tema.dart';

part 'estado/busqueda_pedidos_cuenta.dart';
part 'estado/carrito.dart';
part 'estado/favoritos.dart';
part 'estado/navegacion_preferencias.dart';
part 'estado/persistencia.dart';

const int despachoGratisDesde = 39990;
const String telefonoVisible = '+56 9 6642 3803';

/// Local de retiro de Comercial Sedyjo (dirección de ejemplo, inventada para la maqueta).
class TiendaRetiro {
  const TiendaRetiro();
  String get nombre => 'Local de retiro Sedyjo';
  String get calle => 'Av. Collao 2480';
  String get comuna => 'Concepción';
  String get direccionCompleta => '$calle, $comuna';
  String get horario => 'Lunes a viernes de 9:30 a 18:30\nSábado de 10:00 a 14:00';
  String get horarioCorto => 'Lun a vie 9:30–18:30 · Sáb 10:00–14:00';
  String get plazo => 'Listo para retirar en 2 horas hábiles';
  String get referencia => 'Frente al paradero Collao, portón verde con el logo de Sedyjo.';
  double get latitud => -36.8056;
  double get longitud => -73.0332;
}

const tienda = TiendaRetiro();

String clp(int valor) {
  final s = valor.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${valor < 0 ? '-' : ''}\$${b.toString()}';
}

class Producto {
  Producto({
    required this.id,
    required this.slug,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.precio,
    required this.oferta,
    required this.descuento,
    required this.imagen,
    required this.stock,
  });

  final int id;
  final String slug;
  final String nombre;
  final String descripcion;
  final String categoria;
  final int precio;
  final int? oferta;
  final int? descuento;
  final String? imagen;
  final int stock;

  int get precioFinal => oferta ?? precio;
  bool get agotado => stock <= 0;

  /// Foto "en uso" (segunda imagen de la ficha), solo para algunos productos.
  String? get fotoUso {
    const mapa = {
      'coca-cola-sabor-original-591-ml': 'bebida-con-hielo',
      'chocolate-costa-rama-de-leche-115-g': 'chocolates-partidos',
      'galletas-costa-chocolate-140-g': 'galletas-para-compartir',
      'jugo-guallarauco-mango-1-l': 'jugo-de-mango',
      'spaghetti-carozzi-400-g': 'spaghetti-preparado',
      'te-ceylan-premium-supremo-40-g': 'taza-de-te',
    };
    final n = mapa[slug];
    return n == null ? null : 'assets/img/uso/$n.webp';
  }
  bool get enOferta => oferta != null && descuento != null;
  Color get fondo => fondoCategoria(categoria);
  String? get ruta => imagen == null ? null : 'assets/img/p/$imagen';

  factory Producto.desdeJson(Map<String, dynamic> j) => Producto(
        id: j['id'] as int,
        slug: j['slug'] as String,
        nombre: j['name'] as String,
        descripcion: (j['desc'] as String?) ?? '',
        categoria: j['cat'] as String,
        precio: j['price'] as int,
        oferta: j['offer'] as int?,
        descuento: j['pct'] as int?,
        imagen: j['img'] as String?,
        stock: (j['stock'] as int?) ?? 0,
      );
}

class Categoria {
  const Categoria(this.nombre, this.icono, this.archivo);
  final String nombre;
  final IconData icono;

  /// Ilustración transparente de la categoría en `assets/img/cat/`.
  final String archivo;
  Color get color => fondoCategoria(nombre);
  String get ruta => 'assets/img/cat/$archivo';
}

const categorias = <Categoria>[
  Categoria('Abarrotes', LucideIcons.wheat, 'abarrotes.webp'),
  Categoria('Bebidas', LucideIcons.cupSoda, 'bebidas.webp'),
  Categoria('Confitería', LucideIcons.candy, 'confiteria.webp'),
  Categoria('Galletas y Snacks', LucideIcons.cookie, 'galletas-snacks.webp'),
  Categoria('Té e Infusiones', LucideIcons.coffee, 'te-infusiones.webp'),
];

/// Estado de carga del catálogo. Hoy los datos son locales; con servidor, cada sección muestra
/// esqueletos mientras `cargando`, y un reintento si `error`.
enum Carga { cargando, listo, error }

class Catalogo {
  static List<Producto> productos = [];
  static final ValueNotifier<Carga> carga = ValueNotifier(Carga.cargando);

  /// Lee el catálogo. No lanza: si falla, deja `carga` en `error` para que la interfaz ofrezca reintentar.
  static Future<void> cargar() async {
    try {
      final texto = await rootBundle.loadString('assets/data/productos.json');
      productos = (jsonDecode(texto) as List)
          .map((e) => Producto.desdeJson(e as Map<String, dynamic>))
          .toList();
      estado.depurarCarrito();
      carga.value = Carga.listo;
    } catch (_) {
      carga.value = Carga.error;
    }
  }

  /// En la maqueta: finge que aún no hay datos (para ver esqueletos y el error de sección).
  static bool forzarVacio = false;

  /// Vuelve a pedir el catálogo (jalar para actualizar o "Reintentar"). La maqueta simula la red según
  /// `estado.simulacionRed`: lenta tarda 2,5 s y error falla. Devuelve si se pudo.
  /// Si ya había datos y falla, los conserva (no se muestra el error de sección).
  static Future<bool> recargar() async {
    final teniaDatos = productos.isNotEmpty && !forzarVacio;
    carga.value = Carga.cargando;
    final espera = switch (estado.simulacionRed) {
      SimulacionRed.lenta => const Duration(milliseconds: 2500),
      SimulacionRed.error => const Duration(milliseconds: 900),
      SimulacionRed.normal => const Duration(milliseconds: 700),
    };
    await Future<void>.delayed(espera);
    if (estado.simulacionRed == SimulacionRed.error) {
      carga.value = teniaDatos ? Carga.listo : Carga.error;
      return false;
    }
    await cargar();
    forzarVacio = false;
    return carga.value == Carga.listo;
  }

  /// Para el panel de la maqueta: repite la primera carga (con esqueletos) con la red simulada actual.
  static Future<void> probarCargaInicial() async {
    forzarVacio = true;
    await recargar();
  }

  static Producto porId(int id) => productos.firstWhere((p) => p.id == id);
  static List<Producto> enOferta() => productos.where((p) => p.enOferta).toList();
  static List<Producto> deCategoria(String c) => productos.where((p) => p.categoria == c).toList();
  static Producto primeroDe(String c) => productos.firstWhere((p) => p.categoria == c && p.imagen != null);
}

/// Cómo responde la "red" en la maqueta (se cambia desde el panel lateral).
enum SimulacionRed { normal, lenta, error }

/// Cómo responde el pago en la maqueta (se cambia desde el panel lateral).
enum SimulacionPago { aprobado, rechazado }

/// Lo que la app recuerda entre aperturas: si ya la abrió, y todo lo que la persona hizo (carrito, sesión,
/// direcciones, pedidos y preferencias). Se guarda solo, poco después de cada cambio.
class Memoria {
  static const _claveVisita = 'ya_abrio';
  static const _claveEstado = 'estado_v1';
  static Timer? _pendiente;

  static Future<void> cargar() async {
    try {
      final p = await SharedPreferences.getInstance();
      estado.primeraVez = !(p.getBool(_claveVisita) ?? false);
      final texto = p.getString(_claveEstado);
      if (texto != null) estado.restaurar(jsonDecode(texto) as Map<String, dynamic>);
    } catch (_) {
      // Sin almacenamiento (pruebas, navegador privado) o datos dañados: se empieza de cero.
    }
  }

  /// Desde aquí, cada cambio de la app se guarda (con una pausa corta para no escribir en cada toque).
  static void empezarAGuardar() => estado.addListener(_programar);

  static void _programar() {
    _pendiente?.cancel();
    _pendiente = Timer(const Duration(milliseconds: 600), guardar);
  }

  /// Guarda ya, sin esperar la pausa: se usa cuando la app pasa a segundo plano o se está cerrando,
  /// para no perder lo último que hizo la persona.
  static Future<void> guardarYa() {
    _pendiente?.cancel();
    return guardar();
  }

  static Future<void> guardar() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_claveEstado, jsonEncode(estado.aJson()));
    } catch (_) {}
  }

  static Future<void> guardarVisita() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_claveVisita, true);
    } catch (_) {}
  }
}

class Direccion {
  Direccion(this.alias, this.calle, this.comuna, this.referencia, {this.principal = false});
  String alias;
  String calle;
  String comuna;
  String referencia;
  bool principal;

  Map<String, dynamic> toJson() => {'alias': alias, 'calle': calle, 'comuna': comuna, 'referencia': referencia, 'principal': principal};

  factory Direccion.desdeJson(Map<String, dynamic> j) =>
      Direccion(j['alias'] as String, j['calle'] as String, j['comuna'] as String, j['referencia'] as String, principal: (j['principal'] as bool?) ?? false);
}

enum EstadoPedido { recibido, preparando, enCamino, entregado }

extension EstadoPedidoX on EstadoPedido {
  /// Con retiro en tienda, "En camino" es "Listo para retirar" y "Entregado" es "Retirado".
  String textoPara(bool retiro) => !retiro
      ? texto
      : switch (this) {
          EstadoPedido.recibido => 'Recibido',
          EstadoPedido.preparando => 'Preparando',
          EstadoPedido.enCamino => 'Listo para retirar',
          EstadoPedido.entregado => 'Retirado',
        };

  String get texto => switch (this) {
        EstadoPedido.recibido => 'Recibido',
        EstadoPedido.preparando => 'Preparando',
        EstadoPedido.enCamino => 'En camino',
        EstadoPedido.entregado => 'Entregado',
      };
}

class Pedido {
  Pedido(this.numero, this.fecha, EstadoPedido estado, this.lineas, this.direccion, {this.correo, this.creado, this.franja, this.notas, this.retiro = false}) : _estado = estado;
  final String numero;
  final String fecha;
  final EstadoPedido _estado;
  final Map<int, int> lineas;
  final String direccion;

  /// Correo con el que se compró (para seguirlo sin cuenta).
  final String? correo;

  /// Cuándo se hizo. Los pedidos hechos en la app avanzan solos con el tiempo; los de ejemplo quedan como están.
  final DateTime? creado;

  /// Franja de entrega elegida y recado para el repartidor (opcionales).
  final String? franja;
  final String? notas;

  /// `true` si se retira en la tienda en vez de recibirse a domicilio.
  final bool retiro;

  /// Recibido al comprar, preparando a los 2 minutos, en camino a los 30 minutos y entregado a las 24 horas.
  EstadoPedido get estado {
    final c = creado;
    if (c == null) return _estado;
    final edad = DateTime.now().difference(c);
    if (edad >= const Duration(hours: 24)) return EstadoPedido.entregado;
    if (edad >= const Duration(minutes: 30)) return EstadoPedido.enCamino;
    if (edad >= const Duration(minutes: 2)) return EstadoPedido.preparando;
    return EstadoPedido.recibido;
  }

  int get total => lineas.entries.fold(0, (a, e) => a + Catalogo.porId(e.key).precioFinal * e.value);

  Map<String, dynamic> toJson() => {
        'numero': numero,
        'fecha': fecha,
        'estado': _estado.index,
        'lineas': lineas.map((k, v) => MapEntry('$k', v)),
        'direccion': direccion,
        'correo': correo,
        'creado': creado?.toIso8601String(),
        'franja': franja,
        'notas': notas,
        'retiro': retiro,
      };

  factory Pedido.desdeJson(Map<String, dynamic> j) => Pedido(
        j['numero'] as String,
        j['fecha'] as String,
        EstadoPedido.values[(j['estado'] as int).clamp(0, EstadoPedido.values.length - 1)],
        (j['lineas'] as Map).map((k, v) => MapEntry(int.parse(k as String), v as int)),
        j['direccion'] as String,
        correo: j['correo'] as String?,
        creado: j['creado'] == null ? null : DateTime.tryParse(j['creado'] as String),
        franja: j['franja'] as String?,
        notas: j['notas'] as String?,
        retiro: (j['retiro'] as bool?) ?? false,
      );
}

/// Estado único de la maqueta: carrito, sesión simulada, tamaño de letra y avisos.
enum ModoTema { auto, claro, oscuro }

/// Estado único de la app, repartido por tema en `lib/app/estado/`: carrito, navegación y preferencias,
/// búsqueda, pedidos, cuenta y persistencia. Cada tema es un `mixin` con su propio código y sus propias pruebas;
/// aquí solo se juntan para que las pantallas sigan escuchando un solo objeto.
class Estado extends ChangeNotifier
    with NavegacionEstado, CarritoEstado, PreferenciasEstado, BusquedaEstado, PedidosEstado, CuentaEstado, FavoritosEstado, PersistenciaEstado {
  /// Las funciones estáticas de un mixin no se heredan: se exponen aquí con el mismo nombre de siempre.
  static String nombreDesdeCorreo(String correo) => CuentaEstado.nombreDesdeCorreo(correo);
  static String nombreCorto(String nombre) => BusquedaEstado.nombreCorto(nombre);
}

final estado = Estado();
