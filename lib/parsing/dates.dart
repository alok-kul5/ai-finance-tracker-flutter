/// Finds the first date in free text in the shapes Indian banks and shop
/// receipts use: 12-03-24, 12/03/2024, 12.03.24, 12-Mar-24, 12Mar24,
/// 12 Mar 2024, Mar 12, 2024, 2024-03-12. Day-first, as in India.
library;

const _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'sept': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

const _mon = r'(jan|feb|mar|apr|may|jun|jul|aug|sept|sep|oct|nov|dec)[a-z]*';

final _iso = RegExp(r'\b(20\d{2})[-/.](\d{1,2})[-/.](\d{1,2})\b');
final _numeric = RegExp(r'\b(\d{1,2})[-/.](\d{1,2})[-/.](\d{4}|\d{2})\b');
final _named = RegExp('\\b(\\d{1,2})[ -]?$_mon[ ,-]*(\\d{4}|\\d{2})?\\b',
    caseSensitive: false);
final _namedUs = RegExp('\\b$_mon (\\d{1,2}),? (\\d{4})\\b', caseSensitive: false);
final _time = RegExp(r'(?<![-/\d])\b(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(am|pm)?\b',
    caseSensitive: false);

int _year(String y) {
  final v = int.parse(y);
  return y.length == 2 ? 2000 + v : v;
}

DateTime? _valid(int y, int m, int d) {
  if (m < 1 || m > 12 || d < 1 || d > 31 || y < 2000 || y > 2100) return null;
  final dt = DateTime(y, m, d);
  return dt.month == m ? dt : null; // rejects 31-02
}

/// The first date found in [text], or null. [fallbackYear] fills in a year
/// when the text gives only day and month.
DateTime? findDate(String text, {int? fallbackYear}) {
  final candidates = <(int, DateTime)>[];
  for (final m in _iso.allMatches(text)) {
    final d = _valid(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    if (d != null) candidates.add((m.start, d));
  }
  for (final m in _numeric.allMatches(text)) {
    final d = _valid(_year(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
    if (d != null) candidates.add((m.start, d));
  }
  for (final m in _named.allMatches(text)) {
    final month = _months[m[2]!.toLowerCase().substring(0, 3)]!;
    final y = m[3] != null ? _year(m[3]!) : (fallbackYear ?? DateTime.now().year);
    final d = _valid(y, month, int.parse(m[1]!));
    if (d != null) candidates.add((m.start, d));
  }
  for (final m in _namedUs.allMatches(text)) {
    final month = _months[m[1]!.toLowerCase().substring(0, 3)]!;
    final d = _valid(int.parse(m[3]!), month, int.parse(m[2]!));
    if (d != null) candidates.add((m.start, d));
  }
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => a.$1.compareTo(b.$1));
  return candidates.first.$2;
}

/// The first clock time in [text] as (hour, minute), or null.
(int, int)? findTime(String text) {
  for (final m in _time.allMatches(text)) {
    var h = int.parse(m[1]!);
    final min = int.parse(m[2]!);
    final ampm = m[4]?.toLowerCase();
    if (ampm == 'pm' && h < 12) h += 12;
    if (ampm == 'am' && h == 12) h = 0;
    if (h < 24 && min < 60) return (h, min);
  }
  return null;
}
