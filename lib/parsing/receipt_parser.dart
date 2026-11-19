/// Pulls total, merchant and date out of OCR text from a shop receipt.
///
/// OCR output is noisy: lines come out of order, "TOTAL" and its amount can
/// land on separate lines, and subtotals, taxes and item counts look a lot
/// like totals. The parser scores every amount by the label next to it and
/// falls back to the largest amount on the slip.
library;

import '../domain/money.dart';
import 'dates.dart';

class ParsedReceipt {
  const ParsedReceipt({this.totalPaise, this.merchant, this.date});
  final int? totalPaise;
  final String? merchant;
  final DateTime? date;

  bool get isEmpty => totalPaise == null && merchant == null && date == null;

  @override
  String toString() => 'ParsedReceipt($totalPaise, $merchant, $date)';
}

class ReceiptParser {
  const ReceiptParser();

  static final _amount = RegExp(
      r'(?:rs\.?|inr|₹)?\s*(\d{1,3}(?:,\d{2,3})+(?:\.\d{1,2})?|\d+[.,]\d{2}|\d+)(?!\s*%)(?![\d/:-])',
      caseSensitive: false);

  // Label → score. Higher wins; ties go to the later line (totals sit low).
  static final _labels = <(RegExp, int)>[
    (RegExp(r'grand\s*total|g\.?\s*total', caseSensitive: false), 100),
    (RegExp(r'net\s*(amount|amt|payable|total)|amount\s*payable|total\s*payable|to\s*pay|bill\s*amount|total\s*amount|total\s*amt|amount\s*due|balance\s*due', caseSensitive: false), 90),
    (RegExp(r'\btotal\b|\btot\b', caseSensitive: false), 70),
    (RegExp(r'\b(paid|card|upi|cash)\b', caseSensitive: false), 30),
  ];
  static final _notTotal = RegExp(
      r'sub\s*-?\s*total|total\s*(items?|qty|quantity|savings?|discount|tax|gst)|items?\s*total|\b(c|s|i)?gst\b|\bvat\b|\btax\b|discount|saved|savings|change|round(ed)?\s*off|tender|mrp',
      caseSensitive: false);

  static final _skipForMerchant = RegExp(
      r'invoice|receipt|bill\s*no|tax|gst|gstin|cin|fssai|phone|ph\.?|tel|mob|date|time|cashier|table|order|token|welcome|thank|www\.|http|@|customer|^\W*$|\d{5,}',
      caseSensitive: false);

  ParsedReceipt parse(String ocrText, {DateTime? now}) {
    final lines = ocrText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const ParsedReceipt();
    return ParsedReceipt(
      totalPaise: _total(lines),
      merchant: _merchant(lines),
      date: findDate(ocrText, fallbackYear: (now ?? DateTime.now()).year),
    );
  }

  List<int> _amountsIn(String line) {
    final out = <int>[];
    for (final m in _amount.allMatches(line)) {
      var s = m.group(1)!;
      // "123,45" written with a decimal comma.
      if (RegExp(r'^\d+,\d{2}$').hasMatch(s)) s = s.replaceFirst(',', '.');
      // Whole numbers without a currency sign are usually quantities.
      final hasCurrency = RegExp(r'rs|inr|₹', caseSensitive: false).hasMatch(m.group(0)!);
      if (!s.contains('.') && !hasCurrency && !s.contains(',')) continue;
      try {
        final v = parseRupeesToPaise(s);
        if (v > 0 && v < 100000000) out.add(v);
      } on FormatException {
        // not an amount
      }
    }
    return out;
  }

  int? _total(List<String> lines) {
    int? best;
    var bestScore = -1;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_notTotal.hasMatch(line)) continue;
      int score = 0;
      for (final (re, s) in _labels) {
        if (re.hasMatch(line)) {
          score = s;
          break;
        }
      }
      if (score == 0) continue;
      var amounts = _amountsIn(line);
      // The label and its amount were split across lines.
      if (amounts.isEmpty && i + 1 < lines.length && !_notTotal.hasMatch(lines[i + 1])) {
        amounts = _amountsIn(lines[i + 1]);
      }
      if (amounts.isEmpty) continue;
      final v = amounts.last;
      if (score >= bestScore) {
        bestScore = score;
        best = v;
      }
    }
    if (best != null) return best;
    // No labelled total: the biggest amount on the slip.
    final all = [for (final l in lines) if (!_notTotal.hasMatch(l)) ..._amountsIn(l)];
    if (all.isEmpty) return null;
    all.sort();
    return all.last;
  }

  String? _merchant(List<String> lines) {
    for (final line in lines.take(6)) {
      if (_skipForMerchant.hasMatch(line)) continue;
      final letters = RegExp(r'[A-Za-z]').allMatches(line).length;
      if (letters < 3 || letters < line.length * 0.5) continue;
      final cleaned = line.replaceAll(RegExp(r'[^A-Za-z0-9&\x27 .\-]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (cleaned.isEmpty) continue;
      return cleaned
          .split(' ')
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
          .join(' ');
    }
    return null;
  }
}
