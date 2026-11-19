/// Money is stored as integer paise (1 rupee = 100 paise) so totals never
/// suffer floating-point drift.
library;

int parseRupeesToPaise(String raw) {
  final cleaned = raw.replaceAll(',', '').trim();
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(cleaned);
  if (match == null) {
    throw FormatException('not an amount: $raw');
  }
  final rupees = int.parse(match.group(1)!);
  final frac = (match.group(2) ?? '0').padRight(2, '0');
  return rupees * 100 + int.parse(frac);
}

/// Indian digit grouping: 1,23,45,678.90
String formatPaise(int paise, {bool symbol = true, bool decimals = true}) {
  final negative = paise < 0;
  final abs = paise.abs();
  final rupees = abs ~/ 100;
  final rem = abs % 100;
  final digits = rupees.toString();
  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  final frac = decimals ? '.${rem.toString().padLeft(2, '0')}' : '';
  return '${negative ? '-' : ''}${symbol ? '₹' : ''}$grouped$frac';
}
