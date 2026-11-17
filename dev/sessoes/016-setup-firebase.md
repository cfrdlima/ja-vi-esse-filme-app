# Sessão 016 — Fase 2: setup do Firebase

**Data**: 2026-11-16 · **Branch**: `feature/016-setup-firebase` · **Status**: aberta

## Objetivo
Ligar o app ao projeto Firebase `ja-vi-esse-filme`. A sessão roda o `flutterfire configure` só para Android, decide se o `firebase_options.dart` e o `google-services.json` entram no git (decisão 011) e chama o `Firebase.initializeApp` no `main.dart` sem quebrar os handlers de erro. Entra só o `firebase_core`. Auth, Firestore e regras ficam para as próximas sessões.

## Checklist
### Pré-requisitos (usuário, no console e no terminal)
- [x] Projeto `ja-vi-esse-filme` criado, com o Firestore `(default)`
- [x] **Plano de cobrança.** O projeto está no **Blaze**, e a decisão 010 assume o Spark. Voltar ao Spark ("Modificar") ou manter o Blaze com um orçamento e alertas em 50%, 90% e 100%. A escolha entra na decisão 011 **Feito:** voltou para o Spark
- [x] Firestore: a aba Regras mostra `allow read, write: if false;` (modo de produção)
- [x] Firestore: a região é `southamerica-east1`, conferida no Google Cloud. Se for outra, recriar o banco enquanto está vazio
- [x] SHA-1 e SHA-256 de debug (`keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`). SHA-1 `68:34:9C:40:1B:C5:B9:CB:02:7A:60:6D:30:2E:B0:DD:CA:00:A2:34`, SHA-256 `1F:E5:E3:EE:07:CB:37:B8:96:38:DE:29:F5:AC:A2:31:90:03:70:8A:60:74:CE:1F:3B:18:CF:F4:56:75:3D:34`
- [x] App Android `io.github.cfrdlima.ja_vi_esse_filme` registrado com o SHA-1 e o SHA-256, sem baixar o `google-services.json`
- [x] Authentication: provedor Google ativado, com o e-mail de suporte, e os outros provedores desligados
- [x] `firebase login` feito
- [x] `flutterfire_cli` atualizado (`dart pub global activate flutterfire_cli`). Na 1.4.0, o prompt de atualização trava em shell não interativo. Atualizado para a 1.5.0

### Código
- [x] Conferir a versão do `firebase_core` (pub.dev/Context7) e o minSdk exigido contra a decisão 003. Hoje o `build.gradle.kts` usa `flutter.minSdkVersion`. **Feito:** `firebase_core` 5.2.0 pede minSdk 24, igual à decisão 003
- [x] `flutterfire configure --platforms=android` e conferir no `git status` que os arquivos gerados ficaram fora do git. **Feito:** os dois arquivos ficaram ignorados; o `firebase.json` (sem chave) apareceu como novo
- [x] Decisão 011: versionar os arquivos (chave restrita antes do commit, com fingerprint no `.gitleaksignore`) ou gerá-los no CI. Registrar também o plano de cobrança. **Feito:** versionar, com Spark
- [x] Se versionar: restringir a chave `AIza…` no Google Cloud (pacote + SHA-1, só Identity Toolkit, Token Service e Firestore) antes do commit. **Feito** pelo usuário antes do `bee97e1`
- [x] CI: o build e os testes continuam passando com a escolha da decisão 011. **Feito localmente:** format, analyze e 741 testes; o CI confirma no push
- [x] RED: o bootstrap chama o initializer injetado antes do `runApp`
- [x] GREEN: implementação mínima
- [x] RED: uma falha na inicialização vai para o `report` e não derruba os handlers nem deixa tela branca
- [x] GREEN: implementação mínima
- [x] REFACTOR, mantendo o verde
- [x] `firebase_core` no `pubspec`, com `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` depois do `registerErrorHandlers()`
- [x] Tríade: `flutter analyze`, `flutter test`, `gitleaks` e o app subindo no emulador. **Feito:** analyze limpo, 741 testes, gitleaks git sem vazamento, e no emulador o Descobrir carrega os filmes com `FirebaseApp initialization successful` no logcat
- [x] `security-auditor` (a sessão toca config e chaves). **Aprovado**, sem achado crítico, alto ou médio
- [ ] `/fechar-sessao`

## Decisões
- [011 — Arquivos do Firebase versionados com chave restrita, e plano Spark](../decisoes/011-arquivos-firebase-versionados-e-spark.md)

## Commits
- `8823c30` docs: decisão 011 e pré-requisitos da sessão 016
- `bee97e1` chore: configura o Firebase no Android com firebase_core
- `f81304e` chore: ignora no gitleaks a chave restrita do Firebase

## Notas
- Achados do `security-auditor`, que viram pré-requisito da sessão do `firebase_auth` e das regras:
  - (baixo) A restrição de app Android da chave pode ser forjada por quem extrai a chave do APK. Por isso só o provedor Google fica ativo no Auth (conferido pelo usuário), e falta ligar a proteção contra enumeração de e-mail. Os limites de tamanho e quantidade entram nas regras, e o App Check vem antes se houver abuso.
  - (baixo) Falta o `data_extraction_rules.xml`, já previsto no plano: exclui `sharedpref` e `database` do `cloud-backup` e do `device-transfer`. Bloqueia a entrada do `firebase_auth`.
  - (info) O `redactSecrets` ainda não cobre JWT, `ya29.`, `idToken`, `refreshToken` nem e-mail, também previsto no plano antes do `firebase_auth`.
  - (info) O `gitleaks dir .` acusa a chave compilada nos `.dill` de `build/` e `.dart_tool/`. Na verificação local, use o `gitleaks git` ou rode depois de um `flutter clean`. Nunca adicione esses fingerprints.
  - (info) O `// ignore_for_file: type=lint` do `firebase_options.dart` vem do gerador do FlutterFire. Não foi colocado para fazer o lint passar.
- No emulador, o `FirebaseApp initialization successful` apareceu no logcat, sem erro reportado pelo bootstrap. Sem o `env/dev.json`, o app para no splash com `ConfigException: TMDB_BASE_URL ausente`, lançada ao montar o repositório antes do `runApp`. Isso já acontecia antes desta sessão, não vem do Firebase e já está no `BACKLOG.md` (sessão 008).
- **Integrar esta branch com merge commit**, nunca squash ou rebase: o `.gitleaksignore` usa o hash `bee97e1` (decisão 011).
- O `gitleaks` não está instalado na máquina. Na sessão foi usado o binário 8.30.1 do CI, com checksum conferido, numa pasta temporária.
- A CLI do Firebase está logada por padrão em outra conta. Os comandos deste projeto usam `--account` com a conta do projeto.
- Arquivos que a sessão deve tocar: `pubspec.yaml`/`.lock`, `lib/main.dart` e um bootstrap testável em `core/`, com testes espelhados, `android/settings.gradle.kts` e `android/app/build.gradle.kts` (plugin `google-services`), `.gitignore`/`.gitleaksignore`, `.github/workflows/ci.yml`, `dev/decisoes/011-*.md` e o `CLAUDE.md`.
- Riscos:
  - o CI quebra se os arquivos ficarem fora do git e não forem gerados lá;
  - uma chave sem restrição pode ir para um commit;
  - o `flutterfire configure` pode registrar apps de iOS ou web, por isso o comando leva `--platforms=android`;
  - um erro no `initializeApp` assíncrono não pode virar tela branca;
  - se o minSdk do Firebase for maior que 24, a decisão 003 precisa ser revista.
- Ambiente na máquina principal: `firebase-tools` 15.22.4, `flutterfire` 1.4.0 e Java 21.
- A sessão foi aberta e enviada antes dos pré-requisitos, para o usuário continuar em outro dispositivo.
