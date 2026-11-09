import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/componentes.dart';
import 'auth.dart';
import 'shell.dart';

/// Primera pantalla tras la carga: elegir cómo entrar. La compra como invitado es la opción principal.
class BienvenidaPantalla extends StatelessWidget {
  const BienvenidaPantalla({super.key});

  void _entrar(BuildContext context) {
    estado.marcarVisitado();
    estado.pestana = 0;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: dur(context, 400),
      pageBuilder: (_, __, ___) => const Shell(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: estado, builder: (context, _) => _cuerpo(context));
  }

  Widget _cuerpo(BuildContext context) {
    final conSesion = estado.conSesion;
    final primera = estado.primeraVez;
    final nombre = conSesion ? estado.nombre!.split(' ').first : '';
    final titulo = conSesion
        ? 'Hola de nuevo, $nombre'
        : primera
            ? 'Te damos la bienvenida a la aplicación'
            : '¡Qué bueno verte de nuevo!';
    final texto = conSesion
        ? 'Tus pedidos y direcciones están listos. Entra a la tienda cuando quieras.'
        : primera
            ? 'Compra fácil y recíbelo en tu casa, con despacho a domicilio.'
            : 'Sigue comprando como invitado o ingresa para ver tus pedidos.';
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, caja) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: caja.maxHeight),
              child: Column(
                children: [
                  // Zona visual
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Container(
                      height: 320,
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(color: C.verdeSuave, borderRadius: BorderRadius.circular(32)),
                      child: Stack(children: [
                        // Fondo de marca: verde profundo con la textura de doodles y los productos reales apilados.
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [C.verdeBanner, C.verde]),
                            ),
                          ),
                        ),
                        Positioned.fill(child: Opacity(opacity: .18, child: Image.asset('assets/img/patrones/oscuro-v2.webp', fit: BoxFit.cover))),
                        Positioned(left: -8, bottom: -6, child: Image.asset('assets/img/hero/bebidas.webp', height: 138, fit: BoxFit.contain, semanticLabel: '')),
                        Positioned(right: -12, bottom: -4, child: Image.asset('assets/img/hero/abarrotes.webp', height: 140, fit: BoxFit.contain, semanticLabel: '')),
                        Positioned(
                          left: 18,
                          top: 18,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: C.superficie, width: 4),
                              boxShadow: [BoxShadow(color: C.verdeProfundo.withValues(alpha: .25), blurRadius: 14, offset: const Offset(0, 6))],
                            ),
                            child: ClipOval(child: Image.asset('assets/img/logo.webp', fit: BoxFit.cover, semanticLabel: 'Logo de Comercial Sedyjo')),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          top: 26,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(color: C.superficie, borderRadius: BorderRadius.circular(14)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(LucideIcons.truck, size: 22, color: C.verdeOscuro),
                              const SizedBox(width: 8),
                              Text('24 a 48 horas', style: T.cuerpoFuerte.copyWith(fontSize: 16, color: C.verdeOscuro)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Semantics(header: true, child: Text(titulo, style: T.titulo1)),
                      const SizedBox(height: 12),
                      Text(texto, style: T.cuerpo.copyWith(color: C.grisMedio)),
                    ]),
                  ),
                  if (primera && !conSesion) ...[
                    const SizedBox(height: 20),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: _TresPasos()),
                  ],
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: conSesion
                        ? Column(children: [
                            Boton('Entrar a la tienda', icono: LucideIcons.shoppingBasket, onTap: () => _entrar(context), alto: 62),
                            const SizedBox(height: 12),
                            Boton('No soy $nombre: cambiar de cuenta', estilo: EstiloBoton.suave, onTap: estado.cerrarSesion),
                          ])
                        : Column(children: [
                            Boton(primera ? 'Comprar sin crear cuenta' : 'Seguir comprando',
                                icono: LucideIcons.shoppingBasket, onTap: () => _entrar(context), alto: 62),
                            const SizedBox(height: 12),
                            Boton('Ya tengo cuenta: ingresar',
                                estilo: EstiloBoton.contorno,
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IngresarPantalla(desdeBienvenida: true)))),
                            const SizedBox(height: 12),
                            Boton('Crear mi cuenta',
                                estilo: EstiloBoton.suave,
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegistroPantalla(desdeBienvenida: true)))),
                          ]),
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(LucideIcons.phone, size: 20, color: C.azulEnlace),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('¿Necesitas ayuda? Llámanos al $telefonoVisible',
                            textAlign: TextAlign.center, style: T.apoyo.copyWith(color: C.azulEnlace, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// "Elige, paga y recibe": cómo comprar en tres pasos, para quien entra por primera vez.
class _TresPasos extends StatelessWidget {
  const _TresPasos();

  @override
  Widget build(BuildContext context) {
    const pasos = [('elige', 'Elige'), ('paga', 'Paga'), ('recibe', 'Recibe')];
    return Row(children: [
      for (final (i, p) in pasos.indexed) ...[
        if (i > 0) Padding(padding: const EdgeInsets.only(bottom: 22), child: Icon(LucideIcons.chevronRight, size: 20, color: C.bordeControl)),
        Expanded(
          child: Column(children: [
            ExcludeSemantics(child: Image.asset('assets/img/tutorial/${p.$1}.webp', width: 72, height: 72, cacheWidth: 200)),
            const SizedBox(height: 4),
            Text('${i + 1}. ${p.$2}', style: T.cuerpoFuerte.copyWith(fontSize: 16)),
          ]),
        ),
      ],
    ]);
  }
}
