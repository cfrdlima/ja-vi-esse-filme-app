import 'package:flutter/foundation.dart';

import 'secret_redactor.dart';

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

// O debugPrint aparece no logcat também em release, até o crash reporter da
// Fase 4 assumir. A mensagem passa pelo redator porque algumas exceções levam
// dados da requisição (a ClientException do http inclui a URI); rede e storage
// já convertem as suas em falhas tipadas, e o redator é a segunda barreira.
void _logError(Object error, StackTrace? stack) {
  debugPrint(redactSecrets('Erro não tratado: $error'));
  if (stack != null) debugPrint(redactSecrets(stack.toString()));
}
