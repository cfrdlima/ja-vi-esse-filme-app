import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/search_query.dart';
import '../../domain/repositories/movie_repository.dart';
import 'search_results_notifier.dart';
import 'search_state.dart';

export 'search_state.dart';

/// Termo da aba Buscar. Cada termo novo abre uma lista de resultados própria e
/// descarta a anterior, e com ela qualquer resposta atrasada do termo antigo.
/// Nada do que é buscado fica guardado no aparelho.
class SearchNotifier extends ChangeNotifier {
  SearchNotifier({required this._repository});

  /// Espera depois da última tecla, para não pedir uma busca por letra.
  static const debounce = Duration(milliseconds: 400);

  final MovieRepository _repository;

  SearchState _state = const SearchIdle();
  SearchState get state => _state;

  Timer? _debounceTimer;

  /// Texto do campo a cada tecla. Termo inválido muda o estado na hora; termo
  /// válido abre a busca depois do [debounce].
  void onQueryChanged(String text) {
    _debounceTimer?.cancel();
    _withValid(text, (query) {
      _debounceTimer = Timer(debounce, () => _open(query));
    });
  }

  /// "Buscar" do teclado: abre a busca na hora, sem o [debounce].
  void submit(String text) {
    _debounceTimer?.cancel();
    _withValid(text, _open);
  }

  /// Botão de limpar: volta ao estado inicial.
  void clear() {
    _debounceTimer?.cancel();
    _show(const SearchIdle());
  }

  /// Chama [open] com o termo válido que ainda não está na tela. Termo
  /// inválido só troca o estado.
  void _withValid(String text, void Function(SearchQuery) open) {
    final SearchQuery query;
    try {
      query = SearchQuery(text);
    } on InvalidSearchQuery catch (invalid) {
      _show(switch (invalid.reason) {
        InvalidSearchQueryReason.tooShort => const SearchIdle(),
        InvalidSearchQueryReason.tooLong => const SearchTooLong(),
      });
      return;
    }
    if (_state case SearchActive(:final results) when results.query == query) {
      return;
    }
    open(query);
  }

  void _open(SearchQuery query) {
    final results = SearchResultsNotifier(
      repository: _repository,
      query: query,
    );
    _show(SearchActive(results));
    // A lista guarda o resultado, inclusive a falha, no estado.
    unawaited(results.load());
  }

  /// Troca o estado e descarta a lista anterior.
  void _show(SearchState state) {
    // Os estados sem lista são `const`, então repetir um deles (cada tecla de
    // um termo curto) é o mesmo objeto e não notifica de novo.
    if (identical(state, _state)) return;
    final previous = _state;
    _state = state;
    if (previous is SearchActive) previous.results.dispose();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_state case SearchActive(:final results)) results.dispose();
    super.dispose();
  }
}
