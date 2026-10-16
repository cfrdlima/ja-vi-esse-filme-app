import 'dart:io';

/// Lê um JSON de `test/fixtures/`. Os testes nunca acessam o TMDB real.
String readFixture(String name) =>
    File('test/fixtures/$name').readAsStringSync();
