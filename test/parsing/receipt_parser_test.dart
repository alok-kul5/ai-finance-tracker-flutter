import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/parsing/receipt_parser.dart';

void main() {
  const parser = ReceiptParser();

  test('restaurant bill with grand total, taxes and subtotal', () {
    const text = '''
CAFE MOCHA BANDRA
GSTIN 27ABCDE1234F1Z5
Ph: 022 2640 1234
Bill No: 4521   Table: 7
Date: 14/03/2024  21:42
Cappuccino        2   360.00
Pasta Arrabiata   1   420.00
Sub Total             780.00
CGST 2.5%              19.50
SGST 2.5%              19.50
Round Off               0.00
Grand Total       Rs. 819.00
Thank you! Visit again
''';
    final r = parser.parse(text);
    expect(r.totalPaise, 81900);
    expect(r.merchant, 'Cafe Mocha Bandra');
    expect(r.date, DateTime(2024, 3, 14));
  });

  test('supermarket slip with total on the next line', () {
    const text = '''
DMart
Avenue Supermarts Ltd
INVOICE
12-Mar-24
Items: 14   Qty: 22
TOTAL
1,234.50
Total Savings 210.00
Card **** 4821
''';
    final r = parser.parse(text);
    expect(r.totalPaise, 123450);
    expect(r.merchant, 'Dmart');
    expect(r.date, DateTime(2024, 3, 12));
  });

  test('net amount beats a plain total', () {
    const text = '''
Apollo Pharmacy
Total 540.00
Discount 54.00
Net Amount 486.00
''';
    expect(parser.parse(text).totalPaise, 48600);
  });

  test('falls back to the largest amount without labels', () {
    const text = '''
Sharma Sweets
Kaju Katli 450.00
Samosa 40.00
₹ 490.00
''';
    final r = parser.parse(text);
    expect(r.totalPaise, 49000);
    expect(r.merchant, 'Sharma Sweets');
  });

  test('amount with ₹ and lakh grouping', () {
    const text = 'Croma Electronics\nAmount Payable ₹1,02,499.00\n05 Jan 2024';
    final r = parser.parse(text);
    expect(r.totalPaise, 10249900);
    expect(r.date, DateTime(2024, 1, 5));
  });

  test('decimal comma and ISO date', () {
    const text = 'Third Wave Coffee\n2024-02-29\nTotal: 315,00';
    final r = parser.parse(text);
    expect(r.totalPaise, 31500);
    expect(r.date, DateTime(2024, 2, 29));
  });

  test('empty or unreadable text', () {
    expect(parser.parse('').isEmpty, isTrue);
    expect(parser.parse('### ~~ ###').totalPaise, isNull);
  });
}
