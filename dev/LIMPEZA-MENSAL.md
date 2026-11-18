# Limpeza mensal do Firestore

Script da decisão 017, em `firestore/cleanup/`. Ele apaga os `users/{uid}` sem conta no Firebase Authentication e renova pelo TMDB as cópias com mais de 180 dias (o filme que sumiu do TMDB é apagado). A política 2.0 promete essa limpeza uma vez por mês.

## Como rodar (todo mês, pelo dono do projeto)

Uma vez na máquina: instalar o `gcloud` e entrar com a conta dona do projeto Firebase:

```bash
gcloud auth application-default login
```

Todo mês, de dentro de `firestore/` (Node 22):

```bash
npm ci --ignore-scripts
npm run cleanup -- --project <id-do-projeto> --dry-run   # só conta, não grava nada
TMDB_READ_TOKEN=<token de leitura v4> npm run cleanup -- --project <id-do-projeto>
```

- O token de leitura do TMDB vai só na variável de ambiente, nunca em arquivo do repositório nem em argumento. Para não ficar no histórico do shell, digite um espaço antes do comando (com `HISTCONTROL=ignorespace`) ou exporte a variável lendo de um arquivo fora do repositório.
- O script imprime só contagens. Se ele parar no limite do TMDB ou tiver falhas, saia com código 1 e rode de novo em alguns minutos.
- Não cole nada além das contagens neste arquivo nem em issue, commit ou log.

## Execuções

Data e contagens da saída. Um mês sem linha é um mês esquecido.

| Data | Sem conta apagados | Cópias vencidas | Renovadas | Filmes apagados | Falhas |
|---|---|---|---|---|---|
