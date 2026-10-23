import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/links/external_link_opener.dart';
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final kind = switch (trailer.kind) {
      TrailerKind.trailer => l10n.trailerKindTrailer,
      TrailerKind.teaser => l10n.trailerKindTeaser,
    };
    final unnamed = trailer.name.isEmpty;
    final name = unnamed ? kind : trailer.name;
    // Um nó só, de link e não de botão: o rótulo já diz que o trailer sai do
    // app. Por isso o toque fica também no `Semantics`.
    return Semantics(
      link: true,
      label: unnamed
          ? l10n.trailerUnnamedSemantics(kind)
          : l10n.trailerSemantics(name, kind),
      excludeSemantics: true,
      onTap: () => _open(context),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.play_circle_outline),
        title: Text(
          name,
          style: theme.textTheme.bodyLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          l10n.trailerSubtitle(kind),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.open_in_new),
        onTap: () => _open(context),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final failedMessage = AppLocalizations.of(context).trailerOpenFailed;
    try {
      await context.read<ExternalLinkOpener>().open(trailer.youtubeUrl);
    } on LinkNotOpened {
      messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
    }
  }
}
