/// Category assignment, cheapest and surest first:
///   1. the user's own past choice for this merchant ("memory"),
///   2. keyword rules ("rule"),
///   3. the on-device LLM, only when 1 and 2 have nothing ("llm"),
///   4. "Other" ("default").
/// Whatever the LLM says is checked against [kCategories]; anything else is
/// thrown away.
library;

import '../domain/models.dart';
import '../parsing/merchant.dart';
import 'llm.dart';

class CategoryDecision {
  const CategoryDecision(this.category, this.source, this.confidence);
  final String category;
  final String source; // memory | rule | llm | default
  final double confidence;
  @override
  String toString() => 'CategoryDecision($category, $source, $confidence)';
}

/// Keyword → category. Checked against the normalised merchant key and the
/// raw text, longest keywords first so "amazon prime" beats "amazon".
const kCategoryRules = <String, String>{
  // Food & Dining
  'swiggy': 'Food & Dining', 'zomato': 'Food & Dining', 'dominos': 'Food & Dining',
  'domino': 'Food & Dining', 'pizza': 'Food & Dining', 'mcdonald': 'Food & Dining',
  'kfc': 'Food & Dining', 'burger': 'Food & Dining', 'starbucks': 'Food & Dining',
  'cafe': 'Food & Dining', 'coffee': 'Food & Dining', 'chai': 'Food & Dining',
  'restaurant': 'Food & Dining', 'biryani': 'Food & Dining', 'haldiram': 'Food & Dining',
  'sweets': 'Food & Dining', 'bakery': 'Food & Dining', 'eatclub': 'Food & Dining',
  // Groceries
  'bigbasket': 'Groceries', 'blinkit': 'Groceries', 'zepto': 'Groceries',
  'instamart': 'Groceries', 'dmart': 'Groceries', 'grofers': 'Groceries',
  'jiomart': 'Groceries', 'reliance fresh': 'Groceries', 'more retail': 'Groceries',
  'supermarket': 'Groceries', 'kirana': 'Groceries', 'grocery': 'Groceries',
  'milk': 'Groceries', 'dairy': 'Groceries', 'vegetable': 'Groceries', 'spencer': 'Groceries',
  // Transport
  'uber': 'Transport', 'ola': 'Transport', 'rapido': 'Transport', 'metro': 'Transport',
  'fastag': 'Transport', 'petrol': 'Transport', 'fuel': 'Transport', 'hpcl': 'Transport',
  'bpcl': 'Transport', 'indian oil': 'Transport', 'iocl': 'Transport', 'parking': 'Transport',
  'namma yatri': 'Transport', 'redbus': 'Transport', 'auto': 'Transport',
  // Shopping
  'amazon': 'Shopping', 'flipkart': 'Shopping', 'myntra': 'Shopping', 'ajio': 'Shopping',
  'meesho': 'Shopping', 'nykaa': 'Shopping', 'croma': 'Shopping', 'reliance digital': 'Shopping',
  'decathlon': 'Shopping', 'ikea': 'Shopping', 'tata cliq': 'Shopping', 'lenskart': 'Shopping',
  'zara': 'Shopping', 'h&m': 'Shopping', 'westside': 'Shopping', 'electronics': 'Shopping',
  // Bills & Utilities
  'airtel': 'Bills & Utilities', 'jio': 'Bills & Utilities', 'vodafone': 'Bills & Utilities',
  'vi prepaid': 'Bills & Utilities', 'bsnl': 'Bills & Utilities', 'bescom': 'Bills & Utilities',
  'bses': 'Bills & Utilities', 'tata power': 'Bills & Utilities', 'adani': 'Bills & Utilities',
  'electricity': 'Bills & Utilities', 'mahanagar gas': 'Bills & Utilities', 'gas': 'Bills & Utilities',
  'broadband': 'Bills & Utilities', 'act fibernet': 'Bills & Utilities', 'water': 'Bills & Utilities',
  'recharge': 'Bills & Utilities', 'dth': 'Bills & Utilities', 'tata play': 'Bills & Utilities',
  'insurance': 'Bills & Utilities', 'lic': 'Bills & Utilities',
  // Rent
  'rent': 'Rent', 'nobroker': 'Rent', 'landlord': 'Rent', 'housing': 'Rent', 'nestaway': 'Rent',
  'maintenance': 'Rent', 'society': 'Rent',
  // Entertainment
  'bookmyshow': 'Entertainment', 'pvr': 'Entertainment', 'inox': 'Entertainment',
  'cinema': 'Entertainment', 'steam': 'Entertainment', 'playstation': 'Entertainment',
  'district': 'Entertainment', 'concert': 'Entertainment',
  // Subscriptions
  'netflix': 'Subscriptions', 'spotify': 'Subscriptions', 'hotstar': 'Subscriptions',
  'prime video': 'Subscriptions', 'amazon prime': 'Subscriptions', 'youtube': 'Subscriptions',
  'sonyliv': 'Subscriptions', 'zee5': 'Subscriptions', 'apple com bill': 'Subscriptions',
  'google play': 'Subscriptions', 'icloud': 'Subscriptions', 'chatgpt': 'Subscriptions',
  'gym': 'Subscriptions', 'cult fit': 'Subscriptions', 'cultfit': 'Subscriptions',
  // Health
  'apollo': 'Health', 'pharmeasy': 'Health', 'netmeds': 'Health', 'tata 1mg': 'Health',
  'pharmacy': 'Health', 'medical': 'Health', 'hospital': 'Health', 'clinic': 'Health',
  'diagnostic': 'Health', 'practo': 'Health', 'chemist': 'Health',
  // Education
  'udemy': 'Education', 'coursera': 'Education', 'byju': 'Education', 'unacademy': 'Education',
  'school': 'Education', 'college': 'Education', 'university': 'Education', 'tuition': 'Education',
  'books': 'Education', 'exam fee': 'Education',
  // Travel
  'makemytrip': 'Travel', 'goibibo': 'Travel', 'cleartrip': 'Travel', 'irctc': 'Travel',
  'indigo': 'Travel', 'air india': 'Travel', 'vistara': 'Travel', 'akasa': 'Travel',
  'oyo': 'Travel', 'airbnb': 'Travel', 'hotel': 'Travel', 'ixigo': 'Travel', 'yatra': 'Travel',
  // Transfers
  'atm cash': 'Transfers', 'atm': 'Transfers', 'self transfer': 'Transfers',
  'credit card payment': 'Transfers', 'cred': 'Transfers',
  // Income
  'salary': 'Income', 'payroll': 'Income', 'dividend': 'Income', 'interest': 'Income',
};

final _sortedRules = kCategoryRules.entries.toList()
  ..sort((a, b) => b.key.length.compareTo(a.key.length));

/// Rules only: no model, no memory. Null when nothing matches.
CategoryDecision? ruleCategory({
  required String merchant,
  required TxnDirection direction,
  String? vpa,
  String? text,
}) {
  final key = merchantKey(merchant);
  final hay = ' ${key.toLowerCase()} ${merchant.toLowerCase()} ${(text ?? '').toLowerCase()} ';
  for (final e in _sortedRules) {
    final k = e.key;
    final pattern = RegExp('(?<![a-z])${RegExp.escape(k)}(?![a-z])');
    if (pattern.hasMatch(hay)) {
      // Refunds from shops are still Income-side money; keep the shop's
      // category only for debits.
      if (direction == TxnDirection.credit && e.value != 'Income') {
        return const CategoryDecision('Income', 'rule', 0.7);
      }
      return CategoryDecision(e.value, 'rule', 0.9);
    }
  }
  if (vpa != null && looksLikePersonVpa(vpa)) {
    return const CategoryDecision('Transfers', 'rule', 0.75);
  }
  if (direction == TxnDirection.credit) {
    return const CategoryDecision('Income', 'rule', 0.6);
  }
  return null;
}

/// Reads the model's answer and returns a valid category, or null.
String? validateLlmCategory(String output) {
  var s = output.trim();
  if (s.isEmpty) return null;
  // Take the first line, strip quotes, "Category:" prefixes and full stops.
  s = s.split('\n').first;
  s = s.replaceAll(RegExp(r'^(category|answer)\s*[:\-]\s*', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'''^["'`*\s]+|["'`*.\s]+$'''), '');
  final exact = canonicalCategory(s);
  if (exact != null) return exact;
  // A short answer that contains exactly one category name ("It's Groceries").
  if (s.length <= 60) {
    final l = s.toLowerCase();
    // A category counts if its name, or its first word, appears: "Food or
    // Groceries" names two and is rejected as a hedge.
    final hits = [
      for (final c in kCategories)
        if (l.contains(c.toLowerCase()) ||
            RegExp('\\b${RegExp.escape(c.split(' ').first.toLowerCase())}\\b').hasMatch(l))
          c
    ];
    if (hits.length == 1) return hits.single;
  }
  return null;
}

String categoryPrompt(String merchant, int amountPaise, TxnDirection direction) {
  final rupees = (amountPaise / 100).toStringAsFixed(0);
  return 'You sort Indian bank transactions into categories.\n'
      'Allowed categories: ${kCategories.join(', ')}.\n'
      'Transaction: ${direction == TxnDirection.debit ? 'paid' : 'received'} Rs $rupees, merchant "$merchant".\n'
      'Answer with exactly one category name from the list and nothing else.';
}

typedef MemoryLookup = Future<String?> Function(String merchantKey);

class Categorizer {
  Categorizer({required this.llm, required this.memory});

  final LlmClient llm;
  final MemoryLookup memory;

  /// Below this, a rule is "unsure" and the model gets a say.
  static const unsureBelow = 0.65;

  Future<CategoryDecision> categorize({
    required String merchant,
    required int amountPaise,
    required TxnDirection direction,
    String? vpa,
    String? text,
  }) async {
    final remembered = await memory(merchantKey(merchant));
    final canonical = canonicalCategory(remembered);
    if (canonical != null) return CategoryDecision(canonical, 'memory', 1);

    final rule = ruleCategory(merchant: merchant, direction: direction, vpa: vpa, text: text);
    if (rule != null && rule.confidence >= unsureBelow) return rule;

    if (await llm.isReady) {
      try {
        final out = await llm.complete(categoryPrompt(merchant, amountPaise, direction));
        final valid = validateLlmCategory(out);
        if (valid != null) return CategoryDecision(valid, 'llm', 0.6);
      } catch (_) {
        // The model failing is never fatal: fall through to the default.
      }
    }
    return rule ?? const CategoryDecision('Other', 'default', 0);
  }
}
