part of '../datos.dart';

/// Navegación por pestañas.
mixin NavegacionEstado on ChangeNotifier {
  int pestana = 0;
  void irAPestana(int i) {
    pestana = i;
    notifyListeners();
  }

  /// Tocar de nuevo la pestaña en la que ya se está: esa pestaña vuelve arriba del todo.
  int retoques = 0;
  void retocarPestana() {
    retoques++;
    notifyListeners();
  }

  void refrescar() => notifyListeners();
}

/// Preferencias de la persona: apariencia, accesibilidad y avisos (más la red simulada de la maqueta).
mixin PreferenciasEstado on ChangeNotifier {
  // Apariencia
  ModoTema modoTema = ModoTema.auto;
  void cambiarModoTema(ModoTema m) {
    modoTema = m;
    notifyListeners();
  }

  // Accesibilidad. ?letra=1.3 en la dirección abre la maqueta con ese tamaño de letra (solo depuración).
  double escalaTexto = kDebugMode ? (double.tryParse(Uri.base.queryParameters['letra'] ?? '') ?? 1.0) : 1.0;
  bool reducirMovimiento = false;
  void cambiarEscala(double v) {
    escalaTexto = v;
    notifyListeners();
  }

  void cambiarReducirMovimiento(bool v) {
    reducirMovimiento = v;
    notifyListeners();
  }

  /// Consejo de la portada para quien recién empieza: se muestra hasta que lo cierra.
  bool consejoInicioVisto = false;
  void cerrarConsejoInicio() {
    consejoInicioVisto = true;
    notifyListeners();
  }

  /// Si la persona prefiere entrar más rápido: la pantalla de carga muestra solo el logo (1,4 s) en vez de la canasta (5 s).
  bool cargaBreve = false;
  void cambiarCargaBreve(bool v) {
    cargaBreve = v;
    notifyListeners();
  }

  // Avisos
  bool avisosSinLeer = true;
  void marcarAvisosLeidos() {
    if (!avisosSinLeer) return;
    avisosSinLeer = false;
    notifyListeners();
  }

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

  // Simulación del pago (solo maqueta)
  SimulacionPago simulacionPago = SimulacionPago.aprobado;
  void cambiarSimulacionPago(SimulacionPago v) {
    simulacionPago = v;
    notifyListeners();
  }

  // Simulación de la red (solo maqueta)
  SimulacionRed simulacionRed = SimulacionRed.normal;
  void cambiarSimulacionRed(SimulacionRed v) {
    simulacionRed = v;
    notifyListeners();
  }
}
