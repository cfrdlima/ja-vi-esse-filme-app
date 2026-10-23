import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

enum _RetryButtonVariant { filled, text }

/// "Tentar de novo" que, com uma [wait], fica desabilitado e mostra os
/// segundos que faltam. A contagem começa quando o botão aparece; reconstruir
/// com a mesma espera não a recomeça, e uma espera diferente, sim.
class RetryButton extends StatefulWidget {
  const RetryButton.filled({
    required this.onPressed,
    this.wait = Duration.zero,
    super.key,
  }) : _variant = _RetryButtonVariant.filled;

  const RetryButton.text({
    required this.onPressed,
    this.wait = Duration.zero,
    super.key,
  }) : _variant = _RetryButtonVariant.text;

  /// O `Retry-After` vem do servidor; um valor enorme não pode travar o botão.
  static const maxWait = Duration(seconds: 60);

  final VoidCallback onPressed;
  final Duration wait;
  final _RetryButtonVariant _variant;

  @override
  State<RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<RetryButton> {
  static const _tick = Duration(seconds: 1);

  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(RetryButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wait != widget.wait) _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    final millis = widget.wait.inMilliseconds.clamp(
      0,
      RetryButton.maxWait.inMilliseconds,
    );
    _secondsLeft = (millis / Duration.millisecondsPerSecond).ceil();
    if (_secondsLeft > 0) _timer = Timer.periodic(_tick, (_) => _countDown());
  }

  void _countDown() {
    setState(() => _secondsLeft--);
    if (_secondsLeft == 0) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final waiting = _secondsLeft > 0;
    final onPressed = waiting ? null : widget.onPressed;
    final label = Text(waiting ? l10n.retryIn(_secondsLeft) : l10n.retry);
    return switch (widget._variant) {
      _RetryButtonVariant.filled => FilledButton(
        onPressed: onPressed,
        child: label,
      ),
      _RetryButtonVariant.text => TextButton(
        onPressed: onPressed,
        child: label,
      ),
    };
  }
}
