import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Recebe todo erro não tratado do app. É o ponto em que um serviço de crash
/// reporting entra na Fase 4.
typedef ErrorReporter = void Function(Object error, StackTrace? stack);

/// Captura erros do framework e erros assíncronos que escapariam da zona raiz.
void registerErrorHandlers({ErrorReporter report = _logError}) {
  FlutterError.onError = (details) {
    // Em release, o console padrão também imprime no logcat, sem passar pelo
    // report. O report fica como o único caminho do erro fora do debug.
    if (kDebugMode) FlutterError.presentError(details);
    report(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    report(error, stack);
    return true;
  };
}

// A mensagem de algumas exceções carrega dados da requisição (a ClientException
// do http inclui a URI). Por isso, rede e storage convertem as exceções em
// falhas tipadas, sem URL nem segredo, antes que elas escapem até aqui.
void _logError(Object error, StackTrace? stack) {
  developer.log('Erro não tratado', error: error, stackTrace: stack);
}
