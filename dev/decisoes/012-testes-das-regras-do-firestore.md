# 012 — Testes das regras do Firestore com rules-unit-testing e node:test

**Data**: 2026-11-17 · **Status**: aceita

## Contexto
A decisão 010 exige `firestore.rules` versionado e testado no Emulator Suite antes do login e de qualquer escrita. As regras são a única barreira entre a chave pública do APK e os dados do usuário (e, no Spark, contra abuso da cota até o App Check). O `flutter test` não roda o emulador nem avalia regras, então os testes precisam de ferramentas fora do `pubspec`.

## Opções consideradas
1. **`@firebase/rules-unit-testing` + `firebase` (JS SDK) com o runner nativo `node:test`.** É a biblioteca oficial para testar regras: monta contextos autenticados e anônimos e oferece `assertSucceeds`/`assertFails`. O `node:test` vem com o Node e evita mais uma dependência.
2. **A mesma biblioteca com mocha ou vitest.** Melhor relatório, mas é mais uma dependência sem ganho real para cerca de 20 testes.
3. **Chamadas REST cruas ao emulador com tokens falsos.** Nenhuma dependência npm, mas é muito código frágil para reproduzir o que a biblioteca oficial já faz.

## Decisão
Opção 1, isolada em `firestore/` (o app Flutter não vê nada disso):
- `firestore/package.json` com `devDependencies` fixadas na versão exata e um `package-lock.json` versionado:
  - `@firebase/rules-unit-testing` **5.0.2**. A 6.0.0 exige Node ≥ 24.12, e a máquina e o CI usam o Node 22 LTS;
  - `firebase` **12.19.0** (a peer da 5.x é `^12`);
  - `firebase-tools` **15.34.2**, local ao projeto, para que todas as máquinas e o CI usem o mesmo emulador, sem depender da CLI global.

  Uma versão nova só entra com pelo menos duas semanas de publicação.
- Os testes rodam com `npm test` dentro de `firestore/`, que chama `firebase emulators:exec` com o projeto **`demo-ja-vi-esse-filme`**. O prefixo `demo-` garante que o emulador nunca fale com o projeto real.
- O emulador exige **Java 21 ou mais**. Com o Java 17, a `firebase-tools` recusa ("no longer supports Java version before 21").
- O CI ganha um job próprio com Node 22, Java 21 e `npm ci`.

## Consequências
- Dependências npm só de desenvolvimento, que não vão para o APK. O `npm audit` acusa vulnerabilidades transitivas (moderadas e altas) dentro da `firebase-tools`. Elas não têm correção sem voltar para a 13.x, e o código só roda localmente contra o emulador, com o projeto `demo-`. Revisar a cada atualização da `firebase-tools`.
- `node_modules/` e os logs do emulador ficam no `.gitignore`.
- Quem for rodar os testes das regras precisa de Node 22 e de um JDK 21 (`JAVA_HOME`).
- O CI guarda em cache o jar do emulador (`~/.cache/firebase/emulators`), que roda no runner. O risco de um cache adulterado é aceito: o cache de um PR fica restrito à ref dele e não chega à `main`, o workflow usa `pull_request` (nunca `pull_request_target`), `contents: read`, nenhum secret e `persist-credentials: false`. Se o job ganhar algum secret, o cache passa a ser só restaurado nos PRs e salvo apenas no push para a `main`.
- O repositório não tem `.firebaserc`, para nenhum comando sem `--project` apontar para produção. O deploy das regras sempre passa o projeto explícito: `firebase deploy --only firestore:rules --project ja-vi-esse-filme`.
- A sessão do modelo de dados (Fase 2) e a das listas (Fase 3) estendem as regras e estes testes juntas.
