# 017 — Limpeza mensal do Firestore com um script local do Admin SDK

**Data**: 2026-11-18 · **Status**: aceita

## Contexto
A decisão 013 guarda, por filme marcado, uma cópia do título e do caminho do pôster do TMDB e a renova só quando o filme é marcado ou aparece na Estante com a cópia vencida (mais de 180 dias), nas páginas carregadas (até 200 por aba). Os termos da API do TMDB (§1.C) limitam a guarda de conteúdo em cache a 6 meses. Quem não abre a Estante, ou tem mais de 200 filmes numa aba, fica com cópias vencidas sem limite. A 013 pediu decidir a limpeza antes da política 2.0.

A decisão 015 também deixa documentos órfãos possíveis: outro aparelho com um ID token ainda válido (até cerca de 1 h) pode recriar `users/{uid}/movies/{id}` depois da exclusão da conta. A página de exclusão promete apagar os dados que ficaram sem conta.

O projeto está no plano Spark (decisão 011), sem Cloud Functions nem Cloud Scheduler. O repositório do app é público (decisão 016).

## Opções consideradas
1. **Script local com o Admin SDK**, rodado pelo dono do projeto uma vez por mês, com credencial só na máquina dele.
2. **Workflow agendado no GitHub Actions** com o mesmo script. Gratuito no repositório público, mas exige uma chave de conta de serviço como secret num repositório público, com poder total sobre o Firestore e o Auth.
3. **Sem limpeza**, com a cópia guardada enquanto o filme estiver marcado. Fere o limite de 6 meses do TMDB.
4. **Blaze com Cloud Functions agendadas.** Sai do Spark (decisão 011) e põe cobrança no projeto.

## Decisão
Opção 1.
- **Script em `firestore/`** (Node, o mesmo pacote dos testes das regras), com o `firebase-admin` como dependência. A dependência é pedida e registrada na sessão que implementar o script.
- **O que ele faz, em ordem:**
  1. lista os `uid` do Firebase Authentication;
  2. apaga as subcoleções do `UserCollections` de todo `users/{uid}` sem conta no Auth;
  3. nas contas que existem, trata os documentos com `cachedAt` de mais de 180 dias para que nenhuma cópia vencida fique guardada, sem perder as marcas. **Como** fica para a sessão do script: hoje as regras exigem `title` e `cachedAt` e comparam o `title` antigo numa mudança só de marca, e o model do app espera o `title`. As saídas são renovar a cópia pelo TMDB no próprio script (com o token de leitura do dono, fora do git) ou apagar a cópia e adaptar as regras, o model e a Estante a um documento sem cópia, com TDD e testes das regras no mesmo ciclo.
- **Frequência:** uma vez por mês, pelo dono do projeto, com o lembrete no calendário dele. Com isso, nenhuma cópia passa de cerca de 7 meses (180 dias mais o intervalo).
- **Credencial:** a do próprio dono (Application Default Credentials do `gcloud`, ou uma chave guardada fora do repositório e do `env/`), nunca no git, no CI nem em secret do GitHub.
- **Testado no emulador** (Auth e Firestore), como as regras (decisão 012), com o projeto `demo-`. O script nunca roda contra o projeto real nos testes.
- **Saída sem dado pessoal:** o script só imprime contagens (documentos limpos, contas órfãs apagadas), nunca `uid`, e-mail ou títulos.
- **A política 2.0 só é publicada depois do script pronto e da primeira execução**, porque ela promete a limpeza mensal.

- **Emenda (sessão 027): escolhas da implementação.** A cópia vencida é **renovada pelo TMDB** no próprio script (título em pt-BR com o original de reserva, cortado em 300 caracteres, pôster só no formato do TMDB, `cachedAt` com a hora do servidor), com o token de leitura v4 numa variável de ambiente (`TMDB_READ_TOKEN`), nunca em arquivo nem argumento. O app e as regras não mudam, e um teste confere pelas regras que o documento renovado aceita a próxima marca do app. Um filme que **sumiu do TMDB (404) é apagado**, porque o app já não consegue mostrá-lo. No limite de requisições (429), o script para e sai com código 1, e o resto fica para a próxima execução. A credencial é a **ADC do `gcloud`** da conta dona do projeto, sem arquivo de chave. O `firebase-admin` 14.5.0 entra como dependência do `firestore/` (a 14.5.1 tinha menos de duas semanas). Instruções e registro das execuções em `dev/LIMPEZA-MENSAL.md`.

Esta decisão complementa a 013 e a 015 e não substitui nenhuma.

## Consequências
- A política 2.0 diz que a cópia do TMDB sai em até cerca de 7 meses e que os dados sem conta saem na limpeza mensal.
- O Admin SDK passa por cima das regras, mas o documento que ele deixa precisa continuar válido para o app e para as próximas escritas do cliente (ver o passo 3).
- Nova sessão antes da publicação da 2.0: o script, os testes no emulador e a primeira execução.
- Um mês esquecido estica o prazo. O log de cada execução fica no `dev/` (só a data e as contagens), para o dono conferir a regularidade.
- Se o projeto passar para o Blaze, a limpeza pode virar uma Cloud Function agendada, com nova decisão.
