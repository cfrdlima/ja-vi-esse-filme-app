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

  /// Aviso das telas que ainda não foram construídas
  ///
  /// In pt, this message translates to:
  /// **'Em breve'**
  String get comingSoon;

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

  /// Erro 429 do TMDB
  ///
  /// In pt, this message translates to:
  /// **'Muitos pedidos em pouco tempo. Espere um pouco.'**
  String get failureRateLimit;

  /// Qualquer outra falha (401, 404, 5xx, resposta inesperada)
  ///
  /// In pt, this message translates to:
  /// **'Algo deu errado ao falar com o TMDB.'**
  String get failureGeneric;

  /// Rótulo de acessibilidade do pôster quando o TMDB não manda título nenhum
  ///
  /// In pt, this message translates to:
  /// **'Filme sem título'**
  String get movieUntitled;
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
