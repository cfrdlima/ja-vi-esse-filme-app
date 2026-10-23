import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_theme_tokens.dart';

/// Célula 2:3 de carregamento, com o mesmo formato do pôster. Pulsa a
/// opacidade, e fica parada com o "reduzir movimento" ligado.
class PosterSkeleton extends StatefulWidget {
  const PosterSkeleton({super.key});

  @override
  State<PosterSkeleton> createState() => _PosterSkeletonState();
}

class _PosterSkeletonState extends State<PosterSkeleton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.skeletonPulse,
  );
  late final _opacity = Tween<double>(
    begin: 1,
    end: 0.5,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 0;
      _controller.stop();
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radii = theme.extension<AppThemeTokens>()!.radii;
    return FadeTransition(
      opacity: _opacity,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(radii.md),
          ),
        ),
      ),
    );
  }
}
