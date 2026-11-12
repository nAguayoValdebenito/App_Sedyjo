part of '../datos.dart';

/// Lo que la persona busca y mira: alimenta las ideas del buscador.
mixin BusquedaEstado on ChangeNotifier, CarritoEstado {
  // Productos que la persona abrió (los últimos 12)
  final List<int> vistos = [];
  void registrarVisto(int id) {
    vistos.remove(id);
    vistos.insert(0, id);
    if (vistos.length > 12) vistos.removeLast();
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

  /// "Bebida Crush Orange Lata 350 ml" → "Bebida Crush Orange Lata": el nombre sin medidas, para que quepa en el buscador.
  static String nombreCorto(String nombre) {
    final palabras = <String>[];
    for (final w in nombre.split(' ')) {
      if (RegExp(r'[0-9]').hasMatch(w) || palabras.length >= 4) break;
      palabras.add(w);
    }
    return palabras.isEmpty ? nombre : palabras.join(' ');
  }

  /// Ideas para el buscador según lo que la persona hace en la app, de lo más reciente a lo más general:
  /// sus búsquedas, lo que miró, lo que tiene en el carrito y otros productos de esas mismas categorías.
  /// Sin historial, productos populares.
  List<String> sugerenciasBusqueda() {
    final out = <String>[];
    void agregar(String t) {
      if (t.trim().isNotEmpty && !out.any((e) => e.toLowerCase() == t.toLowerCase())) out.add(t.trim());
    }

    if (Catalogo.productos.isEmpty) return const ['arroz', 'bebidas', 'galletas'];
    final porId = {for (final p in Catalogo.productos) p.id: p};
    for (final r in recientes) {
      agregar(r);
    }
    for (final id in vistos) {
      final p = porId[id];
      if (p != null) agregar(nombreCorto(p.nombre));
    }
    final categoriasDeInteres = <String>{
      for (final id in [...vistos, ...carrito.keys])
        if (porId[id] != null) porId[id]!.categoria,
    };
    for (final c in categoriasDeInteres) {
      for (final p in Catalogo.productos.where((p) => p.categoria == c && !carrito.containsKey(p.id) && !p.agotado).take(2)) {
        agregar(nombreCorto(p.nombre));
      }
    }
    if (out.length < 3) {
      for (final p in Catalogo.enOferta().take(4)) {
        agregar(nombreCorto(p.nombre));
      }
    }
    return out.take(8).toList();
  }
}

/// Pedidos: crear uno al comprar, buscarlo y seguirlo.
mixin PedidosEstado on ChangeNotifier, CarritoEstado {
  final List<Pedido> pedidos = [
    Pedido('SED-1042', '3 nov 2026', EstadoPedido.enCamino, {2: 2, 31: 1, 33: 1, 23: 2}, 'Los Aromos 1234'),
    Pedido('SED-1017', '28 oct 2026', EstadoPedido.entregado, {34: 1, 32: 2, 12: 1}, 'Los Aromos 1234'),
    Pedido('SED-0986', '19 oct 2026', EstadoPedido.entregado, {8: 2, 25: 1, 6: 1}, 'Av. Michimalonco 480'),
  ];

  static const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  /// Número siguiente: continúa desde el más alto que existe (SED-1043, SED-1044…).
  String get siguienteNumeroPedido {
    var mayor = 1000;
    for (final p in pedidos) {
      final n = int.tryParse(p.numero.replaceAll(RegExp(r'[^0-9]'), ''));
      if (n != null && n > mayor) mayor = n;
    }
    return 'SED-${mayor + 1}';
  }

  /// Convierte el carrito en un pedido (queda primero en la lista, con el estado "Recibido") y vacía el carrito.
  Pedido registrarPedido({required String correo, required String direccion, String? franja, String? notas, bool retiro = false}) {
    final ahora = DateTime.now();
    final pedido = Pedido(
      siguienteNumeroPedido,
      '${ahora.day} ${_meses[ahora.month - 1]} ${ahora.year}',
      EstadoPedido.recibido,
      Map.of(carrito),
      direccion,
      correo: correo.trim().toLowerCase(),
      creado: ahora,
      franja: franja,
      retiro: retiro,
      notas: (notas == null || notas.trim().isEmpty) ? null : notas.trim(),
    );
    pedidos.insert(0, pedido);
    vaciarCarrito();
    return pedido;
  }

  /// Busca un pedido por número y correo. Los pedidos hechos en la app exigen el mismo correo de la compra.
  /// Sin [correo] (cuando se llega desde la compra recién hecha) solo se compara el número.
  Pedido? buscarPedido(String numero, {String? correo}) {
    final n = numero.trim().toUpperCase().replaceAll(' ', '');
    for (final p in pedidos) {
      if (p.numero.toUpperCase() != n) continue;
      if (correo == null || p.correo == null || p.correo == correo.trim().toLowerCase()) return p;
    }
    return null;
  }
}

/// Cuenta: primera vez, sesión, perfil y direcciones.
mixin CuentaEstado on ChangeNotifier, PedidosEstado {
  // Primera vez en la app (la bienvenida cambia el saludo) y saludo tras iniciar sesión
  bool primeraVez = true;
  bool saludoPendiente = false;
  bool saludoEsPrimera = false;
  void marcarVisitado() {
    primeraVez = false;
    Memoria.guardarVisita();
  }

  void consumirSaludo() {
    saludoPendiente = false;
    notifyListeners();
  }

  // Sesión simulada
  String? nombre;
  String? correo;
  String? telefono;
  bool get conSesion => nombre != null;
  void iniciarSesion([String n = 'María González', String c = 'maria.gonzalez@correo.cl']) {
    nombre = n;
    correo = c;
    saludoPendiente = true;
    saludoEsPrimera = primeraVez;
    primeraVez = false;
    Memoria.guardarVisita();
    notifyListeners();
  }

  /// Guarda lo que la persona cambió en "Mis datos".
  void actualizarPerfil({required String nombre, required String correo, String? telefono}) {
    this.nombre = nombre;
    this.correo = correo;
    this.telefono = (telefono == null || telefono.trim().isEmpty) ? null : telefono.trim();
    notifyListeners();
  }

  void cerrarSesion() {
    nombre = null;
    correo = null;
    telefono = null;
    notifyListeners();
  }

  String get iniciales {
    final partes = (nombre ?? '').trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (partes.isEmpty) return '';
    return (partes.first[0] + (partes.length > 1 ? partes[1][0] : '')).toUpperCase();
  }

  /// "maria.gonzalez@correo.cl" → "Maria Gonzalez": hasta que haya un servidor, el nombre sale del correo.
  static String nombreDesdeCorreo(String correo) {
    final local = correo.split('@').first.replaceAll(RegExp(r'[._\-+0-9]+'), ' ').trim();
    if (local.isEmpty) return 'Cliente';
    return local.split(' ').where((e) => e.isNotEmpty).map((e) => e[0].toUpperCase() + e.substring(1)).join(' ');
  }

  // Datos de la cuenta de ejemplo
  final List<Direccion> direcciones = [
    Direccion('Casa', 'Los Aromos 1234', 'Concepción', 'Portón verde, timbre 2', principal: true),
    Direccion('Casa de mamá', 'Av. Michimalonco 480', 'Concepción', 'Departamento 302'),
  ];

  /// Una cuenta recién creada empieza sin pedidos ni direcciones.
  void crearCuenta(String n, String c) {
    pedidos.clear();
    direcciones.clear();
    iniciarSesion(n, c);
  }
}
