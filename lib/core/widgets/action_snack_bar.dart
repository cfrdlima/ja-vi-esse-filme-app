import 'package:flutter/material.dart';

/// Mostra um aviso com uma ação ("Desfazer", "Tentar de novo") que cabe com a
/// fonte grande, no lugar de qualquer aviso que esteja na tela ou na fila.
///
/// O aviso com ação não some sozinho (`persist`), para não sumir antes de
/// quem usa leitor de tela chegar até ela. Por isso ele troca o anterior na
/// hora: o `showSnackBar` só põe o novo na fila, e um aviso persistente
/// deixaria o seguinte preso até o toque (`/revisar` da sessão 030). Quem
/// guarda o controle sabe pelo `closed` que o aviso saiu ou foi trocado.
///
/// Não usa o `SnackBarAction`: o `SnackBar` do Flutter 3.47 põe a ação numa
/// `Row` sem limite de largura e mede o rótulo sem a escala da fonte. Com a
/// fonte 2x num celular de 320dp, o "Tentar de novo" passa da tela
/// (decisão 020). Aqui a mensagem e a ação ficam num `Wrap`: a ação desce de
/// linha quando não cabe ao lado, e o rótulo quebra quando não cabe na linha.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showActionSnackBar({
  required ScaffoldMessengerState messenger,
  required String message,
  required String actionLabel,
  required VoidCallback onAction,
}) {
  messenger
    ..clearSnackBars()
    ..removeCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      persist: true,
      content: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(message),
          _ActionButton(
            label: actionLabel,
            onPressed: () {
              messenger.hideCurrentSnackBar(
                reason: SnackBarClosedReason.action,
              );
              onAction();
            },
          ),
        ],
      ),
    ),
  );
}

/// Roda o [onPressed] uma vez só, como o `SnackBarAction`: um segundo toque
/// durante a saída do aviso repetiria o desfazer ou a nova tentativa.
class _ActionButton extends StatefulWidget {
  const _ActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  var _pressed = false;

  void _press() {
    if (_pressed) return;
    setState(() => _pressed = true);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final action = Theme.of(context).colorScheme.inversePrimary;
    return TextButton(
      // Desabilitado durante a saída, com a mesma cor: o cinza padrão quase
      // some sobre o fundo do aviso, como um piscar.
      style: TextButton.styleFrom(
        foregroundColor: action,
        disabledForegroundColor: action,
      ),
      onPressed: _pressed ? null : _press,
      child: Text(widget.label),
    );
  }
}
