import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/tmdb_image_url.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/movie.dart';

/// Pôster 2:3 de um filme. Sem `posterPath`, enquanto carrega ou se a imagem
/// falhar, mostra um placeholder desenhado. Com [onTap], vira um botão do
/// tamanho do pôster.
class MoviePoster extends StatelessWidget {
  /// Pôster da grade, lido pelo título do filme.
  MoviePoster({required Movie movie, this.onTap, super.key})
    : posterPath = movie.posterPath,
      label = movie.title;

  /// Pôster lido pelo [label], como o "Pôster de…" do cabeçalho dos Detalhes,
  /// que não tem um `Movie` em mãos.
  const MoviePoster.labeled({
    required this.posterPath,
    required this.label,
    super.key,
  }) : onTap = null;

  final String? posterPath;

  /// O que o leitor de tela lê; vazio vira "sem título".
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radii = Theme.of(context).extension<AppThemeTokens>()!.radii;
    final path = posterPath;
    final onTap = this.onTap;
    return Semantics(
      label: label.isEmpty ? AppLocalizations.of(context).movieUntitled : label,
      image: true,
      // O `excludeSemantics` tira a ação do InkWell da árvore; ela é repetida
      // aqui para o leitor de tela poder tocar.
      button: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radii.md),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (path == null)
                const _PosterPlaceholder()
              else
                _PosterImage(path: path),
              // O ripple fica por cima: por baixo, a imagem o esconderia.
              if (onTap != null)
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(onTap: onTap),
                ),
            ],
          ),
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
    // Decodifica no tamanho do arquivo (w342), sem `memCacheWidth`: a grade,
    // os detalhes e o Hero em voo dividem a mesma imagem no cache, e o pôster
    // voa já desenhado, sem passar pelo placeholder.
    return CachedNetworkImage(
      imageUrl: TmdbImageUrl.poster(path).toString(),
      fit: BoxFit.cover,
      fadeInDuration: reduceMotion ? Duration.zero : AppMotion.medium,
      fadeOutDuration: reduceMotion ? Duration.zero : AppMotion.short,
      placeholder: (_, _) => const _PosterPlaceholder(),
      errorWidget: (_, _, _) => const _PosterPlaceholder(),
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
