import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/error/retry_wait.dart';

void main() {
  group('retryWaitOf', () {
    test('deve usar o retryAfter do 429', () {
      const failure = RateLimitFailure(retryAfter: Duration(seconds: 9));

      expect(retryWaitOf(failure), const Duration(seconds: 9));
    });

    test('deve ser zero no 429 sem retryAfter', () {
      expect(retryWaitOf(const RateLimitFailure()), Duration.zero);
    });

    test('deve ser zero para as outras falhas', () {
      expect(retryWaitOf(const NetworkFailure()), Duration.zero);
    });
  });
}
