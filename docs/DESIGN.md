# Design — Já Vi Esse Filme

> Preencha com a direção visual escolhida (use a skill `frontend-design`). Tudo aqui vira token em `lib/core/theme/`.

## Direção
[ex.: "sala de cinema" — fundo quase preto, pôster como protagonista, acento âmbar de luz de projetor]

## Cores (tema escuro)
| Token | Valor | Uso |
|---|---|---|
| background | | fundo das telas |
| surface | | cards, sheets |
| primary | | ações principais, "já vi" |
| onSurfaceMuted | | metadados (ano, duração) |
| error | | estados de erro |

## Tipografia
[família de títulos / família de texto, escala]

## Espaçamento e forma
Escala: 4 · 8 · 12 · 16 · 24 · 32 · raio dos cards: [ ]

## Padrões de tela
- Grade de pôsteres 2:3, skeleton no carregamento
- Detalhes: backdrop no topo com gradiente, ações fixas (já vi / favorito / lista)
- Estados vazio / erro com ilustração simples e ação
