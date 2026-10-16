// Guarda contra regressão da configuração de segurança do Android, que não
// tem código Dart para testar. Lê o manifest como texto para não exigir uma
// dependência de parser XML.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String manifest;

  setUpAll(() {
    manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
  });

  test('deve pedir a permissão INTERNET no manifest principal', () {
    expect(
      manifest,
      contains('<uses-permission android:name="android.permission.INTERNET"/>'),
    );
  });

  test('deve desligar o backup automático do app', () {
    expect(manifest, contains('android:allowBackup="false"'));
  });

  test('deve proibir tráfego sem HTTPS', () {
    expect(manifest, contains('android:usesCleartextTraffic="false"'));
  });

  test('deve exibir o nome "Já Vi Esse Filme" no launcher', () {
    expect(manifest, contains('android:label="Já Vi Esse Filme"'));
  });
}
