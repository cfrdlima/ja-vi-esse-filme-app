# Política de Privacidade — Já Vi Esse Filme

**Versão:** 1.0 · **Vigência:** a partir de 24 de outubro de 2026

<!--
Fonte da verdade da política (decisão 006). Toda sessão que mudar o que o app
coleta, guarda ou envia atualiza este arquivo e a versão/vigência acima.
Marcadores "A REVISAR" apontam pontos que dependem de decisões futuras e não
podem ir para a versão publicada sem resolução. A cópia publicada sai sem
estes comentários.
O texto do login entra na versão 2.0, publicada junto com a versão do app que
tiver login (decisão 010).
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

<!-- A REVISAR (Fase 4, decisão 001): se entrar um proxy próprio entre o app e o TMDB, ele passa a receber IP e buscas. Rever as seções 2, 3, 6 e 9. -->

## 3. Quais dados são tratados

### 3.1 Busca e navegação

Para buscar e abrir filmes, o aparelho se conecta diretamente aos servidores do TMDB (`api.themoviedb.org` e `image.tmdb.org`). Nessas conexões, o TMDB recebe:

- o **endereço IP** e dados técnicos da conexão;
- os **termos de busca** que você digita e os filmes que você abre.

As requisições se identificam com uma credencial do próprio app, e não com uma credencial sua. O app não guarda o seu histórico de busca.

Para a navegação ser mais rápida e gastar menos dados, o app guarda temporariamente no aparelho os **pôsteres que aparecem na tela** e um índice com o endereço de cada imagem. Esse cache fica só no aparelho e não vai para ninguém. A limpeza acontece enquanto o app está em uso: as imagens sem uso há mais de 30 dias saem na próxima vez que você abre o app, e o cache fica em torno de 200 imagens, podendo passar disso por até um dia. O Android também pode apagá-lo quando precisar de espaço. Para apagar o cache na hora, veja a seção 8.

<!-- Os números do cache (30 dias, cerca de 200 imagens) são o padrão do flutter_cache_manager 3.4.5, dependência transitiva do cached_network_image. Conferir a cada atualização do pacote (checklist de release). -->

<!-- A REVISAR (Fase 2, decisão 010): versão 2.0 com a conta própria. O rascunho do login pela conta TMDB saiu na sessão 015. Cobrir:
- seção 2: tirar o "não tem login" e dizer que o login é opcional e só com o Google;
- nova 3.2 "Conta e listas": nome, e-mail e foto da conta Google (Firebase Auth), e os filmes marcados (assistido, quero assistir, favorito, nota, data) no Cloud Firestore em São Paulo (southamerica-east1);
- seção 4: linha da conta e das listas, com base legal (provavelmente execução de contrato, inciso V);
- seção 6: Google/Firebase como operador e transferência internacional dos dados do Auth;
- seção 7: os dados ficam até a exclusão da conta, e o cache local do Firestore e o token do Auth ficam no aparelho até o logout. Com o data_extraction_rules.xml, dizer "não faz backup nem transfere seus dados para outro aparelho";
- seção 8: excluir a conta pelo app e pela página web;
- seção 9: regras do Firestore (só o dono acessa);
- seção 11: requisitos de idade da conta Google.
-->

<!-- A REVISAR (Fase 3): listas personalizadas no Firestore, na mesma seção da conta (decisão 010). -->

### 3.2 Erros e falhas

Quando o app encontra um erro inesperado, ele registra a mensagem só no log do sistema do aparelho, mascarando identificadores e credenciais. O app não envia esses registros a ninguém. O Android e o Google Play podem coletar relatórios de falha, conforme as configurações de diagnóstico do seu aparelho.

<!-- A REVISAR (Fase 4): se entrar crash reporting (Crashlytics ou Sentry), descrever o serviço, os dados do aparelho enviados, o país de processamento e a base legal, e incluí-lo nas seções 4 e 6. -->

## 4. Para que os dados são usados e com qual base legal

| Dado | Finalidade | Base legal (LGPD, art. 7º) |
|---|---|---|
| IP, termos de busca e filmes abertos, recebidos pelo TMDB | Buscar e exibir as informações de filmes que você pede | Execução de contrato ou de procedimentos ligados a ele, a seu pedido (inciso V): o app só envia ao TMDB o necessário para entregar o conteúdo que você pede |
| Registros locais de erro | Diagnosticar falhas do app | Legítimo interesse (inciso IX) |
| Cache local de pôsteres e índice com o endereço das imagens | Deixar a navegação mais rápida e gastar menos dados | Legítimo interesse (inciso IX); fica só no aparelho |

Este app não usa seus dados para publicidade, perfil de consumo nem treinamento de modelos de IA.

## 5. Links externos

Ao abrir um trailer (YouTube) ou esta política (GitHub Pages), você sai do app. A partir daí vale a política de privacidade de quem mantém o serviço. O app só abre links de endereços conferidos.

## 6. Compartilhamento e transferência internacional

O único terceiro que recebe dados pelo app é o **TMDB**, que fornece o conteúdo. O seu aparelho envia ao TMDB os dados da seção 3, que ele trata conforme a [política de privacidade do TMDB](https://www.themoviedb.org/privacy-policy).

O TMDB processa dados em servidores de vários países, inclusive nos Estados Unidos. Por isso, os dados enviados a ele são transferidos para fora do Brasil. A transferência é necessária para entregar o conteúdo que você pede (LGPD, art. 33, IX, combinado com o art. 7º, V).

## 7. Por quanto tempo os dados ficam guardados

- **Cache de imagens:** as imagens sem uso há mais de 30 dias saem na próxima vez que o app é aberto, e o cache fica em torno de 200 imagens (seção 3.1).
- **No TMDB:** pelo prazo definido na política de privacidade do TMDB.
- O app não faz backup dos seus dados na nuvem do Android.

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

## 9. Segurança

- Todas as conexões usam HTTPS, e o app recusa tráfego sem criptografia.
- A única permissão que o app pede é o acesso à internet.

## 10. Contato

- **Pedidos sobre seus dados** (acesso, correção, eliminação e outros da seção 8): e-mail **xbtechnologies.app@gmail.com**. Esse é o canal privado. Use-o para tudo o que envolva dado pessoal.
- **Dúvidas gerais, sugestões e problemas:** [Issues do repositório de suporte do app no GitHub](https://github.com/cfrdlima/ja-vi-esse-filme-suporte/issues). As Issues são públicas, então **não coloque dados pessoais nelas**.

Se não estiver satisfeito com a resposta, você pode reclamar à Autoridade Nacional de Proteção de Dados (ANPD).

## 11. Crianças e adolescentes

O app é destinado a pessoas a partir de **13 anos** e não é direcionado a crianças. Se você souber que o canal de contato recebeu dados de uma criança sem o consentimento dos pais ou responsáveis, avise pelo e-mail da seção 10, e eles serão apagados.

## 12. Mudanças nesta política

Quando o app passar a tratar dados novos, esta política é atualizada antes da versão do app que traz a mudança, com nova versão e data de vigência. A versão em vigor fica em <https://cfrdlima.github.io/ja-vi-esse-filme-suporte/>.
