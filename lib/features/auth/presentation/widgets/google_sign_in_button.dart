import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// Botão "Entrar com o Google", desenhado conforme as diretrizes de marca do
/// Google: tema Dark, pílula, "G" oficial de 20dp e espaços de 12, 10 e 12dp
/// (override `perfil.md`). Os PNGs prontos do Google trazem o texto em inglês
/// na imagem; por isso o botão é nosso, com o texto traduzido.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({required VoidCallback this.onPressed, super.key});

  /// Enquanto o seletor de contas está aberto: desabilitado, com o indicador
  /// no lugar do "G" e o mesmo texto, para o botão não mudar de largura.
  const GoogleSignInButton.loading({super.key}) : onPressed = null;

  static const _logoAsset = 'assets/images/google_g_logo.png';

  // Medidas das diretrizes, que valem só para este botão.
  static const _logoSize = 20.0;
  static const _logoLeading = 12.0;
  static const _logoGap = 10.0;
  static const _textTrailing = 12.0;
  static const _progressStroke = 2.0;
  static const _disabledOpacity = 0.38;

  /// `null` só no [GoogleSignInButton.loading].
  final VoidCallback? onPressed;

  bool get _loading => onPressed == null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.googleButtonFill,
        // Desabilitado, o fundo continua o da marca, e só o texto e a borda
        // perdem a opacidade, como o Material faz (override `perfil.md`).
        disabledBackgroundColor: AppColors.googleButtonFill,
        foregroundColor: AppColors.googleButtonText,
        disabledForegroundColor: AppColors.googleButtonText.withValues(
          alpha: _disabledOpacity,
        ),
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.disabled)
                ? AppColors.googleButtonStroke.withValues(
                    alpha: _disabledOpacity,
                  )
                : AppColors.googleButtonStroke,
          ),
        ),
        shape: const StadiumBorder(),
        minimumSize: const Size(0, AppSizes.minTouchTarget),
        padding: const EdgeInsetsDirectional.only(
          start: _logoLeading,
          end: _textTrailing,
        ),
        textStyle: AppTypography.googleButton,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_loading)
            const SizedBox.square(
              dimension: _logoSize,
              child: CircularProgressIndicator(
                strokeWidth: _progressStroke,
                color: AppColors.googleButtonText,
              ),
            )
          else
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
              l10n.signInWithGoogle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
    if (!_loading) return button;
    // `container`: sem ele, o rótulo se funde ao nó de quem estiver em volta
    // (o texto do Perfil, por exemplo), e o botão deixa de ser lido sozinho.
    return Semantics(
      container: true,
      label: l10n.signingInWithGoogle,
      excludeSemantics: true,
      button: true,
      enabled: false,
      child: button,
    );
  }
}
