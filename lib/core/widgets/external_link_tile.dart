import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../links/external_link_opener.dart';

/// Item de lista que abre [url] fora do app pelo [ExternalLinkOpener], e
/// avisa com [failureMessage] quando nenhum app abre o link.
class ExternalLinkTile extends StatelessWidget {
  const ExternalLinkTile({
    required this.url,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.semanticsLabel,
    required this.failureMessage,
    super.key,
  });

  final Uri url;
  final IconData icon;
  final String title;
  final String subtitle;

  /// Diz para onde o link leva, porque o leitor de tela não vê o ícone.
  final String semanticsLabel;
  final String failureMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void open() => _open(context);
    // Um nó só, de link e não de botão: o rótulo já diz que o link sai do
    // app. Por isso o toque fica também no `Semantics`.
    return Semantics(
      link: true,
      label: semanticsLabel,
      excludeSemantics: true,
      onTap: open,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.open_in_new),
        onTap: open,
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ExternalLinkOpener>().open(url);
    } on LinkNotOpened {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }
}
