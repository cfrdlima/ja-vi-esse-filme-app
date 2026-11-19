import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/movie_copy.dart';
import '../../domain/repositories/shelf_repository.dart';
import '../../domain/usecases/choose_watched_on.dart';
import '../state/shelf_marks_notifier.dart';
import '../state/watched_diary_notifier.dart';
import '../state/watched_diary_state.dart';
import 'add_to_list.dart';
import 'shelf_marks_bar.dart';
import 'unwatch_dialog.dart';
import 'watched_diary_panel.dart';

/// As marcas de um filme, no assistido a nota e o dia (decisão 018) e o
/// "Adicionar à lista" (decisão 019), com os notifiers deles. Lê do contexto
/// o [ShelfRepository], o `MovieListsRepository` e o [AuthRepository],
/// montados no `main.dart`.
///
/// Sem cópia válida (título vazio ou id fora das regras, decisão 013), não
/// mostra nada: a Estante recusaria a marca.
class ShelfMarksSection extends StatelessWidget {
  const ShelfMarksSection({
    required this.movieId,
    required this.title,
    this.posterPath,
    super.key,
  });

  final int movieId;
  final String title;
  final String? posterPath;

  @override
  Widget build(BuildContext context) {
    if (!MovieCopy.canCopy(movieId: movieId, title: title)) {
      return const SizedBox.shrink();
    }
    final copy = MovieCopy(
      movieId: movieId,
      title: title,
      posterPath: posterPath,
    );
    // O de dentro ouve o de fora, e o Flutter desmonta de dentro para fora:
    // o diário para de ouvir antes de as marcas fecharem.
    return ChangeNotifierProvider(
      create: (context) => ShelfMarksNotifier(
        shelf: context.read<ShelfRepository>(),
        account: context.read<AuthRepository>().authStateChanges,
        copy: copy,
      ),
      child: ChangeNotifierProvider(
        create: (context) {
          final shelf = context.read<ShelfRepository>();
          return WatchedDiaryNotifier(
            shelf: shelf,
            chooseWatchedOn: ChooseWatchedOn(shelf: shelf, now: DateTime.now),
            watchedMovie: context.read<ShelfMarksNotifier>().watchedMovie,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShelfMarksBar(confirmUnwatch: _confirmUnwatch),
            const WatchedDiaryPanel(),
            AddToListButton(copy: copy),
          ],
        ),
      ),
    );
  }

  /// Só pergunta quando há nota ou dia para apagar.
  static Future<bool> _confirmUnwatch(BuildContext context) async =>
      switch (context.read<WatchedDiaryNotifier>().state) {
        DiaryReady(hasPersonalData: true) => UnwatchDialog.confirm(context),
        _ => true,
      };
}
