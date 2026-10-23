import '../../../../l10n/app_localizations.dart';

/// Duração do filme em horas e minutos ("2 h 15 min"), sem a parte que der
/// zero. A nota e a data saem direto do ARB, que já formata pelo `intl`.
String formatRuntime(AppLocalizations l10n, Duration runtime) {
  final hours = runtime.inHours;
  final minutes = runtime.inMinutes.remainder(60);
  if (hours == 0) return l10n.runtimeMinutes(minutes);
  if (minutes == 0) return l10n.runtimeHours(hours);
  return l10n.runtimeHoursMinutes(hours, minutes);
}
