import '../entities/list_name.dart';
import '../entities/movie_copy.dart';
import '../entities/movie_list.dart';
import '../entities/shelf_movie.dart';
import '../entities/shelf_page.dart';

/// As listas personalizadas do usuário logado (decisão 019): cada lista em
/// `users/{uid}/lists/{listId}`, só com o nome, e os filmes dela no mapa
/// `lists` do documento de cada filme. As falhas são as de
/// `core/error/failures.dart`, e sem ninguém logado tudo falha com
/// `SignInRequiredFailure`.
///
/// **Offline**, como no `ShelfRepository`: criar, renomear, pôr e tirar
/// filme não falham, aparecem nos streams na hora e só completam quando o
/// servidor confirma. A UI não espera por eles. Só apagar uma lista precisa
/// do servidor.
abstract interface class MovieListsRepository {
  /// Emite as listas em ordem alfabética (`MovieList.sortedByName`) ao
  /// assinar e a cada mudança. O stream pode emitir erro com
  /// `NetworkFailure` ou `UnexpectedFailure`.
  Stream<List<MovieList>> watchLists();

  /// Uma lista nova com o id já escolhido, sem gravar nada: a UI mostra a
  /// lista e pode pôr um filme nela antes de o servidor confirmar.
  MovieList newList(ListName name);

  /// Quantas listas a conta tem, do servidor ou, offline, do aparelho.
  Future<int> countLists();

  /// Grava a [list] criada pelo [newList]. Pode falhar com
  /// `RateLimitFailure` (cota esgotada), `NetworkFailure` (só se o servidor
  /// recusar por prazo) ou `UnexpectedFailure`.
  Future<void> createList(MovieList list);

  /// Troca o nome da [list]. Uma lista que não existe mais conta como
  /// sucesso. As mesmas falhas do [createList].
  Future<void> renameList(MovieList list, ListName name);

  /// Tira a [list] de todos os filmes, lendo do servidor em lotes, e só
  /// depois apaga a lista (decisão 019). Uma falha no meio deixa a lista
  /// com menos filmes, e tentar de novo termina. Falha com `NetworkFailure`
  /// sem rede ou depois do prazo de cada passo.
  Future<void> deleteList(MovieList list);

  /// Emite os filmes da [list], o que entrou por último primeiro, até o
  /// [limit], como o `ShelfRepository.watchShelf`.
  ///
  /// Lança [ArgumentError] com [limit] menor que 1.
  Stream<ShelfPage> watchList(MovieList list, {required int limit});

  /// Quantos filmes a [list] tem, do servidor ou, offline, do aparelho.
  Future<int> countMovies(MovieList list);

  /// Põe o filme da [copy] na [list] com a hora do servidor e regrava a
  /// cópia, o que renova o prazo dela. Cria o documento do filme se ele não
  /// existir. As mesmas falhas do [createList].
  Future<void> addToList(MovieCopy copy, MovieList list);

  /// Tira o [movie] da [list]. Se o filme não tiver marca nem outra lista,
  /// apaga o documento. Um documento que não existe mais conta como
  /// sucesso. As mesmas falhas do [createList].
  Future<void> removeFromList(ShelfMovie movie, MovieList list);

  /// Encerra os streams ainda abertos, como o `ShelfRepository.closeStreams`.
  Future<void> closeStreams();
}
