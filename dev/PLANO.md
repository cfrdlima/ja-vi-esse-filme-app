# Plano — Já Vi Esse Filme (Flutter)

> Fonte da verdade do que construir. Atualizado por `/fechar-sessao`.

## Última sessão
**015 — Fase 2: replanejar a conta (Firebase)** (fechada em 2026-10-24) · [log](sessoes/015-conta-firebase-plano.md)
A conta deixa de ser a sessão do TMDB e passa a ser conta própria, com login do Google no Firebase e as listas no Firestore (decisão 010). As Fases 2 e 3, o `CLAUDE.md` e o `security-auditor` foram reescritos com os achados da auditoria. Só documentação, com 738 testes.
**Próximo passo:** o setup do Firebase. Antes, o usuário cria o projeto (Firestore em `southamerica-east1`, modo de produção), registra o app Android com o SHA-1 de debug, liga o provedor Google e instala o `flutterfire` CLI e o `firebase-tools`. Depois vêm as regras do Firestore com testes no emulador.

## Fase 0 — Fundação
- [x] Criar projeto (`io.github.cfrdlima.ja_vi_esse_filme`), `analysis_options.yaml`, `.gitignore` com `env/*.json` (exceto `example.json`)
- [x] `analysis_options.yaml` estrito (`strict-casts`, `strict-inference`, `strict-raw-types`, `avoid_dynamic_calls`, `unawaited_futures`, `avoid_print`…)
- [x] Manifest: permissão `INTERNET` no `main`, `android:allowBackup="false"` e `usesCleartextTraffic="false"` explícito (antes do `core/network`)
- [x] README do projeto e descrição real no `pubspec.yaml`
- [x] `.gitignore`: remover o bloco duplicado e acrescentar `.env*`
- [x] `setup-claude.sh` atualizado (citar a skill `ui-ux-pro-max`)
- [x] Registrar a justificativa do minSdk 24 (decisão curta ou `CLAUDE.md`)
- [x] Handlers globais de erro no `main.dart` (`FlutterError.onError` e `PlatformDispatcher.instance.onError`)
- [x] `core/config` lendo `--dart-define-from-file` + `env/example.json` (token v4 de leitura; atualizar o README junto)
- [x] Gerar design system com `ui-ux-pro-max` (stack Flutter) → `design-system/ja-vi-esse-filme/MASTER.md`
- [x] `core/theme` com tokens do `MASTER.md` (tema escuro, fontes empacotadas)
- [x] `core/network`: cliente TMDB com falhas tipadas (rede, 401, 404, 429, 5xx) — TDD com `MockClient`
- [x] `core/network`: autenticar com o token v4 em `Authorization: Bearer`, sem `api_key` na query (auditoria da sessão 002)
- [x] Redator de segredos (`api_key`, `session_id`, `request_token`) aplicado no `report` dos handlers, que em release ainda precisa de um destino real (o `developer.log` não aparece)
- [x] `go_router` com shell de navegação (Descobrir / Buscar / Estante / Perfil)
- [x] CI (GitHub Actions): format, analyze, test, gitleaks, com a versão do Flutter fixada (3.44.5)
- [x] Confirmar decisão 001 (chave TMDB e proxy)

## Antes da Fase 1
- [x] Decisão: strings de UI centralizadas (`flutter_localizations` + ARB) ou em constantes
- [x] Decisão: `intl` para datas e números em pt-BR (dependência nova)
- [x] Política de privacidade (o que o app coleta, LGPD), para a tela "Sobre"

## Fase 1 — Explorar (sem login)
- [x] Descobrir: populares com paginação infinita (sessão 008)
- [x] Descobrir: em cartaz (`region=BR`) e melhor avaliados, com seletor na tela, generalizando o notifier (`PagedMoviesNotifier`) e usando o `retryAfter` do 429 no botão "Tentar de novo" (sessão 009)
- [x] Declarar em `docs/PRIVACIDADE.md` o cache de imagens (`cached_network_image`): prazo e como apagar
- [x] Busca com debounce e estados vazio/erro, com `include_adult=false` (público 13+, política de privacidade) (sessão 010)
- [x] Detalhes do filme: sinopse, gêneros, duração, nota, elenco (sessão 011)
- [x] Hero do pôster entre a grade e os detalhes, com tag única por navigator de aba (sessão 012)
- [x] Trailers (abrir YouTube externo com host validado) (sessão 013)
- [x] Tela "Sobre" com atribuição ao TMDB, política de privacidade e licenças das fontes (`LicenseRegistry`). Antes dela, criar o repositório público de suporte e publicar a política seguindo o procedimento da decisão 006. O link vai só para o Pages e exige aprovar o `url_launcher` (sessão 014)

## Fase 2 — Conta própria (Firebase, decisão 010)
- [x] Replanejar a conta: conta própria com login do Google no Firebase no lugar da sessão do TMDB (decisão 010) (sessão 015)
- [ ] Setup do Firebase. Antes do `flutterfire configure`, o `google-services.json` e o `firebase_options.dart` já estão no `.gitignore`. O usuário cria o projeto (Firestore em `southamerica-east1`, **em modo de produção**, nunca em "modo de teste"), o app Android, o SHA-1 de debug e liga o provedor Google. Depois vêm o `flutterfire configure` e a decisão sobre versionar o `firebase_options.dart` e o `google-services.json`. Se forem versionados, a chave é restrita antes do commit (pacote, SHA-1 e só as APIs usadas) e a exceção no `.gitleaksignore` vai por fingerprint. A outra opção é gerá-los no CI. O `Firebase.initializeApp` entra no `main.dart` sem quebrar os handlers de erro
- [ ] Regras do Firestore (`firestore.rules`): só o dono lê e escreve `users/{uid}/…`, e o dono pode apagar todos os documentos dele. Validação de campos e tamanhos, e testes no Emulator Suite e no CI, que cobrem:
  - nenhum `match /{document=**}` com `allow`;
  - leitura de outro `uid` negada;
  - acesso sem login negado;
  - `collectionGroup` negado.

  Vem antes do login e de qualquer escrita.
- [ ] Domínio da conta: entidade do usuário (`uid`, nome, e-mail, foto), contrato do repositório (usuário atual em stream, entrar, sair e excluir) e falhas tipadas (login cancelado, sem rede, conta desativada). O cancelamento não é erro
- [ ] Login com o Google: `google_sign_in` nativo (só a identidade básica, sem escopos extras) e credencial no `FirebaseAuth`, injetado no `main.dart`, com fakes nos testes. Na mesma entrega:
  - o `data_extraction_rules.xml` (+ `fullBackupContent`), excluindo pelo menos `sharedpref` (token do Auth) e `database` (cache do Firestore) do `cloud-backup` e do `device-transfer`;
  - o redator de segredos com JWT (`eyJ…`), `ya29.…`, `idToken`, `accessToken`, `refreshToken` e e-mail.
- [ ] Perfil logado e deslogado: botão "Entrar com Google" (diretrizes de marca do Google), nome e foto, e os 4 estados (consultar a `ui-ux-pro-max`)
- [ ] Login opcional: uma ação que precisa de conta leva ao login e volta para onde estava
- [ ] Logout na ordem da decisão 010: cancelar os streams; `terminate()`; `clearPersistence()`; `signOut()` do Firebase e do Google; recriar a instância. Teste: a falha ao limpar o cache não deixa a sessão aberta
- [ ] Modelo dos dados do filme: um documento por filme (`movie_id`, assistido, quero ver, favorito, datas) e se guarda cópia do título e do `poster_path` (nunca a imagem), com `cached_at` e renovação para o limite de 6 meses dos termos do TMDB
- [ ] Marcar como **assistido**, **quero assistir** e **favorito** nos detalhes, com atualização otimista e erro com "tentar de novo"
- [ ] Estante: abas Assistidos, Quero assistir e Favoritos, com paginação e os 4 estados
- [ ] Excluir a conta pelo app, na ordem da decisão 010: login recente; documentos das subcoleções de uma lista fixa no código, com confirmação do servidor e teste no emulador de que não sobra nada em `users/{uid}`; `user.delete()`; `disconnect()`. Excluir também pela web, com o mecanismo decidido na sessão: página com o Firebase JS ou pedido por formulário ou e-mail, já que o Spark não tem Cloud Functions. É exigência do Google Play
- [ ] Política de privacidade 2.0: conta Google, Firestore e região, Google como operador, transferência internacional do Auth, base legal, prazo e exclusão. Não dizer que o token é "cifrado", porque ele fica em SharedPreferences, protegido só pelo sandbox. Publicada no Pages (decisão 006) antes de uma versão com login chegar ao usuário

## Fase 3 — "Já vi esse filme"
- [ ] Nota pessoal e data em que assistiu, no documento do filme
- [ ] Listas personalizadas (criar, renomear, apagar, adicionar e remover filme), com o nome validado e o tamanho máximo no domínio, e as regras do Firestore cobrindo as listas

## Fase 4 — Polimento e release
- [ ] Acessibilidade e fonte grande
- [ ] Ícone, splash, nome do app
- [ ] Crash reporting (Crashlytics ou Sentry — exige decisão de dependência); ao entrar, tirar o `debugPrint` do reporter do release (`kDebugMode`) e atualizar a política
- [ ] Política de privacidade: nenhum marcador `A REVISAR`, vigência com data explícita, cópia publicada igual ao `docs/PRIVACIDADE.md` e permissões do manifest mesclado iguais às da política, e os números do cache de imagens (30 dias, cerca de 200) conferidos no `flutter_cache_manager` da versão em uso
- [ ] App Check do Firebase com enforcement no Firestore e no Auth antes da primeira versão na loja, e o provedor de debug no desenvolvimento (decisão 010)
- [ ] Rever a decisão 001 (proxy) antes da loja (se entrar, atualizar a política): host do proxy em `AppConfig.allowedHosts`, e atenção ao `replace(queryParameters:)`, que descarta a query da base URL
- [ ] Build release ofuscado e assinado: pôr `--obfuscate --split-debug-info=build/symbols` no comando do `CLAUDE.md` e trocar a assinatura de debug
