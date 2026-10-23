import 'search_results_notifier.dart';

/// O que a aba Buscar mostra para o termo digitado.
sealed class SearchState {
  const SearchState();
}

/// Sem termo ou com um termo curto demais: nada foi pedido.
final class SearchIdle extends SearchState {
  const SearchIdle();
}

/// O termo passou do máximo e não vai ao TMDB.
final class SearchTooLong extends SearchState {
  const SearchTooLong();
}

/// Uma busca aberta; os estados da lista ficam em [results].
final class SearchActive extends SearchState {
  const SearchActive(this.results);

  final SearchResultsNotifier results;
}
