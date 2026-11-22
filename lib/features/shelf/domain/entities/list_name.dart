/// Por que um nome de lista foi recusado, para a UI dizer o motivo.
enum ListNameIssue { empty, tooLong, controlCharacter }

/// O nome digitado não serve para uma lista (decisão 019).
final class InvalidListNameException implements Exception {
  const InvalidListNameException(this.issue);

  final ListNameIssue issue;

  @override
  String toString() => 'InvalidListNameException: ${issue.name}';
}

/// O nome de uma lista personalizada, no formato que as regras do Firestore
/// aceitam (decisão 019).
final class ListName {
  /// Tira os espaços das pontas e recusa com [InvalidListNameException] o
  /// nome vazio, o maior que [maxLength] e o com caractere de controle.
  factory ListName(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      throw const InvalidListNameException(ListNameIssue.empty);
    }
    if (value.length > maxLength) {
      throw const InvalidListNameException(ListNameIssue.tooLong);
    }
    if (_controlCharacter.hasMatch(value)) {
      throw const InvalidListNameException(ListNameIssue.controlCharacter);
    }
    return ListName._(value);
  }

  const ListName._(this.value);

  /// Em unidades UTF-16, o `length` do Dart, que é como as regras contam o
  /// `size()`: um emoji fora do plano básico conta 2.
  static const maxLength = 50;

  // O mesmo `\p{Cc}` das regras: C0, DEL e C1.
  static final _controlCharacter = RegExp(r'[\u0000-\u001F\u007F-\u009F]');

  final String value;

  @override
  bool operator ==(Object other) => other is ListName && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
