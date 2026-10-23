# 007 — `fake_async` como dependência de desenvolvimento

**Data**: 2026-10-23 · **Status**: aceita

## Contexto
A busca (sessão 010) espera 400 ms depois da última tecla antes de pedir ao TMDB. O `SearchNotifier` usa um `Timer` para isso, e os testes de unidade dele precisam avançar o relógio sem esperar o tempo real, para não ficarem lentos nem instáveis.

O `flutter_test` usa o `fake_async` por dentro (o relógio do `testWidgets` é falso), mas não reexporta o `fakeAsync`. Importar um pacote transitivo sem declará-lo viola o lint `depend_on_referenced_packages`.

## Opções consideradas
1. **`fake_async` em `dev_dependencies`**: testes de unidade puros com `fakeAsync((async) => async.elapse(...))`. O pacote é mantido pelo time do Dart e já estava no `pubspec.lock` como transitivo do `flutter_test`, com a mesma versão (1.3.3) e o mesmo sha. Nada novo é baixado, e ele não entra no APK.
2. **Testar o notifier dentro de `testWidgets`**, avançando com `tester.pump(Duration)`: não precisa de dependência, mas é teste de unidade vestido de teste de widget e depende do binding sem precisar dele.

## Decisão
Opção 1, escolhida pelo usuário na sessão 010. A dependência é `fake_async: ^1.3.3`, só em `dev_dependencies`.

## Consequências
- Código com `Timer` ou `Future.delayed` (debounce, contagens) tem teste de unidade com `fakeAsync`, e o `testWidgets` fica para a UI.
- A versão segue a que o `flutter_test` do SDK resolve. Se um upgrade do Flutter exigir outra, o `pub get` acusa, e a restrição acompanha a do SDK.
