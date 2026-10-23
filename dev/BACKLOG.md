# Backlog

Ideias que surgiram e não estão no plano imediato. Marque **[prioritário]** o que deve entrar na próxima fase.

- Modo offline para a estante (cache local). Os termos da API do TMDB limitam o cache a 6 meses (conferido na sessão 007), e a política de privacidade precisa declarar o cache
- Onde assistir (`/movie/{id}/watch/providers`, região BR)
- Estatísticas: filmes vistos por mês / gênero
- Compartilhar lista por link
- Séries (TV) além de filmes
- `==`/`hashCode` em `AppSpacing`, `AppRadii` e `AppThemeTokens`, para que `copyWith`/`lerp` não gerem temas "diferentes" à toa. Cobrir também a troca de espaçamento e raios no `lerp` com `t >= 0.5` (revisão da sessão 001, sugestão 10)
- Limpeza dos testes de tema (revisão da sessão 001, sugestões 8, 9, 11 e 12):
  - remover ou reescrever o teste tautológico "famílias do pubspec" em `app_typography_test.dart`, para que leia o `pubspec.yaml`;
  - trocar `expect(theme.colorScheme, AppColors.darkScheme)` em `app_theme_test.dart`, que repete o código;
  - mover `app_contrast_test.dart` para um `group('contraste')` em `app_colors_test.dart`, para espelhar `lib/`;
  - expor `AppTheme.dark` como `static final`, para não recriar o `ThemeData` a cada `build`.
- Empacotar as fontes itálicas (`PlayfairDisplay-Italic[wght]`, `Inter-Italic[opsz,wght]`) se o design passar a usar itálico; hoje sairia itálico sintetizado (revisão da sessão 001, sugestão 13)
- Extrair um `bootstrap()` testável do `main()` quando a composição crescer (config, injeção), para que remover o `registerErrorHandlers()` quebre algum teste (revisão da sessão 002, sugestão 5)
- Se um dia existir `.env.example`, adicionar `!.env.example` ao `.gitignore`, porque o `.env*` o ignoraria (auditoria da sessão 002)
- Revisão da sessão 004, sugestões 8 e 9: comentar em `app_shell.dart` que Buscar não tem `selectedIcon` (não existe variante preenchida de `Icons.search`) e mover `AppShell.firstTab` para junto do campo `navigationShell`
- `firstTabBranch`/`tabBranch` recebem a tela raiz como `Widget`; trocar por builder (`GoRouterState`) quando uma aba precisar de parâmetro da rota (sessão 004)
- `NavigationRail` no lugar da `NavigationBar` em telas largas (tablet, regra `adaptive-navigation` da `ui-ux-pro-max`) (sessão 004)
- Dependabot para `github-actions`: o pin por SHA do workflow cobre só o primeiro nível, e o `subosito/flutter-action` chama `actions/cache@v5` por tag (revisão da sessão 005, item 5)
- `CODEOWNERS` cobrindo `.gitleaks.toml`, `.gitleaksignore` e `.github/`, com a branch protection exigindo revisão do dono, para que um PR não desligue a própria varredura de segredos (revisão da sessão 005, item 6)
- Ponto único da configuração do `MaterialApp` (tema, locale, delegates) para o `main.dart` e para `testApp`/`testRouterApp`, quando surgir um quarto campo comum, como `themeMode` ou `darkTheme` (revisão da sessão 006, item 6)
- Fase 1: chaves de título próprias por tela (`discoverTitle`, `searchTitle`, `profileTitle`), para que encurtar o rótulo de uma aba não mude o título da tela (revisão da sessão 006, item 7)
- Tela de "configuração inválida" em debug: com o `env/*.json` sem token, a `ConfigException` acontece antes do `runApp`, e o app fica parado na tela de abertura sem nenhuma mensagem (sessão 008)
- Transição animada entre os estados das telas (carregando, vazio, erro e sucesso), porque o `MASTER.md` §7 pede que a mudança de estado não seja instantânea (sessão 008)
- "Puxar para atualizar" na Descobrir. O notifier já descarta a resposta atrasada da página seguinte (contador de geração), conforme a revisão da sessão 008
- Limite de 500 páginas nas listas do TMDB, citado pela comunidade mas sem documentação oficial encontrada na sessão 008. Hoje uma página recusada vira erro no rodapé
- Uma fábrica injetada no lugar do router montando o `PopularMoviesNotifier` (`createAppRouter`), quando houver mais de uma feature com estado próprio (revisão da sessão 008, S10)
