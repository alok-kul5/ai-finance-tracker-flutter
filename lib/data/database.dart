import 'package:drift/drift.dart';

part 'database.g.dart';

@DataClassName('TxnRow')
class Txns extends Table {
  TextColumn get id => text()();
  IntColumn get amountPaise => integer()();
  TextColumn get direction => text()(); // debit | credit
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get merchant => text()();
  TextColumn get category => text()();
  TextColumn get categorySource => text().withDefault(const Constant('rule'))();
  TextColumn get source => text()(); // sms | receipt | manual
  TextColumn get note => text().nullable()();
  TextColumn get reference => text().nullable()();
  TextColumn get account => text().nullable()();
  IntColumn get updatedAt => integer()(); // ms since epoch
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BudgetRow')
class Budgets extends Table {
  TextColumn get category => text()();
  IntColumn get limitPaise => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {category};
}

@DataClassName('MerchantMemoryRow')
class MerchantMemories extends Table {
  TextColumn get merchantKey => text()();
  TextColumn get category => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {merchantKey};
}

@DataClassName('OutboxRow')
class Outbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get kind => text()();
  TextColumn get recordId => text()();
}

@DataClassName('KvRow')
class Kv extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Txns, Budgets, MerchantMemories, Outbox, Kv])
class KharchaDatabase extends _$KharchaDatabase {
  KharchaDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement('CREATE INDEX IF NOT EXISTS txns_occurred ON txns (occurred_at)');
          await customStatement('CREATE INDEX IF NOT EXISTS txns_reference ON txns (reference)');
        },
      );
}
