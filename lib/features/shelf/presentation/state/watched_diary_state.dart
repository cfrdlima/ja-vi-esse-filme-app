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
    required this.failure,
  });

  /// Nula sem nota.
  final Rating? rating;

  /// O dia escolhido; nulo quando o usuário não escolheu.
  final WatchedOn? watchedOn;

  /// O dia local em que o Assistido entrou: a sugestão do seletor, que não
  /// é gravada.
  final WatchedOn markedOn;

  /// A recusa da última escrita, para a mensagem e o "tentar de novo".
  final Failure? failure;

  /// Se tirar o Assistido apaga algo: a tela avisa antes.
  bool get hasPersonalData => rating != null || watchedOn != null;

  /// A nota com meia estrela a mais; a mesma no máximo.
  Rating get increasedRating {
    final halfStars = (rating?.halfStars ?? 0) + 1;
    return Rating(halfStars.clamp(1, Rating.maxHalfStars));
  }

  /// A nota com meia estrela a menos; nula ao descer de meia estrela ou sem
  /// nota.
  Rating? get decreasedRating {
    final halfStars = (rating?.halfStars ?? 0) - 1;
    return halfStars < 1 ? null : Rating(halfStars);
  }
}
