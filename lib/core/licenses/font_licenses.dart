import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Põe as licenças das fontes empacotadas na página de licenças do app. O
/// Flutter só junta sozinho as licenças dos pacotes, e a OFL pede que a
/// licença acompanhe a fonte.
void registerFontLicenses() {
  LicenseRegistry.addLicense(_fontLicenses);
}

Stream<LicenseEntry> _fontLicenses() async* {
  yield LicenseEntryWithLineBreaks(const [
    'Inter',
  ], await rootBundle.loadString('assets/fonts/Inter-OFL.txt'));
  yield LicenseEntryWithLineBreaks(const [
    'Playfair Display',
  ], await rootBundle.loadString('assets/fonts/PlayfairDisplay-OFL.txt'));
}
