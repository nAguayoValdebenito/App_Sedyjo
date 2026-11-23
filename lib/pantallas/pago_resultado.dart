import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../pago/modelos_pago.dart';
import 'direccion.dart' show mostrarContacto;
import '../ui/componentes.dart';
import 'pedidos.dart';
import 'shell.dart' show BarraInferior;

// `ResultadoPago` vive ahora en los modelos del pago; se reexporta para no tocar a quienes lo importan de aquí.
export '../pago/modelos_pago.dart' show ResultadoPago, MotivoNoPago, ComprobantePago;

/// Estado del sello circular de arriba.
enum Sello { procesando, aprobado, rechazado, sinConfirmar }

/// Fecha y hora de Chile continental (`dd/mm/aaaa HH:mm`) a partir de un instante cualquiera.
///
/// No hay paquete de zonas horarias en el proyecto (y `toLocal()` dependería de la zona del teléfono o de la
/// máquina de pruebas), así que se aplica a mano la regla vigente de Chile continental: UTC-4 en invierno y UTC-3
/// en horario de verano, que empieza el primer domingo desde el 2 de septiembre a las 04:00 UTC y termina el
/// primer domingo desde el 2 de abril a las 03:00 UTC. Limitación: esa regla rige desde 2023; en fechas anteriores
/// los cambios de hora pudieron caer en otro día, y Magallanes (UTC-3 todo el año) no está contemplado.
String fechaChile(DateTime fecha) {
  final u = fecha.toUtc();
  DateTime domingoDesdeEl2(int mes, int hora) {
    final dia2 = DateTime.utc(u.year, mes, 2, hora);
    return dia2.add(Duration(days: (DateTime.sunday - dia2.weekday) % 7));
  }

  final verano = !u.isBefore(domingoDesdeEl2(9, 4)) || u.isBefore(domingoDesdeEl2(4, 3));
  final l = u.subtract(Duration(hours: verano ? 3 : 4));
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(l.day)}/${dos(l.month)}/${l.year} ${dos(l.hour)}:${dos(l.minute)}';
}

/// Pantalla del resultado del pago, en tres tiempos:
/// 1. Solo un círculo que gira mientras se confirma el pago ("Confirmando tu pago…").
/// 2. El círculo se cierra y se vuelve verde con una marca (aprobado), rojo con una cruz (rechazado o cancelado)
///    o gris con una «!» (sin confirmar: no se sabe cómo terminó).
/// 3. Recién entonces aparece el mensaje completo: ilustración, título, número de pedido y los botones.
///
/// Con [procesar] hace el trabajo real (registrar el pedido, cobrar); con [resultado] muestra uno ya conocido
/// (también pasa por el círculo, para que la secuencia sea la misma). [alRevisarDeNuevo] es lo que hace el botón
/// «Revisar de nuevo» del resultado sin confirmar; sin él, el botón no aparece.
class ResultadoPagoPantalla extends StatefulWidget {
  const ResultadoPagoPantalla({super.key, this.procesar, this.resultado, this.alRevisarDeNuevo}) : assert(procesar != null || resultado != null);
  final Future<ResultadoPago> Function()? procesar;
  final ResultadoPago? resultado;
  final VoidCallback? alRevisarDeNuevo;

  @override
  State<ResultadoPagoPantalla> createState() => _ResultadoPagoPantallaState();
}

class _ResultadoPagoPantallaState extends State<ResultadoPagoPantalla> {
  ResultadoPago? _r;
  bool _contenido = false;
  Timer? _tContenido;
  Timer? _tMinimo;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    // El círculo gira al menos un momento: un resultado instantáneo se sentiría falso.
    final minimo = Completer<void>();
    _tMinimo = Timer(const Duration(milliseconds: 1800), minimo.complete);
    final r = widget.resultado ?? await widget.procesar!();
    await minimo.future;
    if (!mounted) return;
    setState(() => _r = r);
    if (r.aprobado) {
      vibracionLogro();
    } else {
      vibracionError();
    }
    // Se deja ver el sello cambiar de color antes de mostrar el mensaje.
    _tContenido = Timer(Duration(milliseconds: sinMovimiento(context) ? 200 : 1100), () {
      if (mounted) setState(() => _contenido = true);
    });
  }

  @override
  void dispose() {
    _tContenido?.cancel();
    _tMinimo?.cancel();
    super.dispose();
  }

  Sello get _sello {
    final r = _r;
    if (r == null) return Sello.procesando;
    if (r.aprobado) return Sello.aprobado;
    return r.motivo == MotivoNoPago.sinConfirmar ? Sello.sinConfirmar : Sello.rechazado;
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    return PopScope(
      // Mientras se confirma el pago no se puede salir: evitaría dejar la compra a medias.
      canPop: r != null,
      child: Scaffold(
        // Si el pago no se completó (rechazado o cancelado), la barra de pestañas sigue a la vista para ir a cualquier
        // parte de la tienda. Sin confirmar no: ahí el cliente debe revisar el pago, no seguir comprando.
        bottomNavigationBar: (_contenido && r != null && !r.aprobado && r.motivo != MotivoNoPago.sinConfirmar)
            ? BarraInferior(alElegir: (i) {
                Navigator.of(context).popUntil((x) => x.isFirst);
                estado.irAPestana(i);
              })
            : null,
        body: SafeArea(
          // Primero solo el círculo; cuando ya cambió de color, se va y entra la pantalla final con el mensaje.
          child: AnimatedSwitcher(
            duration: dur(context, 550),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: (_contenido && r != null) ? _vistaFinal(context, r) : _vistaCirculo(),
          ),
        ),
      ),
    );
  }

  /// El círculo solo, en el centro de la pantalla.
  Widget _vistaCirculo() {
    return SizedBox.expand(
      key: const ValueKey('circulo'),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SelloPago(_sello),
        if (_r == null) ...[
          const SizedBox(height: Esp.x6),
          Semantics(liveRegion: true, child: Text('Confirmando tu pago…', textAlign: TextAlign.center, style: T.titulo3)),
          const SizedBox(height: Esp.x2),
          Text('Un momento, no cierres la aplicación.', textAlign: TextAlign.center, style: T.apoyo),
        ],
      ]),
    );
  }

  /// El mensaje completo del resultado, sin el círculo.
  Widget _vistaFinal(BuildContext context, ResultadoPago r) {
    return Column(key: const ValueKey('final'), children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Esp.x6),
          child: Column(children: r.aprobado ? _aprobado(context, r) : _noPagado(r.motivo)),
        ),
      ),
      _botones(context, r),
    ]);
  }

  List<Widget> _aprobado(BuildContext context, ResultadoPago r) => [
        const SizedBox(height: Esp.x8 + Esp.x6),
        Revelar(child: const IlustracionEstado('compra-exitosa.webp', ancho: 260)),
        const SizedBox(height: Esp.x6),
        Revelar(indice: 1, child: Semantics(liveRegion: true, header: true, child: Text('¡Tu compra está lista!', textAlign: TextAlign.center, style: T.titulo1))),
        const SizedBox(height: Esp.x3),
        Revelar(
          indice: 2,
          child: Text('Pagaste ${clp(r.total)}. Te enviamos el comprobante a ${r.correo.isEmpty ? 'tu correo' : r.correo}.', textAlign: TextAlign.center, style: T.cuerpo.copyWith(color: C.grisMedio)),
        ),
        const SizedBox(height: Esp.x6),
        Revelar(
          indice: 3,
          child: Panel(
            fondo: C.verdeSuave,
            borde: C.verdeSuave,
            child: SizedBox(
              width: double.infinity,
              child: Column(children: [
                Text('Número de pedido', style: T.apoyo.copyWith(color: C.verdeOscuro)),
                const SizedBox(height: Esp.x1),
                Text(r.numero ?? '', style: T.titulo1.copyWith(color: C.verdeProfundo, fontSize: 32, letterSpacing: .5)),
                const SizedBox(height: Esp.x2),
                Text('Anótalo: con él puedes seguir tu pedido sin cuenta.', textAlign: TextAlign.center, style: T.apoyo.copyWith(color: C.verdeOscuro)),
              ]),
            ),
          ),
        ),
        if (r.comprobante != null) ...[
          const SizedBox(height: Esp.x4),
          Revelar(indice: 4, child: _comprobante(r, r.comprobante!)),
        ],
        const SizedBox(height: Esp.x4),
        Revelar(
          indice: 4,
          child: Row(children: [
            Icon(r.retiro ? LucideIcons.store : LucideIcons.truck, color: C.verde),
            const SizedBox(width: Esp.x3),
            Expanded(child: Text(r.retiro ? 'Estará lista para retirar en ${tienda.calle} en 2 horas hábiles.' : 'Llegará en 24 a 48 horas.', style: T.cuerpoFuerte)),
          ]),
        ),
        const SizedBox(height: Esp.x4),
      ];

  /// Panel con los datos de la transacción que informó el banco.
  Widget _comprobante(ResultadoPago r, ComprobantePago c) {
    final filas = <(String, String)>[
      ('Número de pedido', r.numero ?? ''),
      ('Monto', clp(r.total)),
      ('Código de autorización', c.codigoAutorizacion),
      ('Tarjeta', '•••• ${c.tarjetaUltimos4}'),
      ('Tipo de pago', c.tipoPago),
      ('Cuotas', c.cuotas == 0 ? 'Sin cuotas' : '${c.cuotas} cuotas'),
      if (c.fecha != null) ('Fecha', fechaChile(c.fecha!)),
    ];
    return Panel(
      child: SizedBox(
        width: double.infinity,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(header: true, child: Text('Comprobante de pago', style: T.titulo3)),
          const SizedBox(height: Esp.x3),
          for (final (etiqueta, valor) in filas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Esp.x1),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(etiqueta, style: T.apoyo.copyWith(color: C.grisMedio))),
                const SizedBox(width: Esp.x3),
                Flexible(child: Text(valor, textAlign: TextAlign.end, style: T.cuerpoFuerte)),
              ]),
            ),
        ]),
      ),
    );
  }

  /// Contenido de un pago que no quedó aprobado: rechazado, cancelado por el cliente o sin confirmar.
  List<Widget> _noPagado(MotivoNoPago? motivo) {
    final (titulo, cuerpo) = switch (motivo) {
      MotivoNoPago.cancelado => ('Cancelaste el pago', 'No te cobramos nada y tus productos siguen en el carrito. Puedes intentarlo de nuevo.'),
      MotivoNoPago.sinConfirmar => (
          'Estamos confirmando tu pago',
          'No pudimos saber cómo terminó. Si tu banco te cobró, tu pedido aparecerá en Mis pedidos. No pagues de nuevo todavía.'
        ),
      _ => ('El pago no se completó', 'No te cobramos nada y tus productos siguen en el carrito. Puedes intentarlo de nuevo.'),
    };
    return [
      const SizedBox(height: Esp.x8 + Esp.x6),
      Revelar(child: const IlustracionEstado('pago-no-completado.webp', ancho: 260)),
      const SizedBox(height: Esp.x6),
      Revelar(indice: 1, child: Semantics(liveRegion: true, header: true, child: Text(titulo, textAlign: TextAlign.center, style: T.titulo1))),
      const SizedBox(height: Esp.x3),
      Revelar(indice: 2, child: Text(cuerpo, textAlign: TextAlign.center, style: T.cuerpo.copyWith(color: C.grisMedio))),
      const SizedBox(height: Esp.x4),
    ];
  }

  Widget _botones(BuildContext context, ResultadoPago r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Esp.x6, Esp.x2, Esp.x6, Esp.x5),
      child: Column(children: r.aprobado
          ? [
              Boton('Seguir mi pedido', icono: LucideIcons.packageCheck, onTap: () {
                Navigator.of(context).popUntil((x) => x.isFirst);
                irA(context, SeguimientoPantalla(numero: r.numero));
              }),
              const SizedBox(height: Esp.x3),
              Boton('Volver al inicio', estilo: EstiloBoton.suave, onTap: () {
                Navigator.of(context).popUntil((x) => x.isFirst);
                estado.irAPestana(0);
              }),
            ]
          : [
              // Sin confirmar no se invita a pagar otra vez: primero se revisa si el cobro llegó a hacerse.
              if (r.motivo == MotivoNoPago.sinConfirmar) ...[
                if (widget.alRevisarDeNuevo != null) ...[
                  Boton('Revisar de nuevo', icono: LucideIcons.refreshCw, onTap: widget.alRevisarDeNuevo),
                  const SizedBox(height: Esp.x2),
                ],
              ] else ...[
                Boton('Intentar de nuevo', icono: LucideIcons.refreshCw, onTap: () => Navigator.of(context).maybePop()),
                const SizedBox(height: Esp.x2),
              ],
              Boton('Volver al inicio', estilo: EstiloBoton.suave, icono: LucideIcons.house, onTap: () {
                Navigator.of(context).popUntil((x) => x.isFirst);
                estado.irAPestana(0);
              }),
              const SizedBox(height: Esp.x2),
              Boton('Llamar para recibir ayuda', estilo: EstiloBoton.contorno, icono: LucideIcons.phone, alto: 52, onTap: () => mostrarContacto(context)),
            ]),
    );
  }
}

/// Compra exitosa (se usa también desde el panel de la maqueta y las pruebas).
class ExitoPantalla extends StatelessWidget {
  const ExitoPantalla({super.key, required this.numero, required this.total, required this.correo, this.retiro = false});
  final String numero;
  final int total;
  final String correo;
  final bool retiro;

  @override
  Widget build(BuildContext context) =>
      ResultadoPagoPantalla(resultado: ResultadoPago.aprobado(numero: numero, total: total, correo: correo, retiro: retiro));
}

/// Pago rechazado.
class ErrorPagoPantalla extends StatelessWidget {
  const ErrorPagoPantalla({super.key});

  @override
  Widget build(BuildContext context) => const ResultadoPagoPantalla(resultado: ResultadoPago.rechazado());
}

/// El círculo del resultado: gira mientras se confirma; al resolverse el aro se cierra, el disco se llena
/// (verde con una marca, o rojo con una cruz) y la marca se dibuja. Con "reducir movimiento" el cambio es directo.
class SelloPago extends StatefulWidget {
  const SelloPago(this.sello, {super.key, this.tam = 104});
  final Sello sello;
  final double tam;

  @override
  State<SelloPago> createState() => _SelloPagoState();
}

class _SelloPagoState extends State<SelloPago> with TickerProviderStateMixin {
  late final AnimationController _giro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _res = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (widget.sello == Sello.procesando) {
      _giro.repeat();
    } else {
      _res.value = 1;
    }
  }

  @override
  void didUpdateWidget(SelloPago old) {
    super.didUpdateWidget(old);
    if (old.sello == Sello.procesando && widget.sello != Sello.procesando) {
      if (sinMovimiento(context)) {
        _res.value = 1;
        _giro.stop();
      } else {
        _res.forward(from: 0).whenComplete(_giro.stop);
      }
    }
  }

  @override
  void dispose() {
    _giro.dispose();
    _res.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final etiqueta = switch (widget.sello) {
      Sello.procesando => 'Confirmando tu pago',
      Sello.aprobado => 'Pago aprobado',
      Sello.rechazado => 'Pago rechazado',
      Sello.sinConfirmar => 'Pago sin confirmar',
    };
    return Semantics(
      label: etiqueta,
      liveRegion: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_giro, _res]),
            builder: (_, _) => CustomPaint(
              size: Size.square(widget.tam),
              painter: _PintorSello(
                giro: _giro.value,
                res: widget.sello == Sello.procesando ? 0 : _res.value,
                sello: widget.sello,
                pista: C.borde,
                aro: C.verde,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PintorSello extends CustomPainter {
  _PintorSello({required this.giro, required this.res, required this.sello, required this.pista, required this.aro})
      : relleno = switch (sello) {
          Sello.rechazado => C.rojo,
          Sello.sinConfirmar => C.grisMedio,
          _ => C.verde,
        };
  final double giro;
  final double res;
  final Sello sello;
  final Color pista;
  final Color aro;
  final Color relleno;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 6;
    final grosor = size.width * .07;

    // 1) Aro: una pista suave y un arco que gira; al resolverse el arco se cierra y el aro se desvanece.
    final aroAlfa = 1 - ((res - .25) / .25).clamp(0.0, 1.0);
    if (aroAlfa > 0) {
      canvas.drawCircle(c, r, Paint()..color = pista.withValues(alpha: aroAlfa)..style = PaintingStyle.stroke..strokeWidth = grosor);
      final cierre = Curves.easeOut.transform((res / .25).clamp(0.0, 1.0));
      final barrido = (math.pi * 1.1) + (math.pi * 2 - math.pi * 1.1) * cierre;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        giro * math.pi * 2 - math.pi / 2,
        barrido,
        false,
        Paint()
          ..color = aro.withValues(alpha: aroAlfa)
          ..style = PaintingStyle.stroke
          ..strokeWidth = grosor
          ..strokeCap = StrokeCap.round,
      );
    }

    // 2) Disco de color que crece desde el centro con un pequeño rebote.
    final crece = Curves.easeOutBack.transform(((res - .30) / .35).clamp(0.0, 1.0));
    if (crece > 0) canvas.drawCircle(c, (r + grosor / 2) * crece, Paint()..color = relleno);

    // 3) Marca (visto bueno, cruz o «!») que se dibuja.
    final p = Curves.easeOut.transform(((res - .55) / .45).clamp(0.0, 1.0));
    if (p > 0) {
      final w = size.width;
      final ruta = Path();
      switch (sello) {
        case Sello.aprobado:
          ruta
            ..moveTo(w * .30, w * .53)
            ..lineTo(w * .44, w * .67)
            ..lineTo(w * .71, w * .37);
        case Sello.sinConfirmar:
          // La «!»: una raya y, al final del trazo, el punto de abajo (un tramo casi nulo con punta redonda).
          ruta
            ..moveTo(w * .50, w * .28)
            ..lineTo(w * .50, w * .54)
            ..moveTo(w * .50, w * .70)
            ..lineTo(w * .50, w * .702);
        case Sello.procesando || Sello.rechazado:
          ruta
            ..moveTo(w * .36, w * .36)
            ..lineTo(w * .64, w * .64)
            ..moveTo(w * .64, w * .36)
            ..lineTo(w * .36, w * .64);
      }
      final lapiz = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .08
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      var largoTotal = 0.0;
      final tramos = ruta.computeMetrics().toList();
      for (final t in tramos) {
        largoTotal += t.length;
      }
      var restante = largoTotal * p;
      for (final t in tramos) {
        if (restante <= 0) break;
        canvas.drawPath(t.extractPath(0, math.min(t.length, restante)), lapiz);
        restante -= t.length;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PintorSello old) => old.giro != giro || old.res != res || old.sello != sello || old.relleno != relleno;
}
