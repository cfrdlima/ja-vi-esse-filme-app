import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/tmdb_image_url.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/movie.dart';

/// Pôster 2:3 de um filme. Sem `posterPath`, enquanto carrega ou se a imagem
/// falhar, mostra um placeholder desenhado.
class MoviePoster extends StatelessWidget {
  const MoviePoster({required this.movie, super.key});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final radii = Theme.of(context).extension<AppThemeTokens>()!.radii;
    final path = movie.posterPath;
    return Semantics(
      label: movie.title.isEmpty
          ? AppLocalizations.of(context).movieUntitled
          : movie.title,
      image: true,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radii.md),
          child: path == null
              ? const _PosterPlaceholder()
              : _PosterImage(path: path),
        ),
      ),
    );
  }
}

class _PosterImage extends StatelessWidget {
  const _PosterImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    // Decodifica na largura da célula, e não no tamanho do arquivo (w342).
    return LayoutBuilder(
      builder: (_, constraints) => CachedNetworkImage(
        imageUrl: TmdbImageUrl.poster(path).toString(),
        fit: BoxFit.cover,
        memCacheWidth: constraints.hasBoundedWidth
            ? (constraints.maxWidth * pixelRatio).round()
            : null,
        fadeInDuration: reduceMotion ? Duration.zero : AppMotion.medium,
        fadeOutDuration: reduceMotion ? Duration.zero : AppMotion.short,
        placeholder: (_, _) => const _PosterPlaceholder(),
        errorWidget: (_, _, _) => const _PosterPlaceholder(),
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainer,
      child: Center(
        child: Icon(Icons.movie_outlined, color: colors.onSurfaceVariant),
      ),
    );
  }
}
