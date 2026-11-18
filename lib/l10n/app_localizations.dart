import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('pt')];

  /// Rótulo da aba Descobrir na barra de navegação e título da tela dela
  ///
  /// In pt, this message translates to:
  /// **'Descobrir'**
  String get tabDiscover;

  /// Rótulo da aba Buscar e título da tela dela
  ///
  /// In pt, this message translates to:
  /// **'Buscar'**
  String get tabSearch;

  /// Rótulo curto da aba da estante; precisa caber na barra com fonte 1.3x
  ///
  /// In pt, this message translates to:
  /// **'Estante'**
  String get tabShelf;

  /// Rótulo da aba Perfil e título da tela dela
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get tabProfile;

  /// Título da tela da estante
  ///
  /// In pt, this message translates to:
  /// **'Minha estante'**
  String get shelfTitle;

  /// Título da tela de rota desconhecida
  ///
  /// In pt, this message translates to:
  /// **'Página não encontrada'**
  String get notFoundTitle;

  /// Botão da tela de rota desconhecida que leva à aba Descobrir
  ///
  /// In pt, this message translates to:
  /// **'Ir para Descobrir'**
  String get notFoundGoHome;

  /// Título da tela Descobrir; separado de tabDiscover para que encurtar o rótulo da aba não mude o título
  ///
  /// In pt, this message translates to:
  /// **'Descobrir'**
  String get discoverTitle;

  /// Anúncio do leitor de tela enquanto uma grade de filmes (Descobrir, Buscar) carrega
  ///
  /// In pt, this message translates to:
  /// **'Carregando filmes'**
  String get moviesLoading;

  /// Estado vazio da categoria escolhida, que vem do TMDB e não do usuário
  ///
  /// In pt, this message translates to:
  /// **'Nenhum filme por aqui agora.'**
  String get discoverEmpty;

  /// Título da tela Buscar; separado de tabSearch para que encurtar o rótulo da aba não mude o título
  ///
  /// In pt, this message translates to:
  /// **'Buscar'**
  String get searchTitle;

  /// Rótulo visível do campo de busca
  ///
  /// In pt, this message translates to:
  /// **'Título do filme'**
  String get searchFieldLabel;

  /// Tooltip e rótulo do leitor de tela do botão que apaga o termo digitado
  ///
  /// In pt, this message translates to:
  /// **'Limpar busca'**
  String get searchClear;

  /// Estado inicial da Buscar, sem termo ou com termo curto demais
  ///
  /// In pt, this message translates to:
  /// **'Busque pelo título, em português ou no original.'**
  String get searchIdle;

  /// Estado vazio da Buscar, com o termo digitado e uma sugestão
  ///
  /// In pt, this message translates to:
  /// **'Nenhum filme encontrado para “{query}”. Confira a grafia ou tente o título original.'**
  String searchEmpty(String query);

  /// Aviso quando o termo passa do tamanho máximo e não é buscado
  ///
  /// In pt, this message translates to:
  /// **'Use até {max} caracteres na busca.'**
  String searchTooLong(int max);

  /// Categoria da Descobrir: filmes populares no TMDB
  ///
  /// In pt, this message translates to:
  /// **'Populares'**
  String get categoryPopular;

  /// Categoria da Descobrir: filmes nos cinemas do Brasil agora
  ///
  /// In pt, this message translates to:
  /// **'Em cartaz'**
  String get categoryNowPlaying;

  /// Categoria da Descobrir: filmes com as maiores notas no TMDB
  ///
  /// In pt, this message translates to:
  /// **'Mais bem avaliados'**
  String get categoryTopRated;

  /// Rodapé da grade quando a próxima página falha; os filmes já carregados continuam
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar mais filmes.'**
  String get moviesLoadMoreFailed;

  /// Botão que repete a última ação que falhou
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get retry;

  /// Botão desabilitado enquanto corre a espera pedida pelo TMDB depois de um limite de requisições (429)
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo em {seconds} s'**
  String retryIn(int seconds);

  /// O mesmo que retryIn, para o leitor de tela, que leria o "s" como letra
  ///
  /// In pt, this message translates to:
  /// **'{seconds, plural, =1{Tentar de novo em 1 segundo} other{Tentar de novo em {seconds} segundos}}'**
  String retryInSemantics(int seconds);

  /// Erro de rede, DNS, TLS ou tempo esgotado
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão com a internet. Confira sua rede.'**
  String get failureNetwork;

  /// Erro 429 do TMDB ou excesso de tentativas no login (too-many-requests)
  ///
  /// In pt, this message translates to:
  /// **'Muitos pedidos em pouco tempo. Espere um pouco.'**
  String get failureRateLimit;

  /// Login recusado porque a conta foi desativada no Firebase (user-disabled)
  ///
  /// In pt, this message translates to:
  /// **'Esta conta foi desativada.'**
  String get failureAccountDisabled;

  /// Ação sensível, como excluir a conta, que pede login recente (requires-recent-login)
  ///
  /// In pt, this message translates to:
  /// **'Por segurança, entre de novo com o Google para continuar.'**
  String get failureRecentLoginRequired;

  /// Ação que precisa de conta, como marcar um filme, sem ninguém logado
  ///
  /// In pt, this message translates to:
  /// **'Entre com o Google para guardar seus filmes.'**
  String get failureSignInRequired;

  /// Qualquer outra falha do TMDB (401, 404, 5xx, resposta inesperada) ou da conta. Neutra: não cita o TMDB
  ///
  /// In pt, this message translates to:
  /// **'Algo deu errado. Tente de novo em instantes.'**
  String get failureGeneric;

  /// Rótulo de acessibilidade do pôster quando o TMDB não manda título nenhum
  ///
  /// In pt, this message translates to:
  /// **'Filme sem título'**
  String get movieUntitled;

  /// Duração do filme com horas e minutos, nos detalhes
  ///
  /// In pt, this message translates to:
  /// **'{hours} h {minutes} min'**
  String runtimeHoursMinutes(int hours, int minutes);

  /// Duração do filme em horas exatas, nos detalhes
  ///
  /// In pt, this message translates to:
  /// **'{hours} h'**
  String runtimeHours(int hours);

  /// Duração do filme abaixo de uma hora, nos detalhes
  ///
  /// In pt, this message translates to:
  /// **'{minutes} min'**
  String runtimeMinutes(int minutes);

  /// Nota do TMDB (0 a 10) com uma casa decimal, ao lado da estrela nos detalhes
  ///
  /// In pt, this message translates to:
  /// **'{value}'**
  String rating(double value);

  /// A nota para o leitor de tela, com a escala
  ///
  /// In pt, this message translates to:
  /// **'Nota {value} de 10'**
  String ratingSemantics(double value);

  /// Data de lançamento no formato curto do idioma (dd/MM/aaaa no pt-BR)
  ///
  /// In pt, this message translates to:
  /// **'{date}'**
  String releaseDate(DateTime date);

  /// Anúncio do leitor de tela enquanto os detalhes do filme carregam
  ///
  /// In pt, this message translates to:
  /// **'Carregando o filme'**
  String get movieDetailsLoading;

  /// Detalhes de um filme que o TMDB não tem (404) ou endereço com id inválido
  ///
  /// In pt, this message translates to:
  /// **'Filme não encontrado.'**
  String get movieNotFound;

  /// Título da seção de sinopse nos detalhes
  ///
  /// In pt, this message translates to:
  /// **'Sinopse'**
  String get movieOverviewTitle;

  /// Quando o filme não tem sinopse em pt-BR nem no idioma original
  ///
  /// In pt, this message translates to:
  /// **'Sinopse não disponível.'**
  String get movieNoOverview;

  /// Título da seção de elenco nos detalhes
  ///
  /// In pt, this message translates to:
  /// **'Elenco'**
  String get movieCastTitle;

  /// Rótulo de acessibilidade do pôster no cabeçalho dos detalhes
  ///
  /// In pt, this message translates to:
  /// **'Pôster de {title}'**
  String moviePosterOf(String title);

  /// O leitor de tela lê a pessoa do elenco e o personagem num nó só
  ///
  /// In pt, this message translates to:
  /// **'{name}, {character}'**
  String castMemberSemantics(String name, String character);

  /// Título da seção de trailers nos detalhes
  ///
  /// In pt, this message translates to:
  /// **'Trailers'**
  String get movieTrailersTitle;

  /// Tipo de vídeo: trailer completo
  ///
  /// In pt, this message translates to:
  /// **'Trailer'**
  String get trailerKindTrailer;

  /// Tipo de vídeo: teaser, mais curto que o trailer
  ///
  /// In pt, this message translates to:
  /// **'Teaser'**
  String get trailerKindTeaser;

  /// Linha abaixo do nome do trailer: o tipo e onde ele abre
  ///
  /// In pt, this message translates to:
  /// **'{kind} · YouTube'**
  String trailerSubtitle(String kind);

  /// O leitor de tela lê o trailer como link que sai do app
  ///
  /// In pt, this message translates to:
  /// **'{name}, {kind}. Abre no YouTube'**
  String trailerSemantics(String name, String kind);

  /// Leitor de tela no trailer sem nome: o tipo já faz as vezes do nome
  ///
  /// In pt, this message translates to:
  /// **'{kind}. Abre no YouTube'**
  String trailerUnnamedSemantics(String kind);

  /// Aviso quando nenhum app do aparelho abre o trailer
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o trailer.'**
  String get trailerOpenFailed;

  /// Entrada do Perfil que abre a tela Sobre
  ///
  /// In pt, this message translates to:
  /// **'Sobre o app'**
  String get profileAboutEntry;

  /// Anúncio do leitor de tela enquanto o Perfil espera o estado da conta
  ///
  /// In pt, this message translates to:
  /// **'Carregando a conta'**
  String get profileAccountLoading;

  /// Título do Perfil sem conta, acima do botão Entrar com o Google
  ///
  /// In pt, this message translates to:
  /// **'Entre para guardar seus filmes'**
  String get profileSignedOutTitle;

  /// Texto de apoio do Perfil sem conta: o que a conta guarda e que o login é opcional
  ///
  /// In pt, this message translates to:
  /// **'Com a conta, o que você já viu, quer ver e favoritou fica guardado e aparece em qualquer aparelho. Descobrir e Buscar continuam funcionando sem conta.'**
  String get profileSignedOutBody;

  /// Nome mostrado no Perfil quando a conta Google não tem nome público
  ///
  /// In pt, this message translates to:
  /// **'Sua conta'**
  String get profileUnnamedAccount;

  /// Botão do Perfil que encerra a sessão da conta
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get profileSignOut;

  /// Texto do botão de login, traduzido de "Sign in with Google" como as diretrizes de marca do Google permitem
  ///
  /// In pt, this message translates to:
  /// **'Entrar com o Google'**
  String get signInWithGoogle;

  /// Rótulo do leitor de tela para o botão de login enquanto o seletor de contas está aberto
  ///
  /// In pt, this message translates to:
  /// **'Entrando com o Google'**
  String get signingInWithGoogle;

  /// Título da tela Sobre
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get aboutTitle;

  /// Nome do app, a marca mais destacada da tela Sobre
  ///
  /// In pt, this message translates to:
  /// **'Já Vi Esse Filme'**
  String get appName;

  /// Versão do app na tela Sobre
  ///
  /// In pt, this message translates to:
  /// **'Versão {version}'**
  String aboutVersion(String version);

  /// Título da seção de atribuição ao TMDB
  ///
  /// In pt, this message translates to:
  /// **'Dados e imagens'**
  String get aboutTmdbTitle;

  /// Texto alternativo do logo do TMDB
  ///
  /// In pt, this message translates to:
  /// **'Logo do TMDB'**
  String get aboutTmdbLogoSemantics;

  /// Tradução do aviso de não endosso exigido pelos termos do TMDB; o original em inglês fica fora do ARB
  ///
  /// In pt, this message translates to:
  /// **'Este app usa o TMDB e as APIs do TMDB, mas não é endossado, certificado nem aprovado de outra forma pelo TMDB.'**
  String get aboutTmdbNotice;

  /// Título da seção de privacidade da tela Sobre
  ///
  /// In pt, this message translates to:
  /// **'Privacidade'**
  String get aboutPrivacyTitle;

  /// Resumo da política de privacidade; acompanha a versão publicada (decisão 006)
  ///
  /// In pt, this message translates to:
  /// **'O app não tem login nem servidor próprio. As buscas vão direto ao TMDB, e o app guarda no aparelho só um cache temporário dos pôsteres. Não há anúncios nem analytics.'**
  String get aboutPrivacySummary;

  /// Link que abre a política publicada no GitHub Pages
  ///
  /// In pt, this message translates to:
  /// **'Política de privacidade'**
  String get aboutPrivacyPolicyLink;

  /// Aviso abaixo do link da política de que ele sai do app
  ///
  /// In pt, this message translates to:
  /// **'Abre no navegador'**
  String get aboutPrivacyPolicySubtitle;

  /// O leitor de tela lê o link da política como link que sai do app
  ///
  /// In pt, this message translates to:
  /// **'Política de privacidade. Abre no navegador'**
  String get aboutPrivacyPolicySemantics;

  /// Aviso quando nenhum app do aparelho abre a política
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir a política de privacidade.'**
  String get aboutPrivacyPolicyOpenFailed;

  /// Título da seção de licenças da tela Sobre
  ///
  /// In pt, this message translates to:
  /// **'Licenças'**
  String get aboutLicensesTitle;

  /// Entrada que abre a página de licenças do Flutter
  ///
  /// In pt, this message translates to:
  /// **'Licenças de código aberto'**
  String get aboutLicensesEntry;

  /// Marca de filme já assistido, nos Detalhes
  ///
  /// In pt, this message translates to:
  /// **'Assistido'**
  String get shelfMarkWatched;

  /// Marca de filme que a pessoa quer assistir, nos Detalhes
  ///
  /// In pt, this message translates to:
  /// **'Quero assistir'**
  String get shelfMarkWatchlist;

  /// Marca de filme favorito, nos Detalhes
  ///
  /// In pt, this message translates to:
  /// **'Favorito'**
  String get shelfMarkFavorite;

  /// Anúncio do leitor de tela enquanto as marcas do filme carregam nos Detalhes
  ///
  /// In pt, this message translates to:
  /// **'Carregando suas marcas'**
  String get shelfMarksLoading;

  /// Erro ao ler as marcas do filme nos Detalhes, ao lado do Tentar de novo
  ///
  /// In pt, this message translates to:
  /// **'Não deu para carregar suas marcas.'**
  String get shelfMarksLoadFailed;

  /// Título da folha de login que abre ao marcar um filme sem conta
  ///
  /// In pt, this message translates to:
  /// **'Entre para guardar seus filmes'**
  String get signInSheetTitle;

  /// Texto da folha de login que abre ao marcar um filme sem conta
  ///
  /// In pt, this message translates to:
  /// **'Com a conta Google, suas marcas ficam salvas e aparecem em qualquer aparelho.'**
  String get signInSheetBody;

  /// Botão Sair desabilitado enquanto o app espera as marcas chegarem ao servidor (até 5 s)
  ///
  /// In pt, this message translates to:
  /// **'Saindo'**
  String get profileSigningOut;

  /// Aviso no Perfil quando o logout acharia marcas feitas offline e ainda não sincronizadas
  ///
  /// In pt, this message translates to:
  /// **'Algumas marcas ainda não chegaram ao servidor. Se sair agora, elas serão apagadas deste aparelho e não vão para a sua conta.'**
  String get profileUnsyncedWarning;

  /// Confirma o logout apesar das marcas não sincronizadas
  ///
  /// In pt, this message translates to:
  /// **'Sair mesmo assim'**
  String get profileSignOutAnyway;

  /// Desiste do logout para as marcas não sincronizadas chegarem ao servidor
  ///
  /// In pt, this message translates to:
  /// **'Ficar na conta'**
  String get profileStaySignedIn;

  /// Aba da Estante com os filmes assistidos
  ///
  /// In pt, this message translates to:
  /// **'Assistidos'**
  String get shelfTabWatched;

  /// Aba da Estante com os filmes que a pessoa quer assistir
  ///
  /// In pt, this message translates to:
  /// **'Quero assistir'**
  String get shelfTabWatchlist;

  /// Aba da Estante com os filmes favoritos
  ///
  /// In pt, this message translates to:
  /// **'Favoritos'**
  String get shelfTabFavorite;

  /// Anúncio do leitor de tela enquanto uma aba da Estante carrega
  ///
  /// In pt, this message translates to:
  /// **'Carregando sua Estante'**
  String get shelfLoading;

  /// Vazio da aba Assistidos
  ///
  /// In pt, this message translates to:
  /// **'Nenhum filme assistido ainda.'**
  String get shelfEmptyWatched;

  /// Vazio da aba Quero assistir
  ///
  /// In pt, this message translates to:
  /// **'Nada na lista de quero assistir.'**
  String get shelfEmptyWatchlist;

  /// Vazio da aba Favoritos
  ///
  /// In pt, this message translates to:
  /// **'Nenhum favorito ainda.'**
  String get shelfEmptyFavorite;

  /// Botão do vazio da Estante que leva à aba Descobrir
  ///
  /// In pt, this message translates to:
  /// **'Descobrir filmes'**
  String get shelfDiscoverAction;

  /// Rótulo do pôster na Estante quando a cópia do TMDB venceu e está sendo renovada
  ///
  /// In pt, this message translates to:
  /// **'Atualizando dados do filme'**
  String get shelfCopyUpdating;

  /// Erro no rodapé da Estante, com os filmes já na tela, ao lado do Tentar de novo
  ///
  /// In pt, this message translates to:
  /// **'Não deu para atualizar a Estante.'**
  String get shelfUpdateFailed;

  /// Convite para entrar na aba Estante sem conta
  ///
  /// In pt, this message translates to:
  /// **'Entre para guardar os filmes que você viu, quer ver e mais gosta.'**
  String get shelfSignInBody;

  /// Rodapé da aba da Estante quando ela chega ao teto de filmes por aba e ainda há mais
  ///
  /// In pt, this message translates to:
  /// **'Mostrando os {count} filmes mais recentes.'**
  String shelfCapped(int count);

  /// Aviso na Estante quando a saída da conta falhou; as abas não voltam até sair ou reiniciar
  ///
  /// In pt, this message translates to:
  /// **'Não deu para sair da conta. Tente de novo no Perfil.'**
  String get shelfSignOutFailed;

  /// Botão do aviso de saída que falhou, na Estante, que leva à aba Perfil
  ///
  /// In pt, this message translates to:
  /// **'Ir para o Perfil'**
  String get shelfGoToProfile;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
