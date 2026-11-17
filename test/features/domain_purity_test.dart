import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `domain/` é Dart puro (CLAUDE.md): só a biblioteca básica do Dart, outros
/// arquivos de `domain/` e as falhas de `core/error/failures.dart`.
///
/// O teste é transversal a todas as features, por isso não espelha nenhum
/// arquivo de `lib/`.
void main() {
  const allowedDartLibraries = {
    'dart:core',
    'dart:async',
    'dart:collection',
    'dart:math',
  };
  const packagePrefix = 'package:ja_vi_esse_filme/';

  final libDir = Directory('lib').absolute.uri;

  // A diretiva inteira, mesmo quebrada em várias linhas, até o `;`.
  final directive = RegExp(
    r'^\s*(?:import|export)\b(.*?);',
    multiLine: true,
    dotAll: true,
  );
  // Todas as URIs da diretiva, incluindo as de import condicional
  // (`if (dart.library.io) '...'`) e as raw strings.
  final uriLiteral = RegExp(r'''r?(['"])(.*?)\1''');

  List<File> domainFiles() => Directory('lib/features')
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (f) =>
            f.uri.pathSegments.contains('domain') && f.path.endsWith('.dart'),
      )
      .toList();

  Iterable<String> urisOf(File file) => directive
      .allMatches(file.readAsStringSync())
      .expand((d) => uriLiteral.allMatches(d.group(1)!))
      .map((m) => m.group(2)!);

  bool isInsideAllowedLib(Uri target) {
    if (!target.path.startsWith(libDir.path)) return false;
    final segments = Uri(
      path: target.path.substring(libDir.path.length),
    ).pathSegments;
    final isDomain =
        segments.length > 2 &&
        segments.first == 'features' &&
        segments.contains('domain');
    final isFailures = segments.join('/') == 'core/error/failures.dart';
    return isDomain || isFailures;
  }

  bool isAllowed(File file, String uri) {
    if (uri.startsWith('dart:')) return allowedDartLibraries.contains(uri);
    if (uri.startsWith(packagePrefix)) {
      return isInsideAllowedLib(
        libDir.resolve(uri.substring(packagePrefix.length)),
      );
    }
    if (Uri.parse(uri).hasScheme) return false;
    return isInsideAllowedLib(file.absolute.uri.resolve(uri));
  }

  test('deve encontrar arquivos de domain para verificar', () {
    expect(domainFiles(), isNotEmpty);
  });

  test('nenhum domain importa nada fora do Dart puro e do próprio domain', () {
    final violations = [
      for (final file in domainFiles())
        for (final uri in urisOf(file))
          if (!isAllowed(file, uri)) '${file.path}: $uri',
    ];

    expect(violations, isEmpty);
  });
}
