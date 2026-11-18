import '../../../../core/error/failures.dart';
import '../../domain/entities/rating.dart';
import '../../domain/entities/watched_on.dart';

/// A nota e o dia em que assistiu, nos Detalhes (decisão 018). A tela faz
/// `switch` exaustivo nele.
sealed class WatchedDiaryState {
  const WatchedDiaryState();
}

/// O filme não está assistido, ou a Estante ainda não confirmou o Assistido:
/// sem o documento lido, não há onde gravar.
final class DiaryHidden extends WatchedDiaryState {
  const DiaryHidden();
}

/// A nota e o dia, já com as escritas que ainda não voltaram da Estante.
final class DiaryReady extends WatchedDiaryState {
  const DiaryReady({
    required this.rating,
    required this.watchedOn,
    required this.markedOn,
    required this.today,
    required this.failure,
  });

  /// Nula sem nota.
  final Rating? rating;

  /// O dia escolhido; nulo quando o usuário não escolheu.
  final WatchedOn? watchedOn;

  /// O dia local em que o Assistido entrou: a sugestão do seletor, que não
  /// é gravada.
  final WatchedOn markedOn;

  /// O último dia que o seletor deixa escolher.
  final WatchedOn today;

  /// A recusa da última escrita, para a mensagem e o "tentar de novo".
  final Failure? failure;

  /// Se tirar o Assistido apaga algo: a tela avisa antes.
  bool get hasPersonalData => rating != null || watchedOn != null;
}
