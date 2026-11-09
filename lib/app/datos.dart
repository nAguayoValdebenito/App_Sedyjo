import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'tema.dart';

const int despachoGratisDesde = 49990;
const String telefonoVisible = '+56 9 6642 3803';

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

class Catalogo {
  static List<Producto> productos = [];

  static Future<void> cargar() async {
    final texto = await rootBundle.loadString('assets/data/productos.json');
    productos = (jsonDecode(texto) as List)
        .map((e) => Producto.desdeJson(e as Map<String, dynamic>))
        .toList();
  }

  static Producto porId(int id) => productos.firstWhere((p) => p.id == id);
  static List<Producto> enOferta() => productos.where((p) => p.enOferta).toList();
  static List<Producto> deCategoria(String c) => productos.where((p) => p.categoria == c).toList();
  static Producto primeroDe(String c) => productos.firstWhere((p) => p.categoria == c && p.imagen != null);
}

class Direccion {
  Direccion(this.alias, this.calle, this.comuna, this.referencia, {this.principal = false});
  String alias;
  String calle;
  String comuna;
  String referencia;
  bool principal;
}

enum EstadoPedido { recibido, preparando, enCamino, entregado }

extension EstadoPedidoX on EstadoPedido {
  String get texto => switch (this) {
        EstadoPedido.recibido => 'Recibido',
        EstadoPedido.preparando => 'Preparando',
        EstadoPedido.enCamino => 'En camino',
        EstadoPedido.entregado => 'Entregado',
      };
}

class Pedido {
  Pedido(this.numero, this.fecha, this.estado, this.lineas, this.direccion);
  final String numero;
  final String fecha;
  final EstadoPedido estado;
  final Map<int, int> lineas;
  final String direccion;

  int get total => lineas.entries.fold(0, (a, e) => a + Catalogo.porId(e.key).precioFinal * e.value);
}

/// Estado único de la maqueta: carrito, sesión simulada, tamaño de letra y avisos.
enum ModoTema { auto, claro, oscuro }

class Estado extends ChangeNotifier {
  // Primera vez en la app (la bienvenida cambia el saludo) y saludo tras iniciar sesión
  bool primeraVez = true;
  bool saludoPendiente = false;
  bool saludoEsPrimera = false;
  bool avisosSinLeer = true;
  void marcarAvisosLeidos() {
    if (!avisosSinLeer) return;
    avisosSinLeer = false;
    notifyListeners();
  }
  void marcarVisitado() => primeraVez = false;
  void consumirSaludo() {
    saludoPendiente = false;
    notifyListeners();
  }

  // Apariencia
  ModoTema modoTema = ModoTema.auto;
  void cambiarModoTema(ModoTema m) {
    modoTema = m;
    notifyListeners();
  }

  // Navegación por pestañas
  int pestana = 0;
  void irAPestana(int i) {
    pestana = i;
    notifyListeners();
  }

  void refrescar() => notifyListeners();

  // Carrito
  final Map<int, int> carrito = {};
  int get cantidadCarrito => carrito.values.fold(0, (a, b) => a + b);
  int get subtotal => carrito.entries.fold(0, (a, e) => a + Catalogo.porId(e.key).precioFinal * e.value);
  int get ahorro => carrito.entries.fold(0, (a, e) {
        final p = Catalogo.porId(e.key);
        return a + (p.precio - p.precioFinal) * e.value;
      });
  bool get despachoGratis => subtotal >= despachoGratisDesde;
  int get faltaParaGratis => (despachoGratisDesde - subtotal).clamp(0, despachoGratisDesde);

  void agregar(Producto p, [int n = 1]) {
    carrito[p.id] = (carrito[p.id] ?? 0) + n;
    notifyListeners();
  }

  void cambiarCantidad(Producto p, int n) {
    if (n <= 0) {
      carrito.remove(p.id);
    } else {
      carrito[p.id] = n;
    }
    notifyListeners();
  }

  void vaciarCarrito() {
    carrito.clear();
    notifyListeners();
  }

  // Sesión simulada
  String? nombre;
  String? correo;
  bool get conSesion => nombre != null;
  void iniciarSesion([String n = 'María González', String c = 'maria.gonzalez@correo.cl']) {
    nombre = n;
    correo = c;
    saludoPendiente = true;
    saludoEsPrimera = primeraVez;
    primeraVez = false;
    notifyListeners();
  }

  void cerrarSesion() {
    nombre = null;
    correo = null;
    notifyListeners();
  }

  String get iniciales {
    final partes = (nombre ?? '').trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (partes.isEmpty) return '';
    return (partes.first[0] + (partes.length > 1 ? partes[1][0] : '')).toUpperCase();
  }

  // Accesibilidad
  // ?letra=1.3 en la dirección abre la maqueta con ese tamaño de letra (revisión de diseño).
  double escalaTexto = double.tryParse(Uri.base.queryParameters['letra'] ?? '') ?? 1.0;
  bool reducirMovimiento = false;
  void cambiarEscala(double v) {
    escalaTexto = v;
    notifyListeners();
  }

  void cambiarReducirMovimiento(bool v) {
    reducirMovimiento = v;
    notifyListeners();
  }

  // Búsquedas recientes (las últimas 5)
  final List<String> recientes = ['Arroz', 'Coca-Cola'];
  void agregarReciente(String q) {
    final t = q.trim();
    if (t.isEmpty) return;
    recientes.removeWhere((e) => e.toLowerCase() == t.toLowerCase());
    recientes.insert(0, t);
    if (recientes.length > 5) recientes.removeLast();
    notifyListeners();
  }

  void borrarRecientes() {
    recientes.clear();
    notifyListeners();
  }

  // Avisos
  int minutosOfertas = 10; // 0 = apagado; por defecto activo, el usuario lo cierra o lo apaga
  bool relampagoSilenciadoHoy = false;
  bool pushOfertas = true;
  bool pushPedidos = true;
  void silenciarRelampagoHoy() {
    relampagoSilenciadoHoy = true;
    notifyListeners();
  }

  void ajustarAvisos({int? minutos, bool? ofertas, bool? pedidos}) {
    if (minutos != null) minutosOfertas = minutos;
    if (ofertas != null) pushOfertas = ofertas;
    if (pedidos != null) pushPedidos = pedidos;
    notifyListeners();
  }

  // Datos de la cuenta de ejemplo
  final List<Direccion> direcciones = [
    Direccion('Casa', 'Los Aromos 1234', 'Concepción', 'Portón verde, timbre 2', principal: true),
    Direccion('Casa de mamá', 'Av. Michimalonco 480', 'Concepción', 'Departamento 302'),
  ];

  late final List<Pedido> pedidos = [
    Pedido('SED-1042', '3 nov 2026', EstadoPedido.enCamino, {2: 2, 31: 1, 33: 1, 23: 2}, 'Los Aromos 1234'),
    Pedido('SED-1017', '28 oct 2026', EstadoPedido.entregado, {34: 1, 32: 2, 12: 1}, 'Los Aromos 1234'),
    Pedido('SED-0986', '19 oct 2026', EstadoPedido.entregado, {8: 2, 25: 1, 6: 1}, 'Av. Michimalonco 480'),
  ];

  void cargarCarritoDeEjemplo() {
    carrito
      ..clear()
      ..addAll({4: 2, 32: 1, 12: 1});
    notifyListeners();
  }
}

final estado = Estado();
