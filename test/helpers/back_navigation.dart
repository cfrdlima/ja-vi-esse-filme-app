import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Grava o último aviso ao Android sobre quem trata o voltar. Com predictive
/// back, se o app disser que não trata, o sistema fecha a activity sem chamar
/// o Flutter.
ValueGetter<bool?> recordFrameworkHandlesBack(WidgetTester tester) {
  bool? last;
  // Sem app em primeiro plano, o Flutter não avisa nada ao sistema.
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
        last = call.arguments as bool;
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return () => last;
}
