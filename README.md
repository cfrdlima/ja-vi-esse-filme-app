# Já Vi Esse Filme

[![CI](https://github.com/cfrdlima/ja-vi-esse-filme-app/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/cfrdlima/ja-vi-esse-filme-app/actions/workflows/ci.yml)

App Android, em Flutter, para cinéfilos: busque filmes, veja sinopse, elenco e trailers, marque o que **já viu**, guarde favoritos e monte listas próprias. Os dados vêm da [API do TMDB](https://developer.themoviedb.org/).

> Em desenvolvimento. O roadmap está em [`dev/PLANO.md`](dev/PLANO.md).

É a reescrita, com TDD e Clean Architecture, do projeto web [`cfrdlima/Ja-vi-esse-filme`](https://github.com/cfrdlima/Ja-vi-esse-filme).

## Stack

Flutter 3.44 (Material 3, tema escuro), `http`, `go_router`, `provider`, `cached_network_image` e `url_launcher`. A conta e as listas do usuário vão usar o Firebase (Auth com o Google e Firestore), conforme a decisão 010. A arquitetura é Clean Architecture por feature (`lib/features/<feature>/{domain,data,presentation}`).

## Como rodar

1. Instale o Flutter 3.44 e o Android SDK.
2. Em [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api), copie o **API Read Access Token** (não a "API Key" v3). O app o envia no header `Authorization: Bearer` (decisão 001).
3. Copie `env/example.json` para `env/dev.json` e preencha `TMDB_READ_ACCESS_TOKEN`. O arquivo é ignorado pelo git; nunca o commite.
4. Rode:

```bash
flutter pub get
flutter run --dart-define-from-file=env/dev.json \
  --dart-define=APP_VERSION=$(sed -n 's/^version: *\([^+]*\).*/\1/p' pubspec.yaml)
```

O `APP_VERSION` leva a versão do `pubspec.yaml` para a tela "Sobre". Sem ele, o app roda e a tela só não mostra a versão.

## Desenvolvimento

```bash
flutter analyze   # deve ficar sem issues
flutter test      # todos os testes
dart format lib/ test/
```

O [CI](.github/workflows/ci.yml) roda em push na `main` e em pull requests, com o Flutter 3.44.5. Ele confere o `dart format`, o `flutter analyze --fatal-infos` e o `flutter test` e roda o `gitleaks` em todo o histórico. Não usa nenhum secret: os testes rodam sem `env/*.json`.

Convenções, TDD e regras de segurança: [`CLAUDE.md`](CLAUDE.md). Design: [`design-system/ja-vi-esse-filme/MASTER.md`](design-system/ja-vi-esse-filme/MASTER.md) e [`docs/DESIGN.md`](docs/DESIGN.md). Decisões: [`dev/decisoes/`](dev/decisoes/).

## Atribuição

Este produto usa a API do TMDB, mas não é endossado nem certificado pelo TMDB.

As fontes Playfair Display e Inter são distribuídas sob a SIL Open Font License (veja `assets/fonts/`).
