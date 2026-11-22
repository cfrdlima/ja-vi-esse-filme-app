import 'package:flutter/material.dart';

/// Troca de tela que respeita o "Remover animações" do Android: com ele, a
/// página entra sem transição; sem ele, usa a [fallback].
///
/// As transições do Material não olham o `disableAnimations`, que é o que
/// esse ajuste liga no Flutter. O controller da rota já encurta a animação
/// para 5% (os 800ms viram cerca de 40ms); aqui ela vai a zero
/// (`MASTER.md`, movimento reduzido).
///
/// Escolhas conscientes (`/revisar` da sessão 030): com o ajuste ligado, o
/// gesto de voltar perde a prévia animada do `PredictiveBack`, mas continua
/// voltando; e o Hero do pôster ainda voa nos cerca de 40ms da rota.
class ReducedMotionPageTransitions extends PageTransitionsBuilder {
  const ReducedMotionPageTransitions(this.fallback);

  final PageTransitionsBuilder fallback;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      fallback.delegatedTransition;

  @override
  Duration get transitionDuration => fallback.transitionDuration;

  @override
  Duration get reverseTransitionDuration => fallback.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MediaQuery.disableAnimationsOf(context)
      ? child
      : fallback.buildTransitions(
          route,
          context,
          animation,
          secondaryAnimation,
          child,
        );
}
