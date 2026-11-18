/// O dia em que o usuário assistiu ao filme, como ele escolheu (decisão
/// 018): uma data do calendário, sem hora nem fuso, para não mudar de dia
/// conforme o fuso de quem lê.
final class WatchedOn {
  /// Recusa com [ArgumentError] o dia que não existe no calendário e o ano
  /// fora de [firstYear] a [lastYear].
  WatchedOn({required this.year, required this.month, required this.day}) {
    if (year < firstYear || year > lastYear) {
      throw ArgumentError.value(year, 'year', 'deve ser de 1888 a 9999');
    }
    final date = DateTime.utc(year, month, day);
    if (date.month != month || date.day != day) {
      throw ArgumentError('não existe no calendário: $year-$month-$day');
    }
  }

  /// O dia local de [moment], para sugerir o dia do `watchedAt`.
  factory WatchedOn.fromLocal(DateTime moment) {
    final local = moment.toLocal();
    return WatchedOn(year: local.year, month: local.month, day: local.day);
  }

  /// O ano da primeira filmagem que sobreviveu: antes disso, ninguém
  /// assistiu a um filme.
  static const firstYear = 1888;

  /// O formato das regras tem quatro dígitos no ano.
  static const lastYear = 9999;

  final int year;
  final int month;
  final int day;

  bool isAfter(WatchedOn other) => _ordinal > other._ordinal;

  int get _ordinal => (year * 100 + month) * 100 + day;

  @override
  bool operator ==(Object other) =>
      other is WatchedOn && other._ordinal == _ordinal;

  @override
  int get hashCode => _ordinal.hashCode;
}
