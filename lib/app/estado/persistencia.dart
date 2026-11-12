part of '../datos.dart';

/// Versión del formato guardado. Súbela cuando cambie la forma de los datos y agrega el paso a [_migrar].
const int versionDatos = 2;

/// Guardar y restaurar todo lo que la persona hizo. Cada versión del formato se migra a la siguiente,
/// así una actualización de la app nunca descarta ni rompe lo guardado.
mixin PersistenciaEstado on ChangeNotifier, CarritoEstado, PreferenciasEstado, BusquedaEstado, PedidosEstado, CuentaEstado, FavoritosEstado {
  Map<String, dynamic> aJson() => {
        'v': versionDatos,
        'carrito': carrito.map((k, v) => MapEntry('$k', v)),
        'modoTema': modoTema.index,
        'escala': escalaTexto,
        'reducir': reducirMovimiento,
        'minutosOfertas': minutosOfertas,
        'pushOfertas': pushOfertas,
        'pushPedidos': pushPedidos,
        'recientes': recientes,
        'vistos': vistos,
        'favoritos': favoritos,
        'avisosSinLeer': avisosSinLeer,
        'consejoInicioVisto': consejoInicioVisto,
        'cargaBreve': cargaBreve,
        'nombre': nombre,
        'correo': correo,
        'telefono': telefono,
        'direcciones': [for (final d in direcciones) d.toJson()],
        'pedidos': [for (final p in pedidos) p.toJson()],
        'silenciadoHasta': relampagoSilenciadoHoy ? _hoy : null,
      };

  static String get _hoy {
    final d = DateTime.now();
    return '${d.year}-${d.month}-${d.day}';
  }

  /// Lleva lo guardado por versiones anteriores al formato actual.
  /// v1 (sin número de versión) ya tenía los mismos campos, así que solo se marca como v2.
  static Map<String, dynamic> migrar(Map<String, dynamic> j) {
    var datos = Map<String, dynamic>.of(j);
    var v = (datos['v'] as int?) ?? 1;
    if (v < 2) {
      datos['v'] = v = 2;
    }
    // Un formato más nuevo que esta app (por ejemplo, tras volver a una versión anterior) se lee con lo que se entienda.
    return datos;
  }

  void restaurar(Map<String, dynamic> guardado) {
    final j = migrar(guardado);
    final c = j['carrito'];
    if (c is Map) {
      carrito
        ..clear()
        ..addAll(c.map((k, v) => MapEntry(int.parse(k as String), v as int)));
    }
    modoTema = ModoTema.values[((j['modoTema'] as int?) ?? 0).clamp(0, ModoTema.values.length - 1)];
    if (!kDebugMode || Uri.base.queryParameters['letra'] == null) escalaTexto = (j['escala'] as num?)?.toDouble() ?? escalaTexto;
    reducirMovimiento = (j['reducir'] as bool?) ?? reducirMovimiento;
    minutosOfertas = (j['minutosOfertas'] as int?) ?? minutosOfertas;
    pushOfertas = (j['pushOfertas'] as bool?) ?? pushOfertas;
    pushPedidos = (j['pushPedidos'] as bool?) ?? pushPedidos;
    recientes
      ..clear()
      ..addAll(((j['recientes'] as List?) ?? const []).cast<String>());
    vistos
      ..clear()
      ..addAll(((j['vistos'] as List?) ?? const []).cast<int>());
    favoritos
      ..clear()
      ..addAll(((j['favoritos'] as List?) ?? const []).cast<int>());
    _sincronizarFavoritos();
    avisosSinLeer = (j['avisosSinLeer'] as bool?) ?? avisosSinLeer;
    consejoInicioVisto = (j['consejoInicioVisto'] as bool?) ?? consejoInicioVisto;
    cargaBreve = (j['cargaBreve'] as bool?) ?? cargaBreve;
    nombre = j['nombre'] as String?;
    correo = j['correo'] as String?;
    telefono = j['telefono'] as String?;
    if (j['direcciones'] is List) {
      direcciones
        ..clear()
        ..addAll((j['direcciones'] as List).map((e) => Direccion.desdeJson(e as Map<String, dynamic>)));
    }
    if (j['pedidos'] is List) {
      pedidos
        ..clear()
        ..addAll((j['pedidos'] as List).map((e) => Pedido.desdeJson(e as Map<String, dynamic>)));
    }
    relampagoSilenciadoHoy = j['silenciadoHasta'] == _hoy;
  }
}
