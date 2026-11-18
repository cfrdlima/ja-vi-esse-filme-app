import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/failure_message.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widgets/retry_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/rating.dart';
import '../../domain/entities/watched_on.dart';
import '../state/watched_diary_notifier.dart';
import '../state/watched_diary_state.dart';

/// A nota e o dia em que assistiu, abaixo das marcas (override
/// `detalhes.md`, "Nota e dia em que assistiu"). Lê o
/// [WatchedDiaryNotifier] do contexto.
class WatchedDiaryPanel extends StatelessWidget {
  const WatchedDiaryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<WatchedDiaryNotifier>();
    final spacing = Theme.of(context).extension<AppThemeTokens>()!.spacing;
    return switch (notifier.state) {
      DiaryHidden() => const SizedBox.shrink(),
      final DiaryReady ready => Padding(
        padding: EdgeInsets.only(top: spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RatingRow(rating: ready.rating, notifier: notifier),
            SizedBox(height: spacing.sm),
            _DayRow(state: ready, notifier: notifier),
            if (ready.failure case final failure?)
              _DiaryFailure(
                message: failureMessage(AppLocalizations.of(context), failure),
                onRetry: notifier.retryWrite,
              ),
          ],
        ),
      ),
    };
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.notifier});

  final Rating? rating;
  final WatchedDiaryNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rating = this.rating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // O nó das estrelas já leva o rótulo: lido aqui, sairia duas vezes.
        ExcludeSemantics(
          child: Text(l10n.diaryRatingLabel, style: theme.textTheme.titleSmall),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Um nó só, ajustável de meia em meia estrela: as estrelas
            // ficam fora da árvore de semântica.
            Semantics(
              key: const ValueKey('diary-stars'),
              label: l10n.diaryRatingLabel,
              value: _valueOf(l10n, rating),
              increasedValue: _valueOf(l10n, _step(rating, 1)),
              decreasedValue: _valueOf(l10n, _step(rating, -1)),
              onIncrease: notifier.increase,
              onDecrease: notifier.decrease,
              container: true,
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var star = 1; star <= 5; star++)
                      _Star(
                        key: ValueKey('diary-star-$star'),
                        icon: _iconFor(star, rating),
                        onPressed: () => notifier.tapStar(star),
                      ),
                  ],
                ),
              ),
            ),
            if (rating != null)
              TextButton(
                onPressed: notifier.clearRating,
                child: Text(l10n.diaryClearRating),
              ),
          ],
        ),
      ],
    );
  }

  static String _valueOf(AppLocalizations l10n, Rating? rating) =>
      rating == null ? l10n.diaryNoRating : l10n.diaryRatingValue(rating.stars);

  /// A nota depois de subir ou descer meia estrela, como no notifier.
  static Rating? _step(Rating? rating, int delta) {
    final halfStars = (rating?.halfStars ?? 0) + delta;
    if (halfStars < 1) return null;
    return Rating(halfStars.clamp(1, Rating.maxHalfStars));
  }

  static IconData _iconFor(int star, Rating? rating) {
    final halfStars = rating?.halfStars ?? 0;
    if (halfStars >= star * 2) return Icons.star;
    if (halfStars == star * 2 - 1) return Icons.star_half;
    return Icons.star_border;
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.icon, required this.onPressed, super.key});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(icon),
      color: icon == Icons.star_border
          ? colors.onSurfaceVariant
          : colors.primary,
      constraints: const BoxConstraints(
        minWidth: AppSizes.minTouchTarget,
        minHeight: AppSizes.minTouchTarget,
      ),
      onPressed: onPressed,
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.state, required this.notifier});

  final DiaryReady state;
  final WatchedDiaryNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final chosen = state.watchedOn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.diaryDayLabel, style: theme.textTheme.titleSmall),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.event),
              label: Text(
                chosen == null
                    ? l10n.diarySuggestedDay(_dateOf(state.markedOn))
                    : l10n.diaryChosenDay(_dateOf(chosen)),
                style: chosen == null
                    ? TextStyle(color: theme.colorScheme.onSurfaceVariant)
                    : null,
              ),
              onPressed: () => unawaited(_pickDay(context)),
            ),
            if (chosen != null)
              TextButton(
                onPressed: notifier.clearWatchedOn,
                child: Text(l10n.diaryClearDay),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDay(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOf(state.watchedOn ?? state.markedOn),
      firstDate: DateTime(WatchedOn.firstYear),
      lastDate: _dateOf(state.today),
    );
    if (picked == null) return;
    notifier.chooseWatchedOn(WatchedOn.fromLocal(picked));
  }

  static DateTime _dateOf(WatchedOn day) =>
      DateTime(day.year, day.month, day.day);
}

class _DiaryFailure extends StatelessWidget {
  const _DiaryFailure({required this.message, required this.onRetry});

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
