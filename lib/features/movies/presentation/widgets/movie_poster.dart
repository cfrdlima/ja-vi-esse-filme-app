import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/tmdb_image_url.dart';
import '../../../../core/theme/app_theme_tokens.dart';
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
      label: movie.title,
      image: true,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radii.md),
          child: path == null
              ? const _PosterPlaceholder()
              : CachedNetworkImage(
                  imageUrl: TmdbImageUrl.poster(path).toString(),
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const _PosterPlaceholder(),
                  errorWidget: (_, _, _) => const _PosterPlaceholder(),
                ),
        ),
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
