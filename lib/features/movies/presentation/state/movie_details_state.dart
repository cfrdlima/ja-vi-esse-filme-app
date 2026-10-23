import '../../../../core/error/failures.dart';
import '../../domain/entities/movie_details.dart';

/// Estado da tela de detalhes. A tela faz `switch` exaustivo nele.
sealed class MovieDetailsState {
  const MovieDetailsState();
}

final class MovieDetailsLoading extends MovieDetailsState {
  const MovieDetailsLoading();
}

/// O TMDB não tem o filme, ou o id da rota não é de filme nenhum. Tentar de
/// novo daria o mesmo resultado.
final class MovieDetailsNotFound extends MovieDetailsState {
  const MovieDetailsNotFound();
}

final class MovieDetailsError extends MovieDetailsState {
  const MovieDetailsError(this.failure);

  final Failure failure;
}

final class MovieDetailsLoaded extends MovieDetailsState {
  const MovieDetailsLoaded(this.details);

  final MovieDetails details;
}
