# Política de Privacidade — Já Vi Esse Filme

**Versão:** 0.1 (rascunho) · **Vigência:** a partir da publicação na URL pública (ver decisão 006)

<!--
Fonte da verdade da política (decisão 006). Toda sessão que mudar o que o app
coleta, guarda ou envia atualiza este arquivo e a versão/vigência acima.
Marcadores "A REVISAR" apontam pontos que dependem de decisões futuras e não
podem ir para a versão publicada sem resolução.
-->

Esta política explica quais dados o app **Já Vi Esse Filme** trata, para quê, com quem eles são compartilhados e como você pode exercer seus direitos, conforme a Lei Geral de Proteção de Dados (Lei nº 13.709/2018, LGPD).

## 1. Quem é o responsável

O app é um projeto independente mantido por um desenvolvedor pessoa física. Ele é o controlador dos dados que o próprio app trata. O contato está na seção 9.

O app usa a API do **The Movie Database (TMDB)**, mas não é endossado, certificado nem aprovado pelo TMDB. O TMDB é um serviço de terceiros com política de privacidade própria (seção 5).

## 2. Resumo

- O app **não tem servidor próprio**. Os dados de filmes vêm direto do TMDB.
- O app **não usa** analytics, anúncios, localização, câmera, microfone nem contatos. A única permissão do Android é o acesso à internet.
- O app **não vende nem compartilha** seus dados com ninguém além do TMDB, que fornece o conteúdo.
- Sem login, o app não guarda nenhum dado pessoal no aparelho.

## 3. Quais dados são tratados

### 3.1 Uso sem login

Ao buscar e abrir filmes, o aparelho se conecta diretamente aos servidores do TMDB (`api.themoviedb.org` e `image.tmdb.org`). Nessas conexões, o TMDB recebe:

- o **endereço IP** e dados técnicos da conexão;
- os **termos de busca** que você digita e os filmes que você abre.

O app não guarda seu histórico de busca. As requisições se identificam com uma credencial do próprio app, e não com uma credencial sua.

### 3.2 Uso com login na conta TMDB

O login é opcional e acontece **no site do TMDB, no seu navegador**. O app nunca vê nem guarda sua senha. Depois que você aprova o acesso, o app recebe:

- um **identificador de sessão** (`session_id`), guardado só no armazenamento seguro do Android (Keystore), usado para agir na sua conta e nunca registrado em log;
- o **identificador e o nome de usuário** da sua conta TMDB, para mostrar seu perfil.

**Favoritos, watchlist ("quero ver") e listas** ficam na sua conta do TMDB, e não no app. O app só os lê e altera a seu pedido.

### 3.3 "Já vi esse filme", nota pessoal e data

<!-- A REVISAR (Fase 3): o armazenamento do "já vi" ainda não foi decidido (local no aparelho ou na conta TMDB). Descrever aqui onde fica, por quanto tempo e como apagar. -->

Os filmes marcados como já vistos, a nota pessoal e a data em que você assistiu são guardados conforme descrito nesta seção, quando o recurso existir.

### 3.4 Erros e falhas

Quando o app encontra um erro inesperado, a mensagem é registrada só no log local do aparelho, sem identificador de sessão nem credenciais. Ela não é enviada a ninguém.

<!-- A REVISAR (Fase 4): se entrar crash reporting (Crashlytics ou Sentry), descrever o serviço, os dados do aparelho enviados, o país de processamento e a base legal, e incluí-lo na seção 5. -->

## 4. Para que os dados são usados e com qual base legal

| Dado | Finalidade | Base legal (LGPD, art. 7º) |
|---|---|---|
| IP, termos de busca, filmes abertos (recebidos pelo TMDB) | Buscar e exibir informações de filmes | Execução do serviço que você solicitou (inciso V) |
| `session_id`, identificador e nome de usuário TMDB | Acessar sua conta TMDB a seu pedido (favoritos, watchlist, listas) | Execução do serviço que você solicitou (inciso V) |

Nenhum dado é usado para perfil de publicidade, venda ou treinamento de modelos de IA.

## 5. Compartilhamento e transferência internacional

O único terceiro é o **TMDB**, que fornece o conteúdo e a conta. Ele recebe os dados descritos na seção 3 diretamente do seu aparelho e os trata conforme a [política de privacidade do TMDB](https://www.themoviedb.org/privacy-policy).

O TMDB processa dados em servidores de vários países, inclusive nos Estados Unidos. Ao usar o app, os dados enviados ao TMDB são transferidos para fora do Brasil (LGPD, art. 33).

## 6. Por quanto tempo os dados ficam guardados

- **No aparelho:** o identificador de sessão fica guardado até você sair da conta no app (o que também encerra a sessão no TMDB) ou desinstalar o app.
- **No TMDB:** pelo prazo definido na política de privacidade do TMDB.
- O app não faz backup dos seus dados na nuvem do Android.

## 7. Seus direitos

Pela LGPD (art. 18), você pode pedir confirmação de tratamento, acesso, correção, eliminação, portabilidade e informação sobre compartilhamento, além de revogar consentimento.

- **Dados no aparelho:** saia da conta no app ou desinstale o app para apagá-los.
- **Dados na sua conta TMDB** (favoritos, watchlist, listas, perfil): o TMDB é o controlador. Exerça seus direitos direto com ele, pelas configurações da conta no site ou pelo contato da política do TMDB.
- **Dúvidas sobre este app:** use o canal da seção 9.

## 8. Segurança

- Todas as conexões usam HTTPS. O app recusa tráfego sem criptografia.
- O identificador de sessão fica no armazenamento seguro do Android e nunca aparece em logs.
- O app não pede permissões além do acesso à internet.

## 9. Contato

Dúvidas, pedidos e reclamações sobre esta política: abra uma **Issue** no repositório público de suporte do app no GitHub.

<!-- A REVISAR (Fase 4): o repositório público (nome provisório cfrdlima/ja-vi-esse-filme-suporte) ainda não existe. Pôr o link definitivo das Issues e a URL do GitHub Pages antes de publicar (decisão 006). -->

Você também pode reclamar à Autoridade Nacional de Proteção de Dados (ANPD).

## 10. Crianças

O app não é direcionado a crianças. A conta TMDB segue os requisitos de idade definidos pelo próprio TMDB.

## 11. Mudanças nesta política

Quando o app passar a tratar dados novos, esta política será atualizada antes da versão que traz a mudança, com nova versão e data de vigência.
