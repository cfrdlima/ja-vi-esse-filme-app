import 'package:flutter/material.dart';

/// Pôster que voa da grade até os detalhes. A tag só precisa ser única no
/// navigator da aba, e a grade já tira os filmes repetidos entre as páginas.
/// Com o movimento reduzido, não há voo: a troca é a da rota.
class PosterHero extends StatelessWidget {
  const PosterHero({required this.movieId, required this.child, super.key});

  final int movieId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return Hero(tag: 'poster-$movieId', child: child);
  }
}
