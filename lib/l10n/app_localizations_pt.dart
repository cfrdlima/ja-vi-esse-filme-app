// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get tabDiscover => 'Descobrir';

  @override
  String get tabSearch => 'Buscar';

  @override
  String get tabShelf => 'Estante';

  @override
  String get tabProfile => 'Perfil';

  @override
  String get shelfTitle => 'Minha estante';

  @override
  String get comingSoon => 'Em breve';

  @override
  String get notFoundTitle => 'Página não encontrada';

  @override
  String get notFoundGoHome => 'Ir para Descobrir';

  @override
  String get discoverTitle => 'Descobrir';

  @override
  String get moviesLoading => 'Carregando filmes';

  @override
  String get discoverEmpty => 'Nenhum filme por aqui agora.';

  @override
  String get categoryPopular => 'Populares';

  @override
  String get categoryNowPlaying => 'Em cartaz';

  @override
  String get categoryTopRated => 'Mais bem avaliados';

  @override
  String get moviesLoadMoreFailed => 'Não foi possível carregar mais filmes.';

  @override
  String get retry => 'Tentar de novo';

  @override
  String retryIn(int seconds) {
    return 'Tentar de novo em $seconds s';
  }

  @override
  String retryInSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Tentar de novo em $seconds segundos',
      one: 'Tentar de novo em 1 segundo',
    );
    return '$_temp0';
  }

  @override
  String get failureNetwork => 'Sem conexão com a internet. Confira sua rede.';

  @override
  String get failureRateLimit =>
      'Muitos pedidos em pouco tempo. Espere um pouco.';

  @override
  String get failureGeneric => 'Algo deu errado ao falar com o TMDB.';

  @override
  String get movieUntitled => 'Filme sem título';
}
