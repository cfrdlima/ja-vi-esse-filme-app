# Sessão 015 — Fase 2: replanejar a conta (Firebase)

**Data**: 2026-10-24 · **Branch**: `feature/015-conta-firebase-plano` · **Status**: fechada

## Objetivo
A conta do usuário deixa de ser a sessão do TMDB e passa a ser uma conta própria, com login do Google no Firebase e as listas (assistidos, quero assistir, favoritos e depois as personalizadas) no Firestore. Esta sessão só registra a decisão e reescreve o plano e a documentação. O código começa na 016.

## Checklist
- [x] Analisar o pedido de conta própria com o Google contra o plano da conta TMDB
- [x] Perguntar ao usuário o backend, se o login é obrigatório, os provedores e o escopo da sessão
- [x] Conferir na documentação (Context7) o `google_sign_in` 7.x e o login do Google no `firebase_auth` para Android
- [x] Decisão 010: conta própria com login do Google no Firebase. Status da 001 atualizado
- [x] `CLAUDE.md` e `README.md`: stack, auth e segurança com o Firebase
- [x] `PLANO.md`: Fases 2 e 3 reescritas, sem o POST/DELETE no `TmdbClient`, e App Check na Fase 4
- [x] `docs/PRIVACIDADE.md`: rascunhos do login TMDB (comentários, fora da versão publicada) trocados por um marcador da versão 2.0. O texto publicado não muda
- [x] Auditoria (`security-auditor`) da decisão e do plano: nada bloqueante. Por escolha do usuário, os 12 achados foram aplicados
- [x] `/fechar-sessao`

## Decisões
- [010 — Conta própria com login do Google no Firebase](../decisoes/010-conta-propria-com-firebase.md), que substitui a parte do `session_id` da [001](../decisoes/001-chave-tmdb-e-sessao.md)

## Commits
- (este commit) docs: achados da reauditoria da sessão 015
- 9489b09 docs: fecha sessão 015
- 20cf4fe chore: checklist do security-auditor com o modelo do Firebase
- 145b279 chore: arquivos do Firebase fora do git e regras de segurança no CLAUDE.md
- 7f70251 docs: decisão 010 e plano com os achados da auditoria
- 985ba5d docs: abre sessão 015
- be2ca48 docs: marcador da política 2.0 no lugar do rascunho do login TMDB
- 67e2bd5 docs: Fases 2 e 3 do plano com a conta própria
- 497558f docs: CLAUDE.md e README com a conta no Firebase
- 18d517d docs: decisão 010, conta própria com login do Google no Firebase

## Notas
- A sessão abriu como `feature/015-tmdb-client-escrita`, para o item "`TmdbClient` com POST/DELETE". O usuário pediu a conta própria com o Google antes de qualquer código, e a branch e o log foram renomeados.
- Respostas do usuário: o backend é o Firebase, o login é opcional, o único provedor é o Google, e a sessão só replaneja.
- **`google_sign_in` em vez de `signInWithProvider`:** no Android, o `signInWithProvider(GoogleAuthProvider())` do `firebase_auth` abre uma Custom Tab. Com o `android:taskAffinity=""` do manifest, a aba fecha quando o usuário troca de app, e o retorno dá `web-context-already-presented` (documentação do FlutterFire). O `google_sign_in` 7.x (`GoogleSignIn.instance.initialize` / `authenticate`) usa o seletor nativo.
- **Pendente para a 016**, que depende do usuário:
  - criar o projeto no console do Firebase, com o Firestore em `southamerica-east1` (a região não muda depois);
  - registrar o app Android `io.github.cfrdlima.ja_vi_esse_filme` com o SHA-1 de debug;
  - ligar o provedor Google;
  - instalar o `flutterfire` CLI e o `firebase-tools`.
- **Auditoria (`security-auditor`):** nada bloqueante e aprovada para fechar. O texto publicado da política não mudou (a comparação foi sem os comentários), e o `gitleaks` não achou nada nos commits. O usuário decidiu aplicar os 12 achados agora:
  - o Firestore nasce em modo de produção, e as regras com testes no emulador vêm antes do login;
  - o `google-services.json` e o `firebase_options.dart` estão no `.gitignore` até a decisão do setup, com a chave restrita antes de qualquer commit;
  - a exclusão da conta tem ordem definida, e a página web fica entre o Firebase JS e um pedido por formulário ou e-mail, porque o Spark não tem Cloud Functions;
  - o logout tem ordem definida: `terminate`, `clearPersistence` e só então `signOut`;
  - o redator ganha JWT, `ya29.`, os campos de token e o e-mail;
  - o `data_extraction_rules.xml` entra junto com o login;
  - o App Check com enforcement entra antes da loja;
  - a política não pode dizer que o token é "cifrado";
  - o login pede só a identidade básica;
  - a cópia do TMDB guarda só o título e o `poster_path` (nunca a imagem), com `cached_at`;
  - no `CLAUDE.md`, os testes nunca acessam o Firebase real;
  - o checklist do `security-auditor` passou para o modelo do Firebase.
- O item "Redator de segredos (`api_key`, `session_id`, `request_token`)" da Fase 0 não mudou, porque é histórico de uma tarefa já feita.
- **Tríade no fechamento:**
  - `dart format` sem mudanças (136 arquivos);
  - `flutter analyze` sem issues;
  - `flutter test` com 738 testes passando;
  - `gitleaks` sem vazamentos.

  A sessão não teve código nem UI, então não precisou de emulador.
- **Reauditoria** dos achados aplicados: aprovada. Os achados 1, 2 e 4 a 12 estão OK. O 3 tinha um erro técnico novo (M1): o SDK do cliente não lista subcoleções, porque o `listCollections()` só existe no Admin SDK. Com o ok do usuário, foram corrigidos:
  - M1: lista fixa de subcoleções e teste no emulador;
  - B1: o `CLAUDE.md` passa a mandar ler a 010;
  - B2: as regras também negam o acesso sem login;
  - B3: este log;
  - B4: `**/` no `.gitignore` e `GoogleService-Info.plist`.
