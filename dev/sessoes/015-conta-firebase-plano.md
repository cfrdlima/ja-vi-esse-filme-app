# Sessão 015 — Fase 2: replanejar a conta (Firebase)

**Data**: 2026-10-24 · **Branch**: `feature/015-conta-firebase-plano` · **Status**: aberta

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
- [ ] `/fechar-sessão`

## Decisões
- [010 — Conta própria com login do Google no Firebase](../decisoes/010-conta-propria-com-firebase.md), que substitui a parte do `session_id` da [001](../decisoes/001-chave-tmdb-e-sessao.md)

## Commits

## Notas
- A sessão abriu como `feature/015-tmdb-client-escrita`, para o item "`TmdbClient` com POST/DELETE". O usuário pediu a conta própria com o Google antes de qualquer código, e a branch e o log foram renomeados.
- Respostas do usuário: o backend é o Firebase, o login é opcional, o único provedor é o Google, e a sessão só replaneja.
- **`google_sign_in` em vez de `signInWithProvider`:** no Android, o `signInWithProvider(GoogleAuthProvider())` do `firebase_auth` abre uma Custom Tab. Com o `android:taskAffinity=""` do manifest, a aba fecha quando o usuário troca de app, e o retorno dá `web-context-already-presented` (documentação do FlutterFire). O `google_sign_in` 7.x (`GoogleSignIn.instance.initialize` / `authenticate`) usa o seletor nativo.
- **Pendente para a 016**, que depende do usuário:
  - criar o projeto no console do Firebase, com o Firestore em `southamerica-east1` (a região não muda depois);
  - registrar o app Android `io.github.cfrdlima.ja_vi_esse_filme` com o SHA-1 de debug;
  - ligar o provedor Google;
  - instalar o `flutterfire` CLI e o `firebase-tools`.
