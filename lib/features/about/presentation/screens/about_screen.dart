import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Atribuição ao TMDB, política de privacidade e licenças.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).aboutTitle)),
    );
  }
}
