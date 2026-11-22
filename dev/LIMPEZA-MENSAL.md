# Limpeza mensal do Firestore

Script da decisão 017, em `firestore/cleanup/`. Ele apaga os `users/{uid}` sem conta no Firebase Authentication e renova pelo TMDB as cópias com mais de 180 dias. O filme que o TMDB diz que não existe mais (404 com o código 34) sai da Estante. A política 2.0 promete essa limpeza uma vez por mês.

## Uma vez na máquina

1. Instale o `gcloud` (Google Cloud CLI).
2. Use a conta Google dona do projeto Firebase, com verificação em duas etapas ligada.
3. **Nunca** crie chave de conta de serviço para isto.

## Todo mês

De dentro de `firestore/` (Node 22), num terminal novo:

```bash
# 1. Nada de emulador nem de chave de conta de serviço neste shell.
unset FIRESTORE_EMULATOR_HOST FIREBASE_AUTH_EMULATOR_HOST FIREBASE_EMULATOR_HUB GOOGLE_APPLICATION_CREDENTIALS

# 2. Só as dependências do script, sem as de teste e sem scripts de instalação.
npm ci --omit=dev --ignore-scripts

# 3. Credencial temporária da conta dona do projeto.
gcloud auth application-default login
gcloud auth application-default set-quota-project <id-do-projeto>

# 4. Simulação: só conta, não grava nada.
npm run cleanup -- --project <id-do-projeto> --dry-run

# 5. Token de leitura do TMDB sem aparecer na tela nem no histórico.
read -rs TMDB_READ_TOKEN && export TMDB_READ_TOKEN

# 6. Execução real. Se a simulação pediu, acrescente --confirm-orphans <n>
#    com o número que ela mostrou.
npm run cleanup -- --project <id-do-projeto>

# 7. Limpeza da credencial e do token.
unset TMDB_READ_TOKEN
gcloud auth application-default revoke
```

- **Etapas:** primeiro os `users/{uid}` sem conta, depois as chaves de lista sem a lista delas (o filme que fica sem marca e sem lista é apagado, decisão 019), por fim as cópias vencidas. A etapa das chaves lê todos os filmes que estão em alguma lista: cerca de uma leitura por filme assim, mais uma por lista.
- **Saída:** só contagens. Com falhas ou uma parada (limite do TMDB, token recusado, 404 seguidos, cota, teto de escritas), o script sai com código 1 e explica o que fazer. Um filme sem título no TMDB não muda o código de saída.
- **Travas:** o script recusa rodar com variável de emulador no ambiente ou com projeto `demo-`. Ele também se recusa a apagar quando o Auth não devolve nenhuma conta. Acima de 5 contas sem dados (ou 20% dos `users/{uid}`, o que for maior), ele só apaga com `--confirm-orphans` igual à contagem da simulação.
- **Credencial:** o `application-default login` grava um token de longa duração em `~/.config/gcloud/`. Por isso ele é feito a cada execução e revogado no fim.
- **Registro:** anote abaixo só a data e as contagens. Não cole nada além disso neste arquivo nem em issue, commit ou log.

## Execuções

Data e contagens da saída. Um mês sem linha é um mês esquecido.

| Data | Sem conta apagados | Chaves sem lista (filmes, apagados) | Cópias vencidas | Renovadas | Filmes apagados | Falhas | Sem título | Puladas | Parada |
|---|---|---|---|---|---|---|---|---|---|
