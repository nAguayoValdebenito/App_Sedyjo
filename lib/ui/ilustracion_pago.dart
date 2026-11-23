import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/tema.dart';
import 'movimiento.dart';

/// Qué cuenta la ilustración de un pago que no es un error.
enum TipoIlustracionPago {
  /// El pago puede haberse cobrado y aún no sabemos cómo terminó: tarjeta con un reloj.
  confirmando,

  /// El cliente decidió no pagar: tarjeta apagada con una insignia gris. No es una alerta.
  cancelado,
}

/// Ilustración de los resultados de pago que **no** son un fallo, dibujada en código con el mismo lenguaje que las
/// ilustraciones de `assets/img/estados` (fondo suave, tarjeta inclinada, insignia en la esquina) para que el aviso
/// de color rojo quede reservado a lo que de verdad falló.
/// Mide lo mismo que [IlustracionEstado] (proporción 600:340) y flota igual de suave.
class IlustracionPago extends StatelessWidget {
  const IlustracionPago(this.tipo, {super.key, this.ancho = 260});
  final TipoIlustracionPago tipo;
  final double ancho;

  // El dibujo se hace en una escena fija de 260 × 147 y se escala al ancho pedido.
  static const _baseAncho = 260.0;
  static const _baseAlto = _baseAncho * 340 / 600;

  @override
  Widget build(BuildContext context) {
    final confirmando = tipo == TipoIlustracionPago.confirmando;
    // Tarjeta azul mientras se confirma; apagada (gris azulado) si se canceló.
    final tarjeta = confirmando ? const [Color(0xFF4F9BE0), Color(0xFF2B6CB0)] : const [Color(0xFFA9B9CB), Color(0xFF8196AD)];
    final banda = confirmando ? const Color(0xFF1B3F73) : const Color(0xFF5B6C80);
    final insignia = confirmando ? C.azul : const Color(0xFF5F6B7A);

    return Center(
      child: ExcludeSemantics(
        child: Flota(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(R.l),
            child: SizedBox(
              width: ancho,
              height: ancho * _baseAlto / _baseAncho,
              child: ColoredBox(
                color: C.verdeSuave,
                child: FittedBox(
                  child: SizedBox(
                    width: _baseAncho,
                    height: _baseAlto,
                    child: Stack(children: [
                      Positioned(
                        left: 52,
                        top: 26,
                        child: Transform.rotate(
                          angle: -.2,
                          child: Container(
                            width: 132,
                            height: 84,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: tarjeta),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: Stack(children: [
                              Positioned(left: 0, right: 0, top: 16, height: 18, child: ColoredBox(color: banda)),
                              Positioned(
                                left: 14,
                                top: 44,
                                child: Container(
                                  width: 24,
                                  height: 17,
                                  decoration: BoxDecoration(color: const Color(0xFFF2D27A), borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              for (final (i, ancho) in const [(14.0, 18.0), (36.0, 18.0), (58.0, 26.0)].indexed)
                                Positioned(
                                  left: ancho.$1,
                                  bottom: 10,
                                  child: Container(
                                    width: ancho.$2,
                                    height: 6,
                                    decoration: BoxDecoration(color: banda.withValues(alpha: .7 - i * .1), borderRadius: BorderRadius.circular(3)),
                                  ),
                                ),
                            ]),
                          ),
                        ),
                      ),
                      // La insignia: un reloj (se está confirmando) o una cruz suave (se canceló).
                      Positioned(
                        right: 56,
                        bottom: 14,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: insignia,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .22), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Icon(confirmando ? LucideIcons.clock : LucideIcons.x, size: 30, color: Colors.white),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
