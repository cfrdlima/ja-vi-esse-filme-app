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

  // `allowBackup="false"` não impede a transferência entre aparelhos a partir
  // do Android 12, e o token do Auth e o cache do Firestore ficam nos dados do
  // app (decisão 010).
  group('regras de backup', () {
    const domains = ['root', 'file', 'database', 'sharedpref', 'external'];

    String readXml(String name) => File(
      'android/app/src/main/res/xml/$name',
    ).readAsStringSync().replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

    String section(String xml, String tag) =>
        RegExp('<$tag\\b[^>]*>(.*?)</$tag>', dotAll: true).firstMatch(xml)![1]!;

    Matcher excludesDomain(String domain) =>
        matches(RegExp('<exclude\\s+domain="$domain"\\s+path="\\."\\s*/>'));

    test('deve apontar as regras de extração de dados no manifest', () {
      expect(
        applicationTag,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
    });

    test('deve apontar as regras de backup completo no manifest', () {
      expect(
        applicationTag,
        contains('android:fullBackupContent="@xml/backup_rules"'),
      );
    });

    for (final tag in ['cloud-backup', 'device-transfer']) {
      for (final domain in domains) {
        test('deve excluir o domínio $domain do $tag', () {
          final xml = readXml('data_extraction_rules.xml');

          expect(section(xml, tag), excludesDomain(domain));
        });
      }
    }

    for (final domain in domains) {
      test('deve excluir o domínio $domain do backup completo', () {
        final xml = readXml('backup_rules.xml');

        expect(section(xml, 'full-backup-content'), excludesDomain(domain));
      });
    }
  });

  test('deve exibir o nome "Já Vi Esse Filme" no launcher', () {
    expect(applicationTag, contains('android:label="Já Vi Esse Filme"'));
  });
}
