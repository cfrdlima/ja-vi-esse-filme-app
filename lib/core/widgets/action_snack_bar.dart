import 'package:flutter/material.dart';

/// Aviso com uma ação ("Desfazer", "Tentar de novo") que cabe com a fonte
/// grande.
///
/// Não usa o `SnackBarAction`: o `SnackBar` do Flutter 3.47 põe a ação numa
/// `Row` sem limite de largura e mede o rótulo sem a escala da fonte. Com a
/// fonte 2x num celular de 320dp, o "Tentar de novo" passa da tela
/// (decisão 020). Aqui a mensagem e a ação ficam num `Wrap`: a ação desce de
/// linha quando não cabe ao lado, e o rótulo quebra quando não cabe na linha.
SnackBar actionSnackBar({
  required ScaffoldMessengerState messenger,
  required String message,
  required String actionLabel,
  required VoidCallback onAction,
}) => SnackBar(
  // Como o `SnackBarAction`: o aviso com ação só sai pelo toque ou por outro
  // aviso, e não some antes de quem usa leitor de tela chegar até ela.
  persist: true,
  content: Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(message),
      _ActionButton(
        label: actionLabel,
        onPressed: () {
          messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
          onAction();
        },
      ),
    ],
  ),
);

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
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.inversePrimary,
    ),
    onPressed: _pressed ? null : _press,
    child: Text(widget.label),
  );
}
