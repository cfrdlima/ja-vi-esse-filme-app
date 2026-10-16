# Já Vi Esse Filme

App Android, em Flutter, para cinéfilos: busque filmes, veja sinopse, elenco e trailers, marque o que **já viu**, guarde favoritos e monte listas próprias. Os dados vêm da [API do TMDB](https://developer.themoviedb.org/).

> Em desenvolvimento. O roadmap está em [`dev/PLANO.md`](dev/PLANO.md).

É a reescrita, com TDD e Clean Architecture, do projeto web [`cfrdlima/Ja-vi-esse-filme`](https://github.com/cfrdlima/Ja-vi-esse-filme).

## Stack

Flutter 3.44 (Material 3, tema escuro), `http`, `go_router`, `provider`, `cached_network_image` e `flutter_secure_storage`. A arquitetura é Clean Architecture por feature (`lib/features/<feature>/{domain,data,presentation}`).

## Como rodar

1. Instale o Flutter 3.44 e o Android SDK.
2. Em [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api), copie o **API Read Access Token** (não a "API Key" v3). O app o envia no header `Authorization: Bearer` (decisão 001).
3. Copie `env/example.json` para `env/dev.json` e preencha `TMDB_READ_ACCESS_TOKEN`. O arquivo é ignorado pelo git; nunca o commite.
4. Rode:

```bash
flutter pub get
flutter run --dart-define-from-file=env/dev.json
```

## Desenvolvimento

```bash
flutter analyze   # deve ficar sem issues
flutter test      # todos os testes
dart format lib/ test/
```

Convenções, TDD e regras de segurança: [`CLAUDE.md`](CLAUDE.md). Design: [`design-system/ja-vi-esse-filme/MASTER.md`](design-system/ja-vi-esse-filme/MASTER.md) e [`docs/DESIGN.md`](docs/DESIGN.md). Decisões: [`dev/decisoes/`](dev/decisoes/).

## Atribuição

Este produto usa a API do TMDB, mas não é endossado nem certificado pelo TMDB.

As fontes Playfair Display e Inter são distribuídas sob a SIL Open Font License (veja `assets/fonts/`).
