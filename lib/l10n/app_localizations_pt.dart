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
  String get searchTitle => 'Buscar';

  @override
  String get searchFieldLabel => 'Título do filme';

  @override
  String get searchClear => 'Limpar busca';

  @override
  String get searchIdle => 'Busque pelo título, em português ou no original.';

  @override
  String searchEmpty(String query) {
    return 'Nenhum filme encontrado para “$query”. Confira a grafia ou tente o título original.';
  }

  @override
  String searchTooLong(int max) {
    return 'Use até $max caracteres na busca.';
  }

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

  @override
  String runtimeHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String runtimeHours(int hours) {
    return '$hours h';
  }

  @override
  String runtimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String rating(double value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String valueString = valueNumberFormat.format(value);

    return '$valueString';
  }

  @override
  String ratingSemantics(double value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String valueString = valueNumberFormat.format(value);

    return 'Nota $valueString de 10';
  }

  @override
  String releaseDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get movieDetailsLoading => 'Carregando o filme';

  @override
  String get movieNotFound => 'Filme não encontrado.';

  @override
  String get movieOverviewTitle => 'Sinopse';

  @override
  String get movieNoOverview => 'Sinopse não disponível.';

  @override
  String get movieCastTitle => 'Elenco';

  @override
  String moviePosterOf(String title) {
    return 'Pôster de $title';
  }

  @override
  String castMemberSemantics(String name, String character) {
    return '$name, $character';
  }

  @override
  String get movieTrailersTitle => 'Trailers';

  @override
  String get trailerKindTrailer => 'Trailer';

  @override
  String get trailerKindTeaser => 'Teaser';

  @override
  String trailerSubtitle(String kind) {
    return '$kind · YouTube';
  }

  @override
  String trailerSemantics(String name, String kind) {
    return '$name, $kind. Abre no YouTube';
  }

  @override
  String get trailerOpenFailed => 'Não foi possível abrir o trailer.';
}
