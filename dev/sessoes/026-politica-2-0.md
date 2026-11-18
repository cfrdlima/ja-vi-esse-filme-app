# Sessão 026 — Fase 2: política de privacidade 2.0

**Data**: 2026-11-18 · **Branch**: `feature/026-politica-2-0` (empilhada na `feature/025-excluir-conta-web`) · **Status**: fechada

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
- [ ] **Bloqueada pela decisão 017** (script e primeira execução), pelo B2 e pela prova empírica. Cópia limpa no repositório de suporte (`index.md`), `gitleaks`, commit noreply, push e conferência da URL
- [ ] README do suporte atualizado se precisar

### Entrega
- [x] `PLANO.md` (item da 2.0 marcado; portão de release). **Mudou:** o item continua aberto (texto pronto, publicação pendente) e ganhou antes dele o script da 017
- [x] Tríade (format, analyze, `flutter test`) e `gitleaks`. **Antes do `/revisar`:** format 0 de 222, analyze limpo, 1399 verdes. **Depois dos achados:** format 0 de 222, analyze limpo, 1398 verdes (os dois testes do resumo viraram um)
- [x] `/revisar` (publica conteúdo sobre auth e storage). **Feito:** `code-reviewer` (1 bloqueante, 7 importantes, 8 sugestões) e `security-auditor` (2 bloqueantes, 9 importantes, 8 sugestões)

### Achados aceitos do `/revisar` (o usuário escolheu a opção (a) e mandou aplicar importantes e sugestões)
- [x] (B1) Limpeza das cópias e dos dados sem conta: decisão 017 (script local do Admin SDK, mensal); a política promete a limpeza e a publicação espera o script. **Achado ao escrever:** as regras exigem `title`, então "apagar a cópia" fica para a sessão do script decidir (renovar pelo TMDB ou adaptar regras e app)
- [ ] (B2) Console: S7 (backup, PITR, export do Firestore) e aceite dos termos de tratamento de dados do Firebase. Pendência do usuário; marcadores `A REVISAR` na política
- [x] Importantes: outros aparelhos e dados sem conta na seção 7 (link certo para a página), exclusão interrompida sem contradição, pôsteres da Estante ao TMDB, log mascara "credenciais e o e-mail", identificador da conta Google e e-mail verificado (também na página de exclusão), perfil junto do token no aparelho, inciso II para atender pedido, 6 meses para todos os pedidos, Gmail na seção 6 e na transferência, `USE_FINGERPRINT` e a origem da biometria (`androidx.credentials` 1.6.0, puxado pelo `firebase-auth`), marcador do App Check para uma 2.1
- [x] Sugestões: login também ao marcar um filme, renovação só da cópia vencida, fotos do elenco no cache, resumo do Sobre com a conta (RED/GREEN, teste único), frases reescritas, confirmação no endereço da conta na seção 10, menores de 13 nem com conta supervisionada, adesão ao serviço, correção na conta Google, portabilidade por e-mail, vigência com marcador para a data real
- [ ] Prova empírica: sem conta, nenhuma conexão a `*.googleapis.com` (proxy ou logcat de rede), antes de publicar
- [x] `/fechar-sessao`: PR com base na `feature/025-excluir-conta-web`; merge só depois do CI destravar e da 025 integrada. **Feito:** format 0 de 222, analyze limpo, 1398 verdes, `gitleaks` em container sem vazamento

## Decisões
- [017](../decisoes/017-limpeza-mensal-com-admin-sdk.md): limpeza mensal do Firestore com um script local do Admin SDK (cópias vencidas e dados sem conta); a 2.0 só é publicada depois do script pronto e da primeira execução.

## Commits
- `3fad9aa` docs: abre a sessão 026
- `48023e4` test: resumo de privacidade do Sobre com a conta opcional do Google
- `24e3805` add: resumo de privacidade do Sobre de acordo com a política 2.0
- `864e31f` docs: política de privacidade 2.0 com a conta Google, as marcas no Firestore e a exclusão da conta
- `361c7c0` docs: andamento da sessão 026
- `63f0734` test: resumo de privacidade do Sobre cita a conta no Firebase, num teste só
- `9581ea2` add: resumo de privacidade do Sobre cita a conta no Firebase
- `ac58ad2` docs: decisão 017 e política 2.0 com os achados do /revisar da sessão 026

- `26f9076` docs: achados do /revisar da sessão 026 no log e script da decisão 017 no plano
- (este) docs: fecha sessão 026

## Notas
- **Empilhada:** o CI da conta está travado por cobrança (sessão 025, decisão 016). Quando destravar, a 025 entra primeiro na `main` e o PR desta é reapontado para a `main`.
- **Conferido no código para a 2.0:** cópia vencida com 180 dias (`ShelfMovie.copyMaxAge`), até 200 por aba (`ShelfTabNotifier.maxLimit`), `clearPersistence` + `terminate()` no logout (`FirestoreAccountCache`), `clearStaleAccountCache` só com o primeiro estado `SignedOut`, `data_extraction_rules.xml` excluindo tudo de backup e transferência, rótulos "Entrar com o Google", "Sair" e "Excluir conta" no ARB.
- **Permissões do manifesto mesclado de release** (`./gradlew :app:processReleaseMainManifest`): `INTERNET`, `ACCESS_NETWORK_STATE` (`firebase-auth` 25.0.0), `USE_BIOMETRIC` e `USE_FINGERPRINT` (`androidx.biometric` 1.1.0), `READ_GSERVICES` (`recaptcha` 18.6.1) e a `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` do próprio app. A 1.0 dizia "só internet"; a 2.0 lista as de instalação e diz que nenhuma é pedida durante o uso.
- **Antes do `/revisar`, fora da 2.0:** a varredura do Admin SDK e o S7 (backups/PITR do Firestore), que espera a conferência do usuário no console.
- **Sem conta, nada vai ao Google** (`security-auditor`): o `ComponentDiscoveryService` do manifesto de release só registra core, common, auth e firestore (sem Installations nem `datatransport`), o `GoogleSignIn.initialize` é preguiçoso e, sem conta, o Firestore só faz o `clearPersistence` local. Falta a prova empírica de rede.
- **Pendências para publicar a 2.0:** script da decisão 017 e a primeira execução (sessão 027); no console, o S7 (backup, PITR, export) e o aceite dos termos de tratamento de dados do Firebase; prova de rede sem conta; conferir o resumo novo do Sobre no emulador; vigência com a data real; republicar a página de exclusão junto (frase da limpeza mensal e identificador da conta Google).
