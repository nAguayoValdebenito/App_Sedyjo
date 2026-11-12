import 'package:flutter/material.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import 'componentes.dart';

/// Corazón para guardar un producto en favoritos. Área táctil de 48 dp; el disco se llena de verde al guardar
/// (el rojo de la marca queda solo para descuentos). Cada corazón escucha solo su producto.
class BotonFavorito extends StatelessWidget {
  const BotonFavorito(this.p, {super.key});
  final Producto p;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: estado.favoritoDe(p.id),
      builder: (context, fav, _) => Tocable(
        etiqueta: fav ? 'Quitar ${p.nombre} de favoritos' : 'Guardar ${p.nombre} en favoritos',
        onTap: () {
          vibracionLeve();
          estado.alternarFavorito(p.id);
        },
        radio: 24,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: dur(context, 200),
              curve: Mov.entra,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: C.superficie.withValues(alpha: .94),
                border: Border.all(color: C.borde),
              ),
              // Corazón relleno y rojo al guardar (convención universal de "favorito"); contorno gris si no.
              child: AnimatedSwitcher(
                duration: dur(context, 220),
                transitionBuilder: (h, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: h),
                child: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, key: ValueKey(fav), size: Ico.m, color: fav ? C.rojo : C.grisMedio),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
