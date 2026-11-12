part of '../datos.dart';

/// Productos que la persona guardó con el corazón (del más nuevo al más antiguo).
mixin FavoritosEstado on ChangeNotifier {
  final List<int> favoritos = [];

  /// Un notificador por producto: cada corazón escucha solo el suyo.
  final Map<int, ValueNotifier<bool>> _esFavorito = {};
  ValueListenable<bool> favoritoDe(int id) => _esFavorito.putIfAbsent(id, () => ValueNotifier(favoritos.contains(id)));

  void _sincronizarFavoritos() {
    for (final e in _esFavorito.entries) {
      e.value.value = favoritos.contains(e.key);
    }
    notifyListeners();
  }

  void alternarFavorito(int id) {
    if (!favoritos.remove(id)) favoritos.insert(0, id);
    _sincronizarFavoritos();
  }
}
