---
name: tmdb-endpoint
description: Receita para consumir um endpoint novo da API do TMDB neste app (fixture, model com parse defensivo, datasource, repositório, falhas tipadas) seguindo TDD. Use sempre que for integrar ou alterar uma chamada ao TMDB.
---
# Integrar endpoint do TMDB

Siga em ciclos Red → Green → Refactor, um passo por vez. Nunca acesse o TMDB real em testes.

1. **Confirme o contrato** — consulte a documentação oficial do endpoint (Context7 ou developer.themoviedb.org). Liste os campos que o app realmente usa; não modele o resto.
2. **Fixture** — salve um JSON realista em `test/fixtures/<recurso>.json`, incluindo um caso com campos `null`/vazios (`poster_path: null`, `release_date: ""`, `overview: ""`).
3. **Model (`data/models/`)** — teste primeiro: `fromJson` com a fixture completa e com a degradada. Regras:
   - campos de imagem → `String?`; datas vazias → `null`; números podem vir `int` ou `double` (`(json['vote_average'] as num?)?.toDouble()`).
   - método `toEntity()` que converte para a entidade de `domain/`. A entidade não conhece JSON.
4. **Datasource (`data/datasources/`)** — teste com `MockClient` de `package:http/testing.dart`:
   - URL montada com `Uri.https`/`replace(queryParameters:)`, nunca concatenando strings; `language=pt-BR`.
   - mapeie status → falha tipada de `core/network`: sem rede, 401 (chave/sessão inválida), 404, 429 (rate limit), 5xx.
   - nenhum log pode conter `api_key` ou `session_id`.
5. **Repositório (`data/repositories/`)** — implementa o contrato abstrato de `domain/`; trata paginação (`page`, `total_pages`) e devolve entidades.
6. **Composição** — registre a implementação concreta só em `main.dart`/`core`.
7. **Verificação** — `flutter analyze` limpo e `flutter test` verde; cole a saída.
