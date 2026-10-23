import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/retry_wait.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../../../core/widgets/retry_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/movie.dart';
import '../state/movie_details_notifier.dart';
import '../state/movie_details_state.dart';
import '../widgets/movie_details_content.dart';
import '../widgets/movie_details_skeleton.dart';
import '../widgets/paged_movies_view.dart';

/// Detalhes de um filme, numa rota dentro da aba que o abriu.
class MovieDetailsScreen extends StatelessWidget {
  const MovieDetailsScreen({this.preview, super.key});

  final Movie? preview;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<MovieDetailsNotifier>();
    final l10n = AppLocalizations.of(context);
    final state = notifier.state;
    return Scaffold(
      appBar: AppBar(
        // Vazio até o filme chegar: o título da rota anterior não serve.
        title: Text(
          switch (state) {
            MovieDetailsLoaded(:final details) when details.title.isNotEmpty =>
              details.title,
            MovieDetailsLoaded() => l10n.movieUntitled,
            _ => '',
          },
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: switch (state) {
        MovieDetailsLoading() => MovieDetailsSkeleton(poster: preview),
        // Repetir daria o mesmo resultado: a saída é o voltar da barra.
        MovieDetailsNotFound() => MoviesMessage(message: l10n.movieNotFound),
        MovieDetailsError(:final failure) => MoviesMessage(
          message: failureMessage(l10n, failure),
          action: RetryButton.filled(
            onPressed: notifier.load,
            wait: retryWaitOf(failure),
          ),
        ),
        MovieDetailsLoaded(:final details) => MovieDetailsContent(
          details: details,
        ),
      },
    );
  }
}
