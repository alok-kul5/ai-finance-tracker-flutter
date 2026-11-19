/// Plain domain types shared by parsers, the query engine, storage and the UI.
library;

enum TxnDirection { debit, credit }

enum TxnSource { sms, receipt, manual }

/// The fixed category list. The LLM may only choose from these.
const kCategories = <String>[
  'Food & Dining',
  'Groceries',
  'Transport',
  'Shopping',
  'Bills & Utilities',
  'Rent',
  'Entertainment',
  'Health',
  'Education',
  'Travel',
  'Subscriptions',
  'Transfers',
  'Income',
  'Other',
];

/// Returns the canonical category for [raw] if it names one of [kCategories]
/// (case and punctuation insensitive), else null.
String? canonicalCategory(String? raw) {
  if (raw == null) return null;
  String norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'\band\b'), '').replaceAll(RegExp(r'[^a-z]'), '');
  final n = norm(raw);
  if (n.isEmpty) return null;
  for (final c in kCategories) {
    if (norm(c) == n) return c;
  }
  return null;
}

class ParsedTxn {
  const ParsedTxn({
    required this.amountPaise,
    required this.direction,
    required this.occurredAt,
    required this.merchant,
    this.account,
    this.reference,
    this.balancePaise,
    this.bank,
    this.vpa,
    this.raw,
  });

  final int amountPaise;
  final TxnDirection direction;
  final DateTime occurredAt;
  final String merchant;
  final String? account; // masked, e.g. "XX1234"
  final String? reference; // UPI / bank reference, used to de-duplicate
  final int? balancePaise;
  final String? bank;
  final String? vpa;
  final String? raw;

  @override
  String toString() =>
      'ParsedTxn(${direction.name} $amountPaise, $merchant, $occurredAt, ref=$reference, acct=$account, bal=$balancePaise)';
}

class Txn {
  Txn({
    required this.id,
    required this.amountPaise,
    required this.direction,
    required this.occurredAt,
    required this.merchant,
    required this.category,
    required this.source,
    this.note,
    this.reference,
    this.account,
    this.categorySource = 'rule',
    DateTime? updatedAt,
    this.deleted = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final int amountPaise;
  final TxnDirection direction;
  final DateTime occurredAt;
  final String merchant;
  final String category;
  final TxnSource source;
  final String? note;
  final String? reference;
  final String? account;

  /// "rule", "memory", "llm", "user" or "default": shown in the UI so users
  /// know why a transaction landed in its category.
  final String categorySource;

  /// Last local edit; the sync uses it for last-write-wins.
  final DateTime updatedAt;
  final bool deleted;

  bool get isDebit => direction == TxnDirection.debit;

  Txn copyWith({
    String? category,
    String? categorySource,
    String? merchant,
    String? note,
    int? amountPaise,
    DateTime? occurredAt,
    DateTime? updatedAt,
    bool? deleted,
  }) =>
      Txn(
        id: id,
        amountPaise: amountPaise ?? this.amountPaise,
        direction: direction,
        occurredAt: occurredAt ?? this.occurredAt,
        merchant: merchant ?? this.merchant,
        category: category ?? this.category,
        source: source,
        note: note ?? this.note,
        reference: reference,
        account: account,
        categorySource: categorySource ?? this.categorySource,
        updatedAt: updatedAt ?? this.updatedAt,
        deleted: deleted ?? this.deleted,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'amount_paise': amountPaise,
        'direction': direction.name,
        'occurred_at': occurredAt.toUtc().toIso8601String(),
        'merchant': merchant,
        'category': category,
        'category_source': categorySource,
        'source': source.name,
        'note': note,
        'reference': reference,
        'account': account,
      };

  static Txn fromJson(Map<String, Object?> j,
          {required DateTime updatedAt, bool deleted = false}) =>
      Txn(
        id: j['id']! as String,
        amountPaise: (j['amount_paise']! as num).toInt(),
        direction: TxnDirection.values.byName(j['direction']! as String),
        occurredAt: DateTime.parse(j['occurred_at']! as String).toLocal(),
        merchant: j['merchant']! as String,
        category: canonicalCategory(j['category'] as String?) ?? 'Other',
        categorySource: (j['category_source'] as String?) ?? 'rule',
        source: TxnSource.values.byName((j['source'] as String?) ?? 'manual'),
        note: j['note'] as String?,
        reference: j['reference'] as String?,
        account: j['account'] as String?,
        updatedAt: updatedAt,
        deleted: deleted,
      );

  @override
  String toString() =>
      'Txn($id ${direction.name} $amountPaise $merchant [$category] $occurredAt)';
}

/// A monthly spending limit for one category.
class Budget {
  Budget({
    required this.category,
    required this.limitPaise,
    DateTime? updatedAt,
    this.deleted = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String category;
  final int limitPaise;
  final DateTime updatedAt;
  final bool deleted;

  /// One budget per category, so the category is the id.
  String get id => category;

  Map<String, Object?> toJson() =>
      {'category': category, 'limit_paise': limitPaise};

  static Budget fromJson(Map<String, Object?> j,
          {required DateTime updatedAt, bool deleted = false}) =>
      Budget(
        category: j['category']! as String,
        limitPaise: (j['limit_paise']! as num).toInt(),
        updatedAt: updatedAt,
        deleted: deleted,
      );
}
