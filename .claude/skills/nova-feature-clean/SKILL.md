---
name: nova-feature-clean
description: Cria uma feature nova em lib/features/<nome> seguindo a Clean Architecture deste projeto (domain/data/presentation) e TDD, com testes espelhados. Use ao iniciar qualquer feature nova ou migrar código para features/.
---
# Nova feature (Clean Architecture por feature)

Pré-requisito: há uma sessão aberta (`/sessao`). Se não houver, sugira abrir.

## Ordem (de dentro para fora, cada passo com teste antes)
1. **domain/entities** — classes imutáveis (`final`, `const` construtor, `==`/`hashCode` se comparadas em teste). Dart puro: proibido importar `flutter`, `http`, storage.
2. **domain/repositories** — contrato `abstract interface class XRepository`.
3. **domain/usecases** — só crie se houver regra além de repassar ao repositório (ex.: validar tamanho do nome da lista, ordenar, filtrar). Teste com um fake do repositório.
4. **data/** — models, datasources e implementação do repositório (use a skill `tmdb-endpoint` se a fonte for o TMDB).
5. **presentation/state** — `ChangeNotifier` com estado explícito (sealed class: `Loading`, `Empty`, `Failure`, `Success`), nunca booleans soltos ou `null` como sinal. Teste as transições com fake do caso de uso/repositório.
6. **presentation/screens e widgets** — use a skill `tela-4-estados`.
7. **Rota** — registre no `go_router` em `core/routing`.

## Regras
- Crie só as pastas que a feature usa agora.
- Testes espelham `lib/`: `lib/features/x/domain/y.dart` → `test/features/x/domain/y_test.dart`.
- Nomes de teste em PT-BR descrevendo comportamento.
- Ao final: `flutter analyze` + `flutter test` verdes e item marcado na sessão.
