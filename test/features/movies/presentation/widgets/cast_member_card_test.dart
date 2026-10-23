import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/theme/app_sizes.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/cast_member.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/widgets/cast_member_card.dart';

import '../../../../helpers/test_app.dart';

void main() {
  const member = CastMember(
    id: 1,
    name: 'Fernando Meirelles',
    character: 'Himself',
  );

  Future<double> cardWidth(WidgetTester tester, TextScaler scaler) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: scaler),
        child: testApp(
          home: const Align(
            alignment: Alignment.topLeft,
            child: CastMemberCard(member: member),
          ),
        ),
      ),
    );
    return tester.getSize(find.byType(CastMemberCard)).width;
  }

  testWidgets('deve ter a largura do design com a fonte padrão', (
    tester,
  ) async {
    expect(
      await cardWidth(tester, TextScaler.noScaling),
      AppSizes.castPhotoWidth,
    );
  });

  // Com a largura fixa, o nome quebrava no meio da palavra na fonte grande.
  testWidgets('deve crescer junto com a fonte grande', (tester) async {
    expect(
      await cardWidth(tester, const TextScaler.linear(1.5)),
      AppSizes.castPhotoWidth * 1.5,
    );
  });

  // O Android 14 escala a fonte de forma não linear: o texto pequeno cresce
  // 1,5x, e um "tamanho" de 96 quase não cresce.
  testWidgets('deve crescer na escala do texto do nome na escala não linear', (
    tester,
  ) async {
    expect(
      await cardWidth(tester, const _NonLinearScaler()),
      AppSizes.castPhotoWidth * 1.5,
    );
  });
}

/// Escala 1,5x até 20, e nada acima disso, como a do Android em fonte grande
/// (de forma simplificada).
class _NonLinearScaler extends TextScaler {
  const _NonLinearScaler();

  @override
  double scale(double fontSize) => fontSize <= 20 ? fontSize * 1.5 : fontSize;

  @override
  double get textScaleFactor => 1.5;

  @override
  TextScaler clamp({double minScaleFactor = 0, double maxScaleFactor = 1}) =>
      this;
}
