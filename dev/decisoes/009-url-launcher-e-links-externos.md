# 009 — `url_launcher` e links externos

**Data**: 2026-10-23 · **Status**: aceita

## Contexto
A Fase 1 pede que os trailers do TMDB abram no YouTube, fora do app. A tela "Sobre" vai abrir a política de privacidade no GitHub Pages (decisão 006). O `CLAUDE.md` exige que toda URL externa abra em modo externo e com host validado, e o Flutter não abre URL sozinho: é preciso um plugin que dispare o `Intent` de `VIEW` no Android.

As chaves dos vídeos (`videos.results[].key`) vêm do TMDB, que é conteúdo editado pela comunidade. Assim, uma `key` não é confiável.

## Opções consideradas
1. **`url_launcher`** (pacote oficial do time do Flutter, 6.3.3). O `url_launcher_android` 6.3.33 pede minSdk 24, o mesmo do app (decisão 003). O pacote abre a URL em outro app (`LaunchMode.externalApplication`) e devolve `false` ou lança `PlatformException` quando não consegue.
2. **Platform channel próprio**, com um `Intent` em Kotlin. Evita a dependência, mas reescreve o que o plugin oficial já resolve e cria código nativo para manter.
3. **WebView no app.** Descartada: o `CLAUDE.md` pede modo externo, e uma WebView traria cookies e sessão do YouTube para dentro do app.

## Decisão
Opção 1, com o `url_launcher: ^6.3.3`.

- O plugin fica atrás de uma interface em `core`, injetada no `main.dart`. Widgets e estado não importam o `url_launcher`, e os testes usam um fake.
- **A URL é montada pelo app.** O trailer guarda só a `key`, validada pelo formato do YouTube (11 caracteres de `[A-Za-z0-9_-]`). A URL sai de um molde fixo, `https://www.youtube.com/watch?v=<key>`.
- **Antes de abrir, toda URL passa pela validação de link externo:** esquema `https`, host comparado por igualdade com uma lista própria (sem `endsWith`), sem `userInfo` e sem porta. A lista começa com `www.youtube.com`, e o `cfrdlima.github.io` entra com a tela "Sobre". **Ela não é o `AppConfig.allowedHosts`**, que recebe o token Bearer (decisões 001 e 006).
- **Sem `canLaunchUrl`.** A chamada vai direto ao `launchUrl`, e `false` ou exceção viram falha tipada, que a tela mostra como aviso. Assim o manifest não precisa de `<queries>`: o README do plugin pede `<queries>` só para o `canLaunchUrl` e para o `supportsLaunchMode` funcionarem a partir do Android 11, e não declarar nada não dá ao app visibilidade de pacotes.

## Consequências
- Dependência nova no `pubspec.yaml`, com os plugins de cada plataforma vindo de forma transitiva.
- Não há aviso prévio de "nenhum app abre este link": o usuário só descobre depois de tocar, e aí vê a mensagem de erro.
- A política de privacidade já diz que abrir um trailer leva para fora do app (seção sobre links externos). As permissões do manifest não mudam.
- Um host novo na lista de links externos exige uma decisão ou uma nota de sessão que diga o porquê.
