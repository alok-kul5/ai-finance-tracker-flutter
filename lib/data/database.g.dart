// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TxnsTable extends Txns with TableInfo<$TxnsTable, TxnRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TxnsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categorySourceMeta = const VerificationMeta(
    'categorySource',
  );
  @override
  late final GeneratedColumn<String> categorySource = GeneratedColumn<String>(
    'category_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('rule'),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountMeta = const VerificationMeta(
    'account',
  );
  @override
  late final GeneratedColumn<String> account = GeneratedColumn<String>(
    'account',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amountPaise,
    direction,
    occurredAt,
    merchant,
    category,
    categorySource,
    source,
    note,
    reference,
    account,
    updatedAt,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'txns';
  @override
  VerificationContext validateIntegrity(
    Insertable<TxnRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    } else if (isInserting) {
      context.missing(_merchantMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('category_source')) {
      context.handle(
        _categorySourceMeta,
        categorySource.isAcceptableOrUnknown(
          data['category_source']!,
          _categorySourceMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    if (data.containsKey('account')) {
      context.handle(
        _accountMeta,
        account.isAcceptableOrUnknown(data['account']!, _accountMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TxnRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TxnRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      categorySource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_source'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      ),
      account: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $TxnsTable createAlias(String alias) {
    return $TxnsTable(attachedDatabase, alias);
  }
}

class TxnRow extends DataClass implements Insertable<TxnRow> {
  final String id;
  final int amountPaise;
  final String direction;
  final DateTime occurredAt;
  final String merchant;
  final String category;
  final String categorySource;
  final String source;
  final String? note;
  final String? reference;
  final String? account;
  final int updatedAt;
  final bool deleted;
  const TxnRow({
    required this.id,
    required this.amountPaise,
    required this.direction,
    required this.occurredAt,
    required this.merchant,
    required this.category,
    required this.categorySource,
    required this.source,
    this.note,
    this.reference,
    this.account,
    required this.updatedAt,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['direction'] = Variable<String>(direction);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['merchant'] = Variable<String>(merchant);
    map['category'] = Variable<String>(category);
    map['category_source'] = Variable<String>(categorySource);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    if (!nullToAbsent || account != null) {
      map['account'] = Variable<String>(account);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  TxnsCompanion toCompanion(bool nullToAbsent) {
    return TxnsCompanion(
      id: Value(id),
      amountPaise: Value(amountPaise),
      direction: Value(direction),
      occurredAt: Value(occurredAt),
      merchant: Value(merchant),
      category: Value(category),
      categorySource: Value(categorySource),
      source: Value(source),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      account: account == null && nullToAbsent
          ? const Value.absent()
          : Value(account),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
    );
  }

  factory TxnRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TxnRow(
      id: serializer.fromJson<String>(json['id']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      direction: serializer.fromJson<String>(json['direction']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      merchant: serializer.fromJson<String>(json['merchant']),
      category: serializer.fromJson<String>(json['category']),
      categorySource: serializer.fromJson<String>(json['categorySource']),
      source: serializer.fromJson<String>(json['source']),
      note: serializer.fromJson<String?>(json['note']),
      reference: serializer.fromJson<String?>(json['reference']),
      account: serializer.fromJson<String?>(json['account']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'direction': serializer.toJson<String>(direction),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'merchant': serializer.toJson<String>(merchant),
      'category': serializer.toJson<String>(category),
      'categorySource': serializer.toJson<String>(categorySource),
      'source': serializer.toJson<String>(source),
      'note': serializer.toJson<String?>(note),
      'reference': serializer.toJson<String?>(reference),
      'account': serializer.toJson<String?>(account),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  TxnRow copyWith({
    String? id,
    int? amountPaise,
    String? direction,
    DateTime? occurredAt,
    String? merchant,
    String? category,
    String? categorySource,
    String? source,
    Value<String?> note = const Value.absent(),
    Value<String?> reference = const Value.absent(),
    Value<String?> account = const Value.absent(),
    int? updatedAt,
    bool? deleted,
  }) => TxnRow(
    id: id ?? this.id,
    amountPaise: amountPaise ?? this.amountPaise,
    direction: direction ?? this.direction,
    occurredAt: occurredAt ?? this.occurredAt,
    merchant: merchant ?? this.merchant,
    category: category ?? this.category,
    categorySource: categorySource ?? this.categorySource,
    source: source ?? this.source,
    note: note.present ? note.value : this.note,
    reference: reference.present ? reference.value : this.reference,
    account: account.present ? account.value : this.account,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
  );
  TxnRow copyWithCompanion(TxnsCompanion data) {
    return TxnRow(
      id: data.id.present ? data.id.value : this.id,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      direction: data.direction.present ? data.direction.value : this.direction,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      category: data.category.present ? data.category.value : this.category,
      categorySource: data.categorySource.present
          ? data.categorySource.value
          : this.categorySource,
      source: data.source.present ? data.source.value : this.source,
      note: data.note.present ? data.note.value : this.note,
      reference: data.reference.present ? data.reference.value : this.reference,
      account: data.account.present ? data.account.value : this.account,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TxnRow(')
          ..write('id: $id, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('direction: $direction, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('merchant: $merchant, ')
          ..write('category: $category, ')
          ..write('categorySource: $categorySource, ')
          ..write('source: $source, ')
          ..write('note: $note, ')
          ..write('reference: $reference, ')
          ..write('account: $account, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    amountPaise,
    direction,
    occurredAt,
    merchant,
    category,
    categorySource,
    source,
    note,
    reference,
    account,
    updatedAt,
    deleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TxnRow &&
          other.id == this.id &&
          other.amountPaise == this.amountPaise &&
          other.direction == this.direction &&
          other.occurredAt == this.occurredAt &&
          other.merchant == this.merchant &&
          other.category == this.category &&
          other.categorySource == this.categorySource &&
          other.source == this.source &&
          other.note == this.note &&
          other.reference == this.reference &&
          other.account == this.account &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted);
}

class TxnsCompanion extends UpdateCompanion<TxnRow> {
  final Value<String> id;
  final Value<int> amountPaise;
  final Value<String> direction;
  final Value<DateTime> occurredAt;
  final Value<String> merchant;
  final Value<String> category;
  final Value<String> categorySource;
  final Value<String> source;
  final Value<String?> note;
  final Value<String?> reference;
  final Value<String?> account;
  final Value<int> updatedAt;
  final Value<bool> deleted;
  final Value<int> rowid;
  const TxnsCompanion({
    this.id = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.direction = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.merchant = const Value.absent(),
    this.category = const Value.absent(),
    this.categorySource = const Value.absent(),
    this.source = const Value.absent(),
    this.note = const Value.absent(),
    this.reference = const Value.absent(),
    this.account = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TxnsCompanion.insert({
    required String id,
    required int amountPaise,
    required String direction,
    required DateTime occurredAt,
    required String merchant,
    required String category,
    this.categorySource = const Value.absent(),
    required String source,
    this.note = const Value.absent(),
    this.reference = const Value.absent(),
    this.account = const Value.absent(),
    required int updatedAt,
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       amountPaise = Value(amountPaise),
       direction = Value(direction),
       occurredAt = Value(occurredAt),
       merchant = Value(merchant),
       category = Value(category),
       source = Value(source),
       updatedAt = Value(updatedAt);
  static Insertable<TxnRow> custom({
    Expression<String>? id,
    Expression<int>? amountPaise,
    Expression<String>? direction,
    Expression<DateTime>? occurredAt,
    Expression<String>? merchant,
    Expression<String>? category,
    Expression<String>? categorySource,
    Expression<String>? source,
    Expression<String>? note,
    Expression<String>? reference,
    Expression<String>? account,
    Expression<int>? updatedAt,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (direction != null) 'direction': direction,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (merchant != null) 'merchant': merchant,
      if (category != null) 'category': category,
      if (categorySource != null) 'category_source': categorySource,
      if (source != null) 'source': source,
      if (note != null) 'note': note,
      if (reference != null) 'reference': reference,
      if (account != null) 'account': account,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TxnsCompanion copyWith({
    Value<String>? id,
    Value<int>? amountPaise,
    Value<String>? direction,
    Value<DateTime>? occurredAt,
    Value<String>? merchant,
    Value<String>? category,
    Value<String>? categorySource,
    Value<String>? source,
    Value<String?>? note,
    Value<String?>? reference,
    Value<String?>? account,
    Value<int>? updatedAt,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return TxnsCompanion(
      id: id ?? this.id,
      amountPaise: amountPaise ?? this.amountPaise,
      direction: direction ?? this.direction,
      occurredAt: occurredAt ?? this.occurredAt,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      categorySource: categorySource ?? this.categorySource,
      source: source ?? this.source,
      note: note ?? this.note,
      reference: reference ?? this.reference,
      account: account ?? this.account,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (categorySource.present) {
      map['category_source'] = Variable<String>(categorySource.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (account.present) {
      map['account'] = Variable<String>(account.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TxnsCompanion(')
          ..write('id: $id, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('direction: $direction, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('merchant: $merchant, ')
          ..write('category: $category, ')
          ..write('categorySource: $categorySource, ')
          ..write('source: $source, ')
          ..write('note: $note, ')
          ..write('reference: $reference, ')
          ..write('account: $account, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, BudgetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limitPaiseMeta = const VerificationMeta(
    'limitPaise',
  );
  @override
  late final GeneratedColumn<int> limitPaise = GeneratedColumn<int>(
    'limit_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    category,
    limitPaise,
    updatedAt,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('limit_paise')) {
      context.handle(
        _limitPaiseMeta,
        limitPaise.isAcceptableOrUnknown(data['limit_paise']!, _limitPaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_limitPaiseMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {category};
  @override
  BudgetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetRow(
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      limitPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_paise'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class BudgetRow extends DataClass implements Insertable<BudgetRow> {
  final String category;
  final int limitPaise;
  final int updatedAt;
  final bool deleted;
  const BudgetRow({
    required this.category,
    required this.limitPaise,
    required this.updatedAt,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['category'] = Variable<String>(category);
    map['limit_paise'] = Variable<int>(limitPaise);
    map['updated_at'] = Variable<int>(updatedAt);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      category: Value(category),
      limitPaise: Value(limitPaise),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
    );
  }

  factory BudgetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetRow(
      category: serializer.fromJson<String>(json['category']),
      limitPaise: serializer.fromJson<int>(json['limitPaise']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'category': serializer.toJson<String>(category),
      'limitPaise': serializer.toJson<int>(limitPaise),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  BudgetRow copyWith({
    String? category,
    int? limitPaise,
    int? updatedAt,
    bool? deleted,
  }) => BudgetRow(
    category: category ?? this.category,
    limitPaise: limitPaise ?? this.limitPaise,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
  );
  BudgetRow copyWithCompanion(BudgetsCompanion data) {
    return BudgetRow(
      category: data.category.present ? data.category.value : this.category,
      limitPaise: data.limitPaise.present
          ? data.limitPaise.value
          : this.limitPaise,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetRow(')
          ..write('category: $category, ')
          ..write('limitPaise: $limitPaise, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(category, limitPaise, updatedAt, deleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetRow &&
          other.category == this.category &&
          other.limitPaise == this.limitPaise &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted);
}

class BudgetsCompanion extends UpdateCompanion<BudgetRow> {
  final Value<String> category;
  final Value<int> limitPaise;
  final Value<int> updatedAt;
  final Value<bool> deleted;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.category = const Value.absent(),
    this.limitPaise = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String category,
    required int limitPaise,
    required int updatedAt,
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : category = Value(category),
       limitPaise = Value(limitPaise),
       updatedAt = Value(updatedAt);
  static Insertable<BudgetRow> custom({
    Expression<String>? category,
    Expression<int>? limitPaise,
    Expression<int>? updatedAt,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (category != null) 'category': category,
      if (limitPaise != null) 'limit_paise': limitPaise,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith({
    Value<String>? category,
    Value<int>? limitPaise,
    Value<int>? updatedAt,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return BudgetsCompanion(
      category: category ?? this.category,
      limitPaise: limitPaise ?? this.limitPaise,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (limitPaise.present) {
      map['limit_paise'] = Variable<int>(limitPaise.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('category: $category, ')
          ..write('limitPaise: $limitPaise, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MerchantMemoriesTable extends MerchantMemories
    with TableInfo<$MerchantMemoriesTable, MerchantMemoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MerchantMemoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _merchantKeyMeta = const VerificationMeta(
    'merchantKey',
  );
  @override
  late final GeneratedColumn<String> merchantKey = GeneratedColumn<String>(
    'merchant_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [merchantKey, category, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'merchant_memories';
  @override
  VerificationContext validateIntegrity(
    Insertable<MerchantMemoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('merchant_key')) {
      context.handle(
        _merchantKeyMeta,
        merchantKey.isAcceptableOrUnknown(
          data['merchant_key']!,
          _merchantKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_merchantKeyMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {merchantKey};
  @override
  MerchantMemoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MerchantMemoryRow(
      merchantKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_key'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MerchantMemoriesTable createAlias(String alias) {
    return $MerchantMemoriesTable(attachedDatabase, alias);
  }
}

class MerchantMemoryRow extends DataClass
    implements Insertable<MerchantMemoryRow> {
  final String merchantKey;
  final String category;
  final int updatedAt;
  const MerchantMemoryRow({
    required this.merchantKey,
    required this.category,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['merchant_key'] = Variable<String>(merchantKey);
    map['category'] = Variable<String>(category);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  MerchantMemoriesCompanion toCompanion(bool nullToAbsent) {
    return MerchantMemoriesCompanion(
      merchantKey: Value(merchantKey),
      category: Value(category),
      updatedAt: Value(updatedAt),
    );
  }

  factory MerchantMemoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MerchantMemoryRow(
      merchantKey: serializer.fromJson<String>(json['merchantKey']),
      category: serializer.fromJson<String>(json['category']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'merchantKey': serializer.toJson<String>(merchantKey),
      'category': serializer.toJson<String>(category),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  MerchantMemoryRow copyWith({
    String? merchantKey,
    String? category,
    int? updatedAt,
  }) => MerchantMemoryRow(
    merchantKey: merchantKey ?? this.merchantKey,
    category: category ?? this.category,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MerchantMemoryRow copyWithCompanion(MerchantMemoriesCompanion data) {
    return MerchantMemoryRow(
      merchantKey: data.merchantKey.present
          ? data.merchantKey.value
          : this.merchantKey,
      category: data.category.present ? data.category.value : this.category,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MerchantMemoryRow(')
          ..write('merchantKey: $merchantKey, ')
          ..write('category: $category, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(merchantKey, category, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MerchantMemoryRow &&
          other.merchantKey == this.merchantKey &&
          other.category == this.category &&
          other.updatedAt == this.updatedAt);
}

class MerchantMemoriesCompanion extends UpdateCompanion<MerchantMemoryRow> {
  final Value<String> merchantKey;
  final Value<String> category;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const MerchantMemoriesCompanion({
    this.merchantKey = const Value.absent(),
    this.category = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MerchantMemoriesCompanion.insert({
    required String merchantKey,
    required String category,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : merchantKey = Value(merchantKey),
       category = Value(category),
       updatedAt = Value(updatedAt);
  static Insertable<MerchantMemoryRow> custom({
    Expression<String>? merchantKey,
    Expression<String>? category,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (merchantKey != null) 'merchant_key': merchantKey,
      if (category != null) 'category': category,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MerchantMemoriesCompanion copyWith({
    Value<String>? merchantKey,
    Value<String>? category,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return MerchantMemoriesCompanion(
      merchantKey: merchantKey ?? this.merchantKey,
      category: category ?? this.category,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (merchantKey.present) {
      map['merchant_key'] = Variable<String>(merchantKey.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MerchantMemoriesCompanion(')
          ..write('merchantKey: $merchantKey, ')
          ..write('category: $category, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [seq, kind, recordId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final int seq;
  final String kind;
  final String recordId;
  const OutboxRow({
    required this.seq,
    required this.kind,
    required this.recordId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['kind'] = Variable<String>(kind);
    map['record_id'] = Variable<String>(recordId);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      seq: Value(seq),
      kind: Value(kind),
      recordId: Value(recordId),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      seq: serializer.fromJson<int>(json['seq']),
      kind: serializer.fromJson<String>(json['kind']),
      recordId: serializer.fromJson<String>(json['recordId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'kind': serializer.toJson<String>(kind),
      'recordId': serializer.toJson<String>(recordId),
    };
  }

  OutboxRow copyWith({int? seq, String? kind, String? recordId}) => OutboxRow(
    seq: seq ?? this.seq,
    kind: kind ?? this.kind,
    recordId: recordId ?? this.recordId,
  );
  OutboxRow copyWithCompanion(OutboxCompanion data) {
    return OutboxRow(
      seq: data.seq.present ? data.seq.value : this.seq,
      kind: data.kind.present ? data.kind.value : this.kind,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('seq: $seq, ')
          ..write('kind: $kind, ')
          ..write('recordId: $recordId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(seq, kind, recordId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.seq == this.seq &&
          other.kind == this.kind &&
          other.recordId == this.recordId);
}

class OutboxCompanion extends UpdateCompanion<OutboxRow> {
  final Value<int> seq;
  final Value<String> kind;
  final Value<String> recordId;
  const OutboxCompanion({
    this.seq = const Value.absent(),
    this.kind = const Value.absent(),
    this.recordId = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.seq = const Value.absent(),
    required String kind,
    required String recordId,
  }) : kind = Value(kind),
       recordId = Value(recordId);
  static Insertable<OutboxRow> custom({
    Expression<int>? seq,
    Expression<String>? kind,
    Expression<String>? recordId,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (kind != null) 'kind': kind,
      if (recordId != null) 'record_id': recordId,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? seq,
    Value<String>? kind,
    Value<String>? recordId,
  }) {
    return OutboxCompanion(
      seq: seq ?? this.seq,
      kind: kind ?? this.kind,
      recordId: recordId ?? this.recordId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('seq: $seq, ')
          ..write('kind: $kind, ')
          ..write('recordId: $recordId')
          ..write(')'))
        .toString();
  }
}

class $KvTable extends Kv with TableInfo<$KvTable, KvRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KvTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kv';
  @override
  VerificationContext validateIntegrity(
    Insertable<KvRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KvRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KvRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KvTable createAlias(String alias) {
    return $KvTable(attachedDatabase, alias);
  }
}

class KvRow extends DataClass implements Insertable<KvRow> {
  final String key;
  final String value;
  const KvRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KvCompanion toCompanion(bool nullToAbsent) {
    return KvCompanion(key: Value(key), value: Value(value));
  }

  factory KvRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KvRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KvRow copyWith({String? key, String? value}) =>
      KvRow(key: key ?? this.key, value: value ?? this.value);
  KvRow copyWithCompanion(KvCompanion data) {
    return KvRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KvRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KvRow && other.key == this.key && other.value == this.value);
}

class KvCompanion extends UpdateCompanion<KvRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KvCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KvCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KvRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KvCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KvCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KvCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$KharchaDatabase extends GeneratedDatabase {
  _$KharchaDatabase(QueryExecutor e) : super(e);
  $KharchaDatabaseManager get managers => $KharchaDatabaseManager(this);
  late final $TxnsTable txns = $TxnsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $MerchantMemoriesTable merchantMemories = $MerchantMemoriesTable(
    this,
  );
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $KvTable kv = $KvTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    txns,
    budgets,
    merchantMemories,
    outbox,
    kv,
  ];
}

typedef $$TxnsTableCreateCompanionBuilder = TxnsCompanion Function({
  required String id,
  required int amountPaise,
  required String direction,
  required DateTime occurredAt,
  required String merchant,
  required String category,
  Value<String> categorySource,
  required String source,
  Value<String?> note,
  Value<String?> reference,
  Value<String?> account,
  required int updatedAt,
  Value<bool> deleted,
  Value<int> rowid,
});
typedef $$TxnsTableUpdateCompanionBuilder = TxnsCompanion Function({
  Value<String> id,
  Value<int> amountPaise,
  Value<String> direction,
  Value<DateTime> occurredAt,
  Value<String> merchant,
  Value<String> category,
  Value<String> categorySource,
  Value<String> source,
  Value<String?> note,
  Value<String?> reference,
  Value<String?> account,
  Value<int> updatedAt,
  Value<bool> deleted,
  Value<int> rowid,
});

class $$TxnsTableFilterComposer
    extends Composer<_$KharchaDatabase, $TxnsTable> {
  $$TxnsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categorySource => $composableBuilder(
    column: $table.categorySource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TxnsTableOrderingComposer
    extends Composer<_$KharchaDatabase, $TxnsTable> {
  $$TxnsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categorySource => $composableBuilder(
    column: $table.categorySource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TxnsTableAnnotationComposer
    extends Composer<_$KharchaDatabase, $TxnsTable> {
  $$TxnsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get categorySource => $composableBuilder(
    column: $table.categorySource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get account =>
      $composableBuilder(column: $table.account, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$TxnsTableTableManager
    extends
        RootTableManager<
          _$KharchaDatabase,
          $TxnsTable,
          TxnRow,
          $$TxnsTableFilterComposer,
          $$TxnsTableOrderingComposer,
          $$TxnsTableAnnotationComposer,
          $$TxnsTableCreateCompanionBuilder,
          $$TxnsTableUpdateCompanionBuilder,
          (TxnRow, BaseReferences<_$KharchaDatabase, $TxnsTable, TxnRow>),
          TxnRow,
          PrefetchHooks Function()
        > {
  $$TxnsTableTableManager(_$KharchaDatabase db, $TxnsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TxnsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TxnsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TxnsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String> merchant = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> categorySource = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> account = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TxnsCompanion(
                id: id,
                amountPaise: amountPaise,
                direction: direction,
                occurredAt: occurredAt,
                merchant: merchant,
                category: category,
                categorySource: categorySource,
                source: source,
                note: note,
                reference: reference,
                account: account,
                updatedAt: updatedAt,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int amountPaise,
                required String direction,
                required DateTime occurredAt,
                required String merchant,
                required String category,
                Value<String> categorySource = const Value.absent(),
                required String source,
                Value<String?> note = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> account = const Value.absent(),
                required int updatedAt,
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TxnsCompanion.insert(
                id: id,
                amountPaise: amountPaise,
                direction: direction,
                occurredAt: occurredAt,
                merchant: merchant,
                category: category,
                categorySource: categorySource,
                source: source,
                note: note,
                reference: reference,
                account: account,
                updatedAt: updatedAt,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TxnsTable, TxnRow>(table),
                  BaseReferences<_$KharchaDatabase, $TxnsTable, TxnRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TxnsTableProcessedTableManager =
    ProcessedTableManager<
      _$KharchaDatabase,
      $TxnsTable,
      TxnRow,
      $$TxnsTableFilterComposer,
      $$TxnsTableOrderingComposer,
      $$TxnsTableAnnotationComposer,
      $$TxnsTableCreateCompanionBuilder,
      $$TxnsTableUpdateCompanionBuilder,
      (TxnRow, BaseReferences<_$KharchaDatabase, $TxnsTable, TxnRow>),
      TxnRow,
      PrefetchHooks Function()
    >;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  required String category,
  required int limitPaise,
  required int updatedAt,
  Value<bool> deleted,
  Value<int> rowid,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<String> category,
  Value<int> limitPaise,
  Value<int> updatedAt,
  Value<bool> deleted,
  Value<int> rowid,
});

class $$BudgetsTableFilterComposer
    extends Composer<_$KharchaDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitPaise => $composableBuilder(
    column: $table.limitPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$KharchaDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitPaise => $composableBuilder(
    column: $table.limitPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$KharchaDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get limitPaise => $composableBuilder(
    column: $table.limitPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$KharchaDatabase,
          $BudgetsTable,
          BudgetRow,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (
            BudgetRow,
            BaseReferences<_$KharchaDatabase, $BudgetsTable, BudgetRow>,
          ),
          BudgetRow,
          PrefetchHooks Function()
        > {
  $$BudgetsTableTableManager(_$KharchaDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> category = const Value.absent(),
                Value<int> limitPaise = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion(
                category: category,
                limitPaise: limitPaise,
                updatedAt: updatedAt,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String category,
                required int limitPaise,
                required int updatedAt,
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion.insert(
                category: category,
                limitPaise: limitPaise,
                updatedAt: updatedAt,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetsTable, BudgetRow>(table),
                  BaseReferences<_$KharchaDatabase, $BudgetsTable, BudgetRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$KharchaDatabase,
      $BudgetsTable,
      BudgetRow,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (BudgetRow, BaseReferences<_$KharchaDatabase, $BudgetsTable, BudgetRow>),
      BudgetRow,
      PrefetchHooks Function()
    >;
typedef $$MerchantMemoriesTableCreateCompanionBuilder =
    MerchantMemoriesCompanion Function({
      required String merchantKey,
      required String category,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$MerchantMemoriesTableUpdateCompanionBuilder =
    MerchantMemoriesCompanion Function({
      Value<String> merchantKey,
      Value<String> category,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$MerchantMemoriesTableFilterComposer
    extends Composer<_$KharchaDatabase, $MerchantMemoriesTable> {
  $$MerchantMemoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get merchantKey => $composableBuilder(
    column: $table.merchantKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MerchantMemoriesTableOrderingComposer
    extends Composer<_$KharchaDatabase, $MerchantMemoriesTable> {
  $$MerchantMemoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get merchantKey => $composableBuilder(
    column: $table.merchantKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MerchantMemoriesTableAnnotationComposer
    extends Composer<_$KharchaDatabase, $MerchantMemoriesTable> {
  $$MerchantMemoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get merchantKey => $composableBuilder(
    column: $table.merchantKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MerchantMemoriesTableTableManager
    extends
        RootTableManager<
          _$KharchaDatabase,
          $MerchantMemoriesTable,
          MerchantMemoryRow,
          $$MerchantMemoriesTableFilterComposer,
          $$MerchantMemoriesTableOrderingComposer,
          $$MerchantMemoriesTableAnnotationComposer,
          $$MerchantMemoriesTableCreateCompanionBuilder,
          $$MerchantMemoriesTableUpdateCompanionBuilder,
          (
            MerchantMemoryRow,
            BaseReferences<
              _$KharchaDatabase,
              $MerchantMemoriesTable,
              MerchantMemoryRow
            >,
          ),
          MerchantMemoryRow,
          PrefetchHooks Function()
        > {
  $$MerchantMemoriesTableTableManager(
    _$KharchaDatabase db,
    $MerchantMemoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MerchantMemoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MerchantMemoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MerchantMemoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> merchantKey = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MerchantMemoriesCompanion(
                merchantKey: merchantKey,
                category: category,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String merchantKey,
                required String category,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MerchantMemoriesCompanion.insert(
                merchantKey: merchantKey,
                category: category,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MerchantMemoriesTable, MerchantMemoryRow>(table),
                  BaseReferences<
                    _$KharchaDatabase,
                    $MerchantMemoriesTable,
                    MerchantMemoryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MerchantMemoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$KharchaDatabase,
      $MerchantMemoriesTable,
      MerchantMemoryRow,
      $$MerchantMemoriesTableFilterComposer,
      $$MerchantMemoriesTableOrderingComposer,
      $$MerchantMemoriesTableAnnotationComposer,
      $$MerchantMemoriesTableCreateCompanionBuilder,
      $$MerchantMemoriesTableUpdateCompanionBuilder,
      (
        MerchantMemoryRow,
        BaseReferences<
          _$KharchaDatabase,
          $MerchantMemoriesTable,
          MerchantMemoryRow
        >,
      ),
      MerchantMemoryRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  Value<int> seq,
  required String kind,
  required String recordId,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<int> seq,
  Value<String> kind,
  Value<String> recordId,
});

class $$OutboxTableFilterComposer
    extends Composer<_$KharchaDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$KharchaDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$KharchaDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$KharchaDatabase,
          $OutboxTable,
          OutboxRow,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (
            OutboxRow,
            BaseReferences<_$KharchaDatabase, $OutboxTable, OutboxRow>,
          ),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$KharchaDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> seq = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> recordId = const Value.absent(),
          }) => OutboxCompanion(seq: seq, kind: kind, recordId: recordId),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String kind,
                required String recordId,
              }) => OutboxCompanion.insert(
                seq: seq,
                kind: kind,
                recordId: recordId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxRow>(table),
                  BaseReferences<_$KharchaDatabase, $OutboxTable, OutboxRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$KharchaDatabase,
      $OutboxTable,
      OutboxRow,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$KharchaDatabase, $OutboxTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;
typedef $$KvTableCreateCompanionBuilder = KvCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$KvTableUpdateCompanionBuilder = KvCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$KvTableFilterComposer extends Composer<_$KharchaDatabase, $KvTable> {
  $$KvTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KvTableOrderingComposer extends Composer<_$KharchaDatabase, $KvTable> {
  $$KvTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KvTableAnnotationComposer
    extends Composer<_$KharchaDatabase, $KvTable> {
  $$KvTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KvTableTableManager
    extends
        RootTableManager<
          _$KharchaDatabase,
          $KvTable,
          KvRow,
          $$KvTableFilterComposer,
          $$KvTableOrderingComposer,
          $$KvTableAnnotationComposer,
          $$KvTableCreateCompanionBuilder,
          $$KvTableUpdateCompanionBuilder,
          (KvRow, BaseReferences<_$KharchaDatabase, $KvTable, KvRow>),
          KvRow,
          PrefetchHooks Function()
        > {
  $$KvTableTableManager(_$KharchaDatabase db, $KvTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KvTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KvTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KvTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KvCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => KvCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KvTable, KvRow>(table),
                  BaseReferences<_$KharchaDatabase, $KvTable, KvRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KvTableProcessedTableManager =
    ProcessedTableManager<
      _$KharchaDatabase,
      $KvTable,
      KvRow,
      $$KvTableFilterComposer,
      $$KvTableOrderingComposer,
      $$KvTableAnnotationComposer,
      $$KvTableCreateCompanionBuilder,
      $$KvTableUpdateCompanionBuilder,
      (KvRow, BaseReferences<_$KharchaDatabase, $KvTable, KvRow>),
      KvRow,
      PrefetchHooks Function()
    >;

class $KharchaDatabaseManager {
  final _$KharchaDatabase _db;
  $KharchaDatabaseManager(this._db);
  $$TxnsTableTableManager get txns => $$TxnsTableTableManager(_db, _db.txns);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$MerchantMemoriesTableTableManager get merchantMemories =>
      $$MerchantMemoriesTableTableManager(_db, _db.merchantMemories);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$KvTableTableManager get kv => $$KvTableTableManager(_db, _db.kv);
}
