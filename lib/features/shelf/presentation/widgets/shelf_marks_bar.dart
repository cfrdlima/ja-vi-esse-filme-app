import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/failure_message.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widgets/retry_button.dart';
import '../../../../core/widgets/skeleton_pulse.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/sign_in_sheet.dart';
import '../../domain/entities/shelf_mark.dart';
import '../state/shelf_marks_notifier.dart';
import '../state/shelf_marks_state.dart';

/// As marcas do filme nos Detalhes, com os 4 estados (override `detalhes.md`,
/// "Marcas"). Lê o [ShelfMarksNotifier] do contexto.
class ShelfMarksBar extends StatelessWidget {
  const ShelfMarksBar({this.confirmUnwatch, super.key});

  /// Perguntado antes de tirar o Assistido; sem ele, tira na hora. Com
  /// `false`, o Assistido fica (decisão 018: a nota e o dia saem junto).
  final Future<bool> Function(BuildContext context)? confirmUnwatch;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ShelfMarksNotifier>();
    final l10n = AppLocalizations.of(context);
    return switch (notifier.state) {
      ShelfMarksLoading() => const _MarksSkeleton(),
      ShelfMarksSignedOut() => _MarkChips(
        isMarked: (_) => false,
        onTap: (mark) => unawaited(_signInThenMark(context, mark)),
      ),
      ShelfMarksError() => _MarksMessage(
        message: l10n.shelfMarksLoadFailed,
        onRetry: notifier.retry,
      ),
      ShelfMarksReady(:final failedWrite) && final ready => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MarkChips(
            isMarked: ready.isMarked,
            onTap: (mark) => unawaited(_toggle(context, ready, mark)),
          ),
          if (failedWrite != null)
            _MarksMessage(
              message: failureMessage(l10n, failedWrite.failure),
              onRetry: notifier.retryWrite,
            ),
        ],
      ),
    };
  }

  // O notifier é lido antes do diálogo, como antes da folha de login.
  Future<void> _toggle(
    BuildContext context,
    ShelfMarksReady ready,
    ShelfMark mark,
  ) async {
    final notifier = context.read<ShelfMarksNotifier>();
    final confirm = confirmUnwatch;
    final unwatching = mark == ShelfMark.watched && ready.isMarked(mark);
    if (unwatching && confirm != null) {
      final confirmed = await confirm(context);
      if (!confirmed || !context.mounted) return;
      // Outro aparelho pode ter tirado o Assistido com o diálogo aberto: o
      // `toggle` o poria de volta.
      if (notifier.state case ShelfMarksReady(
        :final isMarked,
      ) when !isMarked(mark)) {
        return;
      }
    }
    notifier.toggle(mark);
  }

  // O notifier é lido antes da folha: o contexto pode sumir enquanto ela
  // está aberta. Se os Detalhes saíram, a marca não entra (o notifier também
  // ignora o pedido depois do dispose).
  static Future<void> _signInThenMark(
    BuildContext context,
    ShelfMark mark,
  ) async {
    final notifier = context.read<ShelfMarksNotifier>();
    final signedIn = await showSignInSheet(context);
    if (signedIn && context.mounted) notifier.queueMark(mark);
  }
}

class _MarkChips extends StatelessWidget {
  const _MarkChips({required this.isMarked, required this.onTap});

  final bool Function(ShelfMark mark) isMarked;
  final void Function(ShelfMark mark) onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppThemeTokens>()!.spacing;
    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: [
        for (final mark in ShelfMark.values)
          _MarkChip(
            mark: mark,
            selected: isMarked(mark),
            onTap: () => onTap(mark),
          ),
      ],
    );
  }
}

class _MarkChip extends StatelessWidget {
  const _MarkChip({
    required this.mark,
    required this.selected,
    required this.onTap,
  });

  final ShelfMark mark;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, outlined, filled) = switch (mark) {
      ShelfMark.watched => (
        l10n.shelfMarkWatched,
        Icons.check_circle_outline,
        Icons.check_circle,
      ),
      ShelfMark.watchlist => (
        l10n.shelfMarkWatchlist,
        Icons.bookmark_border,
        Icons.bookmark,
      ),
      ShelfMark.favorite => (
        l10n.shelfMarkFavorite,
        Icons.favorite_border,
        Icons.favorite,
      ),
    };
    // O ícone muda de forma, e não só de cor (override `detalhes.md`).
    return FilterChip(
      avatar: Icon(selected ? filled : outlined),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      onSelected: (_) => onTap(),
    );
  }
}

class _MarksMessage extends StatelessWidget {
  const _MarksMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    return Semantics(
      liveRegion: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: spacing.sm,
        children: [
          Text(message, style: theme.textTheme.bodyMedium),
          RetryButton.text(onPressed: onRetry),
        ],
      ),
    );
  }
}

class _MarksSkeleton extends StatelessWidget {
  const _MarksSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final block = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(tokens.radii.sm),
      ),
      child: const SizedBox(
        width: AppSizes.markSkeletonWidth,
        height: AppSizes.markSkeletonHeight,
      ),
    );
    return Semantics(
      label: AppLocalizations.of(context).shelfMarksLoading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: SkeletonPulse(
          builder: (_, opacity) => FadeTransition(
            opacity: opacity,
            // Mesma altura dos chips com o alvo de toque, para não pular.
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.minTouchTarget,
              ),
              child: Wrap(
                spacing: tokens.spacing.sm,
                runSpacing: tokens.spacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [for (final _ in ShelfMark.values) block],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
