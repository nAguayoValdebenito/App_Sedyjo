import 'package:flutter/material.dart';

import '../app/tema.dart';
import 'movimiento.dart';

/// Hace que un elemento aparezca con suavidad (opacidad y una subida de 16 px, 320 ms) cuando entra a la pantalla
/// al desplazarse. Reglas, para que se sienta fino y no cansador:
/// - Aparece **una sola vez**: al volver a subir ya está.
/// - Lo que se ve al abrir la pantalla entra con un escalonado corto (solo los primeros 8); lo que queda fuera
///   espera a que el desplazamiento lo traiga.
/// - Si se desplaza muy rápido (más de 1.800 px/s), aparece sin animación: no se queda atrás de la mano.
/// - Con "reducir movimiento", aparece directo.
/// - Nunca se oculta del lector de pantalla, y el contenido sin desplazamiento (sin `Scrollable`) se ve de inmediato.
/// - Solo anima opacidad y transformación, y deja de escuchar al terminar.
class Revelar extends StatefulWidget {
  const Revelar({super.key, required this.child, this.indice = 0});
  final Widget child;

  /// Posición dentro de su grupo (por ejemplo, la columna de una fila): retrasa 40 ms por posición, hasta 160 ms.
  final int indice;

  @override
  State<Revelar> createState() => _RevelarState();
}

class _RevelarState extends State<Revelar> with SingleTickerProviderStateMixin {
  static const double _velocidadRapida = 1800;
  static const double _subida = 16;

  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  Animation<double>? _anim; // se crea al empezar, con el escalonado que le toca

  final List<ScrollPosition> _posiciones = [];
  bool _visto = false; // ya apareció: se dibuja el hijo tal cual
  bool _oculto = false; // esperando entrar a la pantalla
  bool _decidido = false; // ya se sabe si estaba a la vista al abrir
  bool _comprobando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_visto || _posiciones.isNotEmpty) return;
    // Escucha a todos los desplazamientos que lo contienen (una fila horizontal dentro de una lista vertical).
    context.visitAncestorElements((e) {
      if (e is StatefulElement && e.state is ScrollableState) {
        final pos = (e.state as ScrollableState).position;
        pos.addListener(_alDesplazar);
        _posiciones.add(pos);
      }
      return true;
    });
    if (_posiciones.isEmpty) {
      _visto = true;
      return;
    }
    // Se decide después del primer cuadro, cuando ya se sabe dónde quedó.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _visto) return;
      _decidido = true;
      if (_enPantalla()) {
        _aparecer(animar: widget.indice < 8 && !sinMovimiento(context), alAbrir: true);
      } else {
        setState(() => _oculto = true);
      }
    });
  }

  /// Velocidad aproximada del desplazamiento (px/s), medida entre avisos consecutivos.
  double _velocidad = 0;
  double? _ultimoPx;
  DateTime? _ultimoT;

  void _medirVelocidad() {
    if (_posiciones.isEmpty) return;
    final px = _posiciones.first.pixels;
    final t = DateTime.now();
    if (_ultimoPx != null && _ultimoT != null) {
      final dt = t.difference(_ultimoT!).inMicroseconds / 1e6;
      if (dt > 0) _velocidad = (px - _ultimoPx!).abs() / dt;
    }
    _ultimoPx = px;
    _ultimoT = t;
  }

  void _alDesplazar() {
    _medirVelocidad();
    if (_comprobando || _visto) return;
    _comprobando = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _comprobando = false;
      if (!mounted || _visto || !_oculto) return;
      if (_enPantalla()) {
        final rapido = _velocidad > _velocidadRapida;
        _aparecer(animar: !rapido && !sinMovimiento(context));
      }
    });
  }

  /// ¿Está su parte de arriba dentro de la pantalla (con 24 px de margen abajo)?
  bool _enPantalla() {
    final caja = context.findRenderObject();
    if (caja is! RenderBox || !caja.attached || !caja.hasSize) return true;
    final p = caja.localToGlobal(Offset.zero);
    final pantalla = MediaQuery.sizeOf(context);
    return p.dy < pantalla.height - 24 && p.dx < pantalla.width - 24 && p.dy + caja.size.height > 0 && p.dx + caja.size.width > 0;
  }

  void _aparecer({required bool animar, bool alAbrir = false}) {
    _quitarEscuchas();
    if (!animar) {
      setState(() {
        _oculto = false;
        _visto = true;
      });
      return;
    }
    final espera = (widget.indice * 40).clamp(0, 160);
    final total = 320 + espera;
    _c.duration = Duration(milliseconds: total);
    _anim = CurvedAnimation(parent: _c, curve: Interval(espera / total, 1, curve: Mov.entra));
    setState(() => _oculto = false);
    _c.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _visto = true);
    });
  }

  void _quitarEscuchas() {
    for (final p in _posiciones) {
      p.removeListener(_alDesplazar);
    }
    _posiciones.clear();
  }

  @override
  void dispose() {
    _quitarEscuchas();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_visto) return widget.child;
    final a = (!_decidido || _oculto || _anim == null) ? const AlwaysStoppedAnimation<double>(0) : _anim!;
    return AnimatedBuilder(
      animation: a,
      child: widget.child,
      builder: (_, hijo) => FadeTransition(
        opacity: a,
        // El lector de pantalla lee el contenido aunque todavía no se vea.
        alwaysIncludeSemantics: true,
        child: Transform.translate(offset: Offset(0, (1 - a.value) * _subida), child: hijo),
      ),
    );
  }
}
