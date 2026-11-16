# Sessão 016 — Fase 2: setup do Firebase

**Data**: 2026-11-16 · **Branch**: `feature/016-setup-firebase` · **Status**: aberta

## Objetivo
Ligar o app ao projeto Firebase `ja-vi-esse-filme`. A sessão roda o `flutterfire configure` só para Android, decide se o `firebase_options.dart` e o `google-services.json` entram no git (decisão 011) e chama o `Firebase.initializeApp` no `main.dart` sem quebrar os handlers de erro. Entra só o `firebase_core`. Auth, Firestore e regras ficam para as próximas sessões.

## Checklist
### Pré-requisitos (usuário, no console e no terminal)
- [x] Projeto `ja-vi-esse-filme` criado, com o Firestore `(default)`
- [ ] **Plano de cobrança.** O projeto está no **Blaze**, e a decisão 010 assume o Spark. Voltar ao Spark ("Modificar") ou manter o Blaze com um orçamento e alertas em 50%, 90% e 100%. A escolha entra na decisão 011
- [ ] Firestore: a aba Regras mostra `allow read, write: if false;` (modo de produção)
- [ ] Firestore: a região é `southamerica-east1`, conferida no Google Cloud. Se for outra, recriar o banco enquanto está vazio
- [ ] SHA-1 e SHA-256 de debug (`keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`)
- [ ] App Android `io.github.cfrdlima.ja_vi_esse_filme` registrado com o SHA-1 e o SHA-256, sem baixar o `google-services.json`
- [ ] Authentication: provedor Google ativado, com o e-mail de suporte, e os outros provedores desligados
- [ ] `firebase login` feito
- [ ] `flutterfire_cli` atualizado (`dart pub global activate flutterfire_cli`). Na 1.4.0, o prompt de atualização trava em shell não interativo

### Código
- [ ] Conferir a versão do `firebase_core` (pub.dev/Context7) e o minSdk exigido contra a decisão 003. Hoje o `build.gradle.kts` usa `flutter.minSdkVersion`
- [ ] `flutterfire configure --platforms=android` e conferir no `git status` que os arquivos gerados ficaram fora do git
- [ ] Decisão 011: versionar os arquivos (chave restrita antes do commit, com fingerprint no `.gitleaksignore`) ou gerá-los no CI. Registrar também o plano de cobrança
- [ ] Se versionar: restringir a chave `AIza…` no Google Cloud (pacote + SHA-1, só Identity Toolkit, Token Service e Firestore) antes do commit
- [ ] CI: o build e os testes continuam passando com a escolha da decisão 011
- [ ] RED: o bootstrap chama o initializer injetado antes do `runApp`
- [ ] GREEN: implementação mínima
- [ ] RED: uma falha na inicialização vai para o `report` e não derruba os handlers nem deixa tela branca
- [ ] GREEN: implementação mínima
- [ ] REFACTOR, mantendo o verde
- [ ] `firebase_core` no `pubspec`, com `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` depois do `registerErrorHandlers()`
- [ ] Tríade: `flutter analyze`, `flutter test`, `gitleaks` e o app subindo no emulador
- [ ] `security-auditor` (a sessão toca config e chaves)
- [ ] `/fechar-sessao`

## Decisões

## Commits

## Notas
- Arquivos que a sessão deve tocar: `pubspec.yaml`/`.lock`, `lib/main.dart` e um bootstrap testável em `core/`, com testes espelhados, `android/settings.gradle.kts` e `android/app/build.gradle.kts` (plugin `google-services`), `.gitignore`/`.gitleaksignore`, `.github/workflows/ci.yml`, `dev/decisoes/011-*.md` e o `CLAUDE.md`.
- Riscos:
  - o CI quebra se os arquivos ficarem fora do git e não forem gerados lá;
  - uma chave sem restrição pode ir para um commit;
  - o `flutterfire configure` pode registrar apps de iOS ou web, por isso o comando leva `--platforms=android`;
  - um erro no `initializeApp` assíncrono não pode virar tela branca;
  - se o minSdk do Firebase for maior que 24, a decisão 003 precisa ser revista.
- Ambiente na máquina principal: `firebase-tools` 15.22.4, `flutterfire` 1.4.0 e Java 21.
- A sessão foi aberta e enviada antes dos pré-requisitos, para o usuário continuar em outro dispositivo.
