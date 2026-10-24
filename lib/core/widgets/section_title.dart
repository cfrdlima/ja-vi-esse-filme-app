import 'package:flutter/material.dart';

/// Título de seção de uma tela de conteúdo, marcado como cabeçalho para o
/// leitor de tela poder pular de seção em seção.
class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}
