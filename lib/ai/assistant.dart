import '../domain/models.dart';
import 'intent_parser.dart';
import 'llm.dart';
import 'query.dart';
import 'query_engine.dart';

class AssistantAnswer {
  const AssistantAnswer({
    required this.question,
    required this.text,
    required this.intent,
    required this.result,
  });

  final String question;
  final String text;
  final ParsedIntent intent;
  final QueryResult result;
}

/// Question → structured query (LLM or rules) → numbers (Dart) → template.
class SpendingAssistant {
  SpendingAssistant({required LlmClient llm, DateTime Function()? clock})
      : _parser = LlmIntentParser(llm: llm),
        _clock = clock ?? DateTime.now;

  final LlmIntentParser _parser;
  final DateTime Function() _clock;
  final _engine = const QueryEngine();
  final _composer = const AnswerComposer();

  Future<AssistantAnswer> ask(String question, List<Txn> txns) async {
    final merchants = {for (final t in txns) t.merchant};
    final intent = await _parser.parse(question, now: _clock(), knownMerchants: merchants);
    final result = _engine.run(intent.query, txns);
    return AssistantAnswer(
      question: question,
      text: _composer.compose(result),
      intent: intent,
      result: result,
    );
  }

  /// A one-line, human description of how the question was read.
  static String describe(SpendQuery q) {
    final parts = <String>[
      switch (q.metric) {
        Metric.total => 'total',
        Metric.count => 'count',
        Metric.average => 'average',
        Metric.largest => 'largest',
        Metric.topMerchants => 'top merchants',
        Metric.byCategory => 'by category',
      },
      q.direction == TxnDirection.debit ? 'spending' : 'income',
      if (q.category != null) q.category!,
      if (q.merchant != null) q.merchant!,
      q.range.label,
    ];
    return parts.join(' · ');
  }
}
