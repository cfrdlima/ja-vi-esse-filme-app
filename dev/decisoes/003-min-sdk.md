# 003 — minSdk 24 herdado do Flutter

**Data**: 2026-10-16 · **Status**: aceita

## Contexto
O `android/app/build.gradle.kts` usa `minSdk = flutter.minSdkVersion`, `targetSdk = flutter.targetSdkVersion` e `compileSdk = flutter.compileSdkVersion`. No Flutter 3.44.5 esses valores são 24 (Android 7.0), 36 e 36. A auditoria de prontidão pediu que o minSdk fosse justificado.

## Opções consideradas
1. **Herdar os valores do Flutter**: acompanha o mínimo que o engine suporta sem manutenção extra. Risco: um upgrade do Flutter pode subir o minSdk sem que ninguém perceba.
2. **Fixar `minSdk = 24` no gradle**: o valor fica explícito. Custo: se o Flutter passar a exigir mais, o número fixo fica desatualizado e precisa ser trocado à mão.
3. **Subir para 26 ou mais**: só se justificaria se algum plugin exigisse, e hoje nenhum exige.

## Decisão
Opção 1. O minSdk 24 é o mínimo oficial do Flutter 3.44, cobre praticamente todos os aparelhos Android em uso e não pede nada que o app precise além disso. Os plugins previstos (`flutter_secure_storage`, `url_launcher`, `cached_network_image`) precisam ser conferidos na hora de entrar, e esta decisão é revista se algum deles exigir mais.

## Consequências
- A cada upgrade do Flutter, conferir no changelog se `minSdkVersion`/`targetSdkVersion` mudaram e atualizar esta decisão.
- Antes do release (Fase 4), conferir se o `targetSdk` atende a exigência vigente da Play Store.
- Abaixo do Android 7.0 o app não instala.
