import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/ai/assistant.dart';
import 'package:kharcha/ai/intent_parser.dart';
import 'package:kharcha/ai/query.dart';
import 'package:kharcha/domain/models.dart';

import '../support/fakes.dart';

void main() {
  final now = DateTime(2024, 3, 20, 18, 0); // a Wednesday
  final data = [
    txn('Swiggy', 250, at: DateTime(2024, 3, 2), category: 'Food & Dining'),
    txn('Zomato', 400, at: DateTime(2024, 3, 10), category: 'Food & Dining'),
    txn('Swiggy', 350, at: DateTime(2024, 3, 19), category: 'Food & Dining'),
    txn('BigBasket', 1200, at: DateTime(2024, 3, 5), category: 'Groceries'),
    txn('Uber', 300, at: DateTime(2024, 3, 20, 9), category: 'Transport'),
    txn('Swiggy', 500, at: DateTime(2024, 2, 14), category: 'Food & Dining'),
    txn('Amazon', 2999, at: DateTime(2024, 2, 20), category: 'Shopping'),
    txn('Acme Corp', 85000, at: DateTime(2024, 3, 1), category: 'Income', dir: TxnDirection.credit),
    txn('Netflix', 649, at: DateTime(2023, 12, 3), category: 'Subscriptions'),
  ];

  group('rule intent parser', () {
    const p = RuleIntentParser();
    SpendQuery parse(String q) => p.parse(q, now: now, knownMerchants: data.map((t) => t.merchant));

    test('category + this month', () {
      final q = parse('How much did I spend on food this month?');
      expect(q.metric, Metric.total);
      expect(q.category, 'Food & Dining');
      expect(q.range, DateRange(DateTime(2024, 3), DateTime(2024, 4), ''));
    });
    test('merchant + last month', () {
      final q = parse('what did I pay swiggy last month');
      expect(q.merchant, 'swiggy');
      expect(q.range.start, DateTime(2024, 2));
    });
    test('count, average, largest, breakdown', () {
      expect(parse('how many times did I order from zomato').metric, Metric.count);
      expect(parse('average grocery spend').metric, Metric.average);
      expect(parse('my biggest expense in february').metric, Metric.largest);
      expect(parse('breakdown by category').metric, Metric.byCategory);
      expect(parse('where did I spend the most this week').metric, Metric.topMerchants);
    });
    test('dates: today, yesterday, last N days, month names, years', () {
      expect(parse('spent today').range.start, DateTime(2024, 3, 20));
      expect(parse('spent yesterday').range.start, DateTime(2024, 3, 19));
      expect(parse('spending in the last 7 days').range.start, DateTime(2024, 3, 14));
      expect(parse('spending this week').range.start, DateTime(2024, 3, 18));
      expect(parse('food in December').range.start, DateTime(2023, 12)); // past December
      expect(parse('food in feb 2024').range.start, DateTime(2024, 2));
      expect(parse('all time spending').range.start.year, 2000);
    });
    test('income questions', () {
      final q = parse('how much did I earn this month');
      expect(q.direction, TxnDirection.credit);
    });
  });

  group('assistant answers with numbers computed in Dart', () {
    test('rule fallback when the model is not downloaded', () async {
      final llm = FakeLlm(ready: false);
      final a = await SpendingAssistant(llm: llm, clock: () => now)
          .ask('How much did I spend on food this month?', data);
      expect(a.intent.source, 'rules');
      expect(a.text, 'You spent ₹1,000.00 on Food & Dining this month, across 3 transactions.');
      expect(llm.prompts, isEmpty);
    });

    test('the LLM only parses; its numbers are never used', () async {
      // The model tries to "answer" with a made-up number besides the JSON.
      final llm = FakeLlm(fallback: 'You spent Rs 99999! {"metric":"total","direction":"debit","category":"Food & Dining","merchant":null,"period":"last_month"}');
      final a = await SpendingAssistant(llm: llm, clock: () => now).ask('food last month?', data);
      expect(a.intent.source, 'llm');
      expect(a.text, 'You spent ₹500.00 on Food & Dining in Feb 2024, across 1 transaction.');
      expect(a.text, isNot(contains('99999')));
      expect(llm.prompts.single, contains('Do not answer the question'));
    });

    test('invalid JSON fields fall back to the rules field by field', () async {
      final llm = FakeLlm(fallback: '{"metric":"sum_of_everything","category":"Crypto","period":"next_decade"}');
      final a = await SpendingAssistant(llm: llm, clock: () => now)
          .ask('How much did I spend on groceries this month?', data);
      expect(a.intent.query.metric, Metric.total);
      expect(a.intent.query.category, 'Groceries');
      expect(a.result.totalPaise, 120000);
    });

    test('garbage output means rules', () async {
      final a = await SpendingAssistant(llm: FakeLlm(fallback: 'sorry, I cannot help'), clock: () => now)
          .ask('how much on swiggy this month', data);
      expect(a.intent.source, 'rules');
      expect(a.result.totalPaise, 60000);
    });

    test('month + custom periods from the model are resolved in Dart', () async {
      final month = FakeLlm(fallback: '```json\n{"metric":"largest","period":"month","month":2}\n```');
      final a = await SpendingAssistant(llm: month, clock: () => now).ask('biggest in feb', data);
      expect(a.text, 'Your largest payment in Feb 2024 was ₹2,999.00 to Amazon on 20 Feb 2024.');

      final custom = FakeLlm(fallback: '{"metric":"count","period":"custom","start":"2024-03-01","end":"2024-03-10"}');
      final b = await SpendingAssistant(llm: custom, clock: () => now).ask('how many between 1 and 10 march', data);
      expect(b.result.count, 3); // Swiggy 2nd, BigBasket 5th, Zomato 10th
    });

    test('average, top merchants, breakdown, income, empty', () async {
      final s = SpendingAssistant(llm: FakeLlm(ready: false), clock: () => now);
      expect((await s.ask('average food spend this month', data)).text,
          'Your average spend on Food & Dining this month was ₹333.33 per transaction (3 transactions, ₹1,000.00 total).');
      expect((await s.ask('where did I spend the most this month', data)).text,
          'Your top merchants this month: BigBasket ₹1,200.00, Swiggy ₹600.00, Zomato ₹400.00. Total ₹2,500.00 across 5 transactions.');
      expect((await s.ask('breakdown by category this month', data)).result.ranked.first, ('Groceries', 120000));
      expect((await s.ask('how much did I earn this month', data)).text,
          'You received ₹85,000.00 this month, across 1 transaction.');
      expect((await s.ask('how much on travel this month', data)).text,
          'I found no spending on Travel this month.');
    });
  });

  test('extractJsonObject handles fences, prose and nested braces', () {
    expect(extractJsonObject('x {"a":{"b":1}} y'), {'a': {'b': 1}});
    expect(extractJsonObject('{"s":"}"}'), {'s': '}'});
    expect(extractJsonObject('no json'), isNull);
    expect(extractJsonObject('{broken'), isNull);
  });
}
