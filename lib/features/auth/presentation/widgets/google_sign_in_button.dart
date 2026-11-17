import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// Botão "Entrar com o Google", desenhado conforme as diretrizes de marca do
/// Google: tema Dark, pílula, "G" oficial de 20dp e espaços de 12, 10 e 12dp
/// (override `perfil.md`). Os PNGs prontos do Google trazem o texto em inglês
/// na imagem; por isso o botão é nosso, com o texto traduzido.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({required this.onPressed, super.key});

  static const _logoAsset = 'assets/images/google_g_logo.png';

  // Medidas das diretrizes, que valem só para este botão.
  static const _logoSize = 20.0;
  static const _logoLeading = 12.0;
  static const _logoGap = 10.0;
  static const _textTrailing = 12.0;
  static const _minHeight = 48.0;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.googleButtonFill,
        foregroundColor: AppColors.googleButtonText,
        side: const BorderSide(color: AppColors.googleButtonStroke),
        shape: const StadiumBorder(),
        minimumSize: const Size(0, _minHeight),
        padding: const EdgeInsetsDirectional.only(
          start: _logoLeading,
          end: _textTrailing,
        ),
        textStyle: AppTypography.googleButton,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Image(
            image: AssetImage(_logoAsset),
            width: _logoSize,
            height: _logoSize,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: _logoGap),
          Flexible(
            child: Text(
              AppLocalizations.of(context).signInWithGoogle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
