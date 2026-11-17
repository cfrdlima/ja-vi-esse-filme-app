# Sessão 021 — Fase 2: Modelo dos dados do filme

**Data**: 2026-11-17 · **Branch**: `feature/021-modelo-dados-filme` · **Status**: aberta

## Objetivo
Definir e implementar o documento do filme do usuário em `users/{uid}/movies/{movieId}` (assistido, quero ver, favorito e datas), decidindo se ele guarda cópia do título e do `poster_path` com `cached_at` e renovação no limite de 6 meses dos termos do TMDB. Entrega o domínio, a camada `data` sobre o `cloud_firestore` (fina, atrás de um gateway) e as regras com os testes no emulador. Sem UI: marcar nos detalhes e o login opcional vêm na sessão seguinte.

## Checklist
### Preparação
- [x] Conferir nos termos do TMDB o limite de cache (6 meses) e o que pode ser guardado. **Feito:** §1.C proíbe cache por mais de 6 meses e não proíbe texto nem caminho
- [x] Conferir a versão do `cloud_firestore` no pub.dev. **Feito:** 7.1.0 (2026-10-23, `firebase_core` ^5.1.0); a 7.2.0 tem 1 dia
- [x] Decidir com o usuário cópia, datas e documento sem marcas. **Feito:** decisão 013
- [x] Nome da feature: `lib/features/shelf`

### Regras do Firestore (RED/GREEN/REFACTOR, `firestore/test`)
- [ ] Documento válido com o formato novo é aceito
- [ ] Chave fora da lista e chave obrigatória ausente negadas (formato novo)
- [ ] Tipos errados negados (bool, timestamp, string)
- [ ] Cada `<marca>At` ausente, igual ao salvo ou igual a `request.time`; nenhuma marca é negado
- [ ] `title` com tamanho máximo, `posterPath` opcional só no formato `/xxx.jpg`
- [ ] `cachedAt` só igual a `request.time`

### Domínio (RED/GREEN/REFACTOR)
- [ ] Entidade do filme do usuário (`movieId`, marcas, datas, cópia opcional), com `movieId` ≥ 1
- [ ] Regra de "cópia vencida" (mais de 6 meses desde o `cachedAt`)
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
- [013 — Documento do filme do usuário no Firestore](../decisoes/013-documento-do-filme-no-firestore.md): cópia de `title` e `posterPath` com `cachedAt` (6 meses); marcas como timestamps `watchedAt`/`watchlistAt`/`favoriteAt`; sem marcas, o documento é apagado; feature `shelf`; `cloud_firestore` 7.1.0; gateway fino, sem `fake_cloud_firestore`.

## Commits
- `docs: abre a sessão 021`

## Notas
- Na abertura, com o usuário: o "Login opcional" e o "Logout" do plano dependem de coisas que ainda não existem (nenhuma ação pede conta, e o `cloud_firestore` não está no app). O modelo de dados vem antes; o login opcional entra com "Marcar", e o logout completo depois.
