# Sessão 025 — Fase 2: excluir a conta pela web

**Data**: 2026-11-18 · **Branch**: `feature/025-excluir-conta-web` · **Status**: aberta

## Objetivo
Publicar no Pages (repositório `cfrdlima/ja-vi-esse-filme-suporte`, decisão 006) a página de exclusão da conta exigida pelo Google Play: o que é apagado, como pedir por e-mail (decisão 015), o endereço de suporte e o prazo de atendimento. Fecha o portão do Play da sessão 024 e deixa registrado o que a política 2.0 precisa declarar sobre o pedido.

## Checklist
### Preparação
- [ ] Conferir a exigência do Google Play para a URL de exclusão (o que a página precisa ter: nome do app/desenvolvedor, passos, dados apagados e mantidos, prazo de retenção) na documentação oficial
- [x] Decidir com o usuário: endereço de suporte, prazo de atendimento, prazo de guarda do e-mail do pedido, caminho da página no Pages e se o app ganha um link para ela. **Decidido:** `xbtechnologies.app@gmail.com` (decisão 006); atendimento em até 15 dias (LGPD, art. 19, II); e-mail do pedido guardado por 6 meses depois do atendimento; página em `/ja-vi-esse-filme-suporte/excluir-conta/`; sem link no app (o Perfil já exclui, e o Play pede a URL só no formulário de Segurança dos dados). Emenda na 015
- [ ] Conferir o prazo dos backups e logs do Firebase/Google Cloud depois da exclusão, sem prometer apagamento imediato

### Conteúdo
- [ ] Fonte da verdade da página em `docs/` (ex.: `docs/EXCLUSAO-DA-CONTA.md`): exclusão pelo app (passo a passo), pedido por e-mail (sai do endereço da conta Google, o que escrever), o que é apagado (marcas, cópias do TMDB, conta no Auth), o que fica (cache de outros aparelhos, backups do Google pelo prazo deles, o próprio e-mail do pedido), prazo e o que o dono do projeto vê no console
- [ ] Procedimento de atendimento do pedido (checklist interno em `dev/`, fora da cópia pública): conferir o remetente, achar o `uid`, apagar `users/{uid}/…` e a conta no Auth, responder e apagar o e-mail no prazo

### Publicação (ação pública, só com o ok do usuário)
- [ ] Cópia limpa (sem comentários HTML nem "A REVISAR"), `gitleaks` no repositório público, commit com o e-mail noreply, push e conferência da URL (HTTP 200, `lang="pt-BR"`)

### Entrega
- [ ] `PLANO.md` (item da exclusão pela web, portão do Play) e a política 2.0 com o que a página declara
- [ ] Tríade (format, analyze, `flutter test`); sem UI nova
- [ ] `/revisar` (publica conteúdo)
- [ ] `/fechar-sessao`

## Decisões

## Commits

## Notas
