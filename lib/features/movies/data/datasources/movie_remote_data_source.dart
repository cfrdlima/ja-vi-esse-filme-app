import '../../../../core/error/failures.dart';
import '../../../../core/network/tmdb_client.dart';
import '../../domain/entities/movie_category.dart';
import '../../domain/entities/movie_details.dart';
import '../../domain/entities/movie_page.dart';
import '../../domain/entities/search_query.dart';
import '../models/movie_details_model.dart';
import '../models/movie_model.dart';

/// Filmes do TMDB: listas e detalhes. O [TmdbClient] já converte status e
/// erros de rede em falhas tipadas; aqui só o JSON vira entidade.
class MovieRemoteDataSource {
  MovieRemoteDataSource({required this._client});

  final TmdbClient _client;

  // "Em cartaz" depende do país: sem a região, o TMDB devolve os lançamentos
  // de outros mercados.
  static const _region = 'BR';

  Future<MoviePage> byCategory(
    MovieCategory category, {
    required int page,
  }) async {
    final json = await _client.get(
      _pathOf(category),
      query: {
        'page': '$page',
        if (category == MovieCategory.nowPlaying) 'region': _region,
      },
    );
    return _parsePage(json);
  }

  Future<MoviePage> search(SearchQuery query, {required int page}) async {
    final json = await _client.get(
      'search/movie',
      query: {
        'query': query.text,
        'page': '$page',
        // O app é para 13+ (política de privacidade, seção 11). O padrão do
        // TMDB já é false, mas fica explícito para não depender dele.
        'include_adult': 'false',
      },
    );
    return _parsePage(json);
  }

  /// Detalhes com o elenco, as traduções (decisão 008) e os vídeos no mesmo
  /// pedido.
  Future<MovieDetails> details(int id) async {
    final json = await _client.get(
      'movie/$id',
      query: {
        'append_to_response': 'credits,translations,videos',
        // Sem este filtro, o `language=pt-BR` deixa só os vídeos em
        // português, e a maioria dos filmes ficaria sem trailer. O `pt`
        // sozinho só traz os de Portugal: os do Brasil pedem o `pt-BR`
        // (conferido no emulador, sessão 013).
        'include_video_language': 'pt-BR,pt,en',
      },
    );
    try {
      return MovieDetailsModel.fromJson(json).toEntity();
    } on FormatException {
      throw const UnexpectedFailure('detalhes do filme sem id');
    }
  }

  String _pathOf(MovieCategory category) => switch (category) {
    MovieCategory.popular => 'movie/popular',
    MovieCategory.nowPlaying => 'movie/now_playing',
    MovieCategory.topRated => 'movie/top_rated',
  };

  MoviePage _parsePage(Map<String, Object?> json) {
    final page = json['page'];
    final totalPages = json['total_pages'];
    if (page is! int || totalPages is! int) {
      throw const UnexpectedFailure('página de filmes sem page/total_pages');
    }
    final results = json['results'];
    return MoviePage(
      movies: [
        if (results is List<Object?>)
          for (final item in results)
            if (_tryParse(item) case final model?) model.toEntity(),
      ],
      page: page,
      totalPages: totalPages,
    );
  }

  // Um item quebrado não derruba a página inteira: ele só some da lista.
  MovieModel? _tryParse(Object? item) {
    if (item is! Map<String, Object?>) return null;
    try {
      return MovieModel.fromJson(item);
    } on FormatException {
      return null;
    }
  }
}
