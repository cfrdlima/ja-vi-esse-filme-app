import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `domain/` é Dart puro (CLAUDE.md): sem Flutter, rede, storage nem SDK do
/// Firebase ou do Google.
void main() {
  const forbidden = [
    'package:flutter/',
    'package:http/',
    'package:shared_preferences/',
    'package:flutter_secure_storage/',
    'package:firebase_',
    'package:cloud_firestore/',
    'package:google_sign_in',
  ];
  final importLine = RegExp(r'''^\s*(import|export)\s+['"]([^'"]+)['"]''');

  List<String> violations() {
    final found = <String>[];
    final files = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.contains('/domain/') && f.path.endsWith('.dart'));
    for (final file in files) {
      for (final line in file.readAsLinesSync()) {
        final uri = importLine.firstMatch(line)?.group(2);
        if (uri != null && forbidden.any(uri.startsWith)) {
          found.add('${file.path}: $uri');
        }
      }
    }
    return found;
  }

  test('nenhum domain importa Flutter, rede, storage ou Firebase', () {
    expect(violations(), isEmpty);
  });
}
