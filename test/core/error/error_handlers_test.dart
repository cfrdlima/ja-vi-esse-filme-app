import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/error_handlers.dart';

void main() {
  late FlutterExceptionHandler? originalOnError;
  late FlutterExceptionHandler originalPresentError;
  late ErrorCallback? originalPlatformOnError;
  late List<Object> reported;
  late List<StackTrace?> reportedStacks;
  late List<FlutterErrorDetails> presented;

  setUp(() {
    originalOnError = FlutterError.onError;
    originalPresentError = FlutterError.presentError;
    originalPlatformOnError = PlatformDispatcher.instance.onError;
    presented = [];
    FlutterError.presentError = presented.add;
    reported = [];
    reportedStacks = [];
    registerErrorHandlers(
      report: (error, stack) {
        reported.add(error);
        reportedStacks.add(stack);
      },
    );
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

  test('deve apresentar o erro do framework no console em debug', () {
    final details = FlutterErrorDetails(exception: StateError('falha'));

    FlutterError.onError!(details);

    expect(presented, [details]);
  });

  test('deve repassar a stack trace do erro do framework ao reporter', () {
    final stack = StackTrace.current;

    FlutterError.onError!(
      FlutterErrorDetails(exception: StateError('falha'), stack: stack),
    );

    expect(reportedStacks, [stack]);
  });

  test('deve repassar a stack trace do erro assíncrono ao reporter', () {
    final stack = StackTrace.current;

    PlatformDispatcher.instance.onError!(StateError('falha'), stack);

    expect(reportedStacks, [stack]);
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
