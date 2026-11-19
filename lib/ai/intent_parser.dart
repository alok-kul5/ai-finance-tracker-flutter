/// Turns a question into a [SpendQuery]: by rules ([RuleIntentParser], always
/// available) or by the on-device model ([LlmIntentParser], which falls back
/// to the rules field by field when the model's JSON is missing or invalid).
library;

import 'dart:convert';

import '../domain/models.dart';
import '../parsing/merchant.dart';
import 'llm.dart';
import 'query.dart';

/// Everyday words for each category.
const kCategorySynonyms = <String, List<String>>{
  'Food & Dining': ['food', 'dining', 'eating out', 'restaurant', 'restaurants', 'takeaway', 'delivery', 'swiggy', 'zomato', 'coffee', 'lunch', 'dinner', 'breakfast'],
  'Groceries': ['grocery', 'groceries', 'supermarket', 'vegetables', 'kirana'],
  'Transport': ['transport', 'travel to work', 'commute', 'cab', 'cabs', 'taxi', 'auto', 'fuel', 'petrol', 'metro', 'uber', 'ola'],
  'Shopping': ['shopping', 'clothes', 'online shopping', 'gadgets'],
  'Bills & Utilities': ['bills', 'bill', 'utilities', 'utility', 'electricity', 'recharge', 'phone bill', 'internet'],
  'Rent': ['rent', 'house rent'],
  'Entertainment': ['entertainment', 'movies', 'movie', 'fun', 'games'],
  'Health': ['health', 'medical', 'medicine', 'medicines', 'doctor', 'pharmacy', 'hospital'],
  'Education': ['education', 'courses', 'course', 'books', 'fees', 'tuition'],
  'Travel': ['travel', 'trips', 'trip', 'flights', 'flight', 'hotels', 'hotel', 'vacation', 'holiday'],
  'Subscriptions': ['subscriptions', 'subscription', 'netflix', 'spotify', 'ott', 'streaming'],
  'Transfers': ['transfers', 'transfer', 'sent to friends', 'atm'],
  'Income': ['income'],
  'Other': [],
};

bool _has(String q, String word) =>
    RegExp('(?<![a-z])${RegExp.escape(word)}(?![a-z])').hasMatch(q);

class RuleIntentParser {
  const RuleIntentParser();

  SpendQuery parse(String question,
      {required DateTime now, Iterable<String> knownMerchants = const []}) {
    final q = question.toLowerCase().replaceAll(RegExp(r'[?!.,]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    final direction = RegExp(r'\b(earn|earned|income|received|receive|got paid|salary|credited|credit)\b').hasMatch(q)
        ? TxnDirection.credit
        : TxnDirection.debit;

    return SpendQuery(
      metric: _metric(q),
      range: parseRange(q, now),
      direction: direction,
      category: direction == TxnDirection.credit ? null : _category(q),
      merchant: _merchant(q, knownMerchants),
    );
  }

  Metric _metric(String q) {
    if (RegExp(r'\b(how many|number of|count|times)\b').hasMatch(q)) return Metric.count;
    if (RegExp(r'\b(average|avg|per day|typical|mean)\b').hasMatch(q)) return Metric.average;
    if (RegExp(r'\b(biggest|largest|most expensive|highest|max(imum)?|single)\b').hasMatch(q)) {
      return Metric.largest;
    }
    if (RegExp(r'\b(top merchants?|which (shops?|merchants?|stores?|places?)|where did i|where do i|spend the most at|most at)\b').hasMatch(q)) {
      return Metric.topMerchants;
    }
    if (RegExp(r'\b(breakdown|by category|categories|split|which category|what did i spend on)\b').hasMatch(q)) {
      return Metric.byCategory;
    }
    return Metric.total;
  }

  String? _category(String q) {
    for (final e in kCategorySynonyms.entries) {
      if (_has(q, e.key.toLowerCase())) return e.key;
    }
    // Longest synonym first, so "eating out" beats "out".
    final pairs = [
      for (final e in kCategorySynonyms.entries)
        for (final s in e.value) (s, e.key)
    ]..sort((a, b) => b.$1.length.compareTo(a.$1.length));
    for (final (word, cat) in pairs) {
      if (_has(q, word)) return cat;
    }
    return null;
  }

  String? _merchant(String q, Iterable<String> known) {
    final keys = {for (final m in known) merchantKey(m)}.where((k) => k.length >= 3).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final k in keys) {
      if (_has(q, k)) return k;
    }
    // "at X" / "on X" for a merchant we haven't seen: let the engine match it.
    final m = RegExp(r'\b(?:at|from|to) ([a-z][a-z0-9&]+)\b').firstMatch(q);
    if (m != null) {
      final word = m.group(1)!;
      const notMerchants = {'all', 'the', 'least', 'most', 'home', 'work', 'date', 'now'};
      if (!notMerchants.contains(word) && monthFromName(word) == null && !kCategorySynonyms.values.any((v) => v.contains(word))) {
        return merchantKey(word);
      }
    }
    return null;
  }

  /// Date phrases: today, yesterday, this/last week|month|year, last N days,
  /// a month name (with an optional year), "since March", all time.
  static DateRange parseRange(String q, DateTime now) {
    if (_has(q, 'today')) return resolvePeriod('today', now);
    if (_has(q, 'yesterday')) return resolvePeriod('yesterday', now);
    final lastN = RegExp(r'\b(?:last|past|previous) (\d{1,3}) (day|days|week|weeks|month|months)\b').firstMatch(q);
    if (lastN != null) {
      final n = int.parse(lastN.group(1)!);
      final unit = lastN.group(2)!;
      final days = unit.startsWith('week') ? n * 7 : unit.startsWith('month') ? n * 30 : n;
      return lastNDays(days, now);
    }
    if (RegExp(r'\b(this|current) week\b').hasMatch(q)) return resolvePeriod('this_week', now);
    if (RegExp(r'\b(last|previous|past) week\b').hasMatch(q)) return resolvePeriod('last_week', now);
    if (RegExp(r'\b(last|previous|past) month\b').hasMatch(q)) return resolvePeriod('last_month', now);
    if (RegExp(r'\b(this|current) year\b|\bytd\b|\bso far this year\b').hasMatch(q)) return resolvePeriod('this_year', now);
    if (RegExp(r'\b(last|previous|past) year\b').hasMatch(q)) return resolvePeriod('last_year', now);
    if (RegExp(r'\b(all time|ever|overall|in total|so far)\b').hasMatch(q) && !_has(q, 'month')) {
      return resolvePeriod('all_time', now);
    }
    final since = RegExp(r'\bsince ([a-z]+)(?: (\d{4}))?\b').firstMatch(q);
    if (since != null) {
      final m = monthFromName(since.group(1)!);
      if (m != null) {
        final r = monthRange(m, now, year: since.group(2) == null ? null : int.parse(since.group(2)!));
        return DateRange(r.start, resolvePeriod('today', now).end, 'since ${monthLabel(r.start)}');
      }
    }
    for (final w in RegExp(r'\b([a-z]{3,9})(?: (\d{4}))?\b').allMatches(q)) {
      final word = w.group(1)!;
      if (word == 'may' && !RegExp(r'\b(in|during|for) may\b').hasMatch(q)) continue; // "may I"
      final m = monthFromName(word);
      if (m != null) {
        return monthRange(m, now, year: w.group(2) == null ? null : int.parse(w.group(2)!));
      }
    }
    return resolvePeriod('this_month', now);
  }
}

String intentPrompt(String question, DateTime now) => '''
You convert questions about personal spending into JSON. Do not answer the question and do not calculate anything.
Today is ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.
Return one JSON object with these keys:
"metric": one of ${Metric.values.map((m) => m.name).join(', ')}
"direction": "debit" for spending, "credit" for income
"category": one of ${kCategories.join(', ')}, or null
"merchant": a shop or company name, or null
"period": one of ${kPeriods.join(', ')}, or "month" with "month" (1-12) and optional "year", or "custom" with "start" and "end" as YYYY-MM-DD
Question: "$question"
JSON:''';

/// The parse result with where it came from, for the UI's "how I read
/// your question" chip.
class ParsedIntent {
  const ParsedIntent(this.query, this.source);
  final SpendQuery query;
  final String source; // "llm" or "rules"
}

class LlmIntentParser {
  LlmIntentParser({required this.llm, this.rules = const RuleIntentParser()});

  final LlmClient llm;
  final RuleIntentParser rules;

  Future<ParsedIntent> parse(String question,
      {required DateTime now, Iterable<String> knownMerchants = const []}) async {
    final fallback = rules.parse(question, now: now, knownMerchants: knownMerchants);
    if (!await llm.isReady) return ParsedIntent(fallback, 'rules');
    try {
      final out = await llm.complete(intentPrompt(question, now));
      final json = extractJsonObject(out);
      if (json == null) return ParsedIntent(fallback, 'rules');
      return ParsedIntent(fromJson(json, fallback, now), 'llm');
    } catch (_) {
      return ParsedIntent(fallback, 'rules');
    }
  }

  /// Validates every field; anything unknown keeps the rule parser's value.
  static SpendQuery fromJson(Map<String, Object?> j, SpendQuery fallback, DateTime now) {
    Metric metric = fallback.metric;
    final m = j['metric'];
    if (m is String) {
      final norm = m.replaceAll(RegExp(r'[_\s-]'), '').toLowerCase();
      for (final v in Metric.values) {
        if (v.name.toLowerCase() == norm) metric = v;
      }
    }

    var direction = fallback.direction;
    final d = j['direction'];
    if (d == 'credit' || d == 'income') direction = TxnDirection.credit;
    if (d == 'debit' || d == 'spending') direction = TxnDirection.debit;

    String? category = fallback.category;
    if (j.containsKey('category')) {
      final c = j['category'];
      category = c == null ? null : (canonicalCategory(c.toString()) ?? fallback.category);
    }

    String? merchant = fallback.merchant;
    final mer = j['merchant'];
    if (mer is String && mer.trim().isNotEmpty && mer.toLowerCase() != 'null') {
      merchant = merchantKey(mer);
    }

    return SpendQuery(
      metric: metric,
      direction: direction,
      category: direction == TxnDirection.credit ? null : category,
      merchant: merchant,
      range: _range(j, fallback.range, now),
    );
  }

  static DateRange _range(Map<String, Object?> j, DateRange fallback, DateTime now) {
    final p = j['period'];
    if (p is! String) return fallback;
    if (kPeriods.contains(p)) return resolvePeriod(p, now);
    if (p == 'month') {
      final month = int.tryParse('${j['month']}');
      if (month == null || month < 1 || month > 12) return fallback;
      final year = int.tryParse('${j['year']}');
      return monthRange(month, now, year: year != null && year > 2000 && year <= now.year ? year : null);
    }
    if (p == 'custom') {
      final s = DateTime.tryParse('${j['start']}');
      final e = DateTime.tryParse('${j['end']}');
      if (s == null || e == null || e.isBefore(s)) return fallback;
      final start = DateTime(s.year, s.month, s.day);
      final end = DateTime(e.year, e.month, e.day).add(const Duration(days: 1));
      return DateRange(start, end, 'between ${s.day} ${monthLabel(start)} and ${e.day} ${monthLabel(e)}');
    }
    return fallback;
  }
}

/// The first balanced {...} in [text] decoded as JSON, or null. Small models
/// like to wrap JSON in prose or code fences.
Map<String, Object?>? extractJsonObject(String text) {
  final start = text.indexOf('{');
  if (start < 0) return null;
  var depth = 0;
  var inString = false;
  for (var i = start; i < text.length; i++) {
    final ch = text[i];
    if (ch == '"' && (i == 0 || text[i - 1] != r'\')) inString = !inString;
    if (inString) continue;
    if (ch == '{') depth++;
    if (ch == '}') {
      depth--;
      if (depth == 0) {
        try {
          final v = jsonDecode(text.substring(start, i + 1));
          return v is Map<String, Object?> ? v : null;
        } on FormatException {
          return null;
        }
      }
    }
  }
  return null;
}
