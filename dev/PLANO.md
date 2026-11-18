# Plano — Já Vi Esse Filme (Flutter)

> Fonte da verdade do que construir. Atualizado por `/fechar-sessao`.

## Última sessão
**025 — Fase 2: excluir a conta pela web** (fechada em 2026-11-18) · [log](sessoes/025-excluir-conta-web.md)
A página de exclusão está no ar em `cfrdlima.github.io/ja-vi-esse-filme-suporte/excluir-conta/`: pedido por e-mail ao `xbtechnologies.app@gmail.com` com confirmação do remetente, atendimento em até 15 dias e guarda de 6 meses, com o procedimento local, fora do git (decisões 015 e 016). O `/revisar` achou o repositório do app público; ele fica público (decisão 016).
**Próximo passo:** política de privacidade 2.0 (portão de release), com o conteúdo acumulado no item dela; antes, conferir no console os backups do Firestore (S7 da 025).

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
- [x] Setup do Firebase. Antes do `flutterfire configure`, o `google-services.json` e o `firebase_options.dart` já estão no `.gitignore`. O usuário cria o projeto (Firestore em `southamerica-east1`, **em modo de produção**, nunca em "modo de teste"), o app Android, o SHA-1 de debug e liga o provedor Google. Depois vêm o `flutterfire configure` e a decisão sobre versionar o `firebase_options.dart` e o `google-services.json`. Se forem versionados, a chave é restrita antes do commit (pacote, SHA-1 e só as APIs usadas) e a exceção no `.gitleaksignore` vai por fingerprint. A outra opção é gerá-los no CI. O `Firebase.initializeApp` entra no `main.dart` sem quebrar os handlers de erro
- [x] Regras do Firestore (`firestore.rules`): só o dono lê e escreve `users/{uid}/…`, e o dono pode apagar todos os documentos dele. Validação de campos e tamanhos, e testes no Emulator Suite e no CI, que cobrem:
  - nenhum `match /{document=**}` com `allow`;
  - leitura de outro `uid` negada;
  - acesso sem login negado;
  - `collectionGroup` negado.

  Vem antes do login e de qualquer escrita. (sessão 017)
- [x] Domínio da conta: entidade do usuário (`uid`, nome, e-mail, foto), contrato do repositório (usuário atual em stream, entrar, sair e excluir) e falhas tipadas (login cancelado, sem rede, conta desativada). O cancelamento não é erro (sessão 018)
- [x] Login com o Google: `google_sign_in` nativo (só a identidade básica, sem escopos extras) e credencial no `FirebaseAuth`, injetado no `main.dart`, com fakes nos testes. Na mesma entrega:
  - o `data_extraction_rules.xml` (+ `fullBackupContent`), excluindo pelo menos `sharedpref` (token do Auth) e `database` (cache do Firestore) do `cloud-backup` e do `device-transfer`;
  - o redator de segredos com JWT (`eyJ…`), `ya29.…`, `idToken`, `accessToken`, `refreshToken` e e-mail.
  - o fake do `AuthRepository` em `test/helpers/`, com o formato que os testes do estado pedirem;
  - o `failureGeneric` neutro, porque hoje ele cita o TMDB;
  - o `AppUser` recusando `uid` com `/` ou espaço nas pontas, e a `data` montando o caminho com `collection('users').doc(uid)`;
  - a tradução dos erros do SDK sem `e.message`, `e.email` nem `e.credential` (pendências da sessão 018).

  (sessão 019)
- [x] Perfil logado e deslogado: botão "Entrar com Google" (diretrizes de marca do Google), nome e foto, e os 4 estados (consultar a `ui-ux-pro-max`) (sessão 020)
- [x] Modelo dos dados do filme (decisão 013): um documento por filme com a cópia do título e do `poster_path` (nunca a imagem) e `cachedAt` para o limite de 6 meses dos termos do TMDB, as marcas como timestamps do servidor, as regras e os testes no emulador, o domínio e a camada `data` sobre o `cloud_firestore` (sessão 021, que reordenou este bloco: o login opcional e o logout dependiam de algo que ainda não existia)
- [x] Marcar como **assistido**, **quero assistir** e **favorito** nos detalhes, com atualização otimista e erro com "tentar de novo". Na mesma entrega, o **login opcional** e o **logout completo** (item abaixo), porque o "Marcar" liga o cache do Firestore no aparelho, e só o logout completo o limpa (`security-auditor` da 021). O login opcional: marcar sem conta (`SignInRequiredFailure`) leva ao login e volta para onde estava. Também entram a montagem do `ShelfRepository` no `main.dart` (o `currentUid` vindo do Firebase Auth) e o fake dele em `test/helpers/`. Atenção: offline, o future do `set` só completa quando o servidor confirma, então a UI não espera por ele para mostrar a marca
- [x] Logout na ordem da decisão 010: cancelar os streams; `terminate()`; `clearPersistence()`; `signOut()` do Firebase e do Google; recriar a instância. Teste: a falha ao limpar o cache não deixa a sessão aberta. Entra na mesma sessão do "Marcar", que é quando o Firestore passa a ter cache no aparelho, e cancela também os streams do `ShelfRepository`
- [x] Estante: abas Assistidos, Quero assistir e Favoritos, com paginação e os 4 estados
- [x] Excluir a conta pelo app, na ordem das decisões 010 e 015: reautenticar com o Google antes de apagar; documentos das subcoleções da lista fixa (`UserCollections`, conferida com as regras) em lotes confirmados pelo servidor, com prazo de 15 s por passo; `user.delete()`; `disconnect()`; limpeza local. Teste no emulador de que não sobra nada em `users/{uid}` (sessão 024)
- [x] Excluir a conta pela web, com pedido por e-mail (decisão 015): página no Pages com o que é apagado e como pedir, o endereço de suporte e o prazo de atendimento (sessão 025: `cfrdlima.github.io/ja-vi-esse-filme-suporte/excluir-conta/`, atendimento pelo procedimento local `dev/ATENDIMENTO-EXCLUSAO.md`, fora do git, decisão 016). Antes da loja: a URL no formulário de Segurança dos dados e o nome do desenvolvedor no Play Console igual ao da página
- [ ] Script local de limpeza mensal do Firestore com o Admin SDK (decisão 017): cópias do TMDB com mais de 180 dias (renovar pelo TMDB ou adaptar regras e app, decidido na sessão) e `users/{uid}` sem conta no Auth; testes no emulador, saída só com contagens e a primeira execução. **Antes da publicação da 2.0**
- [ ] Política de privacidade 2.0: **Texto pronto na sessão 026** (`docs/PRIVACIDADE.md`); a publicação espera o script da 017, o S7 e o aceite dos termos de tratamento de dados do Firebase no console, e a prova de rede sem conta. conta Google, Firestore e região, Google como operador, transferência internacional do Auth, base legal, prazo e exclusão. **Portão de release (sessão 020): o botão de login já está no Perfil, então nenhum APK sai do ambiente de desenvolvimento antes da 2.0 publicada.** Conteúdo pedido pelo `security-auditor` da 020: dados da conta (nome, e-mail, foto e `uid`) e a finalidade; a foto só no cache em memória, baixada direto do `googleusercontent.com`, com o Google recebendo IP e user-agent; a conta no Firebase nasce no primeiro login, ao escolher a conta no seletor; o SDK do FirebaseAuth registra o `uid` no logcat local, sem envio pelo app; nada vai para backup nem para outro aparelho. Da sessão 021 (decisão 013 e `security-auditor`): o Firestore guarda, por filme marcado, o título e o caminho do pôster copiados do TMDB (nunca a imagem) e as datas em que cada marca entrou, na região `southamerica-east1`. Sobre o prazo, dizer só o que o app garante: a cópia é renovada quando o filme é marcado ou aparece na Estante (sessão 023: só as cópias das páginas carregadas, até 200 por aba), uma cópia vencida não aparece como atual, e a limpeza com o Admin SDK (mecanismo decidido antes da publicação) apaga as cópias paradas e também os `users/{uid}` sem conta no Firebase Auth (documentos órfãos de outro aparelho depois da exclusão, sessão 024). Uma cópia das marcas, dos títulos e dos caminhos fica no cache local do Firestore no aparelho até o logout, e as escritas feitas offline ficam guardadas no aparelho até sincronizar. Da sessão 022 (`security-auditor`): sair da conta remove do app o cache do Firestore, sem prometer apagamento seguro ou irrecuperável (o `clearPersistence` não sobrescreve os arquivos); as marcas feitas offline que ainda não chegaram ao servidor são apagadas no logout, e o app avisa antes de sair; se a limpeza falhar, o cache fica no aparelho até a próxima abertura do app sem conta (que tenta de novo) ou até "Limpar armazenamento" nas configurações do Android. Não dizer que o token é "cifrado", porque ele fica em SharedPreferences, protegido só pelo sandbox. Da sessão 023 (`security-auditor`): ao abrir a Estante, o app consulta sozinho o TMDB (`GET /movie/{id}`) sobre os filmes com a cópia vencida, para renová-la, e o TMDB recebe o IP e os ids desses filmes; hoje a política diz que o TMDB recebe "os filmes que você abre", com base legal "a seu pedido" (inciso V), que precisa ser revista para essa consulta. Da sessão 024 (decisão 015): a exclusão pelo app apaga as marcas, as cópias do TMDB e a conta no Firebase Auth, revoga o acesso do app à conta Google e limpa o cache do aparelho; a exclusão pela web é um pedido por e-mail, atendido pelo dono do projeto, com o endereço e o prazo; o e-mail recebido no pedido também é dado pessoal, com finalidade e prazo de guarda. Da sessão 025 (decisão 015 emendada): o pedido por e-mail vai para `xbtechnologies.app@gmail.com` e é atendido em até 15 dias; a mensagem e a resposta ficam 6 meses depois do atendimento, como registro; o Google remove os dados dos sistemas ativos e dos backups em até cerca de 180 dias e guarda os IPs do login por algumas semanas; a política 2.0 aponta para a página `excluir-conta/` e repete o que ela promete, sem divergir. Do `/revisar` da 025: base legal da guarda das mensagens do pedido (exercício regular de direitos, art. 7º, VI); os 15 dias como compromisso do projeto, sem citar o art. 19, II; o site do suporte no GitHub Pages carrega o `anchor-js` do cdnjs, e o GitHub e a Cloudflare recebem o IP de quem abre as páginas; conferir no console que o Firestore não tem backup agendado, PITR nem export (se tiver, entra no prazo de retenção). Do `security-auditor` da 024: a revogação do acesso na conta Google é tentada, não garantida (indicar `myaccount.google.com/permissions`), e a limpeza do aparelho segue o que já vale para o logout; o estado parcial (documentos apagados e conta viva e vazia até a próxima tentativa); o Google mantém backups e logs por um prazo próprio depois da exclusão (conferir o prazo na documentação do Firebase e do Google Cloud antes de escrever, sem prometer apagamento imediato e irrecuperável); outros aparelhos com a conta aberta guardam a cópia local até saírem da conta ou abrirem o app sem conta, e podem recriar documentos por até cerca de 1 h, que a varredura do Admin SDK apaga; no pedido por e-mail, como a identidade é conferida (o pedido sai do endereço da própria conta Google) e o que o dono do projeto vê no console ao atender (`uid`, e-mail e marcas). Publicada no Pages (decisão 006) antes de uma versão com login chegar ao usuário

## Fase 3 — "Já vi esse filme"
- [ ] Nota pessoal e data em que assistiu, no documento do filme
- [ ] Listas personalizadas (criar, renomear, apagar, adicionar e remover filme), com o nome validado e o tamanho máximo no domínio, e as regras do Firestore cobrindo as listas. A exclusão da conta passa a apagar os `items` de cada lista antes da lista (exclusão aninhada: o `FirestoreAccountDocuments` hoje só apaga `users/{uid}/<coleção>`), e o teste `rules-file.test.js` aceita o `match` aninhado das listas (decisão 015, `/revisar` da sessão 024)

## Fase 4 — Polimento e release
- [ ] Acessibilidade e fonte grande
- [ ] Ícone, splash, nome do app
- [ ] Crash reporting (Crashlytics ou Sentry — exige decisão de dependência); ao entrar, tirar o `debugPrint` do reporter do release (`kDebugMode`) e atualizar a política
- [ ] Política de privacidade: nenhum marcador `A REVISAR`, vigência com data explícita, cópia publicada igual ao `docs/PRIVACIDADE.md` e permissões do manifest mesclado iguais às da política, e os números do cache de imagens (30 dias, cerca de 200) conferidos no `flutter_cache_manager` da versão em uso
- [ ] App Check do Firebase com enforcement no Firestore e no Auth, e o provedor de debug no desenvolvimento (decisão 010). **Portão de release (sessão 021, `security-auditor`): antes de qualquer APK com login sair do ambiente de desenvolvimento, e não só antes da loja.** Com a chave pública do APK, qualquer conta Google esgota em minutos a cota diária do Spark (20 mil escritas, 20 mil exclusões e 50 mil leituras), e o app cai para todos. Junto: tirar `localhost` dos domínios autorizados do Firebase Auth e ligar um alerta de uso no Firebase
- [ ] Rever a decisão 001 (proxy) antes da loja (se entrar, atualizar a política): host do proxy em `AppConfig.allowedHosts`, e atenção ao `replace(queryParameters:)`, que descarta a query da base URL
- [ ] Build release ofuscado e assinado: pôr `--obfuscate --split-debug-info=build/symbols` no comando do `CLAUDE.md` e trocar a assinatura de debug
