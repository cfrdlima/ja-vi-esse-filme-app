import '../error/error_handlers.dart';

/// Inicialização assíncrona que precisa terminar antes do app subir.
typedef AppInitializer = Future<void> Function();

/// Roda [initialize] e depois [run]. Uma falha na inicialização vai para
/// [report] e o app sobe mesmo assim: Descobrir, Buscar e Detalhes não
/// dependem da conta, e um `await` que lança no `main` deixaria tela branca.
Future<void> bootstrapApp({
  required AppInitializer initialize,
  required void Function() run,
  required ErrorReporter report,
}) async {
  try {
    await initialize();
  } on Object catch (error, stack) {
    report(error, stack);
  }
  run();
}
