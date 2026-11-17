# Sessão 021 — Fase 2: Modelo dos dados do filme

**Data**: 2026-11-17 · **Branch**: `feature/021-modelo-dados-filme` · **Status**: aberta

## Objetivo
Definir e implementar o documento do filme do usuário em `users/{uid}/movies/{movieId}` (assistido, quero ver, favorito e datas), decidindo se ele guarda cópia do título e do `poster_path` com `cached_at` e renovação no limite de 6 meses dos termos do TMDB. Entrega o domínio, a camada `data` sobre o `cloud_firestore` (fina, atrás de um gateway) e as regras com os testes no emulador. Sem UI: marcar nos detalhes e o login opcional vêm na sessão seguinte.

## Checklist
### Preparação
- [ ] Conferir nos termos do TMDB o limite de cache (6 meses) e o que pode ser guardado (texto e caminho da imagem, nunca os bytes)
- [ ] Conferir a versão do `cloud_firestore` no pub.dev (compatível com `firebase_core` ^5.2.0, minSdk 24, publicada há mais de duas semanas)
- [ ] Decidir com o usuário: cópia do título e do `poster_path` (sim/não), quais datas (`updatedAt` do servidor, `watchedAt`), e o que acontece quando as três marcas ficam falsas (apaga o documento ou guarda). Registrar com `/decisao`
- [ ] Nome da feature (proposta: `lib/features/shelf`, a Estante)

### Regras do Firestore (RED/GREEN/REFACTOR, `firestore/test`)
- [ ] Documento válido com o formato novo é aceito
- [ ] Chave fora da lista e chave obrigatória ausente negadas (formato novo)
- [ ] Tipos errados negados (bool, timestamp, string)
- [ ] `updatedAt` só aceito igual a `request.time`
- [ ] Título e `poster_path` com tamanho máximo (se a cópia entrar), `poster_path` só no formato `/xxx.jpg`
- [ ] `cached_at` só igual a `request.time` (se a cópia entrar)

### Domínio (RED/GREEN/REFACTOR)
- [ ] Entidade do filme do usuário (`movieId`, marcas, datas, cópia opcional), com `movieId` ≥ 1
- [ ] Regra de "cópia vencida" (mais de 6 meses desde o `cachedAt`), se a cópia entrar
- [ ] Contrato do repositório: observar um filme, salvar as marcas, com falhas tipadas (sem rede, permissão negada, inesperada)

### Data (RED/GREEN/REFACTOR)
- [ ] Model: mapa do Firestore para a entidade com parse defensivo (campo ausente, tipo errado)
- [ ] Model: entidade para o mapa de escrita (`serverTimestamp` nas datas do servidor)
- [ ] Gateway fino sobre o `cloud_firestore` e o caminho `collection('users').doc(uid).collection('movies').doc('$id')`
- [ ] Repositório: tradução das `FirebaseException` sem `message` para as falhas do domínio
- [ ] Fake do repositório em `test/helpers/`

### Entrega
- [ ] `PLANO.md`: nova ordem (login opcional junto com "Marcar"; logout completo depois do Firestore entrar)
- [ ] Tríade: format, analyze limpo, `flutter test` verde, `npm test` das regras verde
- [ ] `/revisar` (`code-reviewer` e `security-auditor`: regras e storage)
- [ ] `/fechar-sessao`

## Decisões

## Commits
- `docs: abre a sessão 021`

## Notas
- Na abertura, com o usuário: o "Login opcional" e o "Logout" do plano dependem de coisas que ainda não existem (nenhuma ação pede conta, e o `cloud_firestore` não está no app). O modelo de dados vem antes; o login opcional entra com "Marcar", e o logout completo depois.
