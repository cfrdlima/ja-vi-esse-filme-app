# Sessão 026 — Fase 2: política de privacidade 2.0

**Data**: 2026-11-18 · **Branch**: `feature/026-politica-2-0` (empilhada na `feature/025-excluir-conta-web`) · **Status**: aberta

## Objetivo
Escrever a versão 2.0 do `docs/PRIVACIDADE.md`, que cobre a conta Google (Firebase Auth), as marcas no Firestore, a exclusão da conta e tudo o que o item da política 2.0 do `PLANO.md` acumulou das sessões 020 a 025, e publicá-la no repositório de suporte (decisão 006). Esse é o portão de release: nenhum APK com login sai do ambiente de desenvolvimento antes da 2.0 publicada.

## Checklist
### Preparação
- [x] Ler o item da 2.0 no `PLANO.md`, os blocos "A REVISAR" e "FASE 2 (fora da publicada)" do `docs/PRIVACIDADE.md` e as decisões 010, 013, 015 e 016; montar a lista de afirmações a cobrir. **Feito:** ver "Notas"
- [ ] Conferir na documentação oficial: região e operadores do Firebase Auth e do Firestore (transferência internacional), retenção (180 dias, IPs do login), requisitos de idade da conta Google, termos do Firebase sobre o papel de operador
- [ ] (S7 da 025) O usuário confere no console do Firebase se o Firestore tem backup agendado, PITR ou export; o resultado entra na seção de retenção
- [x] Decidir com o usuário: bases legais por finalidade (contrato, inciso V; legítimo interesse; exercício regular de direitos, art. 7º, VI para a guarda do pedido de exclusão), a base da renovação automática das cópias do TMDB na Estante (sessão 023) e a data de vigência. **Decidido:** inciso V para a conta, as marcas, a cópia local e a renovação automática; inciso VI para guardar o registro do pedido por e-mail; inciso IX para erros e cache de pôsteres (como na 1.0); vigência na data da publicação; a 2.0 substitui a 1.0 para todas as versões

### Conteúdo (sem TDD: texto, conferido contra o código)
- [x] Seções 2, 3 (nova 3.2 "Conta e marcas"), 4, 6, 7, 8, 9 e 11 conforme o item do `PLANO.md`
- [x] Afirmações sobre o comportamento do app conferidas no código (logout e `clearPersistence`, `clearStaleAccountCache`, foto só em memória, `data_extraction_rules.xml`, renovação das cópias, exclusão) e citadas no log
- [x] Página de exclusão (`docs/EXCLUSAO-DA-CONTA.md`) e política sem divergência; GitHub Pages e cdnjs no site de suporte
- [x] Versão 2.0, vigência com data, sem "A REVISAR" sobre a Fase 2 (os da Fase 3 e 4 ficam como comentários)

### No app (só se o texto do Sobre mudar; RED/GREEN/REFACTOR)
- [x] Resumo da privacidade no Sobre (ARB) coerente com a 2.0, com widget test. **Feito:** o resumo dizia "O app não tem login"; 2 testes sobre o texto (RED com o texto antigo), ARB novo, 32 verdes em `test/features/about`. **Falta:** conferir no emulador

### Publicação (ação pública, só com o ok do usuário)
- [ ] Cópia limpa no repositório de suporte (`index.md`), `gitleaks`, commit noreply, push e conferência da URL
- [ ] README do suporte atualizado se precisar

### Entrega
- [ ] `PLANO.md` (item da 2.0 marcado; portão de release)
- [ ] Tríade (format, analyze, `flutter test`) e `gitleaks`. **Antes do `/revisar`:** format 0 de 222, analyze limpo, 1399 verdes
- [ ] `/revisar` (publica conteúdo sobre auth e storage)
- [ ] `/fechar-sessao`: PR com base na `feature/025-excluir-conta-web`; merge só depois do CI destravar e da 025 integrada

## Decisões

## Commits
- `3fad9aa` docs: abre a sessão 026
- `48023e4` test: resumo de privacidade do Sobre com a conta opcional do Google
- `24e3805` add: resumo de privacidade do Sobre de acordo com a política 2.0
- `864e31f` docs: política de privacidade 2.0 com a conta Google, as marcas no Firestore e a exclusão da conta

## Notas
- **Empilhada:** o CI da conta está travado por cobrança (sessão 025, decisão 016). Quando destravar, a 025 entra primeiro na `main` e o PR desta é reapontado para a `main`.
- **Conferido no código para a 2.0:** cópia vencida com 180 dias (`ShelfMovie.copyMaxAge`), até 200 por aba (`ShelfTabNotifier.maxLimit`), `clearPersistence` + `terminate()` no logout (`FirestoreAccountCache`), `clearStaleAccountCache` só com o primeiro estado `SignedOut`, `data_extraction_rules.xml` excluindo tudo de backup e transferência, rótulos "Entrar com o Google", "Sair" e "Excluir conta" no ARB.
- **Permissões do manifesto mesclado de release** (`./gradlew :app:processReleaseMainManifest`): `INTERNET`, `ACCESS_NETWORK_STATE` (`firebase-auth` 25.0.0), `USE_BIOMETRIC` e `USE_FINGERPRINT` (`androidx.biometric` 1.1.0), `READ_GSERVICES` (`recaptcha` 18.6.1) e a `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` do próprio app. A 1.0 dizia "só internet"; a 2.0 lista as de instalação e diz que nenhuma é pedida durante o uso.
- **Fora da 2.0, de propósito:** a varredura do Admin SDK (não existe ainda; a política não a promete) e o S7 (backups/PITR do Firestore), que espera a conferência do usuário no console.
