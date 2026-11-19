/// A pure-Dart parser for Indian bank and UPI transaction SMS.
///
/// It understands the common shapes sent by SBI, HDFC, ICICI, Axis, Kotak,
/// PNB, Bank of Baroda, Yes, IDFC First and the card issuers: debited /
/// credited / spent / sent / received, amounts as Rs. / Rs / INR / ₹ with
/// Indian grouping, masked accounts (a/c XX1234, A/C *1234, Card x5678),
/// UPI references, VPAs and available balances. Anything that is not a
/// completed money movement (OTPs, offers, collect requests, failed or
/// scheduled debits) returns null.
library;

import '../domain/models.dart';
import '../domain/money.dart';
import 'dates.dart';
import 'merchant.dart';

class SmsParser {
  const SmsParser();

  static const _cur = r'(?:rs\.?|inr|₹)';
  static const _num = r'(\d{1,3}(?:,\d{2,3})+(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)';

  static final _amountWithCurrency =
      RegExp('$_cur\\s*$_num', caseSensitive: false);
  // "debited by 250.0", "debited for 99" (SBI and others omit the currency).
  static final _amountAfterVerb = RegExp(
      '(?:debited|credited|spent|paid|sent|received)\\s+(?:by|for|with|of)?\\s*$_cur?\\s*$_num',
      caseSensitive: false);
  static final _balance = RegExp(
      '(?:avl\\.?|avail(?:able)?\\.?|total|clr|closing|a/c)?\\s*(?:bal(?:ance)?|bal\\.)\\s*(?:is|:|-|of)?\\s*(?:$_cur)?\\s*:?\\s*$_num',
      caseSensitive: false);
  static final _account = RegExp(
      r'(?:a/c|a/c\.|ac|acct|account|card|a\\c)\s*(?:no\.?|number|ending(?: with)?)?\s*[:.\-]?\s*(?:[x*•]+\s*)?(\d{3,6})\b',
      caseSensitive: false);
  static final _accountX = RegExp(r'\b[xX*]{1,8}(\d{3,6})\b');
  static final _vpa = RegExp(r'\b([a-zA-Z0-9.\-_]{2,})@([a-zA-Z]{2,})\b');
  static final _ref = RegExp(
      r'(?:upi\s*ref(?:erence)?\s*(?:no|number|id)?|ref(?:erence)?\s*(?:no|number|id)?|refno|rrn|txn\s*(?:id|no)|transaction\s*id|imps\s*ref|utr(?:\s*no)?|upi)\s*[:.#\-]?\s*(?:is\s*)?([A-Za-z]{0,4}\d{9,18})',
      caseSensitive: false);
  static final _upiPath =
      RegExp(r'UPI/(?:P2M|P2A|CR|DR)?/?(\d{9,18})/([^/\n]+)', caseSensitive: false);

  static final _reject = RegExp(
      r'\botp\b|one[ -]time password|verification code|is requesting|has requested|requested money|collect request|'
      r'\bfailed\b|declined|unsuccessful|reversed? within|will be debited|to be debited|is due|due on|due date|'
      r'pre-?approved|eligible|apply now|win |cashback offer|get flat|offer|emi of|minimum amount due|'
      r'mandate (?:is )?(?:created|registered)|auto-?pay (?:is )?(?:set|registered)',
      caseSensitive: false);

  static final _debitWords = RegExp(
      r'\b(debited|debit|spent|sent|withdrawn|withdrawal|paid|purchase|dr\b|deducted|transferred to|payment of|txn of)',
      caseSensitive: false);
  static final _creditWords = RegExp(
      r'\b(credited|credit(?!\s*card)|received|deposited|refund(?:ed)?|cr\b|added to)',
      caseSensitive: false);

  static const _banks = <String, String>{
    'sbi': 'SBI', 'hdfc': 'HDFC Bank', 'icici': 'ICICI Bank', 'axis': 'Axis Bank',
    'kotak': 'Kotak', 'pnb': 'PNB', 'bob': 'Bank of Baroda', 'baroda': 'Bank of Baroda',
    'yes': 'Yes Bank', 'idfc': 'IDFC First', 'indus': 'IndusInd', 'canara': 'Canara Bank',
    'union': 'Union Bank', 'federal': 'Federal Bank', 'paytm': 'Paytm Payments Bank',
    'airtel': 'Airtel Payments Bank', 'au ': 'AU Bank', 'amex': 'Amex', 'onecard': 'OneCard',
  };

  /// Parses one message. [sender] is the SMS address ("VM-HDFCBK") and
  /// [receivedAt] the time the phone got it, used when the text has no date.
  ParsedTxn? parse(String body, {String? sender, DateTime? receivedAt}) {
    final text = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    final lower = text.toLowerCase();
    if (text.isEmpty) return null;
    if (_reject.hasMatch(text)) return null;

    final direction = _direction(lower);
    if (direction == null) return null;

    final amount = _amount(text);
    if (amount == null || amount <= 0) return null;

    final now = receivedAt ?? DateTime.now();
    final date = _date(text, now);
    final vpa = _findVpa(text);
    final merchant = _merchant(text, body, direction, vpa);
    final upiPath = _upiPath.firstMatch(body);

    return ParsedTxn(
      amountPaise: amount,
      direction: direction,
      occurredAt: date,
      merchant: merchant,
      account: _accountOf(text),
      reference: upiPath?.group(1) ?? _refOf(text),
      balancePaise: _balanceOf(text),
      bank: _bankOf(sender, lower),
      vpa: vpa,
      raw: body,
    );
  }

  TxnDirection? _direction(String lower) {
    final d = _debitWords.firstMatch(lower);
    final c = _creditWords.firstMatch(lower);
    if (d == null && c == null) return null;
    if (d == null) return TxnDirection.credit;
    if (c == null) return TxnDirection.debit;
    // "Rs 250 debited from a/c ...; SWIGGY credited" -> the first verb is
    // what happened to *your* account.
    return d.start <= c.start ? TxnDirection.debit : TxnDirection.credit;
  }

  bool _isBalanceContext(String text, int start) {
    final before = text
        .substring((start - 22).clamp(0, start), start)
        .toLowerCase();
    return RegExp(r'(bal(ance)?|lmt|limit|avl|available)[^a-z]*$').hasMatch(before) ||
        RegExp(r'(bal(ance)?|lmt|limit)\b[^.;]*$').hasMatch(before);
  }

  int? _amount(String text) {
    for (final m in _amountWithCurrency.allMatches(text)) {
      if (_isBalanceContext(text, m.start)) continue;
      final v = _toPaise(m.group(1)!);
      if (v != null && v > 0) return v;
    }
    final m = _amountAfterVerb.firstMatch(text);
    if (m != null) return _toPaise(m.group(1)!);
    return null;
  }

  int? _toPaise(String s) {
    try {
      return parseRupeesToPaise(s);
    } on FormatException {
      return null;
    }
  }

  int? _balanceOf(String text) {
    final m = _balance.firstMatch(text);
    if (m == null) return null;
    return _toPaise(m.group(1)!);
  }

  String? _accountOf(String text) {
    final m = _account.firstMatch(text) ?? _accountX.firstMatch(text);
    if (m == null) return null;
    final digits = m.group(1)!;
    final last4 = digits.length > 4 ? digits.substring(digits.length - 4) : digits;
    return 'XX$last4';
  }

  String? _refOf(String text) {
    for (final m in _ref.allMatches(text)) {
      final v = m.group(1)!;
      // Phone numbers in "call 18002662" style footers are not references.
      final before = text.substring((m.start - 8).clamp(0, m.start), m.start).toLowerCase();
      if (before.contains('call')) continue;
      return v.toUpperCase();
    }
    return null;
  }

  String? _findVpa(String text) {
    for (final m in _vpa.allMatches(text)) {
      final domain = m.group(2)!.toLowerCase();
      // Skip e-mail addresses.
      if (domain == 'gmail' || domain == 'yahoo' || domain == 'outlook') continue;
      if (text.length > m.end && text[m.end] == '.') {
        final rest = text.substring(m.end + 1);
        if (RegExp(r'^(com|in|co|net|org)\b').hasMatch(rest)) continue;
      }
      return m.group(0)!.toLowerCase();
    }
    return null;
  }

  static final _stop =
      r'(?=\s+(?:on|ref|refno|upi|via|using|from|for|dated|at\s+\d|avl|avail|bal|not you|if not|txn|info|\(|-\s)|[.;,(]|\s*$)';

  String _merchant(String text, String raw, TxnDirection dir, String? vpa) {
    String? pick(RegExp r) {
      final m = r.firstMatch(text);
      final v = m?.group(1)?.trim();
      if (v == null || v.isEmpty) return null;
      if (RegExp(r'^(your|a/c|ac|acct|account|you|xx|\*|card)\b', caseSensitive: false).hasMatch(v)) {
        return null;
      }
      return v;
    }

    final upi = _upiPath.firstMatch(raw);
    final candidates = <String?>[
      if (upi != null) upi.group(2)!.trim(),
      // "Info: NEFT-ACME CORP" / "Info: UPI-SWIGGY"
      pick(RegExp(r'info[:\s]+(?:neft|imps|rtgs|upi|ach|nach)?[-/ ]*([A-Za-z][A-Za-z0-9 &.\-]{1,40}?)' + _stop, caseSensitive: false)),
      // "; SWIGGY credited" (ICICI)
      pick(RegExp(r'[;,]\s*([A-Za-z][A-Za-z0-9 &.\-]{1,40}?)\s+credited', caseSensitive: false)),
      // "at AMAZON on", "spent at Starbucks"
      pick(RegExp(r'\bat\s+([A-Za-z][A-Za-z0-9 &.\-*]{1,40}?)' + _stop, caseSensitive: false)),
      // "trf to SWIGGY Refno", "to VPA x", "To SWIGGY On", "paid to X"
      if (dir == TxnDirection.debit)
        pick(RegExp(r'\b(?:trf to|transfer to|transferred to|paid to|sent to|to vpa|to)\s+([A-Za-z][A-Za-z0-9 &.@\-*]{1,40}?)' + _stop, caseSensitive: false)),
      // "from VPA rahul@okaxis", "by a/c linked to VPA x", "received from X"
      if (dir == TxnDirection.credit)
        pick(RegExp(r'\b(?:linked to vpa|from vpa|received from|from|by)\s+([A-Za-z][A-Za-z0-9 &.@\-*]{1,40}?)' + _stop, caseSensitive: false)),
      vpa,
    ];
    for (final c in candidates) {
      if (c == null) continue;
      final cleaned = c.replaceAll(RegExp(r'^vpa\s+', caseSensitive: false), '').trim();
      if (cleaned.length < 2) continue;
      if (RegExp(r'^(a/c|ac|acct|account|bank|card|x+\d+|\d+)$', caseSensitive: false).hasMatch(cleaned)) continue;
      if (RegExp(r'\b(bank a/?c|a/c|acct)\b', caseSensitive: false).hasMatch(cleaned)) continue;
      // "to rapido.rides@axisbank" stops at the dot: use the whole VPA.
      if (vpa != null && vpa.startsWith(cleaned.toLowerCase())) {
        return displayMerchant(vpa);
      }
      return displayMerchant(cleaned);
    }
    if (RegExp(r'atm|cash withdrawal', caseSensitive: false).hasMatch(text)) return 'ATM Cash';
    return dir == TxnDirection.credit ? 'Incoming transfer' : 'Unknown merchant';
  }

  DateTime _date(String text, DateTime receivedAt) {
    final d = findDate(text, fallbackYear: receivedAt.year);
    if (d == null) return receivedAt;
    final sameDay = d.year == receivedAt.year &&
        d.month == receivedAt.month &&
        d.day == receivedAt.day;
    if (sameDay) return receivedAt;
    final t = findTime(text);
    return DateTime(d.year, d.month, d.day, t?.$1 ?? 12, t?.$2 ?? 0);
  }

  String? _bankOf(String? sender, String lower) {
    final s = (sender ?? '').toLowerCase();
    for (final e in _banks.entries) {
      final k = e.key.trim();
      if (s.contains(k)) return e.value;
    }
    for (final e in _banks.entries) {
      if (RegExp('\\b${RegExp.escape(e.key.trim())}\\b').hasMatch(lower)) return e.value;
    }
    return null;
  }
}

/// Drops messages already seen. Banks often send the same transaction twice
/// (an SMS from the bank and another from the UPI app), so a reference
/// number is the identity; without one, amount + direction + account + the
/// same minute stands in.
class SmsDeduper {
  SmsDeduper([Iterable<String> known = const []]) : _seen = {...known};

  final Set<String> _seen;

  static String keyOf(ParsedTxn t) {
    if (t.reference != null && t.reference!.isNotEmpty) return 'ref:${t.reference}';
    final at = t.occurredAt;
    return 'h:${t.direction.name}:${t.amountPaise}:${t.account ?? '-'}:'
        '${at.year}-${at.month}-${at.day}T${at.hour}:${at.minute}';
  }

  /// True the first time a transaction is seen.
  bool add(ParsedTxn t) => _seen.add(keyOf(t));

  /// Parsed transactions with duplicates removed, in input order.
  List<ParsedTxn> unique(Iterable<ParsedTxn> items) =>
      [for (final t in items) if (add(t)) t];
}
