import 'package:flutter/material.dart';

import '../../../../core/widgets/external_link_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/trailer.dart';

/// Trailers do filme, que abrem no YouTube fora do app (override
/// `detalhes.md`, seção "Trailers").
class TrailerList extends StatelessWidget {
  const TrailerList({required this.trailers, super.key});

  final List<Trailer> trailers;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final trailer in trailers)
        _TrailerTile(key: ValueKey(trailer.key), trailer: trailer),
    ],
  );
}

class _TrailerTile extends StatelessWidget {
  const _TrailerTile({required this.trailer, super.key});

  final Trailer trailer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final kind = switch (trailer.kind) {
      TrailerKind.trailer => l10n.trailerKindTrailer,
      TrailerKind.teaser => l10n.trailerKindTeaser,
    };
    final unnamed = trailer.name.isEmpty;
    final name = unnamed ? kind : trailer.name;
    return ExternalLinkTile(
      url: trailer.youtubeUrl,
      icon: Icons.play_circle_outline,
      title: name,
      subtitle: l10n.trailerSubtitle(kind),
      semanticsLabel: unnamed
          ? l10n.trailerUnnamedSemantics(kind)
          : l10n.trailerSemantics(name, kind),
      failureMessage: l10n.trailerOpenFailed,
    );
  }
}
