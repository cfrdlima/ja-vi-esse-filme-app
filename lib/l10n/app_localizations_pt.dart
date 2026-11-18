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
  String get failureAccountDisabled => 'Esta conta foi desativada.';

  @override
  String get failureRecentLoginRequired =>
      'Por segurança, entre de novo com o Google para continuar.';

  @override
  String get failureSignInRequired =>
      'Entre com o Google para guardar seus filmes.';

  @override
  String get failureGeneric => 'Algo deu errado. Tente de novo em instantes.';

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
  String trailerUnnamedSemantics(String kind) {
    return '$kind. Abre no YouTube';
  }

  @override
  String get trailerOpenFailed => 'Não foi possível abrir o trailer.';

  @override
  String get profileAboutEntry => 'Sobre o app';

  @override
  String get profileAccountLoading => 'Carregando a conta';

  @override
  String get profileSignedOutTitle => 'Entre para guardar seus filmes';

  @override
  String get profileSignedOutBody =>
      'Com a conta, o que você já viu, quer ver e favoritou fica guardado e aparece em qualquer aparelho. Descobrir e Buscar continuam funcionando sem conta.';

  @override
  String get profileUnnamedAccount => 'Sua conta';

  @override
  String get profileSignOut => 'Sair';

  @override
  String get signInWithGoogle => 'Entrar com o Google';

  @override
  String get signingInWithGoogle => 'Entrando com o Google';

  @override
  String get aboutTitle => 'Sobre';

  @override
  String get appName => 'Já Vi Esse Filme';

  @override
  String aboutVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get aboutTmdbTitle => 'Dados e imagens';

  @override
  String get aboutTmdbLogoSemantics => 'Logo do TMDB';

  @override
  String get aboutTmdbNotice =>
      'Este app usa o TMDB e as APIs do TMDB, mas não é endossado, certificado nem aprovado de outra forma pelo TMDB.';

  @override
  String get aboutPrivacyTitle => 'Privacidade';

  @override
  String get aboutPrivacySummary =>
      'O app não tem login nem servidor próprio. As buscas vão direto ao TMDB, e o app guarda no aparelho só um cache temporário dos pôsteres. Não há anúncios nem analytics.';

  @override
  String get aboutPrivacyPolicyLink => 'Política de privacidade';

  @override
  String get aboutPrivacyPolicySubtitle => 'Abre no navegador';

  @override
  String get aboutPrivacyPolicySemantics =>
      'Política de privacidade. Abre no navegador';

  @override
  String get aboutPrivacyPolicyOpenFailed =>
      'Não foi possível abrir a política de privacidade.';

  @override
  String get aboutLicensesTitle => 'Licenças';

  @override
  String get aboutLicensesEntry => 'Licenças de código aberto';

  @override
  String get shelfMarkWatched => 'Assistido';

  @override
  String get shelfMarkWatchlist => 'Quero assistir';

  @override
  String get shelfMarkFavorite => 'Favorito';

  @override
  String get shelfMarksLoading => 'Carregando suas marcas';

  @override
  String get shelfMarksLoadFailed => 'Não deu para carregar suas marcas.';

  @override
  String get signInSheetTitle => 'Entre para guardar seus filmes';

  @override
  String get signInSheetBody =>
      'Com a conta Google, suas marcas ficam salvas e aparecem em qualquer aparelho.';

  @override
  String get profileSigningOut => 'Saindo';

  @override
  String get profileUnsyncedWarning =>
      'Algumas marcas ainda não chegaram ao servidor. Se sair agora, elas serão apagadas deste aparelho e não vão para a sua conta.';

  @override
  String get profileSignOutAnyway => 'Sair mesmo assim';

  @override
  String get profileStaySignedIn => 'Ficar na conta';

  @override
  String get shelfTabWatched => 'Assistidos';

  @override
  String get shelfTabWatchlist => 'Quero assistir';

  @override
  String get shelfTabFavorite => 'Favoritos';

  @override
  String get shelfLoading => 'Carregando sua Estante';

  @override
  String get shelfEmptyWatched => 'Nenhum filme assistido ainda.';

  @override
  String get shelfEmptyWatchlist => 'Nada na lista de quero assistir.';

  @override
  String get shelfEmptyFavorite => 'Nenhum favorito ainda.';

  @override
  String get shelfDiscoverAction => 'Descobrir filmes';

  @override
  String get shelfCopyUpdating => 'Atualizando dados do filme';

  @override
  String get shelfUpdateFailed => 'Não deu para atualizar a Estante.';

  @override
  String get shelfSignInBody =>
      'Entre para guardar os filmes que você viu, quer ver e mais gosta.';

  @override
  String shelfCapped(int count) {
    return 'Mostrando os $count filmes mais recentes.';
  }

  @override
  String get shelfSignOutFailed =>
      'Não deu para sair da conta. Tente de novo no Perfil.';

  @override
  String get shelfGoToProfile => 'Ir para o Perfil';
}
