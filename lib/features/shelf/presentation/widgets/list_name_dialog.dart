import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/list_name.dart';

/// O nome de uma lista, para criar ou renomear (override `estante.md`).
/// Fecha com o [ListName] válido, ou com `null` no "Cancelar" e no voltar.
class ListNameDialog extends StatefulWidget {
  const ListNameDialog({this.initial, super.key});

  /// O nome atual, ao renomear; nulo ao criar.
  final ListName? initial;

  static Future<ListName?> show(BuildContext context, {ListName? initial}) =>
      showDialog<ListName>(
        context: context,
        builder: (_) => ListNameDialog(initial: initial),
      );

  @override
  State<ListNameDialog> createState() => _ListNameDialogState();
}

class _ListNameDialogState extends State<ListNameDialog> {
  late final _controller = TextEditingController(
    text: widget.initial?.value ?? '',
  );

  /// Só acusa o erro depois de a pessoa mexer no campo.
  bool _touched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// O nome válido, ou o motivo da recusa.
  (ListName?, ListNameIssue?) _parse() {
    try {
      return (ListName(_controller.text), null);
    } on InvalidListNameException catch (e) {
      return (null, e.issue);
    }
  }

  void _submit() {
    if (_parse() case (final ListName name, _)) {
      Navigator.of(context).pop(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (name, issue) = _parse();
    final renaming = widget.initial != null;
    return AlertDialog(
      title: Text(renaming ? l10n.listsRenameTitle : l10n.listsNew),
      // Com fonte grande, o campo rola dentro do diálogo.
      content: SingleChildScrollView(
        child: TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _touched = true),
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: l10n.listsNameLabel,
            // O contador conta como as regras do Firestore, em unidades
            // UTF-16 (decisão 019), e não em grafemas como o `maxLength`.
            counterText: l10n.listsNameCounter(
              _controller.text.trim().length,
              ListName.maxLength,
            ),
            errorText: _touched ? _issueMessage(l10n, issue) : null,
            errorMaxLines: 3,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.listsCancel),
        ),
        TextButton(
          onPressed: name == null ? null : _submit,
          child: Text(renaming ? l10n.listsSave : l10n.listsCreate),
        ),
      ],
    );
  }

  static String? _issueMessage(AppLocalizations l10n, ListNameIssue? issue) =>
      switch (issue) {
        null => null,
        ListNameIssue.empty => l10n.listsNameEmpty,
        ListNameIssue.tooLong => l10n.listsNameTooLong(ListName.maxLength),
        ListNameIssue.controlCharacter => l10n.listsNameControl,
      };
}
