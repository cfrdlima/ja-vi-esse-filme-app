# CLAUDE.md

Orientação para o Claude Code neste repositório.

> **Nota:** o usuário se comunica em português (PT-BR). Responda em português.

## O produto

**Já Vi Esse Filme** é um app mobile Flutter para cinéfilos. O usuário busca filmes, vê os detalhes (sinopse, elenco e trailers), marca o que **já viu**, guarda favoritos e organiza listas próprias. Os dados vêm da **API do TMDB**.

Ele é a reescrita do projeto web `cfrdlima/Ja-vi-esse-filme` (Next.js + React + Axios). **Não porte código do projeto antigo.** Use-o só como referência de produto e reimplemente cada parte com TDD e Clean Architecture.

- Roadmap e o que vem a seguir: `dev/PLANO.md` (fonte da verdade).
- Decisões: `dev/decisoes/`. Leia a **001** e a **010** antes de mexer em auth, rede ou chaves.
- Design: `design-system/ja-vi-esse-filme/MASTER.md` (fonte da verdade, gerado pela skill `ui-ux-pro-max`). Regras de adaptação em `docs/DESIGN.md`.

## Stack

- **Flutter** 3.44 (Dart SDK ^3.12.2, conforme o `pubspec.yaml`), Android primeiro, Material 3, tema escuro como padrão.
- **API TMDB** (`https://api.themoviedb.org/3`), com imagens em `https://image.tmdb.org/t/p/<tamanho>`.
- `http` como cliente HTTP, `go_router` para rotas e `provider` + `ChangeNotifier` para estado.
- `cached_network_image` para pôsteres e `shared_preferences` só para flags locais sem nada sensível.
- **Conta própria no Firebase** (decisão 010): `firebase_core`, `firebase_auth` e `google_sign_in` para o login com o Google, e `cloud_firestore` para as listas. Cada pacote entra na sessão que o usar.
- Lints: `flutter_lints` via `analysis_options.yaml`.
- Pacote: `ja_vi_esse_filme` · branch principal: `main`.

Adicionar dependência fora dessa lista exige perguntar antes e registrar com `/decisao`.

## Comandos

```bash
flutter pub get                                   # dependências
flutter test                                      # todos os testes
flutter test test/arquivo_test.dart               # um arquivo
flutter test --plain-name "descricao"             # um teste pelo nome
flutter test --coverage                           # cobertura em coverage/lcov.info
flutter analyze                                   # lint, deve ficar sem issues
dart format lib/ test/                            # formatação (o hook já roda após cada edição)
flutter run --dart-define-from-file=env/dev.json \
  --dart-define=APP_VERSION=$(sed -n 's/^version: *\([^+]*\).*/\1/p' pubspec.yaml)  # roda com a config local
flutter build apk --dart-define-from-file=env/prod.json \
  --dart-define=APP_VERSION=$(sed -n 's/^version: *\([^+]*\).*/\1/p' pubspec.yaml)
dart pub outdated                                 # dependências desatualizadas
gitleaks detect --no-banner                       # vazamento de segredo antes de commitar
```

## Integração com o TMDB e o Firebase

- **Config via `--dart-define-from-file`**: `env/*.json` é **ignorado pelo git**; versione só `env/example.json`. É lido em um único lugar (`core/config/app_config.dart`) com `String.fromEnvironment`.
- Uma chave embutida no APK **não é segredo**, porque pode ser extraída. A decisão 001 diz quanto risco aceitamos e quando passar a usar um proxy. Nunca escreva a chave em código, teste, log ou commit.
- **O TMDB é só de leitura** (GET com o token v4). Conta e listas do usuário ficam no Firebase (decisão 010), e não na conta do TMDB.
- **O login é opcional e só com o Google** (`google_sign_in` nativo → credencial no `FirebaseAuth`). Descobrir, Buscar e Detalhes funcionam sem conta.
- **Os dados do usuário ficam só em `users/{uid}/…`** no Firestore, e as regras (`firestore.rules`, versionadas e testadas) só deixam o dono ler e escrever. A exclusão da conta apaga os documentos e depois a conta no Auth.
- **Os JSONs do TMDB são o contrato.** Os models em `data/` fazem o parse defensivo (campos podem vir `null`, como `poster_path`, `release_date` vazio ou `runtime`). Entidades de `domain/` não conhecem o formato do JSON.
- As respostas de lista são paginadas (`page`, `total_pages`, `results`). Trate paginação no repositório, não no widget.
- Trate o **rate limit (HTTP 429)** e os erros de rede como falhas de domínio tipadas, não como exceção crua do `http`.
- Idioma das requisições: `language=pt-BR`, com fallback para o texto original quando a sinopse vier vazia.
- **Atribuição obrigatória ao TMDB** (logo e aviso de que o app não é endossado) na tela "Sobre". É requisito dos termos da API.
- Nos testes, **nunca** acesse o TMDB real. Use `MockClient` (`package:http/testing.dart`) com fixtures JSON em `test/fixtures/`.
- Nos testes, **nunca** acesse o projeto Firebase real. Use fakes dos contratos do domínio ou o Emulator Suite.

## Estrutura do código (Clean Architecture por feature)

Dependências apontam sempre para dentro: `presentation → domain ← data`.

```
lib/
  core/                 # config, cliente HTTP, tema/tokens, rotas, erros, widgets compartilhados
  features/
    <feature>/          # ex.: movies, movie_details, auth, watched, favorites, lists
      domain/           # entidades, contratos de repositório (abstract), casos de uso: Dart puro
      data/             # models (fromJson), datasources (TMDB/local), repositórios concretos
      presentation/     # telas, widgets, estado (ChangeNotifier)
  main.dart             # composição: monta dependências e sobe o app
```

- **`domain` não importa `flutter`, `http`, `shared_preferences`, `flutter_secure_storage` nem pacotes do Firebase/`google_sign_in`.**
- Widgets não chamam `http`/storage direto. Eles falam com o estado, que chama casos de uso ou repositórios.
- Dependências concretas são montadas em **um ponto só** (`main.dart`/`core`) e injetadas. Nos testes, troque por fakes.
- **Não crie pastas vazias por antecipação.** A estrutura cresce com as features.

## Convenções de código (Clean Code)

Siga o _Clean Code_ sempre que possível, sem dogma. Se um princípio brigar com a clareza ou com o idioma do Flutter, priorize a legibilidade e registre o porquê.

- **Nomes revelam intenção.** Métodos são verbos e classes são substantivos. Código em inglês; textos de UI e nomes de teste em PT-BR.
- **Widgets pequenos e de propósito único.** Extraia um widget (classe) em vez de criar métodos `_buildXxx` gigantes.
- **Funções pequenas, com 0 a 2 argumentos.** Em widgets, use parâmetros nomeados, `required` explícito e `const` com `super.key`.
- **Sem efeitos colaterais escondidos** e sem flag booleana que muda o comportamento do método.
- **Comentário explica o _porquê_**, não o _quê_.
- **Erros como exceções/falhas tipadas.** Não use `null` como controle de fluxo. Modele estados explícitos.
- **Um único `MaterialApp`**, em `main.dart`.
- **DRY** com bom senso: não acople conceitos diferentes só porque o código se parece.

**Design patterns** só quando resolvem um problema concreto. A Clean Architecture já está decidida. Um caso de uso só existe se tiver regra além de repassar a chamada ao repositório.

## Design / UI

- Siga o `MASTER.md` do design system e as regras de `docs/DESIGN.md`. Cores, tipografia e espaçamento vêm de `core/theme/` (`ThemeData` + `ThemeExtension`). **Nada de `Color(0x...)` ou tamanho mágico dentro de widget.**
- **Toda tela tem os 4 estados**: carregando (skeleton, não spinner solto), vazio, erro (com "tentar de novo") e sucesso.
- Acessibilidade: `Semantics` em pôster e ícone clicável, alvo de toque ≥ 48dp, contraste AA e suporte a fonte grande sem overflow.
- Pôster sem `poster_path` mostra um placeholder desenhado, nunca uma imagem quebrada.
- Direção visual e regras de UX vêm da skill `ui-ux-pro-max`, **sempre com stack Flutter**. Antes de criar uma tela nova, consulte a skill para os padrões daquela tela. Se precisar de regra específica, gere um override em `pages/<tela>.md`. A `frontend-design` é opcional, só para explorar conceitos. Depois de mexer na tela, valide no emulador (screenshot via MCP do Flutter).

## Segurança (não negociável)

- Nunca leia, imprima ou commite `env/*.json` (exceto `example.json`), `android/key.properties`, `*.jks` ou `*.keystore`.
- O `android/app/google-services.json` e o `lib/firebase_options.dart` ficam fora do git até a sessão do setup decidir se entram (decisão 010). Se entrarem, a chave já está restrita no Google Cloud antes do commit.
- O Firestore nunca roda em "modo de teste". As regras negam tudo por padrão, e só o dono acessa `users/{uid}/…`.
- Toda URL externa (trailer do YouTube, site do filme) abre via `url_launcher` em modo externo, com host validado.
- Entrada do usuário (busca, nome de lista) é validada e escapada. O tamanho máximo é definido no domínio.
- `android:usesCleartextTraffic="false"`; só HTTPS.
- Logs de debug nunca contêm chave da API, URL com `api_key=`, tokens do Google ou do Firebase (ID, acesso ou refresh), o e-mail do usuário, nem o `uid` junto com dados pessoais.
- Antes de fechar sessão que toque **auth, storage ou rede**, rode o subagente `security-auditor`.

## Fluxo de TDD (obrigatório para código novo)

Ciclo **Red → Green → Refactor**, uma feature por ciclo. "Implementar primeiro, testar depois" está **proibido**.

1. **Red.** Escreva o teste que falha (unidade para domain/data/estado, widget test para UI). Rode `flutter test` e confirme que falha **pelo motivo certo**.
2. **Green.** Escreva o mínimo para passar, sem generalizar. Rode `flutter test`.
3. **Refactor.** Limpe mantendo o verde. Rode `flutter test` de novo.

- **Não junte Red e Green** no mesmo passo.
- Siga o padrão **AAA**, idealmente com uma asserção por teste.
- O nome do teste descreve o comportamento em PT-BR, ex.: `'deve marcar o filme como já visto'`.
- **Testes espelham `lib/`**: `lib/features/x/domain/y.dart` → `test/features/x/domain/y_test.dart`.
- **"Pronto" exige a tríade verde**: `flutter analyze` limpo, `flutter test` passando e verificação no emulador quando houver UI. Se algo falhar, cole a saída. Não afirme sucesso sem ela.
- Use a lista de tarefas para acompanhar RED/GREEN/REFACTOR em features não triviais.

## Sistema de desenvolvimento

O acompanhamento vive em `dev/` e é dirigido por slash commands (`.claude/commands/`). É markdown invocado manualmente, sem automação escondida.

- `dev/PLANO.md`: fases com checklist `[x]` e a seção "Última sessão".
- `dev/BACKLOG.md`: ideias fora do plano imediato.
- `dev/sessoes/NNN-descricao.md`: log por sessão (uma feature ≈ uma sessão).
- `dev/decisoes/NNN-descricao.md`: Contexto / Decisão / Consequências.

| Comando | O que faz |
|---|---|
| `/sessao` | Abre sessão: lê plano e última sessão, cria a branch `feature/*` e o log |
| `/tarefa <desc>` | Adiciona item ao checklist da sessão aberta |
| `/decisao <desc>` | Registra decisão em `dev/decisoes/` |
| `/status` | Fase atual, última sessão, próximo item e pendências |
| `/revisar` | Roda os subagentes `code-reviewer` e `security-auditor` no diff da sessão |
| `/fechar-sessao` | Só fecha com analyze limpo e testes verdes; atualiza log e plano; integra a branch |

Commits: `add:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`, com mensagem curta em PT-BR. Um commit por unidade lógica.

## O que NÃO fazer

- Não desabilitar lint, teste ou `// ignore:` para "fazer passar".
- Não usar `git push --force`, `git reset --hard` nem `rm -rf` sem pedir.
- Não adicionar dependência sem perguntar.
- Não inventar campo do TMDB. Na dúvida, confira a documentação oficial (Context7/web) antes de modelar.
- Não repetir aqui o plano ou as decisões. Aponte para `dev/`.

## Skills e plugins

Plugins declarados em `.claude/settings.json` (`dart-flutter`, `frontend-design`), MCP em `.mcp.json` (`context7`; o MCP do Flutter vem com o plugin) e skills próprias em `.claude/skills/` (`tmdb-endpoint`, `nova-feature-clean`, `tela-4-estados`, `ui-ux-pro-max`).
A `ui-ux-pro-max` é a fonte de design; quando ela sugerir algo de web (imports do Google Fonts, CSS, Tailwind), traduza para o equivalente Flutter conforme `docs/DESIGN.md`.
**Em conflito com skills instaladas, a arquitetura e as convenções deste CLAUDE.md prevalecem** (ex.: `flutter-apply-architecture-best-practices` propõe outra divisão de camadas — siga a Clean Architecture por feature daqui).
