import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../auth/domain/entities/app_user.dart';

/// Foto da conta Google, ou um placeholder desenhado (override `perfil.md`).
/// É decorativa: o nome escrito está ao lado.
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({required this.user, super.key});

  final AppUser user;

  static const _photoHost = 'googleusercontent.com';

  /// Só carrega a foto por HTTPS e do domínio de fotos do Google, para o app
  /// não buscar uma URL qualquer que venha no perfil.
  static bool _isTrustedPhoto(Uri uri) =>
      uri.scheme == 'https' &&
      (uri.host == _photoHost || uri.host.endsWith('.$_photoHost'));

  /// A URL da foto, só quando ela é confiável.
  static String? _trustedPhotoUrl(String? url) {
    final uri = url == null ? null : Uri.tryParse(url);
    return uri != null && _isTrustedPhoto(uri) ? url : null;
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _trustedPhotoUrl(user.photoUrl);
    const size = AppSizes.profileAvatar;
    final placeholder = _AvatarPlaceholder(name: user.displayName);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: switch (photoUrl) {
            final url? => CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              memCacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                  .round(),
              placeholder: (_, _) => placeholder,
              errorWidget: (_, _, _) => placeholder,
            ),
            null => placeholder,
          },
        ),
      ),
    );
  }
}

/// Inicial do nome sobre a cor de contêiner, ou o ícone de pessoa sem nome.
class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name?.trim().characters.firstOrNull?.toUpperCase();
    return ColoredBox(
      color: theme.colorScheme.secondaryContainer,
      child: Center(
        child: switch (initial) {
          final initial? => Text(
            initial,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          null => Icon(
            Icons.person,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        },
      ),
    );
  }
}
