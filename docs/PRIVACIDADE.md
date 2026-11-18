# Política de Privacidade — Já Vi Esse Filme

**Versão:** 2.0 · **Vigência:** a partir de 18 de novembro de 2026

<!-- A REVISAR (publicação, sessão 026): a vigência é a data real da publicação no Pages, que só acontece depois do script de limpeza mensal pronto e da primeira execução (decisão 017). Trocar a data na publicação. -->

<!--
Fonte da verdade da política (decisões 006 e 016). Toda sessão que mudar o que
o app coleta, guarda ou envia atualiza este arquivo e a versão/vigência acima.
Marcadores "A REVISAR" apontam pontos que dependem de decisões futuras e não
podem ir para a versão publicada sem resolução. A cópia publicada sai sem
estes comentários.
A 2.0 (sessão 026) cobre a conta Google, as marcas no Firestore e a exclusão
da conta, e substitui a 1.0 para todas as versões do app.
-->

Esta política explica quais dados o app **Já Vi Esse Filme** trata, para quê, com quem eles são compartilhados e como você pode exercer seus direitos, conforme a Lei Geral de Proteção de Dados (Lei nº 13.709/2018, LGPD). Ao criar a conta, você passa a usar o serviço da Estante como ele está descrito aqui.

## 1. Quem é o responsável

O app é um projeto independente de **Claudinei de Lima**, pessoa física, que é o controlador dos dados tratados pelo app. O contato está na seção 10.

Por ser agente de tratamento de pequeno porte (Resolução CD/ANPD nº 2/2022), o controlador não indicou encarregado. O canal de comunicação da seção 10 cumpre essa função.

O app usa a API do **The Movie Database (TMDB)**, mas não é endossado, certificado nem aprovado pelo TMDB. O TMDB é um serviço de terceiros com política de privacidade própria (seção 6).

## 2. Resumo

- O app **não tem servidor próprio**. O seu aparelho busca os dados de filmes direto no TMDB.
- A **conta é opcional** e só existe se você entrar com o Google. Sem conta, você busca e abre filmes normalmente, e o app não guarda dados seus fora do aparelho.
- Com a conta, os dados dela e os filmes que você marca ficam guardados no **Firebase**, um serviço do Google; os filmes marcados ficam em servidores em São Paulo (seção 3.2).
- O app **não usa** analytics, anúncios, localização, câmera, microfone nem contatos.
- O app **não vende** dados. Ele só os compartilha com o TMDB, que fornece o conteúdo, e com o Google, que opera o login, o armazenamento da conta e o e-mail de contato (seção 6).
- Você pode **excluir a conta** a qualquer momento, pelo app ou por e-mail (seção 8).

<!-- A REVISAR (Fase 4, decisão 001): se entrar um proxy próprio entre o app e o TMDB, ele passa a receber IP e buscas. Rever as seções 2, 3, 6 e 9. -->

<!-- A REVISAR (Fase 4, App Check, decisão 010): com o App Check, o app passa a falar com o Google (Play Integrity e firebaseappcheck.googleapis.com) ao abrir, mesmo sem conta. Rever as seções 2, 3, 6 e 9 e publicar uma 2.1 antes de qualquer APK com App Check sair do ambiente de desenvolvimento. -->

## 3. Quais dados são tratados

### 3.1 Busca e navegação

Para buscar e abrir filmes, o aparelho se conecta diretamente aos servidores do TMDB (`api.themoviedb.org` e `image.tmdb.org`). Nessas conexões, o TMDB recebe:

- o **endereço IP** e dados técnicos da conexão;
- os **termos de busca** que você digita e os filmes que você abre;
- os **pôsteres e fotos** que aparecem na tela e ainda não estão guardados no aparelho, inclusive os dos filmes da sua Estante;
- se você tem conta, os filmes marcados com a cópia vencida: quando você abre a Estante, o app pede ao TMDB os dados desses filmes, mesmo sem você abri-los (seção 3.2).

As requisições se identificam com uma credencial do próprio app, e não com uma credencial sua. O app não manda ao TMDB nenhum dado da sua conta e não guarda o seu histórico de busca.

Para a navegação ser mais rápida e gastar menos dados, o app guarda temporariamente no aparelho os **pôsteres e as fotos do elenco que aparecem na tela** e um índice com o endereço de cada imagem. Esse cache fica só no aparelho e não vai para ninguém. A limpeza acontece enquanto o app está em uso: as imagens sem uso há mais de 30 dias saem na próxima vez que você abre o app, e o cache fica em torno de 200 imagens, podendo passar disso por até um dia. O Android também pode apagá-lo quando precisar de espaço. Para apagar o cache na hora, veja a seção 8.

<!-- Os números do cache (30 dias, cerca de 200 imagens) são o padrão do flutter_cache_manager 3.4.5, dependência transitiva do cached_network_image. Conferir a cada atualização do pacote (checklist de release). -->

### 3.2 Conta e filmes marcados (opcional)

Para entrar, você toca em "Entrar com o Google" no Perfil, ou ao marcar um filme sem conta, e escolhe uma conta no seletor do Google. O app não recebe a sua senha. A conta no app nasce no **Firebase Authentication** na primeira vez que você escolhe a conta no seletor, e guarda:

- o **nome**, o **e-mail**, se o e-mail foi verificado, e o **endereço da foto** da sua conta Google;
- o **identificador da sua conta Google** e um **identificador** da conta no app, criado pelo Firebase;
- as **datas de criação** da conta e do **último acesso**.

O Google também registra os **endereços IP** dos acessos ao login (seção 7).

A foto é baixada direto dos servidores do Google (`googleusercontent.com`), que recebem o IP e os dados técnicos do aparelho. Ela fica só na memória do app enquanto ele está aberto.

Com a conta, cada filme que você marca como **assistido**, **quero assistir** ou **favorito** vira um registro no **Cloud Firestore**, na região de São Paulo (`southamerica-east1`), com:

- o identificador do filme no TMDB;
- as **datas** em que cada marca entrou;
- uma **cópia do título e do caminho do pôster** do filme, vinda do TMDB, com a data da cópia. O app nunca guarda a imagem do pôster no Firestore.

Quando você desmarca a última marca de um filme, o registro dele é apagado. A cópia do título e do pôster é escrita quando você marca o filme. Depois de 6 meses ela fica vencida e não aparece como atual: quando o filme aparece na Estante com a cópia vencida (só nas páginas carregadas, até 200 filmes por aba), o app a renova pelo TMDB (seção 3.1). Uma limpeza feita uma vez por mês cuida das cópias vencidas que a Estante não renovou (seção 7).

No aparelho, o app guarda uma **cópia local** das marcas, dos títulos e dos caminhos dos pôsteres, e as marcas feitas sem internet ficam guardadas até chegarem ao servidor. A sessão da conta (o token do login, com o nome, o e-mail e o endereço da foto) fica nos arquivos privados do app, protegidos pelo sistema do Android. Ao sair da conta, o app remove essa cópia local (seção 7).

O SDK do Firebase Authentication escreve o identificador da conta no log do sistema do aparelho. O app não envia esse log a ninguém.

<!-- A REVISAR (Fase 3): listas personalizadas, nota pessoal e data em que assistiu entram nesta seção e na tabela da seção 4 (decisão 010). -->

### 3.3 Erros e falhas

Quando o app encontra um erro inesperado, ele registra a mensagem só no log do sistema do aparelho, mascarando credenciais e o e-mail. O app não envia esses registros a ninguém. O Android e o Google Play podem coletar relatórios de falha, conforme as configurações de diagnóstico do seu aparelho.

<!-- A REVISAR (Fase 4): se entrar crash reporting (Crashlytics ou Sentry), descrever o serviço, os dados do aparelho enviados, o país de processamento e a base legal, e incluí-lo nas seções 4 e 6. -->

### 3.4 Pedidos por e-mail

Quando você escreve para o e-mail da seção 10 (por exemplo, para pedir a exclusão da conta ou o acesso aos seus dados), recebemos o seu endereço de e-mail e o que você escrever. O e-mail de contato é uma conta do Gmail, do Google. Para atender um pedido sobre a conta, o responsável pelo app vê no console do Firebase o e-mail, o identificador da conta e os filmes marcados.

## 4. Para que os dados são usados e com qual base legal

| Dado | Finalidade | Base legal (LGPD, art. 7º) |
|---|---|---|
| IP, termos de busca, filmes abertos e imagens que aparecem na tela, recebidos pelo TMDB | Buscar e exibir as informações de filmes que você pede | Execução de contrato ou de procedimentos ligados a ele, a seu pedido (inciso V): o app só envia ao TMDB o necessário para entregar o conteúdo que você pede |
| IP e filmes marcados com a cópia vencida, recebidos pelo TMDB ao abrir a Estante | Manter atualizados o título e o pôster dos filmes da sua Estante | Execução de contrato (inciso V): é parte do serviço da Estante que você usa com a conta |
| Nome, e-mail, endereço da foto, identificadores e datas da conta | Entrar com o Google, mostrar a conta no Perfil e ligar as marcas a ela | Execução de contrato (inciso V) |
| Filmes marcados, datas das marcas e cópias do título e do pôster | Guardar e mostrar a sua Estante em qualquer aparelho em que você entrar | Execução de contrato (inciso V) |
| Cópia local das marcas e sessão da conta no aparelho | Mostrar a Estante rápido e guardar marcas feitas sem internet | Execução de contrato (inciso V) |
| Mensagens dos pedidos por e-mail | Atender o pedido e guardar o registro de que ele foi atendido | Atender um pedido sobre os seus dados: cumprimento de obrigação legal (inciso II). Guardar o registro: exercício regular de direitos (inciso VI) |
| Registros locais de erro | Diagnosticar falhas do app | Legítimo interesse (inciso IX) |
| Cache local de pôsteres, fotos do elenco e índice com o endereço das imagens | Deixar a navegação mais rápida e gastar menos dados | Legítimo interesse (inciso IX); fica só no aparelho |

Este app não usa seus dados para publicidade, perfil de consumo nem treinamento de modelos de IA.

## 5. Links externos

Ao abrir um trailer (YouTube) ou esta política (GitHub Pages), você sai do app. A partir daí vale a política de privacidade de quem mantém o serviço. O app só abre links de endereços conferidos.

As páginas desta política e de suporte ficam no GitHub Pages e carregam um script do cdnjs, da Cloudflare. O GitHub e a Cloudflare recebem o IP e os dados técnicos de quem abre as páginas.

## 6. Compartilhamento e transferência internacional

Dois terceiros recebem dados pelo app:

- **TMDB**, que fornece o conteúdo. O seu aparelho envia a ele os dados da seção 3.1, que ele trata conforme a [política de privacidade do TMDB](https://www.themoviedb.org/privacy-policy).
- **Google**, como operador. Se você entrar com a conta, o Firebase Authentication e o Cloud Firestore guardam os dados da seção 3.2 em nome do app, conforme os termos de tratamento de dados do Firebase e a [política de privacidade do Google](https://policies.google.com/privacy). As mensagens que você manda ao e-mail de contato ficam no Gmail. A sua conta Google em si continua sendo tratada pelo Google, conforme a política dele.

<!-- A REVISAR (publicação, sessão 026): conferir no console (Configurações do projeto › Privacidade) que os termos de tratamento de dados do Firebase foram aceitos; sem eles, a frase do Google como operador não se sustenta. -->

Os filmes marcados ficam no Cloud Firestore em São Paulo. O Firebase Authentication, o Gmail e o TMDB processam dados em servidores de vários países, inclusive nos Estados Unidos, então os dados da conta, as mensagens de contato e os dados enviados ao TMDB são transferidos para fora do Brasil. A transferência é necessária para entregar o serviço que você pede e atender os seus pedidos (LGPD, art. 33, IX, combinado com o art. 7º, incisos II e V).

## 7. Por quanto tempo os dados ficam guardados

- **Cache de imagens:** as imagens sem uso há mais de 30 dias saem na próxima vez que o app é aberto, e o cache fica em torno de 200 imagens (seção 3.1).
- **Conta e filmes marcados:** enquanto a conta existir. Cada filme fica até você desmarcar a última marca dele. A cópia do título e do pôster vence com 6 meses, e a limpeza mensal garante que nenhuma cópia vencida fique guardada por mais de cerca de 7 meses desde que foi escrita.
- **No aparelho, com a conta:** a cópia local e a sessão ficam até você sair da conta. Ao sair, o app remove a cópia local do Firestore. Isso não é um apagamento seguro: os arquivos não são sobrescritos. As marcas feitas sem internet que ainda não chegaram ao servidor são apagadas ao sair, e o app avisa antes. Se a limpeza falhar, a cópia fica até a próxima vez que você abrir o app sem conta, quando ele tenta de novo, ou até você usar "Limpar armazenamento" nas configurações do Android.
- **Depois da exclusão da conta:** o Google remove os dados dos sistemas ativos e dos backups em até cerca de **180 dias**, e guarda os IPs dos acessos ao login por algumas semanas.
- **Outros aparelhos:** se a conta estiver aberta em outro aparelho, ele guarda a cópia local das marcas até você sair da conta nele, ou até você abrir o app de novo depois que a conta deixou de existir. Saia da conta nos outros aparelhos antes de excluir. Uma marca feita em outro aparelho logo depois da exclusão pode ficar guardada sem conta ligada a ela. A limpeza mensal apaga esses dados, e você também pode pedir por e-mail (veja a página [Excluir a conta](https://cfrdlima.github.io/ja-vi-esse-filme-suporte/excluir-conta/)).
- **Pedidos por e-mail:** as mensagens de cada pedido ficam por **6 meses** depois do atendimento, como registro, e depois são apagadas.
- **No TMDB:** pelo prazo definido na política de privacidade do TMDB.
- O app **não faz backup** dos seus dados na nuvem do Android nem os transfere para outro aparelho. Ao entrar em outro aparelho, as marcas voltam pela conta.

<!-- A REVISAR (publicação, S7 da sessão 025): conferir no console se o Firestore tem backup agendado, PITR ou export; se tiver, o prazo entra nesta seção e na página de exclusão. -->

## 8. Seus direitos

Pela LGPD (art. 18), você pode pedir:
- confirmação de que há tratamento;
- acesso aos dados;
- correção de dados incompletos, inexatos ou desatualizados;
- anonimização, bloqueio ou eliminação de dados desnecessários ou excessivos;
- portabilidade;
- eliminação dos dados tratados;
- informação sobre com quem os dados são compartilhados.

Você também pode se opor a um tratamento baseado em legítimo interesse.

- **Excluir a conta:** no app, vá em **Perfil › Excluir conta**, confirme e escolha a sua conta Google de novo. O app apaga os filmes marcados, as cópias do TMDB e a conta no Firebase, tenta revogar o acesso do app à sua conta Google e remove a cópia local do aparelho. Se a revogação não acontecer, remova o acesso em <https://myaccount.google.com/permissions>. Se a conexão cair no meio, a conta pode continuar existindo com parte dos filmes, ou sem nenhum, até você tentar de novo. Sem o app, peça por e-mail. O passo a passo, o que é apagado e o que fica por um tempo estão na página [Excluir a conta](https://cfrdlima.github.io/ja-vi-esse-filme-suporte/excluir-conta/).
- **Sair da conta:** em **Perfil › Sair**. As marcas continuam na conta e voltam quando você entrar de novo.
- **Corrigir os dados da conta:** o nome, o e-mail e a foto vêm da sua conta Google. Corrija-os na própria conta Google. Se o app continuar mostrando o dado antigo, peça a correção por e-mail.
- **Portabilidade e acesso:** peça por e-mail, e mandamos os seus filmes marcados, com as datas, num arquivo.
- **Dados no aparelho:** para apagar todos os dados locais, use "Limpar armazenamento" nas configurações do Android ou desinstale o app. "Limpar cache" apaga as imagens guardadas, e o índice delas só sai com "Limpar armazenamento".
- **Outros pedidos sobre este app:** use o e-mail da seção 10. A resposta sai em até 15 dias.

## 9. Segurança

- Todas as conexões usam HTTPS, e o app recusa tráfego sem criptografia.
- O login é feito pelo Google, e o app não recebe nem guarda a sua senha.
- As regras do Firestore só deixam a própria conta ler e escrever os seus filmes marcados.
- O app não pede nenhuma permissão durante o uso. Ao instalar, o Android registra as permissões que o app e as bibliotecas do Google declaram: acesso à internet e ao estado da rede; biometria e impressão digital, de uma biblioteca do Android para credenciais usada pelo login (o app não usa a sua biometria); e leitura de configurações do Google Play Services, de uma biblioteca de proteção contra abuso do Firebase Authentication.

## 10. Contato

- **Pedidos sobre seus dados** (acesso, correção, eliminação, exclusão da conta e outros da seção 8): e-mail **xbtechnologies.app@gmail.com**. Esse é o canal privado. Use-o para tudo o que envolva dado pessoal. Para pedidos sobre a conta, escreva do endereço da conta Google que você usa no app: antes de agir, mandamos a esse endereço um pedido de confirmação.
- **Dúvidas gerais, sugestões e problemas:** [Issues do repositório de suporte do app no GitHub](https://github.com/cfrdlima/ja-vi-esse-filme-suporte/issues). As Issues são públicas, então **não coloque dados pessoais nelas**.

Se não estiver satisfeito com a resposta, você pode reclamar à Autoridade Nacional de Proteção de Dados (ANPD).

## 11. Crianças e adolescentes

O app é destinado a pessoas a partir de **13 anos** e não é direcionado a crianças. Menores de 13 anos não devem usar o app nem criar a conta, mesmo com uma conta Google supervisionada pelos pais. Para entrar com a conta, vale também a idade mínima que o Google exige para ter uma conta Google no seu país. Se você souber que o app ou o canal de contato recebeu dados de uma criança, avise pelo e-mail da seção 10, e eles serão apagados.

## 12. Mudanças nesta política

Quando o app passar a tratar dados novos, esta política é atualizada antes da versão do app que traz a mudança, com nova versão e data de vigência. A versão em vigor fica em <https://cfrdlima.github.io/ja-vi-esse-filme-suporte/>.

A versão 2.0 substitui a 1.0, de 24 de outubro de 2026, e acrescenta a conta Google, os filmes marcados e a exclusão da conta.
