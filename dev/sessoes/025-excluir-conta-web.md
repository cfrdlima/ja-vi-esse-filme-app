# Sessão 025 — Fase 2: excluir a conta pela web

**Data**: 2026-11-18 · **Branch**: `feature/025-excluir-conta-web` · **Status**: aberta

## Objetivo
Publicar no Pages (repositório `cfrdlima/ja-vi-esse-filme-suporte`, decisão 006) a página de exclusão da conta exigida pelo Google Play: o que é apagado, como pedir por e-mail (decisão 015), o endereço de suporte e o prazo de atendimento. Fecha o portão do Play da sessão 024 e deixa registrado o que a política 2.0 precisa declarar sobre o pedido.

## Checklist
### Preparação
- [x] Conferir a exigência do Google Play para a URL de exclusão (o que a página precisa ter: nome do app/desenvolvedor, passos, dados apagados e mantidos, prazo de retenção) na documentação oficial. **Feito:** ver "Notas"
- [x] Decidir com o usuário: endereço de suporte, prazo de atendimento, prazo de guarda do e-mail do pedido, caminho da página no Pages e se o app ganha um link para ela. **Decidido:** `xbtechnologies.app@gmail.com` (decisão 006); atendimento em até 15 dias (LGPD, art. 19, II); e-mail do pedido guardado por 6 meses depois do atendimento; página em `/ja-vi-esse-filme-suporte/excluir-conta/`; sem link no app (o Perfil já exclui, e o Play pede a URL só no formulário de Segurança dos dados). Emenda na 015
- [x] Conferir o prazo dos backups e logs do Firebase/Google Cloud depois da exclusão, sem prometer apagamento imediato. **Feito:** até cerca de 180 dias (ver "Notas")

### Conteúdo
- [x] Fonte da verdade da página em `docs/` (`docs/EXCLUSAO-DA-CONTA.md`): exclusão pelo app (passo a passo), pedido por e-mail (sai do endereço da conta Google, o que escrever), o que é apagado (marcas, cópias do TMDB, conta no Auth), o que fica (cache de outros aparelhos, backups do Google pelo prazo deles, o próprio e-mail do pedido), prazo e o que o dono do projeto vê no console
- [x] Procedimento de atendimento do pedido (checklist interno em `dev/`, fora da cópia pública): conferir o remetente, achar o `uid`, apagar `users/{uid}/…` e a conta no Auth, responder e apagar o e-mail no prazo. **Feito:** `dev/ATENDIMENTO-EXCLUSAO.md`, com a conta desativada antes de apagar e a conferência depois de 1 h

### Publicação (ação pública, só com o ok do usuário)
- [x] Cópia limpa (sem comentários HTML nem "A REVISAR"), `gitleaks` no repositório público, commit com o e-mail noreply, push e conferência da URL (HTTP 200, `lang="pt-BR"`). **Feito:** ver "Notas"

### Entrega
- [x] `PLANO.md` (item da exclusão pela web, portão do Play) e a política 2.0 com o que a página declara
- [x] Tríade (format, analyze, `flutter test`); sem UI nova. **Feito:** `dart format` sem mudança, `flutter analyze` "No issues found!", `flutter test` "+1397: All tests passed!"
- [x] `/revisar` (publica conteúdo)

### Achados aceitos do `/revisar` (o usuário mandou tratar todos, seguindo as recomendações)
- [x] (B1) Repositório do app estava **público**: voltou a privado com o ok do usuário; emenda na 006 com a conferência da visibilidade antes de publicar. **Efeito:** o ruleset `checks` deixa de valer no plano Free (ver "Notas")
- [x] (B2) Dados sem conta depois de uma exclusão pelo app: passo 9 no procedimento (comparar `users` com o Authentication e apagar os sem conta); página diz "apagamos todos os dados que ficaram sem conta"
- [x] (I1) Remetente: DMARC ou SPF/DKIM em PASS, resposta numa mensagem nova sem `Reply-To` e confirmação antes de apagar (passo 2 e página)
- [x] (I2, I3) Ordem desativar → documentos → 1 h da desativação → excluir no Auth; e-mail exato, provedor `google.com`, `uid` conferido e só a linha desativada
- [x] (I4) "Outros aparelhos" igual ao `clearStaleAccountCache`
- [x] (I5) Revogação do acesso no pedido por e-mail: link `myaccount.google.com/permissions` na página e na resposta
- [x] (I6) Saída da tríade no log
- [x] (S1–S6, S8, S9) Passo certo sem conta, rótulos do console, lixeira e enviados, LGPD (19, II e 7º, VI), botão de confirmar, datas do Auth, o que o console mostra, cdnjs/Pages na 2.0, `description` próprio no front matter
- [ ] (S7) Conferir no console se o Firestore tem backup agendado, PITR ou export: o `firebase` CLI da máquina está em outra conta (403 no projeto). Pendência para o usuário, também no item da 2.0
- [ ] Republicar a página corrigida (decisão 006), com `gitleaks` e o noreply
- [ ] `/fechar-sessao`

## Decisões
- Emenda na [015](../decisoes/015-exclusao-da-conta.md): endereço, prazo de 15 dias, guarda de 6 meses, caminho da página, sem link no app e a ordem do atendimento no console.

## Commits
- `46bcccb` docs: abre a sessão 025
- `afb2060` docs: página de exclusão da conta pela web e procedimento de atendimento do pedido
- `5cc4990` docs: emenda na decisão 015 com o endereço, o prazo e a guarda do pedido por e-mail
- Repositório público: `ddc12a6` docs: página de exclusão da conta (autor e committer noreply, sem atribuição, a pedido do usuário)

## Notas
- **Exigência do Play** (Central de Ajuda, "Understanding Google Play's app account deletion requirements"): link funcional; nome do app ou do desenvolvedor igual ao da ficha da loja; caminho de exclusão em destaque; pedido sem precisar do app (e-mail aceito); dados ligados à conta apagados; o que fica guardado e por quê informado; prazo "razoavelmente rápido", sem número. A URL vai no formulário de Segurança dos dados, mesmo com a exclusão no app. **Pendência para a loja:** o nome "Claudinei de Lima" precisa bater com o nome do desenvolvedor no Play Console (o usuário manteve o nome).
- **Prazo do Google:** Firebase (firebase.google.com/support/privacy): o Auth guarda os IPs do login por algumas semanas e remove os dados dos sistemas ativos e dos backups em até 180 dias depois da exclusão. Google Cloud (docs.cloud.google.com/docs/security/deletion): cerca de 2 meses nos sistemas ativos e até 6 meses nos backups; no máximo cerca de 180 dias.
- **Publicação (decisão 006), com o ok do usuário:** cópia como conteúdo em `excluir-conta/index.md` (sem o comentário HTML) e uma linha no `README.md`. A config global do clone trazia o e-mail pessoal; o clone recebeu `user.email` noreply antes do commit, conferido no autor e no committer. O `gitleaks` não está instalado; rodou em container (`docker.io/zricethezav/gitleaks:v8.21.2`, podman) no repositório público e nos commits da sessão, sem vazamento.
- **Conferência no ar:** `https://cfrdlima.github.io/ja-vi-esse-filme-suporte/excluir-conta/` com HTTP 200, `lang="pt-BR"`, o e-mail, os 15 e os 180 dias; o link `../` abre a política (HTTP 200). Os comentários HTML na página são do tema do Jekyll (SEO tag, "Setup Google Analytics" sem script); os únicos scripts são o `anchor-js` do cdnjs (com SRI) e o JSON-LD, como na página da política.
- **`/revisar`:** `code-reviewer` (1 bloqueante, 5 importantes, 7 sugestões) e `security-auditor` (1 bloqueante, 3 importantes, 6 sugestões), consolidados em B1–B2, I1–I6 e S1–S9.
- **Repositório público (B1):** `gh api` mostrava `visibility: public`, sem fork, sem estrelas, sem Pages; a página respondia 200 sem login. Depois do `gh repo edit --visibility private`, 404 sem login. O ruleset `checks` (enforcement `active`) passou a responder 403 "Upgrade to GitHub Pro or make this repository public to enable this feature.": o CI continua rodando nos PRs, mas o merge sem os checks não é mais bloqueado.
- A política 1.0 publicada não mudou: ela descreve o app sem login, e a 2.0 aponta para a página nova.
