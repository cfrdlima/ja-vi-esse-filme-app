# 011 — Arquivos do Firebase versionados com chave restrita, e plano Spark

**Data**: 2026-11-17 · **Status**: aceita

## Contexto
Na sessão 016, o `flutterfire configure --platforms=android` gerou o `lib/firebase_options.dart` e o `android/app/google-services.json` para o projeto `ja-vi-esse-filme`. Os dois trazem a chave de API do Google (`AIza…`) e, pela decisão 010, ficaram no `.gitignore` até esta sessão decidir se entram no git.

O `main.dart` vai importar o `firebase_options.dart` para o `Firebase.initializeApp`, e o plugin `com.google.gms.google-services` passa a exigir o `google-services.json` no build Android. Sem os arquivos no repositório, o `flutter analyze` e o `flutter test` do CI quebram.

A chave vai dentro do APK de qualquer jeito, então pode ser extraída (o mesmo raciocínio da decisão 001). Quem protege os dados do usuário são as regras do Firestore (só o dono acessa `users/{uid}/…`) e, a partir da Fase 4, o App Check.

Também na sessão 016, o projeto foi criado no plano **Blaze**, e a decisão 010 assume o **Spark**.

## Opções consideradas
1. **Versionar os dois arquivos, com a chave restrita antes do commit.** O CI continua igual, e um clone novo compila sem passo extra. É o que a documentação do Firebase recomenda, já que esses valores não são segredo. Custo: a chave fica pública no GitHub, e a proteção depende das restrições no Google Cloud, das regras e do App Check.
2. **Deixar fora do git e gerar no CI com GitHub Secrets** (os arquivos em base64, recriados pelo workflow antes do analyze e do test). A chave não aparece no repositório. Custo: mais trabalho e mais um ponto de falha. Quem clona precisa rodar o `flutterfire configure` antes de compilar, e a chave continua extraível do APK.

Sobre o plano:
1. **Manter o Blaze** com orçamento e alertas em 50%, 90% e 100%. Libera Cloud Functions, mas o abuso da cota vira cobrança.
2. **Voltar ao Spark.** Sem cobrança possível: estourar a cota derruba o app, mas não gera fatura.

## Decisão
- **Versionar** o `lib/firebase_options.dart` e o `android/app/google-services.json` (opção 1). Antes do primeiro commit que os inclua, a chave é restrita no Google Cloud:
  - aplicativos Android: pacote `io.github.cfrdlima.ja_vi_esse_filme` com o SHA-1 de debug (e o de release quando houver assinatura própria, na Fase 4);
  - APIs: só Identity Toolkit, Token Service e Cloud Firestore.
- A exceção do `gitleaks` vai **por fingerprint** no `.gitleaksignore`, uma linha por ocorrência. A regra nunca é desligada.
- O `firebase.json` gerado pelo `flutterfire` também é versionado. Ele só traz o `projectId` e o `appId`, sem chave, e permite repetir o `configure`.
- **Plano Spark.** O usuário voltou o projeto do Blaze para o Spark em 2026-11-17, o que mantém a premissa da decisão 010.

## Consequências
- Os arquivos saem do `.gitignore`. O CI continua sem secrets do Firebase.
- Uma chave nova (rotação ou novo `flutterfire configure`) exige a mesma restrição antes do commit, e o fingerprint do `.gitleaksignore` precisa ser trocado.
- Ao criar a assinatura de release (Fase 4), adicionar o SHA-1 e o SHA-256 de release ao app no Firebase e à restrição da chave.
- Com o Spark, não há Cloud Functions. A exclusão de conta pela web segue o que a decisão 010 prevê (página com o Firebase JS ou pedido por formulário ou e-mail).
- No Spark, um abuso da cota derruba o app para todos. Até o App Check (Fase 4), os limites de tamanho nas regras do Firestore são a única barreira.
- Se algum dia for preciso o Blaze (Functions, por exemplo), esta decisão é revista, com orçamento e alertas em 50%, 90% e 100% antes de ativar.
