import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/domain/models.dart';
import 'package:kharcha/parsing/sms_parser.dart';

/// Synthetic messages in the shapes Indian banks send. Every number, name
/// and reference here is made up.
class _Case {
  const _Case(this.name, this.body,
      {this.sender,
      required this.amount,
      required this.dir,
      this.merchant,
      this.account,
      this.ref,
      this.balance,
      this.date,
      this.bank});
  final String name;
  final String body;
  final String? sender;
  final int amount;
  final TxnDirection dir;
  final String? merchant;
  final String? account;
  final String? ref;
  final int? balance;
  final DateTime? date;
  final String? bank;
}

const d = TxnDirection.debit;
const c = TxnDirection.credit;

final cases = <_Case>[
  _Case('SBI UPI debit (no currency)',
      'Dear UPI user A/C X4821 debited by 250.0 on date 12Mar24 trf to SWIGGY Refno 407212345678. If not u? call 1800111109. -SBI',
      sender: 'VM-SBIUPI', amount: 25000, dir: d, merchant: 'Swiggy', account: 'XX4821',
      ref: '407212345678', date: DateTime(2024, 3, 12, 12), bank: 'SBI'),
  _Case('HDFC multi-line UPI sent',
      'Sent Rs.1,250.00\nFrom HDFC Bank A/C *5512\nTo ZOMATO LIMITED\nOn 14/03/24\nRef 407412349876\nNot You?\nCall 18002586161/SMS BLOCK UPI to 7308080808',
      sender: 'AD-HDFCBK', amount: 125000, dir: d, merchant: 'Zomato Limited', account: 'XX5512',
      ref: '407412349876', date: DateTime(2024, 3, 14, 12), bank: 'HDFC Bank'),
  _Case('HDFC VPA debit',
      'Rs.349.00 debited from a/c **5512 on 15-03-24 to VPA netflix.upi@hdfcbank(UPI Ref No 407512340001). Not you? Call on 18002586161 to report',
      amount: 34900, dir: d, merchant: 'Netflix', account: 'XX5512', ref: '407512340001'),
  _Case('ICICI debit with merchant credited',
      'ICICI Bank Acct XX234 debited for Rs 540.00 on 16-Mar-24; UBER INDIA credited. UPI:407612341111. Call 18002662 for dispute. SMS BLOCK 234 to 9215676766.',
      sender: 'JD-ICICIB', amount: 54000, dir: d, merchant: 'Uber India', account: 'XX234',
      ref: '407612341111', date: DateTime(2024, 3, 16, 12), bank: 'ICICI Bank'),
  _Case('Axis UPI path',
      'INR 899.00 debited\nA/c no. XX7710\n17-03-24, 14:22:11\nUPI/P2M/407712342222/BIGBASKET\nNot you? SMS BLOCKUPI Cust ID to 919951860002\nAxis Bank',
      sender: 'AX-AXISBK', amount: 89900, dir: d, merchant: 'Bigbasket', account: 'XX7710',
      ref: '407712342222', date: DateTime(2024, 3, 17, 14, 22), bank: 'Axis Bank'),
  _Case('Kotak sent to VPA',
      'Sent Rs.120.00 from Kotak Bank AC X9031 to rapido.rides@axisbank on 18-03-24.UPI Ref 407812343333. Not you, https://kotak.com/fraud',
      amount: 12000, dir: d, merchant: 'Rapido Rides', account: 'XX9031', ref: '407812343333', bank: 'Kotak'),
  _Case('UPI credit from a person',
      'Rs.5,000.00 credited to a/c XX4821 on 01-03-24 by a/c linked to VPA rahul.verma@okaxis (UPI Ref No 406112345678).',
      amount: 500000, dir: c, merchant: 'Rahul Verma', account: 'XX4821', ref: '406112345678',
      date: DateTime(2024, 3, 1, 12)),
  _Case('Salary NEFT credit with balance',
      'INR 85,000.00 credited to A/c XX4821 on 01-Mar-24. Info: NEFT-ACME CORP. Avl Bal INR 1,20,500.50',
      amount: 8500000, dir: c, merchant: 'Acme Corp', account: 'XX4821', balance: 12050050),
  _Case('Card spend with available limit',
      'Rs.1,299.00 spent on HDFC Bank Credit Card x5678 at AMAZON on 2024-03-12:10:22:33. Avl Lmt: Rs.50,000.00. Not you? SMS BLOCK 5678 to 7308080808',
      amount: 129900, dir: d, merchant: 'Amazon', account: 'XX5678', date: DateTime(2024, 3, 12, 10, 22)),
  _Case('ICICI card spend',
      'INR 2,450.00 spent using ICICI Bank Card XX9002 on 19-Mar-24 on DMART AVENUE. Avl Limit: INR 87,550.00. If not you, call 1800 2662/SMS BLOCK 9002 to 9215676766',
      amount: 245000, dir: d, account: 'XX9002'),
  _Case('₹ symbol and balance',
      '₹ 75.00 debited from A/c XX1123 for UPI txn to chaipoint@ybl on 20-03-24. Ref no 408012344444. Avl bal ₹12,345.67',
      amount: 7500, dir: d, merchant: 'Chaipoint', account: 'XX1123', ref: '408012344444', balance: 1234567),
  _Case('ATM withdrawal',
      'Rs.2000.00 withdrawn at ATM S1AW000123 from A/c XX4821 on 21-03-24. Avl Bal Rs.18,000.00 -SBI',
      amount: 200000, dir: d, account: 'XX4821', balance: 1800000),
  _Case('Refund credit',
      'Rs 499.00 refund credited to your HDFC Bank Card x5678 from FLIPKART on 22-03-24.',
      amount: 49900, dir: c, merchant: 'Flipkart', account: 'XX5678'),
  _Case('PNB debit',
      'Your A/c XX6612 is debited for Rs.3,200.00 on 23-03-2024 by UPI Ref No 408312345555 to JIO PREPAID. Bal Rs.9,800.00 -PNB',
      sender: 'BP-PNBSMS', amount: 320000, dir: d, merchant: 'Jio Prepaid', account: 'XX6612',
      ref: '408312345555', balance: 980000, date: DateTime(2024, 3, 23, 12), bank: 'PNB'),
  _Case('Bank of Baroda credit IMPS',
      'Rs.15000.00 Credited to A/c ...0451 thru IMPS/408412346666 from Priya S on 24-03-24. Avl Bal Rs.45000.00 -BOB',
      sender: 'VK-BOBTXN', amount: 1500000, dir: c, balance: 4500000, bank: 'Bank of Baroda'),
  _Case('Electricity autopay paid',
      'Payment of Rs 1,845.00 to BESCOM from A/c XX4821 is successful. UPI Ref No 408512347777.',
      amount: 184500, dir: d, merchant: 'Bescom', account: 'XX4821', ref: '408512347777'),
  _Case('Lowercase rs and no space',
      'rs.60 debited from a/c xx3344 to vpa metro.card@paytm on 26-03-24 upi ref 408612348888',
      amount: 6000, dir: d, merchant: 'Metro Card', account: 'XX3344', ref: '408612348888'),
  _Case('IDFC with transaction id',
      'Your IDFC FIRST Bank A/c XX0099 has been debited with INR 650.00 towards PVR CINEMAS on 27/03/2024. Transaction ID 408712349999.',
      sender: 'VM-IDFCFB', amount: 65000, dir: d, account: 'XX0099', ref: '408712349999', bank: 'IDFC First'),
  _Case('Yes bank received',
      'You have received INR 1,000.00 in your YES BANK A/c XX2299 from amit.k@oksbi. UPI Ref 408812340000.',
      amount: 100000, dir: c, merchant: 'Amit K', account: 'XX2299', ref: '408812340000'),
  _Case('Big amount with lakh grouping',
      'INR 1,25,000.00 debited from A/c XX4821 on 28-03-24 to NOBROKER RENT. Ref no 408912341212.',
      amount: 12500000, dir: d, merchant: 'Nobroker Rent', ref: '408912341212'),
];

final rejected = <String>[
  '123456 is your OTP for txn of Rs.1,299.00 at AMAZON. Valid for 10 mins. Do not share.',
  'Get flat Rs.500 cashback on your next recharge! Use code SAVE500. T&C apply.',
  'rahul.verma@okaxis is requesting Rs.500.00 from you. Approve in your UPI app.',
  'Your txn of Rs.250.00 to SWIGGY failed. Any amount debited will be reversed within 3 days.',
  'Rs.999.00 will be debited from your a/c XX4821 on 01-04-24 towards SPOTIFY mandate.',
  'Your credit card bill of Rs.12,340.00 is due on 05-04-24. Minimum amount due Rs.620.00.',
  'You are pre-approved for a personal loan of Rs.5,00,000. Apply now!',
  'Hi! Your order #4021 has shipped and will arrive tomorrow.',
  '',
];

void main() {
  const parser = SmsParser();
  final received = DateTime(2024, 3, 30, 9, 15);

  group('SmsParser parses', () {
    for (final k in cases) {
      test(k.name, () {
        final t = parser.parse(k.body, sender: k.sender, receivedAt: received);
        expect(t, isNotNull, reason: k.body);
        expect(t!.amountPaise, k.amount, reason: '$t');
        expect(t.direction, k.dir, reason: '$t');
        if (k.merchant != null) expect(t.merchant, k.merchant, reason: '$t');
        if (k.account != null) expect(t.account, k.account, reason: '$t');
        if (k.ref != null) expect(t.reference, k.ref, reason: '$t');
        if (k.balance != null) expect(t.balancePaise, k.balance, reason: '$t');
        if (k.date != null) expect(t.occurredAt, k.date, reason: '$t');
        if (k.bank != null) expect(t.bank, k.bank, reason: '$t');
      });
    }
  });

  group('SmsParser ignores non-transactions', () {
    for (final body in rejected) {
      test(body.isEmpty ? '(empty)' : body.substring(0, body.length.clamp(0, 40)), () {
        expect(parser.parse(body, receivedAt: received), isNull);
      });
    }
  });

  test('a message dated the day it arrives keeps the arrival time', () {
    final t = parser.parse('Rs.40.00 debited from A/c XX1111 on 30-03-24 to VPA tea@ybl. UPI Ref No 409012340000',
        receivedAt: received);
    expect(t!.occurredAt, received);
  });

  test('a message with no date uses the arrival time', () {
    final t = parser.parse('Rs.40.00 debited from A/c XX1111 to VPA tea@ybl. UPI Ref No 409012340001',
        receivedAt: received);
    expect(t!.occurredAt, received);
  });

  group('SmsDeduper', () {
    test('drops the same UPI reference sent by bank and app', () {
      final a = parser.parse(cases[0].body, receivedAt: received)!;
      final b = parser.parse(
          'You paid Rs.250.00 to SWIGGY from A/c XX4821. UPI Ref No 407212345678.',
          receivedAt: received)!;
      final dedupe = SmsDeduper();
      expect(dedupe.unique([a, b, a]), hasLength(1));
    });

    test('keeps different references and remembers known ones', () {
      final all = [for (final k in cases) parser.parse(k.body, receivedAt: received)!];
      final dedupe = SmsDeduper(['ref:407212345678']);
      final kept = dedupe.unique(all);
      expect(kept.length, all.length - 1);
    });

    test('without a reference, same amount+account+minute is one txn', () {
      final a = parser.parse('INR 100.00 debited from A/c XX1111 at CAFE COFFEE on 10-03-24 10:05',
          receivedAt: received)!;
      final b = parser.parse('INR 100.00 debited from A/c XX1111 at CAFE COFFEE on 10-03-24 10:05',
          receivedAt: received)!;
      final c2 = parser.parse('INR 100.00 debited from A/c XX1111 at CAFE COFFEE on 10-03-24 18:40',
          receivedAt: received)!;
      expect(SmsDeduper().unique([a, b, c2]), hasLength(2));
    });
  });
}
