// Guarda contra regressão da configuração de segurança do Android, que não
// tem código Dart para testar. Lê o manifest como texto para não exigir uma
// dependência de parser XML.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String manifest;
  late String applicationTag;

  setUpAll(() {
    final raw = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    // Sem comentários, para que um atributo comentado não conte como presente.
    manifest = raw.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
    applicationTag = RegExp(r'<application\b[^>]*>').firstMatch(manifest)![0]!;
  });

  test('deve pedir a permissão INTERNET no manifest principal', () {
    expect(
      manifest,
      matches(
        RegExp(
          r'<uses-permission\s+android:name="android\.permission\.INTERNET"\s*/>',
        ),
      ),
    );
  });

  test('deve desligar o backup automático do app', () {
    expect(applicationTag, contains('android:allowBackup="false"'));
  });

  test('deve proibir tráfego sem HTTPS', () {
    expect(applicationTag, contains('android:usesCleartextTraffic="false"'));
  });

  test('deve exibir o nome "Já Vi Esse Filme" no launcher', () {
    expect(applicationTag, contains('android:label="Já Vi Esse Filme"'));
  });
}
