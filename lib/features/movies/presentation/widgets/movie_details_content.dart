import 'package:flutter/material.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/movie_details.dart';
import '../formatting/movie_format.dart';
import 'cast_member_card.dart';
import 'movie_poster.dart';
import 'poster_hero.dart';

/// Sucesso dos detalhes: cabeçalho, gêneros, sinopse e elenco (override
/// `detalhes.md`). O que o TMDB não mandou some, sem traço.
class MovieDetailsContent extends StatelessWidget {
  const MovieDetailsContent({required this.details, this.posterKey, super.key});

  final MovieDetails details;

  /// Chave do pôster, a mesma do skeleton: ver [MovieDetailsSkeleton.posterKey].
  final Key? posterKey;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.md),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.readableWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(details: details, posterKey: posterKey),
              if (details.genres.isNotEmpty) ...[
                SizedBox(height: spacing.md),
                _Genres(genres: details.genres),
              ],
              SizedBox(height: spacing.lg),
              _SectionTitle(text: l10n.movieOverviewTitle),
              SizedBox(height: spacing.sm),
              _Overview(text: details.overview),
              if (details.cast.isNotEmpty) ...[
                SizedBox(height: spacing.lg),
                _SectionTitle(text: l10n.movieCastTitle),
                SizedBox(height: spacing.sm),
                _CastRow(details: details),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.details, required this.posterKey});

  final MovieDetails details;
  final Key? posterKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    final title = details.title.isEmpty ? l10n.movieUntitled : details.title;
    final releaseDate = details.releaseDate;
    final runtime = details.runtime;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppSizes.detailsPosterWidth,
          child: Semantics(
            label: l10n.moviePosterOf(title),
            image: true,
            excludeSemantics: true,
            child: PosterHero(
              key: posterKey,
              movieId: details.id,
              child: MoviePoster(
                movie: Movie(
                  id: details.id,
                  title: title,
                  posterPath: details.posterPath,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: spacing.xs,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
              if (releaseDate != null)
                _Meta(text: l10n.releaseDate(releaseDate)),
              if (runtime != null) _Meta(text: formatRuntime(l10n, runtime)),
              if (details.voteAverage > 0)
                _Rating(voteAverage: details.voteAverage),
            ],
          ),
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _Rating extends StatelessWidget {
  const _Rating({required this.voteAverage});

  final double voteAverage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.ratingSemantics(voteAverage),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: theme.colorScheme.primary),
          SizedBox(width: spacing.xs),
          Text(l10n.rating(voteAverage), style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// Rótulos não interativos que quebram linha com fonte grande.
class _Genres extends StatelessWidget {
  const _Genres({required this.genres});

  final List<String> genres;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppThemeTokens>()!.spacing;
    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: [for (final genre in genres) Chip(label: Text(genre))],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Overview extends StatelessWidget {
  const _Overview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (text.isNotEmpty) return Text(text, style: theme.textTheme.bodyLarge);
    return Text(
      AppLocalizations.of(context).movieNoOverview,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Fileira horizontal sem altura fixa: são no máximo 15 pessoas, e a altura
/// acompanha a fonte grande (override `detalhes.md`).
class _CastRow extends StatelessWidget {
  const _CastRow({required this.details});

  final MovieDetails details;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppThemeTokens>()!.spacing;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: spacing.sm,
        children: [
          for (final member in details.cast) CastMemberCard(member: member),
        ],
      ),
    );
  }
}
