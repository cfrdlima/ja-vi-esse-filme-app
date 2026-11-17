import '../../../../core/error/failures.dart';
import '../../domain/entities/shelf_mark.dart';

/// As marcas de um filme nos Detalhes. A tela faz `switch` exaustivo nele.
sealed class ShelfMarksState {
  const ShelfMarksState();
}

/// Ainda sem a conta, ou logado e sem o primeiro evento da Estante.
final class ShelfMarksLoading extends ShelfMarksState {
  const ShelfMarksLoading();
}

/// Ninguém logado: as marcas aparecem desligadas, e tocar numa leva ao login.
final class ShelfMarksSignedOut extends ShelfMarksState {
  const ShelfMarksSignedOut();
}

/// Não deu para ler as marcas do filme. Tentar de novo assina outra vez.
final class ShelfMarksError extends ShelfMarksState {
  const ShelfMarksError(this.failure);

  final Failure failure;
}

/// As marcas que o filme tem, já com as escritas que ainda não voltaram da
/// Estante (atualização otimista).
final class ShelfMarksReady extends ShelfMarksState {
  ShelfMarksReady(Set<ShelfMark> marks, {this.failedWrite})
    : marks = Set.unmodifiable(marks);

  final Set<ShelfMark> marks;

  /// A última escrita que o servidor recusou, para a mensagem e o "tentar de
  /// novo". Nula quando nenhuma falhou desde a última tentativa.
  final ShelfFailedWrite? failedWrite;

  bool isMarked(ShelfMark mark) => marks.contains(mark);
}

/// Uma escrita recusada: pôr ([marked] verdadeiro) ou tirar a [mark].
final class ShelfFailedWrite {
  const ShelfFailedWrite({
    required this.mark,
    required this.marked,
    required this.failure,
  });

  final ShelfMark mark;

  /// O que a pessoa queria: a [mark] ligada ou desligada.
  final bool marked;
  final Failure failure;
}
