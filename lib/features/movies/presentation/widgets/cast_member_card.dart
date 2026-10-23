import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/tmdb_image_url.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/cast_member.dart';

/// Uma pessoa do elenco: foto 2:3, nome e personagem. O leitor de tela lê
/// tudo num nó só, e a foto é decorativa dentro dele.
class CastMemberCard extends StatelessWidget {
  const CastMemberCard({required this.member, super.key});

  final CastMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final character = member.character;
    // Cresce na escala do texto do nome: com a largura fixa, o nome quebrava
    // no meio da palavra na fonte grande. A escala do Android é não linear,
    // por isso o fator vem do tamanho da fonte do nome, e não de 96.
    final nameSize = theme.textTheme.bodyMedium!.fontSize!;
    final width =
        AppSizes.castPhotoWidth *
        MediaQuery.textScalerOf(context).scale(nameSize) /
        nameSize;
    return Semantics(
      label: character.isEmpty
          ? member.name
          : AppLocalizations.of(
              context,
            ).castMemberSemantics(member.name, character),
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radii.md),
                child: _CastPhoto(path: member.profilePath, width: width),
              ),
            ),
            SizedBox(height: tokens.spacing.xs),
            Text(
              member.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            if (character.isNotEmpty)
              Text(
                character,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CastPhoto extends StatelessWidget {
  const _CastPhoto({required this.path, required this.width});

  final String? path;
  final double width;

  @override
  Widget build(BuildContext context) {
    final path = this.path;
    if (path == null) return const _PhotoPlaceholder();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return CachedNetworkImage(
      imageUrl: TmdbImageUrl.profile(path).toString(),
      fit: BoxFit.cover,
      memCacheWidth: (width * pixelRatio).round(),
      fadeInDuration: reduceMotion ? Duration.zero : AppMotion.medium,
      fadeOutDuration: reduceMotion ? Duration.zero : AppMotion.short,
      placeholder: (_, _) => const _PhotoPlaceholder(),
      errorWidget: (_, _, _) => const _PhotoPlaceholder(),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainer,
      child: Center(
        child: Icon(Icons.person_outline, color: colors.onSurfaceVariant),
      ),
    );
  }
}
