# Política de Privacidade — Já Vi Esse Filme

**Versão:** 1.0 · **Vigência:** a partir de 24 de outubro de 2026

<!--
Fonte da verdade da política (decisão 006). Toda sessão que mudar o que o app
coleta, guarda ou envia atualiza este arquivo e a versão/vigência acima.
Marcadores "A REVISAR" apontam pontos que dependem de decisões futuras e não
podem ir para a versão publicada sem resolução. A cópia publicada sai sem
estes comentários.
Blocos "FASE 2 (fora da publicada)" guardam o texto do login, que só entra na
versão publicada junto com a versão do app que tiver login (sessão 014).
-->

Esta política explica quais dados o app **Já Vi Esse Filme** trata, para quê, com quem eles são compartilhados e como você pode exercer seus direitos, conforme a Lei Geral de Proteção de Dados (Lei nº 13.709/2018, LGPD).

## 1. Quem é o responsável

O app é um projeto independente de **Claudinei de Lima**, pessoa física, que é o controlador dos dados tratados pelo app. O contato está na seção 10.

Por ser agente de tratamento de pequeno porte (Resolução CD/ANPD nº 2/2022), o controlador não indicou encarregado. O canal de comunicação da seção 10 cumpre essa função.

O app usa a API do **The Movie Database (TMDB)**, mas não é endossado, certificado nem aprovado pelo TMDB. O TMDB é um serviço de terceiros com política de privacidade própria (seção 6).

## 2. Resumo

- O app **não tem servidor próprio**. O seu aparelho busca os dados de filmes direto no TMDB.
- O app **não tem login** nem conta própria.
- O app **não usa** analytics, anúncios, localização, câmera, microfone nem contatos.
- O app **não vende** dados e só os compartilha com o TMDB, que fornece o conteúdo.
- O app guarda no aparelho só um cache temporário dos pôsteres (seção 3.1).

<!-- A REVISAR (Fase 4, decisão 001): se entrar um proxy próprio entre o app e o TMDB, ele passa a receber IP, buscas e, nas rotas de conta, o identificador de sessão. Rever as seções 2, 3, 6 e 9. -->

## 3. Quais dados são tratados

### 3.1 Busca e navegação

Para buscar e abrir filmes, o aparelho se conecta diretamente aos servidores do TMDB (`api.themoviedb.org` e `image.tmdb.org`). Nessas conexões, o TMDB recebe:

- o **endereço IP** e dados técnicos da conexão;
- os **termos de busca** que você digita e os filmes que você abre.

As requisições se identificam com uma credencial do próprio app, e não com uma credencial sua. O app não guarda o seu histórico de busca.

Para a navegação ser mais rápida e gastar menos dados, o app guarda temporariamente no aparelho os **pôsteres que aparecem na tela** e um índice com o endereço de cada imagem. Esse cache fica só no aparelho e não vai para ninguém. A limpeza acontece enquanto o app está em uso: as imagens sem uso há mais de 30 dias saem na próxima vez que você abre o app, e o cache fica em torno de 200 imagens, podendo passar disso por até um dia. O Android também pode apagá-lo quando precisar de espaço. Para apagar o cache na hora, veja a seção 8.

<!-- Os números do cache (30 dias, cerca de 200 imagens) são o padrão do flutter_cache_manager 3.4.5, dependência transitiva do cached_network_image. Conferir a cada atualização do pacote (checklist de release). -->

<!-- FASE 2 (fora da publicada): seção "Uso com login na conta TMDB", que entra como 3.2 e empurra "Erros e falhas" para 3.3.

### 3.2 Uso com login na conta TMDB

O login é opcional e acontece **no site do TMDB, aberto no navegador**. O app nunca vê nem guarda sua senha. Depois que você aprova o acesso, o app recebe:

- um **identificador de sessão** (`session_id`), que permite ao app agir na sua conta. Ele fica cifrado no armazenamento privado do app, com a chave protegida pelo Keystore do Android, e o app é construído para não registrá-lo em logs;
- o **identificador e o nome de usuário** da sua conta TMDB, para mostrar o seu perfil.

A REVISAR (Fase 2): definir se o identificador e o nome de usuário ficam guardados no aparelho. Se ficarem, incluí-los na seção 7. Tirar da seção 2 o "não tem login".

**Favoritos, watchlist ("quero ver") e listas** ficam na sua conta do TMDB, e não no app. O app só os lê e os altera quando você pede.
-->

<!-- A REVISAR (Fase 3): seção "Já vi esse filme, nota pessoal e data". O armazenamento do "já vi" ainda não foi decidido (local no aparelho ou na conta TMDB). Descrever onde fica, por quanto tempo e como apagar, e acrescentar a linha na tabela da seção 4. -->

### 3.2 Erros e falhas

Quando o app encontra um erro inesperado, ele registra a mensagem só no log do sistema do aparelho, mascarando identificadores e credenciais. O app não envia esses registros a ninguém. O Android e o Google Play podem coletar relatórios de falha, conforme as configurações de diagnóstico do seu aparelho.

<!-- A REVISAR (Fase 4): se entrar crash reporting (Crashlytics ou Sentry), descrever o serviço, os dados do aparelho enviados, o país de processamento e a base legal, e incluí-lo nas seções 4 e 6. -->

## 4. Para que os dados são usados e com qual base legal

| Dado | Finalidade | Base legal (LGPD, art. 7º) |
|---|---|---|
| IP, termos de busca e filmes abertos, recebidos pelo TMDB | Buscar e exibir as informações de filmes que você pede | Execução de contrato ou de procedimentos ligados a ele, a seu pedido (inciso V): o app só envia ao TMDB o necessário para entregar o conteúdo que você pede |
| Registros locais de erro | Diagnosticar falhas do app | Legítimo interesse (inciso IX) |
| Cache local de pôsteres e índice com o endereço das imagens | Deixar a navegação mais rápida e gastar menos dados | Legítimo interesse (inciso IX); fica só no aparelho |

<!-- FASE 2 (fora da publicada): linha da tabela acima, depois da primeira.
| `session_id`, identificador e nome de usuário TMDB | Acessar a sua conta TMDB a seu pedido (favoritos, watchlist e listas) | Execução de contrato do qual você é parte, a seu pedido (inciso V): a sua conta no TMDB |
-->

Este app não usa seus dados para publicidade, perfil de consumo nem treinamento de modelos de IA.

## 5. Links externos

Ao abrir um trailer (YouTube) ou esta política (GitHub Pages), você sai do app. A partir daí vale a política de privacidade de quem mantém o serviço. O app só abre links de endereços conferidos.

## 6. Compartilhamento e transferência internacional

O único terceiro que recebe dados pelo app é o **TMDB**, que fornece o conteúdo. O seu aparelho envia ao TMDB os dados da seção 3, que ele trata conforme a [política de privacidade do TMDB](https://www.themoviedb.org/privacy-policy).

O TMDB processa dados em servidores de vários países, inclusive nos Estados Unidos. Por isso, os dados enviados a ele são transferidos para fora do Brasil. A transferência é necessária para entregar o conteúdo que você pede (LGPD, art. 33, IX, combinado com o art. 7º, V).

<!-- FASE 2 (fora da publicada): no primeiro parágrafo, "que fornece o conteúdo e a conta"; no segundo, "necessária para executar o contrato da sua conta TMDB e entregar o conteúdo que você pede". O art. 33, IX só cobre as bases dos incisos II, V e VI do art. 7º, e por isso a busca usa o inciso V, e não o legítimo interesse (sessão 014). -->

## 7. Por quanto tempo os dados ficam guardados

- **Cache de imagens:** as imagens sem uso há mais de 30 dias saem na próxima vez que o app é aberto, e o cache fica em torno de 200 imagens (seção 3.1).
- **No TMDB:** pelo prazo definido na política de privacidade do TMDB.
- O app não faz backup dos seus dados na nuvem do Android.

<!-- FASE 2 (fora da publicada): primeiro item da lista acima.
- **No aparelho:** o identificador de sessão fica guardado até você sair da conta no app. Ao sair, o app apaga o identificador e pede ao TMDB que encerre a sessão. Desinstalar o app apaga a cópia local, mas **não** encerra a sessão no TMDB. Por isso, saia da conta antes de desinstalar.
A REVISAR (Fase 2): com data_extraction_rules.xml, passar a dizer "não faz backup nem transfere seus dados para outro aparelho". Descrever o que acontece se o pedido de encerramento ao TMDB falhar (por exemplo, sem rede).
-->

## 8. Seus direitos

Pela LGPD (art. 18), você pode pedir:
- confirmação de que há tratamento;
- acesso aos dados;
- correção de dados incompletos, inexatos ou desatualizados;
- anonimização, bloqueio ou eliminação de dados desnecessários ou excessivos;
- portabilidade;
- informação sobre com quem os dados são compartilhados.

Você também pode se opor a um tratamento baseado em legítimo interesse.

- **Dados no aparelho:** para apagar todos os dados locais, use "Limpar armazenamento" nas configurações do Android ou desinstale o app. "Limpar cache" apaga as imagens guardadas, e o índice delas só sai com "Limpar armazenamento".
- **Pedidos sobre este app:** use o e-mail da seção 10. A resposta sai em até 15 dias (art. 19, II).

<!-- FASE 2 (fora da publicada): "Dados no aparelho" começa com "saia da conta no app.", e entra o item:
- **Dados na sua conta TMDB** (favoritos, watchlist, listas e perfil): o TMDB é o controlador. Exerça seus direitos direto com ele, nas configurações da conta no site ou pelo contato da política do TMDB.
-->

## 9. Segurança

- Todas as conexões usam HTTPS, e o app recusa tráfego sem criptografia.
- A única permissão que o app pede é o acesso à internet.

<!-- FASE 2 (fora da publicada): item da lista acima, depois do primeiro.
- O identificador de sessão fica cifrado no aparelho, como descrito na seção 3.2.
-->

## 10. Contato

- **Pedidos sobre seus dados** (acesso, correção, eliminação e outros da seção 8): e-mail **xbtechnologies.app@gmail.com**. Esse é o canal privado. Use-o para tudo o que envolva dado pessoal.
- **Dúvidas gerais, sugestões e problemas:** [Issues do repositório de suporte do app no GitHub](https://github.com/cfrdlima/ja-vi-esse-filme-suporte/issues). As Issues são públicas, então **não coloque dados pessoais nelas**.

Se não estiver satisfeito com a resposta, você pode reclamar à Autoridade Nacional de Proteção de Dados (ANPD).

## 11. Crianças e adolescentes

O app é destinado a pessoas a partir de **13 anos** e não é direcionado a crianças. Se você souber que o canal de contato recebeu dados de uma criança sem o consentimento dos pais ou responsáveis, avise pelo e-mail da seção 10, e eles serão apagados.

<!-- FASE 2 (fora da publicada): depois da primeira frase, "O login exige uma conta TMDB, que segue os requisitos de idade do próprio TMDB." -->

## 12. Mudanças nesta política

Quando o app passar a tratar dados novos, esta política é atualizada antes da versão do app que traz a mudança, com nova versão e data de vigência. A versão em vigor fica em <https://cfrdlima.github.io/ja-vi-esse-filme-suporte/>.
