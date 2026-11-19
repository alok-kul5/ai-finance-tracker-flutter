import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/ai/categorizer.dart';
import 'package:kharcha/domain/models.dart';

import '../support/fakes.dart';

void main() {
  Categorizer make(FakeLlm llm, [Map<String, String> memory = const {}]) =>
      Categorizer(llm: llm, memory: (k) async => memory[k]);

  test('rules first: the model is never asked about Swiggy', () async {
    final llm = FakeLlm(fallback: 'Travel');
    final d = await make(llm).categorize(merchant: 'SWIGGY', amountPaise: 25000, direction: TxnDirection.debit);
    expect(d.category, 'Food & Dining');
    expect(d.source, 'rule');
    expect(llm.prompts, isEmpty);
  });

  test('longest keyword wins: Amazon Prime is a subscription', () async {
    final d = await make(FakeLlm(ready: false))
        .categorize(merchant: 'Amazon Prime', amountPaise: 149900, direction: TxnDirection.debit);
    expect(d.category, 'Subscriptions');
  });

  test('remembered merchant beats rules', () async {
    final d = await make(FakeLlm(), {'swiggy': 'Groceries'})
        .categorize(merchant: 'swiggy.instamart@icici', amountPaise: 50000, direction: TxnDirection.debit);
    expect(d.category, 'Groceries');
    expect(d.source, 'memory');
  });

  test('unknown merchant goes to the model, and a valid answer is used', () async {
    final llm = FakeLlm(replies: {'Kumar Hardware': 'Shopping'});
    final d = await make(llm).categorize(merchant: 'Kumar Hardware', amountPaise: 89000, direction: TxnDirection.debit);
    expect(d.category, 'Shopping');
    expect(d.source, 'llm');
    expect(llm.prompts.single, contains('Allowed categories'));
  });

  test('model output is validated against kCategories', () async {
    for (final (out, want) in [
      ('Category: groceries.', 'Groceries'),
      ('"Food & Dining"', 'Food & Dining'),
      ('I think it is Health', 'Health'),
      ('bills and utilities', 'Bills & Utilities'),
    ]) {
      expect(validateLlmCategory(out), want, reason: out);
    }
    for (final bad in ['Hardware', '', 'Food or Groceries maybe', 'Crypto']) {
      expect(validateLlmCategory(bad), isNull, reason: bad);
    }
  });

  test('an invented category falls back to Other', () async {
    final d = await make(FakeLlm(fallback: 'Home Improvement'))
        .categorize(merchant: 'Kumar Hardware', amountPaise: 89000, direction: TxnDirection.debit);
    expect(d.category, 'Other');
    expect(d.source, 'default');
  });

  test('no model downloaded: Other, no crash', () async {
    final d = await make(FakeLlm(ready: false))
        .categorize(merchant: 'Kumar Hardware', amountPaise: 89000, direction: TxnDirection.debit);
    expect(d.category, 'Other');
  });

  test('a crashing model is not fatal', () async {
    final llm = FakeLlm()..throws = true;
    final d = await make(llm).categorize(merchant: 'Kumar Hardware', amountPaise: 1, direction: TxnDirection.debit);
    expect(d.category, 'Other');
  });

  test('money from a person is a transfer, salary is income', () async {
    final c = make(FakeLlm(ready: false));
    expect((await c.categorize(merchant: 'Rahul Verma', vpa: 'rahul.verma@okaxis', amountPaise: 1, direction: TxnDirection.debit)).category,
        'Transfers');
    expect((await c.categorize(merchant: 'Acme Corp', text: 'NEFT SALARY', amountPaise: 1, direction: TxnDirection.credit)).category,
        'Income');
  });
}
