# 010 — Conta própria com login do Google no Firebase

**Data**: 2026-10-24 · **Status**: aceita

## Contexto
O plano original da Fase 2 usava a conta do TMDB (`request_token` → navegador → `session_id`), com favoritos e watchlist guardados no próprio TMDB. Na sessão 015, o usuário pediu uma feature que o app web antigo não tinha: **conta própria com login do Google**, com as listas de assistidos, de quero assistir e de favoritos, e depois as listas personalizadas.

A conta do TMDB não atende a esse pedido:
- o TMDB não oferece login com o Google;
- o usuário seria obrigado a ter uma conta no TMDB;
- o TMDB não tem uma lista de "já vi". Ele só tem favoritos, watchlist e avaliações.

Uma conta própria exige um backend para autenticar o usuário e guardar os dados dele. Até aqui o app não tinha servidor: a política de privacidade 1.0 diz "sem login, sem servidor".

Respostas do usuário na sessão 015:
- o backend é o Firebase;
- o login é opcional;
- no começo, o único provedor é o Google;
- a sessão 015 só replaneja, e o código começa na 016.

## Opções consideradas
1. **Firebase:** Auth com o provedor Google, mais Cloud Firestore.
   - O login do Google tem suporte de primeira linha no Android.
   - O Firestore já guarda os dados no aparelho e reenvia as escritas quando a rede volta.
   - As regras de segurança limitam o acesso pelo `uid`.
   - O plano gratuito (Spark) cobre o uso previsto.
   - Os dados ficam no Google, o que pede transferência internacional na política, a menos que a região do Firestore seja no Brasil.
2. **Supabase:** Auth com Google, mais Postgres com RLS.
   - É open source e usa SQL.
   - O projeto gratuito é pausado depois de um período sem uso, o que derruba o app de um usuário pouco ativo.
   - O login nativo do Google no Android também passa pelo `google_sign_in`.
3. **Manter a conta do TMDB.** Não atende ao pedido (sem Google e sem "já vi").
4. **Só armazenamento local, sem conta.** Não sincroniza entre aparelhos, e os dados se perdem quando o app é desinstalado.

Para o login dentro do Firebase:
- **`google_sign_in` (7.x) + `FirebaseAuth.signInWithCredential`.** O login usa o Credential Manager nativo do Android (o seletor de conta do sistema), sem navegador.
- **`FirebaseAuth.signInWithProvider(GoogleAuthProvider())` sem o `google_sign_in`.** É uma dependência a menos, mas abre uma Custom Tab. Com o `android:taskAffinity=""` do nosso manifest, a aba fecha quando o usuário troca de app, e o retorno dá `web-context-already-presented`.

## Decisão
Opção 1, o **Firebase**, com:
- `firebase_core`, `firebase_auth`, `google_sign_in` e `cloud_firestore`. As versões são conferidas no pub.dev e com o minSdk 24 (decisão 003) quando cada pacote entrar;
- **login só com o Google**, com o `google_sign_in` nativo e a credencial passada ao `FirebaseAuth`. O login pede só a identidade básica (nome, e-mail e foto), sem `authorizationClient` com escopos extras, para a política não precisar declarar mais dados;
- **login opcional:** Descobrir, Buscar e Detalhes continuam sem conta. Uma ação que precisa de conta (marcar, adicionar à lista) leva ao login e volta para onde estava;
- **Firestore na região `southamerica-east1` (São Paulo)**, para as listas ficarem no Brasil. A região não muda depois de criada. Os dados de login (nome, e-mail, foto) ficam no Firebase Auth, que é global;
- **o Firestore nasce em modo de produção (tudo negado)**, nunca em "modo de teste", que libera leitura e escrita de qualquer um por 30 dias com a chave pública do APK. As regras e os testes delas vêm antes do login e de qualquer escrita;
- **os dados de cada usuário só em `users/{uid}/…`**, com regras que só deixam o dono ler e escrever, validam campos e tamanhos e ficam versionadas no repositório (`firestore.rules`), com testes;
- **o TMDB continua só de leitura** (GET com o token v4, decisão 001). O item "`TmdbClient` com POST/DELETE" sai do plano;
- **excluir a conta pelo app e por uma página na web**, porque o Google Play exige isso de apps que criam conta.
  - No app, a ordem é: login recente; apagar os documentos (o SDK do cliente não apaga recursivamente, então o app lista as subcoleções e as listas); `user.delete()`; `GoogleSignIn.disconnect()`. As regras deixam o dono apagar todos os documentos dele.
  - No plano Spark não há Cloud Functions. O mecanismo da página web fica para a sessão da exclusão: uma página no Pages com o Firebase JS e o login do Google, que faz a mesma exclusão, ou um pedido por formulário ou e-mail com prazo, que o Play aceita;
- **guardar o mínimo do filme.** O documento guarda o `movie_id` e os dados do usuário (assistido, quero ver, favorito, data, nota). Se for preciso uma cópia do título e do `poster_path` para montar a lista sem uma chamada por filme, a cópia segue o limite de cache de 6 meses dos termos do TMDB, com um campo `cached_at` e renovação quando a lista é aberta. O Firestore nunca guarda a imagem (bytes). A escolha fica para a sessão do modelo de dados;
- **logout limpa o aparelho**, na ordem: cancelar os streams; `FirebaseFirestore.terminate()`; `clearPersistence()`; `FirebaseAuth.signOut()` e `GoogleSignIn.signOut()`; recriar a instância. Se a limpeza do cache falhar, a sessão não fica aberta, e o usuário vê o erro.

Esta decisão substitui a parte da 001 sobre o `session_id` do TMDB. A parte do token de leitura v4 continua valendo.

## Consequências
- Quatro dependências novas, e o `CLAUDE.md` (stack, auth e segurança) é atualizado.
- O `flutter_secure_storage` deixa de ser necessário para a sessão, porque o Firebase Auth persiste o próprio token. Ele só entra se surgir outro dado sensível.
- **Configuração do Firebase**, feita pelo usuário no console:
  - o projeto, com o Firestore em `southamerica-east1`;
  - o app Android `io.github.cfrdlima.ja_vi_esse_filme`;
  - o SHA-1 da chave de debug (e depois o da de release);
  - o provedor Google habilitado.

  O `flutterfire configure` gera o `firebase_options.dart` e o `google-services.json`. Eles não são segredo, mas trazem uma chave de API do Google (`AIza…`), que o `gitleaks` acusa. Até a sessão do setup decidir se eles entram no git, os dois ficam no `.gitignore`. A chave é restrita no Google Cloud **antes** do primeiro commit: ao pacote e ao SHA-1, e só às APIs usadas (Identity Toolkit, Token Service e Firestore). Se os arquivos forem versionados, a exceção do `gitleaks` vai por fingerprint no `.gitleaksignore`, nunca desligando a regra. A outra opção é gerá-los no CI.
- **Testes:**
  - o domínio e o estado usam fakes dos contratos;
  - a camada `data` fica fina sobre o SDK;
  - as regras do Firestore são testadas no Emulator Suite, que pede `firebase-tools` e Java na máquina e no CI.

  Um pacote fake (`fake_cloud_firestore`, `firebase_auth_mocks`) é dependência nova e precisa ser perguntado antes.
- Os logs nunca levam o token de ID, o token de refresh, o e-mail ou o `uid` junto com dados pessoais. O redator de segredos ganha:
  - JWT (`eyJ…`) e o access token do Google (`ya29.…`);
  - os campos `idToken`, `accessToken` e `refreshToken`;
  - o e-mail.
- O token do Firebase Auth fica em SharedPreferences, protegido só pelo sandbox do app, sem cifra própria. A política não pode dizer que ele é "cifrado".
- **A política de privacidade passa à versão 2.0:**
  - dados da conta Google (nome, e-mail, foto);
  - as listas no Firestore e a região onde ficam;
  - Google/Firebase como operador e a transferência internacional do Auth;
  - a base legal;
  - prazo de guarda e exclusão da conta.

  Ela é publicada no Pages (decisão 006) antes de chegar ao usuário uma versão do app com login.
- O `data_extraction_rules.xml` continua necessário, porque a partir do Android 12 o `allowBackup="false"` não impede a transferência de aparelho para aparelho, e o cache do Firestore e o token do Auth ficam nos dados do app.
- O App Check (proteção contra clientes falsos) fica para a Fase 4, com enforcement no Firestore e no Auth antes da primeira versão na loja e o provedor de debug no desenvolvimento. Até lá, os limites de tamanho nas regras são a única barreira contra abuso da cota do Spark, que derrubaria o app para todos.
