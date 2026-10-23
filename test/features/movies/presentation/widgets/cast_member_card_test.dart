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

  Future<double> cardWidth(WidgetTester tester, double textScale) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
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
    expect(await cardWidth(tester, 1), AppSizes.castPhotoWidth);
  });

  // Com a largura fixa, o nome quebrava no meio da palavra na fonte grande.
  testWidgets('deve crescer junto com a fonte grande', (tester) async {
    expect(await cardWidth(tester, 1.5), AppSizes.castPhotoWidth * 1.5);
  });
}
