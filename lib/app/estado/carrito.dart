part of '../datos.dart';

/// Carrito: qué hay, cuánto cuesta y cuánto falta para el despacho gratis.
mixin CarritoEstado on ChangeNotifier {
  final Map<int, int> carrito = {};
  int get cantidadCarrito => carrito.values.fold(0, (a, b) => a + b);
  int get subtotal => carrito.entries.fold(0, (a, e) => a + Catalogo.porId(e.key).precioFinal * e.value);
  int get ahorro => carrito.entries.fold(0, (a, e) {
        final p = Catalogo.porId(e.key);
        return a + (p.precio - p.precioFinal) * e.value;
      });
  bool get despachoGratis => subtotal >= despachoGratisDesde;
  int get faltaParaGratis => (despachoGratisDesde - subtotal).clamp(0, despachoGratisDesde);

  /// Cantidad de un producto en el carrito como notificador propio: cada tarjeta escucha solo el suyo
  /// y no se reconstruye cuando cambia otro producto.
  final Map<int, ValueNotifier<int>> _cantidades = {};
  ValueListenable<int> cantidadDe(int id) => _cantidades.putIfAbsent(id, () => ValueNotifier(carrito[id] ?? 0));

  void _sincronizar() {
    for (final e in _cantidades.entries) {
      e.value.value = carrito[e.key] ?? 0;
    }
    notifyListeners();
  }

  void agregar(Producto p, [int n = 1]) {
    carrito[p.id] = (carrito[p.id] ?? 0) + n;
    _sincronizar();
  }

  void cambiarCantidad(Producto p, int n) {
    if (n <= 0) {
      carrito.remove(p.id);
    } else {
      carrito[p.id] = n;
    }
    _sincronizar();
  }

  void vaciarCarrito() {
    carrito.clear();
    _sincronizar();
  }

  /// Quita del carrito lo que ya no existe en el catálogo (por ejemplo, un producto retirado desde la última visita).
  void depurarCarrito() {
    final antes = carrito.length;
    carrito.removeWhere((id, n) => n <= 0 || !Catalogo.productos.any((p) => p.id == id));
    if (carrito.length != antes) _sincronizar();
  }

  void cargarCarritoDeEjemplo() {
    carrito
      ..clear()
      ..addAll({4: 2, 32: 1, 12: 1});
    _sincronizar();
  }
}
