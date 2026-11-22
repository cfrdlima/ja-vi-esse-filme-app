import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/theme/reduced_motion_page_transitions.dart';

/// Transição de mentira, para saber se o construtor caiu nela.
class _MarkerTransitions extends PageTransitionsBuilder {
  const _MarkerTransitions();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 450);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => KeyedSubtree(key: const ValueKey('transição'), child: child);
}

void main() {
  const builder = ReducedMotionPageTransitions(_MarkerTransitions());
  const page = SizedBox();

  Future<Widget> transitionOf(
    WidgetTester tester, {
    required bool disableAnimations,
  }) async {
    late Widget built;
    final route = MaterialPageRoute<void>(builder: (_) => page);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Builder(
          builder: (context) {
            built = builder.buildTransitions(
              route,
              context,
              kAlwaysCompleteAnimation,
              kAlwaysDismissedAnimation,
              page,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    return built;
  }

  testWidgets('deve trocar a página sem animação com o reduzir movimento', (
    tester,
  ) async {
    final built = await transitionOf(tester, disableAnimations: true);

    expect(built, same(page));
  });

  testWidgets('deve usar a transição de sempre sem o reduzir movimento', (
    tester,
  ) async {
    final built = await transitionOf(tester, disableAnimations: false);

    expect(built.key, const ValueKey('transição'));
  });

  test('deve manter a duração da transição de sempre', () {
    expect(builder.transitionDuration, const Duration(milliseconds: 450));
  });
}
