import 'package:flutter/material.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/core/theme/app_theme.dart';

/// `MaterialApp` com o tema e o idioma do app, para testar uma tela isolada.
Widget testApp({required Widget home}) => MaterialApp(
  theme: AppTheme.dark(),
  locale: AppLocale.locale,
  supportedLocales: AppLocale.supportedLocales,
  localizationsDelegates: AppLocale.delegates,
  home: home,
);

/// Igual a [testApp], mas com um router no lugar da tela inicial.
Widget testRouterApp({
  required RouterConfig<Object> routerConfig,
  TransitionBuilder? builder,
}) => MaterialApp.router(
  theme: AppTheme.dark(),
  locale: AppLocale.locale,
  supportedLocales: AppLocale.supportedLocales,
  localizationsDelegates: AppLocale.delegates,
  routerConfig: routerConfig,
  builder: builder,
);
