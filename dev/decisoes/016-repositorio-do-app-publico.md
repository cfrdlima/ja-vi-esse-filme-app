# 016 — Repositório do app público, procedimento de atendimento fora do git

**Data**: 2026-11-18 · **Status**: aceita

## Contexto
A decisão 006 parte de um repositório do app **privado** e separa a política num repositório público. No `/revisar` da sessão 025, o `security-auditor` achou o `cfrdlima/ja-vi-esse-filme-app` público (`visibility: public`). Ele voltou a privado e, com isso:
- o ruleset `checks` da `main` deixou de valer (só existe em repositório privado no GitHub Pro);
- o CI passou a consumir a cota paga do Actions; o orçamento de US$ 0 da conta bloqueou os jobs, e a conta ficou travada ("your account is locked due to a billing issue"), mesmo depois de o repositório voltar a ser público e de o orçamento ser apagado.

O usuário quer o repositório público e nenhum gasto com o Actions. Já estão públicos o código, as decisões, os logs de sessão e o e-mail da config de git nos commits antigos. A sessão 025 criou o `dev/ATENDIMENTO-EXCLUSAO.md`, com o passo a passo de como a identidade é conferida no pedido de exclusão por e-mail, que esteve na branch `feature/025-excluir-conta-web` enquanto o repositório era público.

## Opções consideradas
Sobre a visibilidade:
1. **Privado**, como a 006 supõe. Exige o Pro para o ruleset e gasta minutos do Actions.
2. **Público.** Actions gratuito e o ruleset volta a valer; tudo no git passa a ser público.

Sobre o procedimento de atendimento:
1. **No git**, como está. Fica público.
2. **Só local**, no disco do dono do projeto, ignorado pelo git. Some se a máquina se perder.
3. **Nota privada fora do repositório** (Drive, e-mail de suporte).

Sobre o histórico:
1. **Reescrever** a branch (e/ou a `main`) para tirar o procedimento e o e-mail dos commits antigos. Exige `push --force`, e o GitHub guarda os commits do PR (`refs/pull/*`) mesmo assim.
2. **Não reescrever** e só tirar o arquivo daqui para a frente.

## Decisão
- **O repositório do app é público.** Isso substitui a premissa de repositório privado da 006. O resto da 006 (política com fonte no `docs/PRIVACIDADE.md`, cópia no repositório de suporte, procedimento de publicação) continua valendo.
- **Nada interno sensível entra no git.** Procedimentos operacionais que dependem de sigilo, dados de atendimento e qualquer dado de usuário ficam fora do repositório. Antes de cada commit vale a pergunta "isto pode ser público?".
- **O procedimento de atendimento fica só local**, em `dev/ATENDIMENTO-EXCLUSAO.md`, listado no `.gitignore`. O que o projeto promete ao usuário continua público na página (`docs/EXCLUSAO-DA-CONTA.md`) e as regras do atendimento ficam resumidas na decisão 015. A segurança da conferência vem do DMARC/SPF/DKIM e da confirmação pedida ao endereço da conta, não do sigilo do texto.
- **O histórico não é reescrito.** As versões do procedimento que já estiveram nos commits da branch da sessão 025 continuam no histórico, e os commits antigos continuam com o e-mail da config de git. Reescrever não apagaria as cópias que o GitHub guarda nos refs do PR.
- **Actions sem gasto:** repositório público não consome a cota paga. A conta não deve ter repositório privado com workflow ativo enquanto houver orçamento de US$ 0 com bloqueio, para não travar de novo.

## Consequências
- O ruleset `checks` volta a ser aplicado na `main` (repositório público).
- O procedimento de atendimento não tem cópia fora da máquina do dono do projeto: uma cópia de segurança fica por conta dele (ex.: nota privada).
- A decisão 006 fica com a premissa de repositório privado superada por esta; a emenda da sessão 025 nela é corrigida.
- Os logs de sessão, decisões e planos continuam no repositório público: eles nunca trazem `uid`, e-mail de usuário, marcas, segredos ou o passo a passo da conferência de identidade.
- Enquanto a trava de cobrança da conta não sair, o CI não roda; ver o log da sessão 025.
