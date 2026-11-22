import 'package:flutter/material.dart';

/// Troca de tela que respeita o "Remover animações" do Android: com ele, a
/// página entra sem transição; sem ele, usa a [fallback].
///
/// As transições do Material não olham o `disableAnimations`, que é o que
/// esse ajuste liga no Flutter (`MASTER.md`, movimento reduzido).
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
