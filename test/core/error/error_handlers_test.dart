import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/error_handlers.dart';

void main() {
  late FlutterExceptionHandler? originalOnError;
  late FlutterExceptionHandler originalPresentError;
  late ErrorCallback? originalPlatformOnError;
  late List<Object> reported;

  setUp(() {
    originalOnError = FlutterError.onError;
    originalPresentError = FlutterError.presentError;
    originalPlatformOnError = PlatformDispatcher.instance.onError;
    FlutterError.presentError = (_) {};
    reported = [];
    registerErrorHandlers(report: (error, _) => reported.add(error));
  });

  tearDown(() {
    FlutterError.onError = originalOnError;
    FlutterError.presentError = originalPresentError;
    PlatformDispatcher.instance.onError = originalPlatformOnError;
  });

  test('deve reportar erro do framework Flutter', () {
    final error = StateError('falha no build');

    FlutterError.onError!(FlutterErrorDetails(exception: error));

    expect(reported, [error]);
  });

  test('deve reportar erro assíncrono não capturado', () {
    final error = StateError('falha assíncrona');

    PlatformDispatcher.instance.onError!(error, StackTrace.empty);

    expect(reported, [error]);
  });

  test('deve marcar o erro assíncrono como tratado', () {
    final handled = PlatformDispatcher.instance.onError!(
      StateError('falha assíncrona'),
      StackTrace.empty,
    );

    expect(handled, isTrue);
  });
}
