import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/links/app_links.dart';
import 'package:ja_vi_esse_filme/core/links/external_link_policy.dart';

void main() {
  test('deve apontar a política de privacidade para o GitHub Pages', () {
    expect(
      AppLinks.privacyPolicy.toString(),
      'https://cfrdlima.github.io/ja-vi-esse-filme-suporte/',
    );
  });

  test('deve ter a política de privacidade aceita pela política de link', () {
    expect(ExternalLinkPolicy.app.allows(AppLinks.privacyPolicy), isTrue);
  });
}
