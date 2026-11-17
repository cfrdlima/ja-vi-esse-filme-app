import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/movie_copy.dart';
import '../../domain/repositories/shelf_repository.dart';
import '../state/shelf_marks_notifier.dart';
import 'shelf_marks_bar.dart';

/// As marcas de um filme, com o notifier dele. Lê do contexto o
/// [ShelfRepository] e o [AuthRepository], montados no `main.dart`.
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
    return ChangeNotifierProvider(
      create: (context) => ShelfMarksNotifier(
        shelf: context.read<ShelfRepository>(),
        account: context.read<AuthRepository>().authStateChanges,
        copy: MovieCopy(movieId: movieId, title: title, posterPath: posterPath),
      ),
      child: const ShelfMarksBar(),
    );
  }
}
