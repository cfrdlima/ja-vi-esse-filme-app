import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';

/// Pulso de opacidade dos skeletons (override `descobrir.md`). Um controller
/// só serve a tela inteira; com o "reduzir movimento" ligado, fica parado.
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({required this.builder, super.key});

  final Widget Function(BuildContext context, Animation<double> opacity)
  builder;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.skeletonPulse,
  );
  late final _opacity =
      Tween<double>(begin: 1, end: AppMotion.skeletonMinOpacity).animate(
        CurvedAnimation(parent: _controller, curve: AppMotion.skeletonCurve),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0;
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
  Widget build(BuildContext context) => widget.builder(context, _opacity);
}
