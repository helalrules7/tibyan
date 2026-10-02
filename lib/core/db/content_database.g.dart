// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_database.dart';

// ignore_for_file: type=lint
class $SurahTable extends Surah with TableInfo<$SurahTable, SurahRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurahTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningEnMeta = const VerificationMeta(
    'meaningEn',
  );
  @override
  late final GeneratedColumn<String> meaningEn = GeneratedColumn<String>(
    'meaning_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revelationMeta = const VerificationMeta(
    'revelation',
  );
  @override
  late final GeneratedColumn<String> revelation = GeneratedColumn<String>(
    'revelation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revelationOrderMeta = const VerificationMeta(
    'revelationOrder',
  );
  @override
  late final GeneratedColumn<int> revelationOrder = GeneratedColumn<int>(
    'revelation_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahCountMeta = const VerificationMeta(
    'ayahCount',
  );
  @override
  late final GeneratedColumn<int> ayahCount = GeneratedColumn<int>(
    'ayah_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startPageMeta = const VerificationMeta(
    'startPage',
  );
  @override
  late final GeneratedColumn<int> startPage = GeneratedColumn<int>(
    'start_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startPage1405Meta = const VerificationMeta(
    'startPage1405',
  );
  @override
  late final GeneratedColumn<int> startPage1405 = GeneratedColumn<int>(
    'start_page_1405',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startPageShamarlyMeta = const VerificationMeta(
    'startPageShamarly',
  );
  @override
  late final GeneratedColumn<int> startPageShamarly = GeneratedColumn<int>(
    'start_page_shamarly',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nameAr,
    nameEn,
    meaningEn,
    revelation,
    revelationOrder,
    ayahCount,
    startPage,
    startPage1405,
    sourceId,
    startPageShamarly,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surah';
  @override
  VerificationContext validateIntegrity(
    Insertable<SurahRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    } else if (isInserting) {
      context.missing(_nameArMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('meaning_en')) {
      context.handle(
        _meaningEnMeta,
        meaningEn.isAcceptableOrUnknown(data['meaning_en']!, _meaningEnMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningEnMeta);
    }
    if (data.containsKey('revelation')) {
      context.handle(
        _revelationMeta,
        revelation.isAcceptableOrUnknown(data['revelation']!, _revelationMeta),
      );
    } else if (isInserting) {
      context.missing(_revelationMeta);
    }
    if (data.containsKey('revelation_order')) {
      context.handle(
        _revelationOrderMeta,
        revelationOrder.isAcceptableOrUnknown(
          data['revelation_order']!,
          _revelationOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_revelationOrderMeta);
    }
    if (data.containsKey('ayah_count')) {
      context.handle(
        _ayahCountMeta,
        ayahCount.isAcceptableOrUnknown(data['ayah_count']!, _ayahCountMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahCountMeta);
    }
    if (data.containsKey('start_page')) {
      context.handle(
        _startPageMeta,
        startPage.isAcceptableOrUnknown(data['start_page']!, _startPageMeta),
      );
    } else if (isInserting) {
      context.missing(_startPageMeta);
    }
    if (data.containsKey('start_page_1405')) {
      context.handle(
        _startPage1405Meta,
        startPage1405.isAcceptableOrUnknown(
          data['start_page_1405']!,
          _startPage1405Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startPage1405Meta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('start_page_shamarly')) {
      context.handle(
        _startPageShamarlyMeta,
        startPageShamarly.isAcceptableOrUnknown(
          data['start_page_shamarly']!,
          _startPageShamarlyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startPageShamarlyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SurahRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurahRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      meaningEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning_en'],
      )!,
      revelation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revelation'],
      )!,
      revelationOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revelation_order'],
      )!,
      ayahCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_count'],
      )!,
      startPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_page'],
      )!,
      startPage1405: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_page_1405'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      startPageShamarly: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_page_shamarly'],
      )!,
    );
  }

  @override
  $SurahTable createAlias(String alias) {
    return $SurahTable(attachedDatabase, alias);
  }
}

class SurahRow extends DataClass implements Insertable<SurahRow> {
  final int id;
  final String nameAr;
  final String nameEn;
  final String meaningEn;
  final String revelation;
  final int revelationOrder;
  final int ayahCount;

  /// First page in the new edition (1441H).
  final int startPage;

  /// First page in the old edition (1405H).
  final int startPage1405;
  final int sourceId;

  /// Page of verse 1 in the Shamarly (Egyptian) edition.
  final int startPageShamarly;
  const SurahRow({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.meaningEn,
    required this.revelation,
    required this.revelationOrder,
    required this.ayahCount,
    required this.startPage,
    required this.startPage1405,
    required this.sourceId,
    required this.startPageShamarly,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name_ar'] = Variable<String>(nameAr);
    map['name_en'] = Variable<String>(nameEn);
    map['meaning_en'] = Variable<String>(meaningEn);
    map['revelation'] = Variable<String>(revelation);
    map['revelation_order'] = Variable<int>(revelationOrder);
    map['ayah_count'] = Variable<int>(ayahCount);
    map['start_page'] = Variable<int>(startPage);
    map['start_page_1405'] = Variable<int>(startPage1405);
    map['source_id'] = Variable<int>(sourceId);
    map['start_page_shamarly'] = Variable<int>(startPageShamarly);
    return map;
  }

  SurahCompanion toCompanion(bool nullToAbsent) {
    return SurahCompanion(
      id: Value(id),
      nameAr: Value(nameAr),
      nameEn: Value(nameEn),
      meaningEn: Value(meaningEn),
      revelation: Value(revelation),
      revelationOrder: Value(revelationOrder),
      ayahCount: Value(ayahCount),
      startPage: Value(startPage),
      startPage1405: Value(startPage1405),
      sourceId: Value(sourceId),
      startPageShamarly: Value(startPageShamarly),
    );
  }

  factory SurahRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurahRow(
      id: serializer.fromJson<int>(json['id']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      meaningEn: serializer.fromJson<String>(json['meaningEn']),
      revelation: serializer.fromJson<String>(json['revelation']),
      revelationOrder: serializer.fromJson<int>(json['revelationOrder']),
      ayahCount: serializer.fromJson<int>(json['ayahCount']),
      startPage: serializer.fromJson<int>(json['startPage']),
      startPage1405: serializer.fromJson<int>(json['startPage1405']),
      sourceId: serializer.fromJson<int>(json['sourceId']),
      startPageShamarly: serializer.fromJson<int>(json['startPageShamarly']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nameAr': serializer.toJson<String>(nameAr),
      'nameEn': serializer.toJson<String>(nameEn),
      'meaningEn': serializer.toJson<String>(meaningEn),
      'revelation': serializer.toJson<String>(revelation),
      'revelationOrder': serializer.toJson<int>(revelationOrder),
      'ayahCount': serializer.toJson<int>(ayahCount),
      'startPage': serializer.toJson<int>(startPage),
      'startPage1405': serializer.toJson<int>(startPage1405),
      'sourceId': serializer.toJson<int>(sourceId),
      'startPageShamarly': serializer.toJson<int>(startPageShamarly),
    };
  }

  SurahRow copyWith({
    int? id,
    String? nameAr,
    String? nameEn,
    String? meaningEn,
    String? revelation,
    int? revelationOrder,
    int? ayahCount,
    int? startPage,
    int? startPage1405,
    int? sourceId,
    int? startPageShamarly,
  }) => SurahRow(
    id: id ?? this.id,
    nameAr: nameAr ?? this.nameAr,
    nameEn: nameEn ?? this.nameEn,
    meaningEn: meaningEn ?? this.meaningEn,
    revelation: revelation ?? this.revelation,
    revelationOrder: revelationOrder ?? this.revelationOrder,
    ayahCount: ayahCount ?? this.ayahCount,
    startPage: startPage ?? this.startPage,
    startPage1405: startPage1405 ?? this.startPage1405,
    sourceId: sourceId ?? this.sourceId,
    startPageShamarly: startPageShamarly ?? this.startPageShamarly,
  );
  SurahRow copyWithCompanion(SurahCompanion data) {
    return SurahRow(
      id: data.id.present ? data.id.value : this.id,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      meaningEn: data.meaningEn.present ? data.meaningEn.value : this.meaningEn,
      revelation: data.revelation.present
          ? data.revelation.value
          : this.revelation,
      revelationOrder: data.revelationOrder.present
          ? data.revelationOrder.value
          : this.revelationOrder,
      ayahCount: data.ayahCount.present ? data.ayahCount.value : this.ayahCount,
      startPage: data.startPage.present ? data.startPage.value : this.startPage,
      startPage1405: data.startPage1405.present
          ? data.startPage1405.value
          : this.startPage1405,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      startPageShamarly: data.startPageShamarly.present
          ? data.startPageShamarly.value
          : this.startPageShamarly,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurahRow(')
          ..write('id: $id, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('meaningEn: $meaningEn, ')
          ..write('revelation: $revelation, ')
          ..write('revelationOrder: $revelationOrder, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('startPage: $startPage, ')
          ..write('startPage1405: $startPage1405, ')
          ..write('sourceId: $sourceId, ')
          ..write('startPageShamarly: $startPageShamarly')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nameAr,
    nameEn,
    meaningEn,
    revelation,
    revelationOrder,
    ayahCount,
    startPage,
    startPage1405,
    sourceId,
    startPageShamarly,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurahRow &&
          other.id == this.id &&
          other.nameAr == this.nameAr &&
          other.nameEn == this.nameEn &&
          other.meaningEn == this.meaningEn &&
          other.revelation == this.revelation &&
          other.revelationOrder == this.revelationOrder &&
          other.ayahCount == this.ayahCount &&
          other.startPage == this.startPage &&
          other.startPage1405 == this.startPage1405 &&
          other.sourceId == this.sourceId &&
          other.startPageShamarly == this.startPageShamarly);
}

class SurahCompanion extends UpdateCompanion<SurahRow> {
  final Value<int> id;
  final Value<String> nameAr;
  final Value<String> nameEn;
  final Value<String> meaningEn;
  final Value<String> revelation;
  final Value<int> revelationOrder;
  final Value<int> ayahCount;
  final Value<int> startPage;
  final Value<int> startPage1405;
  final Value<int> sourceId;
  final Value<int> startPageShamarly;
  const SurahCompanion({
    this.id = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.meaningEn = const Value.absent(),
    this.revelation = const Value.absent(),
    this.revelationOrder = const Value.absent(),
    this.ayahCount = const Value.absent(),
    this.startPage = const Value.absent(),
    this.startPage1405 = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.startPageShamarly = const Value.absent(),
  });
  SurahCompanion.insert({
    this.id = const Value.absent(),
    required String nameAr,
    required String nameEn,
    required String meaningEn,
    required String revelation,
    required int revelationOrder,
    required int ayahCount,
    required int startPage,
    required int startPage1405,
    required int sourceId,
    required int startPageShamarly,
  }) : nameAr = Value(nameAr),
       nameEn = Value(nameEn),
       meaningEn = Value(meaningEn),
       revelation = Value(revelation),
       revelationOrder = Value(revelationOrder),
       ayahCount = Value(ayahCount),
       startPage = Value(startPage),
       startPage1405 = Value(startPage1405),
       sourceId = Value(sourceId),
       startPageShamarly = Value(startPageShamarly);
  static Insertable<SurahRow> custom({
    Expression<int>? id,
    Expression<String>? nameAr,
    Expression<String>? nameEn,
    Expression<String>? meaningEn,
    Expression<String>? revelation,
    Expression<int>? revelationOrder,
    Expression<int>? ayahCount,
    Expression<int>? startPage,
    Expression<int>? startPage1405,
    Expression<int>? sourceId,
    Expression<int>? startPageShamarly,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameAr != null) 'name_ar': nameAr,
      if (nameEn != null) 'name_en': nameEn,
      if (meaningEn != null) 'meaning_en': meaningEn,
      if (revelation != null) 'revelation': revelation,
      if (revelationOrder != null) 'revelation_order': revelationOrder,
      if (ayahCount != null) 'ayah_count': ayahCount,
      if (startPage != null) 'start_page': startPage,
      if (startPage1405 != null) 'start_page_1405': startPage1405,
      if (sourceId != null) 'source_id': sourceId,
      if (startPageShamarly != null) 'start_page_shamarly': startPageShamarly,
    });
  }

  SurahCompanion copyWith({
    Value<int>? id,
    Value<String>? nameAr,
    Value<String>? nameEn,
    Value<String>? meaningEn,
    Value<String>? revelation,
    Value<int>? revelationOrder,
    Value<int>? ayahCount,
    Value<int>? startPage,
    Value<int>? startPage1405,
    Value<int>? sourceId,
    Value<int>? startPageShamarly,
  }) {
    return SurahCompanion(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      meaningEn: meaningEn ?? this.meaningEn,
      revelation: revelation ?? this.revelation,
      revelationOrder: revelationOrder ?? this.revelationOrder,
      ayahCount: ayahCount ?? this.ayahCount,
      startPage: startPage ?? this.startPage,
      startPage1405: startPage1405 ?? this.startPage1405,
      sourceId: sourceId ?? this.sourceId,
      startPageShamarly: startPageShamarly ?? this.startPageShamarly,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (meaningEn.present) {
      map['meaning_en'] = Variable<String>(meaningEn.value);
    }
    if (revelation.present) {
      map['revelation'] = Variable<String>(revelation.value);
    }
    if (revelationOrder.present) {
      map['revelation_order'] = Variable<int>(revelationOrder.value);
    }
    if (ayahCount.present) {
      map['ayah_count'] = Variable<int>(ayahCount.value);
    }
    if (startPage.present) {
      map['start_page'] = Variable<int>(startPage.value);
    }
    if (startPage1405.present) {
      map['start_page_1405'] = Variable<int>(startPage1405.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (startPageShamarly.present) {
      map['start_page_shamarly'] = Variable<int>(startPageShamarly.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurahCompanion(')
          ..write('id: $id, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('meaningEn: $meaningEn, ')
          ..write('revelation: $revelation, ')
          ..write('revelationOrder: $revelationOrder, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('startPage: $startPage, ')
          ..write('startPage1405: $startPage1405, ')
          ..write('sourceId: $sourceId, ')
          ..write('startPageShamarly: $startPageShamarly')
          ..write(')'))
        .toString();
  }
}

class $AyahTable extends Ayah with TableInfo<$AyahTable, AyahRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AyahTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verseTextMeta = const VerificationMeta(
    'verseText',
  );
  @override
  late final GeneratedColumn<String> verseText = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayTextMeta = const VerificationMeta(
    'displayText',
  );
  @override
  late final GeneratedColumn<String> displayText = GeneratedColumn<String>(
    'display_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _basmalaPrefixMeta = const VerificationMeta(
    'basmalaPrefix',
  );
  @override
  late final GeneratedColumn<int> basmalaPrefix = GeneratedColumn<int>(
    'basmala_prefix',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textSearchMeta = const VerificationMeta(
    'textSearch',
  );
  @override
  late final GeneratedColumn<String> textSearch = GeneratedColumn<String>(
    'text_search',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchBasmalaPrefixMeta =
      const VerificationMeta('searchBasmalaPrefix');
  @override
  late final GeneratedColumn<int> searchBasmalaPrefix = GeneratedColumn<int>(
    'search_basmala_prefix',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _juzMeta = const VerificationMeta('juz');
  @override
  late final GeneratedColumn<int> juz = GeneratedColumn<int>(
    'juz',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hizbQuarterMeta = const VerificationMeta(
    'hizbQuarter',
  );
  @override
  late final GeneratedColumn<int> hizbQuarter = GeneratedColumn<int>(
    'hizb_quarter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manzilMeta = const VerificationMeta('manzil');
  @override
  late final GeneratedColumn<int> manzil = GeneratedColumn<int>(
    'manzil',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _page1405Meta = const VerificationMeta(
    'page1405',
  );
  @override
  late final GeneratedColumn<int> page1405 = GeneratedColumn<int>(
    'page_1405',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sajdaMeta = const VerificationMeta('sajda');
  @override
  late final GeneratedColumn<String> sajda = GeneratedColumn<String>(
    'sajda',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textSourceIdMeta = const VerificationMeta(
    'textSourceId',
  );
  @override
  late final GeneratedColumn<int> textSourceId = GeneratedColumn<int>(
    'text_source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displaySourceIdMeta = const VerificationMeta(
    'displaySourceId',
  );
  @override
  late final GeneratedColumn<int> displaySourceId = GeneratedColumn<int>(
    'display_source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageSourceIdMeta = const VerificationMeta(
    'pageSourceId',
  );
  @override
  late final GeneratedColumn<int> pageSourceId = GeneratedColumn<int>(
    'page_source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageShamarlyMeta = const VerificationMeta(
    'pageShamarly',
  );
  @override
  late final GeneratedColumn<int> pageShamarly = GeneratedColumn<int>(
    'page_shamarly',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageShamarlyEndMeta = const VerificationMeta(
    'pageShamarlyEnd',
  );
  @override
  late final GeneratedColumn<int> pageShamarlyEnd = GeneratedColumn<int>(
    'page_shamarly_end',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    surah,
    number,
    verseText,
    displayText,
    basmalaPrefix,
    textSearch,
    searchBasmalaPrefix,
    juz,
    hizbQuarter,
    manzil,
    page,
    page1405,
    sajda,
    textSourceId,
    displaySourceId,
    pageSourceId,
    pageShamarly,
    pageShamarlyEnd,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ayah';
  @override
  VerificationContext validateIntegrity(
    Insertable<AyahRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _verseTextMeta,
        verseText.isAcceptableOrUnknown(data['text']!, _verseTextMeta),
      );
    } else if (isInserting) {
      context.missing(_verseTextMeta);
    }
    if (data.containsKey('display_text')) {
      context.handle(
        _displayTextMeta,
        displayText.isAcceptableOrUnknown(
          data['display_text']!,
          _displayTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayTextMeta);
    }
    if (data.containsKey('basmala_prefix')) {
      context.handle(
        _basmalaPrefixMeta,
        basmalaPrefix.isAcceptableOrUnknown(
          data['basmala_prefix']!,
          _basmalaPrefixMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_basmalaPrefixMeta);
    }
    if (data.containsKey('text_search')) {
      context.handle(
        _textSearchMeta,
        textSearch.isAcceptableOrUnknown(data['text_search']!, _textSearchMeta),
      );
    } else if (isInserting) {
      context.missing(_textSearchMeta);
    }
    if (data.containsKey('search_basmala_prefix')) {
      context.handle(
        _searchBasmalaPrefixMeta,
        searchBasmalaPrefix.isAcceptableOrUnknown(
          data['search_basmala_prefix']!,
          _searchBasmalaPrefixMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_searchBasmalaPrefixMeta);
    }
    if (data.containsKey('juz')) {
      context.handle(
        _juzMeta,
        juz.isAcceptableOrUnknown(data['juz']!, _juzMeta),
      );
    } else if (isInserting) {
      context.missing(_juzMeta);
    }
    if (data.containsKey('hizb_quarter')) {
      context.handle(
        _hizbQuarterMeta,
        hizbQuarter.isAcceptableOrUnknown(
          data['hizb_quarter']!,
          _hizbQuarterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hizbQuarterMeta);
    }
    if (data.containsKey('manzil')) {
      context.handle(
        _manzilMeta,
        manzil.isAcceptableOrUnknown(data['manzil']!, _manzilMeta),
      );
    } else if (isInserting) {
      context.missing(_manzilMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('page_1405')) {
      context.handle(
        _page1405Meta,
        page1405.isAcceptableOrUnknown(data['page_1405']!, _page1405Meta),
      );
    } else if (isInserting) {
      context.missing(_page1405Meta);
    }
    if (data.containsKey('sajda')) {
      context.handle(
        _sajdaMeta,
        sajda.isAcceptableOrUnknown(data['sajda']!, _sajdaMeta),
      );
    }
    if (data.containsKey('text_source_id')) {
      context.handle(
        _textSourceIdMeta,
        textSourceId.isAcceptableOrUnknown(
          data['text_source_id']!,
          _textSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_textSourceIdMeta);
    }
    if (data.containsKey('display_source_id')) {
      context.handle(
        _displaySourceIdMeta,
        displaySourceId.isAcceptableOrUnknown(
          data['display_source_id']!,
          _displaySourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displaySourceIdMeta);
    }
    if (data.containsKey('page_source_id')) {
      context.handle(
        _pageSourceIdMeta,
        pageSourceId.isAcceptableOrUnknown(
          data['page_source_id']!,
          _pageSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pageSourceIdMeta);
    }
    if (data.containsKey('page_shamarly')) {
      context.handle(
        _pageShamarlyMeta,
        pageShamarly.isAcceptableOrUnknown(
          data['page_shamarly']!,
          _pageShamarlyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pageShamarlyMeta);
    }
    if (data.containsKey('page_shamarly_end')) {
      context.handle(
        _pageShamarlyEndMeta,
        pageShamarlyEnd.isAcceptableOrUnknown(
          data['page_shamarly_end']!,
          _pageShamarlyEndMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pageShamarlyEndMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AyahRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AyahRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      verseText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      displayText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_text'],
      )!,
      basmalaPrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}basmala_prefix'],
      )!,
      textSearch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_search'],
      )!,
      searchBasmalaPrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}search_basmala_prefix'],
      )!,
      juz: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}juz'],
      )!,
      hizbQuarter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hizb_quarter'],
      )!,
      manzil: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}manzil'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      page1405: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_1405'],
      )!,
      sajda: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sajda'],
      ),
      textSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}text_source_id'],
      )!,
      displaySourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_source_id'],
      )!,
      pageSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_source_id'],
      )!,
      pageShamarly: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_shamarly'],
      )!,
      pageShamarlyEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_shamarly_end'],
      )!,
    );
  }

  @override
  $AyahTable createAlias(String alias) {
    return $AyahTable(attachedDatabase, alias);
  }
}

class AyahRow extends DataClass implements Insertable<AyahRow> {
  final int id;
  final int surah;
  final int number;

  /// Tanzil Uthmani text, verbatim (may start with the basmala). Kept for
  /// reference and comparison; not shown.
  final String verseText;

  /// KFGQPC Hafs 2.0 text, verbatim, for the KFGQPC Hafs font. Shown in the
  /// continuous view. Ends with a space and the verse-number glyph.
  final String displayText;

  /// Characters of the basmala before verse 1 in the Tanzil file.
  final int basmalaPrefix;
  final String textSearch;
  final int searchBasmalaPrefix;
  final int juz;
  final int hizbQuarter;
  final int manzil;

  /// Page in the new edition (1441H).
  final int page;

  /// Page in the old edition (1405H).
  final int page1405;
  final String? sajda;
  final int textSourceId;
  final int displaySourceId;
  final int pageSourceId;

  /// Page where the verse starts in the Shamarly (Egyptian) edition.
  final int pageShamarly;

  /// Page of the verse's marker in the Shamarly edition: a verse may run
  /// over a page break there.
  final int pageShamarlyEnd;
  const AyahRow({
    required this.id,
    required this.surah,
    required this.number,
    required this.verseText,
    required this.displayText,
    required this.basmalaPrefix,
    required this.textSearch,
    required this.searchBasmalaPrefix,
    required this.juz,
    required this.hizbQuarter,
    required this.manzil,
    required this.page,
    required this.page1405,
    this.sajda,
    required this.textSourceId,
    required this.displaySourceId,
    required this.pageSourceId,
    required this.pageShamarly,
    required this.pageShamarlyEnd,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surah'] = Variable<int>(surah);
    map['number'] = Variable<int>(number);
    map['text'] = Variable<String>(verseText);
    map['display_text'] = Variable<String>(displayText);
    map['basmala_prefix'] = Variable<int>(basmalaPrefix);
    map['text_search'] = Variable<String>(textSearch);
    map['search_basmala_prefix'] = Variable<int>(searchBasmalaPrefix);
    map['juz'] = Variable<int>(juz);
    map['hizb_quarter'] = Variable<int>(hizbQuarter);
    map['manzil'] = Variable<int>(manzil);
    map['page'] = Variable<int>(page);
    map['page_1405'] = Variable<int>(page1405);
    if (!nullToAbsent || sajda != null) {
      map['sajda'] = Variable<String>(sajda);
    }
    map['text_source_id'] = Variable<int>(textSourceId);
    map['display_source_id'] = Variable<int>(displaySourceId);
    map['page_source_id'] = Variable<int>(pageSourceId);
    map['page_shamarly'] = Variable<int>(pageShamarly);
    map['page_shamarly_end'] = Variable<int>(pageShamarlyEnd);
    return map;
  }

  AyahCompanion toCompanion(bool nullToAbsent) {
    return AyahCompanion(
      id: Value(id),
      surah: Value(surah),
      number: Value(number),
      verseText: Value(verseText),
      displayText: Value(displayText),
      basmalaPrefix: Value(basmalaPrefix),
      textSearch: Value(textSearch),
      searchBasmalaPrefix: Value(searchBasmalaPrefix),
      juz: Value(juz),
      hizbQuarter: Value(hizbQuarter),
      manzil: Value(manzil),
      page: Value(page),
      page1405: Value(page1405),
      sajda: sajda == null && nullToAbsent
          ? const Value.absent()
          : Value(sajda),
      textSourceId: Value(textSourceId),
      displaySourceId: Value(displaySourceId),
      pageSourceId: Value(pageSourceId),
      pageShamarly: Value(pageShamarly),
      pageShamarlyEnd: Value(pageShamarlyEnd),
    );
  }

  factory AyahRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AyahRow(
      id: serializer.fromJson<int>(json['id']),
      surah: serializer.fromJson<int>(json['surah']),
      number: serializer.fromJson<int>(json['number']),
      verseText: serializer.fromJson<String>(json['verseText']),
      displayText: serializer.fromJson<String>(json['displayText']),
      basmalaPrefix: serializer.fromJson<int>(json['basmalaPrefix']),
      textSearch: serializer.fromJson<String>(json['textSearch']),
      searchBasmalaPrefix: serializer.fromJson<int>(
        json['searchBasmalaPrefix'],
      ),
      juz: serializer.fromJson<int>(json['juz']),
      hizbQuarter: serializer.fromJson<int>(json['hizbQuarter']),
      manzil: serializer.fromJson<int>(json['manzil']),
      page: serializer.fromJson<int>(json['page']),
      page1405: serializer.fromJson<int>(json['page1405']),
      sajda: serializer.fromJson<String?>(json['sajda']),
      textSourceId: serializer.fromJson<int>(json['textSourceId']),
      displaySourceId: serializer.fromJson<int>(json['displaySourceId']),
      pageSourceId: serializer.fromJson<int>(json['pageSourceId']),
      pageShamarly: serializer.fromJson<int>(json['pageShamarly']),
      pageShamarlyEnd: serializer.fromJson<int>(json['pageShamarlyEnd']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surah': serializer.toJson<int>(surah),
      'number': serializer.toJson<int>(number),
      'verseText': serializer.toJson<String>(verseText),
      'displayText': serializer.toJson<String>(displayText),
      'basmalaPrefix': serializer.toJson<int>(basmalaPrefix),
      'textSearch': serializer.toJson<String>(textSearch),
      'searchBasmalaPrefix': serializer.toJson<int>(searchBasmalaPrefix),
      'juz': serializer.toJson<int>(juz),
      'hizbQuarter': serializer.toJson<int>(hizbQuarter),
      'manzil': serializer.toJson<int>(manzil),
      'page': serializer.toJson<int>(page),
      'page1405': serializer.toJson<int>(page1405),
      'sajda': serializer.toJson<String?>(sajda),
      'textSourceId': serializer.toJson<int>(textSourceId),
      'displaySourceId': serializer.toJson<int>(displaySourceId),
      'pageSourceId': serializer.toJson<int>(pageSourceId),
      'pageShamarly': serializer.toJson<int>(pageShamarly),
      'pageShamarlyEnd': serializer.toJson<int>(pageShamarlyEnd),
    };
  }

  AyahRow copyWith({
    int? id,
    int? surah,
    int? number,
    String? verseText,
    String? displayText,
    int? basmalaPrefix,
    String? textSearch,
    int? searchBasmalaPrefix,
    int? juz,
    int? hizbQuarter,
    int? manzil,
    int? page,
    int? page1405,
    Value<String?> sajda = const Value.absent(),
    int? textSourceId,
    int? displaySourceId,
    int? pageSourceId,
    int? pageShamarly,
    int? pageShamarlyEnd,
  }) => AyahRow(
    id: id ?? this.id,
    surah: surah ?? this.surah,
    number: number ?? this.number,
    verseText: verseText ?? this.verseText,
    displayText: displayText ?? this.displayText,
    basmalaPrefix: basmalaPrefix ?? this.basmalaPrefix,
    textSearch: textSearch ?? this.textSearch,
    searchBasmalaPrefix: searchBasmalaPrefix ?? this.searchBasmalaPrefix,
    juz: juz ?? this.juz,
    hizbQuarter: hizbQuarter ?? this.hizbQuarter,
    manzil: manzil ?? this.manzil,
    page: page ?? this.page,
    page1405: page1405 ?? this.page1405,
    sajda: sajda.present ? sajda.value : this.sajda,
    textSourceId: textSourceId ?? this.textSourceId,
    displaySourceId: displaySourceId ?? this.displaySourceId,
    pageSourceId: pageSourceId ?? this.pageSourceId,
    pageShamarly: pageShamarly ?? this.pageShamarly,
    pageShamarlyEnd: pageShamarlyEnd ?? this.pageShamarlyEnd,
  );
  AyahRow copyWithCompanion(AyahCompanion data) {
    return AyahRow(
      id: data.id.present ? data.id.value : this.id,
      surah: data.surah.present ? data.surah.value : this.surah,
      number: data.number.present ? data.number.value : this.number,
      verseText: data.verseText.present ? data.verseText.value : this.verseText,
      displayText: data.displayText.present
          ? data.displayText.value
          : this.displayText,
      basmalaPrefix: data.basmalaPrefix.present
          ? data.basmalaPrefix.value
          : this.basmalaPrefix,
      textSearch: data.textSearch.present
          ? data.textSearch.value
          : this.textSearch,
      searchBasmalaPrefix: data.searchBasmalaPrefix.present
          ? data.searchBasmalaPrefix.value
          : this.searchBasmalaPrefix,
      juz: data.juz.present ? data.juz.value : this.juz,
      hizbQuarter: data.hizbQuarter.present
          ? data.hizbQuarter.value
          : this.hizbQuarter,
      manzil: data.manzil.present ? data.manzil.value : this.manzil,
      page: data.page.present ? data.page.value : this.page,
      page1405: data.page1405.present ? data.page1405.value : this.page1405,
      sajda: data.sajda.present ? data.sajda.value : this.sajda,
      textSourceId: data.textSourceId.present
          ? data.textSourceId.value
          : this.textSourceId,
      displaySourceId: data.displaySourceId.present
          ? data.displaySourceId.value
          : this.displaySourceId,
      pageSourceId: data.pageSourceId.present
          ? data.pageSourceId.value
          : this.pageSourceId,
      pageShamarly: data.pageShamarly.present
          ? data.pageShamarly.value
          : this.pageShamarly,
      pageShamarlyEnd: data.pageShamarlyEnd.present
          ? data.pageShamarlyEnd.value
          : this.pageShamarlyEnd,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AyahRow(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('number: $number, ')
          ..write('verseText: $verseText, ')
          ..write('displayText: $displayText, ')
          ..write('basmalaPrefix: $basmalaPrefix, ')
          ..write('textSearch: $textSearch, ')
          ..write('searchBasmalaPrefix: $searchBasmalaPrefix, ')
          ..write('juz: $juz, ')
          ..write('hizbQuarter: $hizbQuarter, ')
          ..write('manzil: $manzil, ')
          ..write('page: $page, ')
          ..write('page1405: $page1405, ')
          ..write('sajda: $sajda, ')
          ..write('textSourceId: $textSourceId, ')
          ..write('displaySourceId: $displaySourceId, ')
          ..write('pageSourceId: $pageSourceId, ')
          ..write('pageShamarly: $pageShamarly, ')
          ..write('pageShamarlyEnd: $pageShamarlyEnd')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    surah,
    number,
    verseText,
    displayText,
    basmalaPrefix,
    textSearch,
    searchBasmalaPrefix,
    juz,
    hizbQuarter,
    manzil,
    page,
    page1405,
    sajda,
    textSourceId,
    displaySourceId,
    pageSourceId,
    pageShamarly,
    pageShamarlyEnd,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AyahRow &&
          other.id == this.id &&
          other.surah == this.surah &&
          other.number == this.number &&
          other.verseText == this.verseText &&
          other.displayText == this.displayText &&
          other.basmalaPrefix == this.basmalaPrefix &&
          other.textSearch == this.textSearch &&
          other.searchBasmalaPrefix == this.searchBasmalaPrefix &&
          other.juz == this.juz &&
          other.hizbQuarter == this.hizbQuarter &&
          other.manzil == this.manzil &&
          other.page == this.page &&
          other.page1405 == this.page1405 &&
          other.sajda == this.sajda &&
          other.textSourceId == this.textSourceId &&
          other.displaySourceId == this.displaySourceId &&
          other.pageSourceId == this.pageSourceId &&
          other.pageShamarly == this.pageShamarly &&
          other.pageShamarlyEnd == this.pageShamarlyEnd);
}

class AyahCompanion extends UpdateCompanion<AyahRow> {
  final Value<int> id;
  final Value<int> surah;
  final Value<int> number;
  final Value<String> verseText;
  final Value<String> displayText;
  final Value<int> basmalaPrefix;
  final Value<String> textSearch;
  final Value<int> searchBasmalaPrefix;
  final Value<int> juz;
  final Value<int> hizbQuarter;
  final Value<int> manzil;
  final Value<int> page;
  final Value<int> page1405;
  final Value<String?> sajda;
  final Value<int> textSourceId;
  final Value<int> displaySourceId;
  final Value<int> pageSourceId;
  final Value<int> pageShamarly;
  final Value<int> pageShamarlyEnd;
  const AyahCompanion({
    this.id = const Value.absent(),
    this.surah = const Value.absent(),
    this.number = const Value.absent(),
    this.verseText = const Value.absent(),
    this.displayText = const Value.absent(),
    this.basmalaPrefix = const Value.absent(),
    this.textSearch = const Value.absent(),
    this.searchBasmalaPrefix = const Value.absent(),
    this.juz = const Value.absent(),
    this.hizbQuarter = const Value.absent(),
    this.manzil = const Value.absent(),
    this.page = const Value.absent(),
    this.page1405 = const Value.absent(),
    this.sajda = const Value.absent(),
    this.textSourceId = const Value.absent(),
    this.displaySourceId = const Value.absent(),
    this.pageSourceId = const Value.absent(),
    this.pageShamarly = const Value.absent(),
    this.pageShamarlyEnd = const Value.absent(),
  });
  AyahCompanion.insert({
    this.id = const Value.absent(),
    required int surah,
    required int number,
    required String verseText,
    required String displayText,
    required int basmalaPrefix,
    required String textSearch,
    required int searchBasmalaPrefix,
    required int juz,
    required int hizbQuarter,
    required int manzil,
    required int page,
    required int page1405,
    this.sajda = const Value.absent(),
    required int textSourceId,
    required int displaySourceId,
    required int pageSourceId,
    required int pageShamarly,
    required int pageShamarlyEnd,
  }) : surah = Value(surah),
       number = Value(number),
       verseText = Value(verseText),
       displayText = Value(displayText),
       basmalaPrefix = Value(basmalaPrefix),
       textSearch = Value(textSearch),
       searchBasmalaPrefix = Value(searchBasmalaPrefix),
       juz = Value(juz),
       hizbQuarter = Value(hizbQuarter),
       manzil = Value(manzil),
       page = Value(page),
       page1405 = Value(page1405),
       textSourceId = Value(textSourceId),
       displaySourceId = Value(displaySourceId),
       pageSourceId = Value(pageSourceId),
       pageShamarly = Value(pageShamarly),
       pageShamarlyEnd = Value(pageShamarlyEnd);
  static Insertable<AyahRow> custom({
    Expression<int>? id,
    Expression<int>? surah,
    Expression<int>? number,
    Expression<String>? verseText,
    Expression<String>? displayText,
    Expression<int>? basmalaPrefix,
    Expression<String>? textSearch,
    Expression<int>? searchBasmalaPrefix,
    Expression<int>? juz,
    Expression<int>? hizbQuarter,
    Expression<int>? manzil,
    Expression<int>? page,
    Expression<int>? page1405,
    Expression<String>? sajda,
    Expression<int>? textSourceId,
    Expression<int>? displaySourceId,
    Expression<int>? pageSourceId,
    Expression<int>? pageShamarly,
    Expression<int>? pageShamarlyEnd,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surah != null) 'surah': surah,
      if (number != null) 'number': number,
      if (verseText != null) 'text': verseText,
      if (displayText != null) 'display_text': displayText,
      if (basmalaPrefix != null) 'basmala_prefix': basmalaPrefix,
      if (textSearch != null) 'text_search': textSearch,
      if (searchBasmalaPrefix != null)
        'search_basmala_prefix': searchBasmalaPrefix,
      if (juz != null) 'juz': juz,
      if (hizbQuarter != null) 'hizb_quarter': hizbQuarter,
      if (manzil != null) 'manzil': manzil,
      if (page != null) 'page': page,
      if (page1405 != null) 'page_1405': page1405,
      if (sajda != null) 'sajda': sajda,
      if (textSourceId != null) 'text_source_id': textSourceId,
      if (displaySourceId != null) 'display_source_id': displaySourceId,
      if (pageSourceId != null) 'page_source_id': pageSourceId,
      if (pageShamarly != null) 'page_shamarly': pageShamarly,
      if (pageShamarlyEnd != null) 'page_shamarly_end': pageShamarlyEnd,
    });
  }

  AyahCompanion copyWith({
    Value<int>? id,
    Value<int>? surah,
    Value<int>? number,
    Value<String>? verseText,
    Value<String>? displayText,
    Value<int>? basmalaPrefix,
    Value<String>? textSearch,
    Value<int>? searchBasmalaPrefix,
    Value<int>? juz,
    Value<int>? hizbQuarter,
    Value<int>? manzil,
    Value<int>? page,
    Value<int>? page1405,
    Value<String?>? sajda,
    Value<int>? textSourceId,
    Value<int>? displaySourceId,
    Value<int>? pageSourceId,
    Value<int>? pageShamarly,
    Value<int>? pageShamarlyEnd,
  }) {
    return AyahCompanion(
      id: id ?? this.id,
      surah: surah ?? this.surah,
      number: number ?? this.number,
      verseText: verseText ?? this.verseText,
      displayText: displayText ?? this.displayText,
      basmalaPrefix: basmalaPrefix ?? this.basmalaPrefix,
      textSearch: textSearch ?? this.textSearch,
      searchBasmalaPrefix: searchBasmalaPrefix ?? this.searchBasmalaPrefix,
      juz: juz ?? this.juz,
      hizbQuarter: hizbQuarter ?? this.hizbQuarter,
      manzil: manzil ?? this.manzil,
      page: page ?? this.page,
      page1405: page1405 ?? this.page1405,
      sajda: sajda ?? this.sajda,
      textSourceId: textSourceId ?? this.textSourceId,
      displaySourceId: displaySourceId ?? this.displaySourceId,
      pageSourceId: pageSourceId ?? this.pageSourceId,
      pageShamarly: pageShamarly ?? this.pageShamarly,
      pageShamarlyEnd: pageShamarlyEnd ?? this.pageShamarlyEnd,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (verseText.present) {
      map['text'] = Variable<String>(verseText.value);
    }
    if (displayText.present) {
      map['display_text'] = Variable<String>(displayText.value);
    }
    if (basmalaPrefix.present) {
      map['basmala_prefix'] = Variable<int>(basmalaPrefix.value);
    }
    if (textSearch.present) {
      map['text_search'] = Variable<String>(textSearch.value);
    }
    if (searchBasmalaPrefix.present) {
      map['search_basmala_prefix'] = Variable<int>(searchBasmalaPrefix.value);
    }
    if (juz.present) {
      map['juz'] = Variable<int>(juz.value);
    }
    if (hizbQuarter.present) {
      map['hizb_quarter'] = Variable<int>(hizbQuarter.value);
    }
    if (manzil.present) {
      map['manzil'] = Variable<int>(manzil.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (page1405.present) {
      map['page_1405'] = Variable<int>(page1405.value);
    }
    if (sajda.present) {
      map['sajda'] = Variable<String>(sajda.value);
    }
    if (textSourceId.present) {
      map['text_source_id'] = Variable<int>(textSourceId.value);
    }
    if (displaySourceId.present) {
      map['display_source_id'] = Variable<int>(displaySourceId.value);
    }
    if (pageSourceId.present) {
      map['page_source_id'] = Variable<int>(pageSourceId.value);
    }
    if (pageShamarly.present) {
      map['page_shamarly'] = Variable<int>(pageShamarly.value);
    }
    if (pageShamarlyEnd.present) {
      map['page_shamarly_end'] = Variable<int>(pageShamarlyEnd.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AyahCompanion(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('number: $number, ')
          ..write('verseText: $verseText, ')
          ..write('displayText: $displayText, ')
          ..write('basmalaPrefix: $basmalaPrefix, ')
          ..write('textSearch: $textSearch, ')
          ..write('searchBasmalaPrefix: $searchBasmalaPrefix, ')
          ..write('juz: $juz, ')
          ..write('hizbQuarter: $hizbQuarter, ')
          ..write('manzil: $manzil, ')
          ..write('page: $page, ')
          ..write('page1405: $page1405, ')
          ..write('sajda: $sajda, ')
          ..write('textSourceId: $textSourceId, ')
          ..write('displaySourceId: $displaySourceId, ')
          ..write('pageSourceId: $pageSourceId, ')
          ..write('pageShamarly: $pageShamarly, ')
          ..write('pageShamarlyEnd: $pageShamarlyEnd')
          ..write(')'))
        .toString();
  }
}

class $AyahPolygonTable extends AyahPolygon
    with TableInfo<$AyahPolygonTable, AyahPolygonRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AyahPolygonTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _markerXMeta = const VerificationMeta(
    'markerX',
  );
  @override
  late final GeneratedColumn<double> markerX = GeneratedColumn<double>(
    'marker_x',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _markerYMeta = const VerificationMeta(
    'markerY',
  );
  @override
  late final GeneratedColumn<double> markerY = GeneratedColumn<double>(
    'marker_y',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    page,
    surah,
    number,
    path,
    markerX,
    markerY,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ayah_polygon';
  @override
  VerificationContext validateIntegrity(
    Insertable<AyahPolygonRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('marker_x')) {
      context.handle(
        _markerXMeta,
        markerX.isAcceptableOrUnknown(data['marker_x']!, _markerXMeta),
      );
    }
    if (data.containsKey('marker_y')) {
      context.handle(
        _markerYMeta,
        markerY.isAcceptableOrUnknown(data['marker_y']!, _markerYMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {page, surah, number};
  @override
  AyahPolygonRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AyahPolygonRow(
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      markerX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}marker_x'],
      ),
      markerY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}marker_y'],
      ),
    );
  }

  @override
  $AyahPolygonTable createAlias(String alias) {
    return $AyahPolygonTable(attachedDatabase, alias);
  }
}

class AyahPolygonRow extends DataClass implements Insertable<AyahPolygonRow> {
  final int page;
  final int surah;
  final int number;
  final String path;
  final double? markerX;
  final double? markerY;
  const AyahPolygonRow({
    required this.page,
    required this.surah,
    required this.number,
    required this.path,
    this.markerX,
    this.markerY,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['page'] = Variable<int>(page);
    map['surah'] = Variable<int>(surah);
    map['number'] = Variable<int>(number);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || markerX != null) {
      map['marker_x'] = Variable<double>(markerX);
    }
    if (!nullToAbsent || markerY != null) {
      map['marker_y'] = Variable<double>(markerY);
    }
    return map;
  }

  AyahPolygonCompanion toCompanion(bool nullToAbsent) {
    return AyahPolygonCompanion(
      page: Value(page),
      surah: Value(surah),
      number: Value(number),
      path: Value(path),
      markerX: markerX == null && nullToAbsent
          ? const Value.absent()
          : Value(markerX),
      markerY: markerY == null && nullToAbsent
          ? const Value.absent()
          : Value(markerY),
    );
  }

  factory AyahPolygonRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AyahPolygonRow(
      page: serializer.fromJson<int>(json['page']),
      surah: serializer.fromJson<int>(json['surah']),
      number: serializer.fromJson<int>(json['number']),
      path: serializer.fromJson<String>(json['path']),
      markerX: serializer.fromJson<double?>(json['markerX']),
      markerY: serializer.fromJson<double?>(json['markerY']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'page': serializer.toJson<int>(page),
      'surah': serializer.toJson<int>(surah),
      'number': serializer.toJson<int>(number),
      'path': serializer.toJson<String>(path),
      'markerX': serializer.toJson<double?>(markerX),
      'markerY': serializer.toJson<double?>(markerY),
    };
  }

  AyahPolygonRow copyWith({
    int? page,
    int? surah,
    int? number,
    String? path,
    Value<double?> markerX = const Value.absent(),
    Value<double?> markerY = const Value.absent(),
  }) => AyahPolygonRow(
    page: page ?? this.page,
    surah: surah ?? this.surah,
    number: number ?? this.number,
    path: path ?? this.path,
    markerX: markerX.present ? markerX.value : this.markerX,
    markerY: markerY.present ? markerY.value : this.markerY,
  );
  AyahPolygonRow copyWithCompanion(AyahPolygonCompanion data) {
    return AyahPolygonRow(
      page: data.page.present ? data.page.value : this.page,
      surah: data.surah.present ? data.surah.value : this.surah,
      number: data.number.present ? data.number.value : this.number,
      path: data.path.present ? data.path.value : this.path,
      markerX: data.markerX.present ? data.markerX.value : this.markerX,
      markerY: data.markerY.present ? data.markerY.value : this.markerY,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AyahPolygonRow(')
          ..write('page: $page, ')
          ..write('surah: $surah, ')
          ..write('number: $number, ')
          ..write('path: $path, ')
          ..write('markerX: $markerX, ')
          ..write('markerY: $markerY')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(page, surah, number, path, markerX, markerY);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AyahPolygonRow &&
          other.page == this.page &&
          other.surah == this.surah &&
          other.number == this.number &&
          other.path == this.path &&
          other.markerX == this.markerX &&
          other.markerY == this.markerY);
}

class AyahPolygonCompanion extends UpdateCompanion<AyahPolygonRow> {
  final Value<int> page;
  final Value<int> surah;
  final Value<int> number;
  final Value<String> path;
  final Value<double?> markerX;
  final Value<double?> markerY;
  final Value<int> rowid;
  const AyahPolygonCompanion({
    this.page = const Value.absent(),
    this.surah = const Value.absent(),
    this.number = const Value.absent(),
    this.path = const Value.absent(),
    this.markerX = const Value.absent(),
    this.markerY = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AyahPolygonCompanion.insert({
    required int page,
    required int surah,
    required int number,
    required String path,
    this.markerX = const Value.absent(),
    this.markerY = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : page = Value(page),
       surah = Value(surah),
       number = Value(number),
       path = Value(path);
  static Insertable<AyahPolygonRow> custom({
    Expression<int>? page,
    Expression<int>? surah,
    Expression<int>? number,
    Expression<String>? path,
    Expression<double>? markerX,
    Expression<double>? markerY,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (page != null) 'page': page,
      if (surah != null) 'surah': surah,
      if (number != null) 'number': number,
      if (path != null) 'path': path,
      if (markerX != null) 'marker_x': markerX,
      if (markerY != null) 'marker_y': markerY,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AyahPolygonCompanion copyWith({
    Value<int>? page,
    Value<int>? surah,
    Value<int>? number,
    Value<String>? path,
    Value<double?>? markerX,
    Value<double?>? markerY,
    Value<int>? rowid,
  }) {
    return AyahPolygonCompanion(
      page: page ?? this.page,
      surah: surah ?? this.surah,
      number: number ?? this.number,
      path: path ?? this.path,
      markerX: markerX ?? this.markerX,
      markerY: markerY ?? this.markerY,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (markerX.present) {
      map['marker_x'] = Variable<double>(markerX.value);
    }
    if (markerY.present) {
      map['marker_y'] = Variable<double>(markerY.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AyahPolygonCompanion(')
          ..write('page: $page, ')
          ..write('surah: $surah, ')
          ..write('number: $number, ')
          ..write('path: $path, ')
          ..write('markerX: $markerX, ')
          ..write('markerY: $markerY, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SourceTable extends Source with TableInfo<$SourceTable, SourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publisherMeta = const VerificationMeta(
    'publisher',
  );
  @override
  late final GeneratedColumn<String> publisher = GeneratedColumn<String>(
    'publisher',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _licenseMeta = const VerificationMeta(
    'license',
  );
  @override
  late final GeneratedColumn<String> license = GeneratedColumn<String>(
    'license',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attributionMeta = const VerificationMeta(
    'attribution',
  );
  @override
  late final GeneratedColumn<String> attribution = GeneratedColumn<String>(
    'attribution',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noticeMeta = const VerificationMeta('notice');
  @override
  late final GeneratedColumn<String> notice = GeneratedColumn<String>(
    'notice',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retrievedAtMeta = const VerificationMeta(
    'retrievedAt',
  );
  @override
  late final GeneratedColumn<String> retrievedAt = GeneratedColumn<String>(
    'retrieved_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    key,
    title,
    publisher,
    version,
    license,
    url,
    attribution,
    notice,
    sha256,
    retrievedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('publisher')) {
      context.handle(
        _publisherMeta,
        publisher.isAcceptableOrUnknown(data['publisher']!, _publisherMeta),
      );
    } else if (isInserting) {
      context.missing(_publisherMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('license')) {
      context.handle(
        _licenseMeta,
        license.isAcceptableOrUnknown(data['license']!, _licenseMeta),
      );
    } else if (isInserting) {
      context.missing(_licenseMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('attribution')) {
      context.handle(
        _attributionMeta,
        attribution.isAcceptableOrUnknown(
          data['attribution']!,
          _attributionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attributionMeta);
    }
    if (data.containsKey('notice')) {
      context.handle(
        _noticeMeta,
        notice.isAcceptableOrUnknown(data['notice']!, _noticeMeta),
      );
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('retrieved_at')) {
      context.handle(
        _retrievedAtMeta,
        retrievedAt.isAcceptableOrUnknown(
          data['retrieved_at']!,
          _retrievedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_retrievedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      publisher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publisher'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      ),
      license: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}license'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      attribution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribution'],
      )!,
      notice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notice'],
      ),
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      retrievedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}retrieved_at'],
      )!,
    );
  }

  @override
  $SourceTable createAlias(String alias) {
    return $SourceTable(attachedDatabase, alias);
  }
}

class SourceRow extends DataClass implements Insertable<SourceRow> {
  final int id;
  final String key;
  final String title;
  final String publisher;
  final String? version;
  final String license;
  final String url;
  final String attribution;
  final String? notice;
  final String sha256;
  final String retrievedAt;
  const SourceRow({
    required this.id,
    required this.key,
    required this.title,
    required this.publisher,
    this.version,
    required this.license,
    required this.url,
    required this.attribution,
    this.notice,
    required this.sha256,
    required this.retrievedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['title'] = Variable<String>(title);
    map['publisher'] = Variable<String>(publisher);
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<String>(version);
    }
    map['license'] = Variable<String>(license);
    map['url'] = Variable<String>(url);
    map['attribution'] = Variable<String>(attribution);
    if (!nullToAbsent || notice != null) {
      map['notice'] = Variable<String>(notice);
    }
    map['sha256'] = Variable<String>(sha256);
    map['retrieved_at'] = Variable<String>(retrievedAt);
    return map;
  }

  SourceCompanion toCompanion(bool nullToAbsent) {
    return SourceCompanion(
      id: Value(id),
      key: Value(key),
      title: Value(title),
      publisher: Value(publisher),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      license: Value(license),
      url: Value(url),
      attribution: Value(attribution),
      notice: notice == null && nullToAbsent
          ? const Value.absent()
          : Value(notice),
      sha256: Value(sha256),
      retrievedAt: Value(retrievedAt),
    );
  }

  factory SourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceRow(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      title: serializer.fromJson<String>(json['title']),
      publisher: serializer.fromJson<String>(json['publisher']),
      version: serializer.fromJson<String?>(json['version']),
      license: serializer.fromJson<String>(json['license']),
      url: serializer.fromJson<String>(json['url']),
      attribution: serializer.fromJson<String>(json['attribution']),
      notice: serializer.fromJson<String?>(json['notice']),
      sha256: serializer.fromJson<String>(json['sha256']),
      retrievedAt: serializer.fromJson<String>(json['retrievedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'title': serializer.toJson<String>(title),
      'publisher': serializer.toJson<String>(publisher),
      'version': serializer.toJson<String?>(version),
      'license': serializer.toJson<String>(license),
      'url': serializer.toJson<String>(url),
      'attribution': serializer.toJson<String>(attribution),
      'notice': serializer.toJson<String?>(notice),
      'sha256': serializer.toJson<String>(sha256),
      'retrievedAt': serializer.toJson<String>(retrievedAt),
    };
  }

  SourceRow copyWith({
    int? id,
    String? key,
    String? title,
    String? publisher,
    Value<String?> version = const Value.absent(),
    String? license,
    String? url,
    String? attribution,
    Value<String?> notice = const Value.absent(),
    String? sha256,
    String? retrievedAt,
  }) => SourceRow(
    id: id ?? this.id,
    key: key ?? this.key,
    title: title ?? this.title,
    publisher: publisher ?? this.publisher,
    version: version.present ? version.value : this.version,
    license: license ?? this.license,
    url: url ?? this.url,
    attribution: attribution ?? this.attribution,
    notice: notice.present ? notice.value : this.notice,
    sha256: sha256 ?? this.sha256,
    retrievedAt: retrievedAt ?? this.retrievedAt,
  );
  SourceRow copyWithCompanion(SourceCompanion data) {
    return SourceRow(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      title: data.title.present ? data.title.value : this.title,
      publisher: data.publisher.present ? data.publisher.value : this.publisher,
      version: data.version.present ? data.version.value : this.version,
      license: data.license.present ? data.license.value : this.license,
      url: data.url.present ? data.url.value : this.url,
      attribution: data.attribution.present
          ? data.attribution.value
          : this.attribution,
      notice: data.notice.present ? data.notice.value : this.notice,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      retrievedAt: data.retrievedAt.present
          ? data.retrievedAt.value
          : this.retrievedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceRow(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('title: $title, ')
          ..write('publisher: $publisher, ')
          ..write('version: $version, ')
          ..write('license: $license, ')
          ..write('url: $url, ')
          ..write('attribution: $attribution, ')
          ..write('notice: $notice, ')
          ..write('sha256: $sha256, ')
          ..write('retrievedAt: $retrievedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    key,
    title,
    publisher,
    version,
    license,
    url,
    attribution,
    notice,
    sha256,
    retrievedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceRow &&
          other.id == this.id &&
          other.key == this.key &&
          other.title == this.title &&
          other.publisher == this.publisher &&
          other.version == this.version &&
          other.license == this.license &&
          other.url == this.url &&
          other.attribution == this.attribution &&
          other.notice == this.notice &&
          other.sha256 == this.sha256 &&
          other.retrievedAt == this.retrievedAt);
}

class SourceCompanion extends UpdateCompanion<SourceRow> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> title;
  final Value<String> publisher;
  final Value<String?> version;
  final Value<String> license;
  final Value<String> url;
  final Value<String> attribution;
  final Value<String?> notice;
  final Value<String> sha256;
  final Value<String> retrievedAt;
  const SourceCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.title = const Value.absent(),
    this.publisher = const Value.absent(),
    this.version = const Value.absent(),
    this.license = const Value.absent(),
    this.url = const Value.absent(),
    this.attribution = const Value.absent(),
    this.notice = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.retrievedAt = const Value.absent(),
  });
  SourceCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String title,
    required String publisher,
    this.version = const Value.absent(),
    required String license,
    required String url,
    required String attribution,
    this.notice = const Value.absent(),
    required String sha256,
    required String retrievedAt,
  }) : key = Value(key),
       title = Value(title),
       publisher = Value(publisher),
       license = Value(license),
       url = Value(url),
       attribution = Value(attribution),
       sha256 = Value(sha256),
       retrievedAt = Value(retrievedAt);
  static Insertable<SourceRow> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? title,
    Expression<String>? publisher,
    Expression<String>? version,
    Expression<String>? license,
    Expression<String>? url,
    Expression<String>? attribution,
    Expression<String>? notice,
    Expression<String>? sha256,
    Expression<String>? retrievedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (title != null) 'title': title,
      if (publisher != null) 'publisher': publisher,
      if (version != null) 'version': version,
      if (license != null) 'license': license,
      if (url != null) 'url': url,
      if (attribution != null) 'attribution': attribution,
      if (notice != null) 'notice': notice,
      if (sha256 != null) 'sha256': sha256,
      if (retrievedAt != null) 'retrieved_at': retrievedAt,
    });
  }

  SourceCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? title,
    Value<String>? publisher,
    Value<String?>? version,
    Value<String>? license,
    Value<String>? url,
    Value<String>? attribution,
    Value<String?>? notice,
    Value<String>? sha256,
    Value<String>? retrievedAt,
  }) {
    return SourceCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      title: title ?? this.title,
      publisher: publisher ?? this.publisher,
      version: version ?? this.version,
      license: license ?? this.license,
      url: url ?? this.url,
      attribution: attribution ?? this.attribution,
      notice: notice ?? this.notice,
      sha256: sha256 ?? this.sha256,
      retrievedAt: retrievedAt ?? this.retrievedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (publisher.present) {
      map['publisher'] = Variable<String>(publisher.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (license.present) {
      map['license'] = Variable<String>(license.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (attribution.present) {
      map['attribution'] = Variable<String>(attribution.value);
    }
    if (notice.present) {
      map['notice'] = Variable<String>(notice.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (retrievedAt.present) {
      map['retrieved_at'] = Variable<String>(retrievedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourceCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('title: $title, ')
          ..write('publisher: $publisher, ')
          ..write('version: $version, ')
          ..write('license: $license, ')
          ..write('url: $url, ')
          ..write('attribution: $attribution, ')
          ..write('notice: $notice, ')
          ..write('sha256: $sha256, ')
          ..write('retrievedAt: $retrievedAt')
          ..write(')'))
        .toString();
  }
}

class $WordBoxTable extends WordBox with TableInfo<$WordBoxTable, WordBoxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordBoxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<int> word = GeneratedColumn<int>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _x0Meta = const VerificationMeta('x0');
  @override
  late final GeneratedColumn<int> x0 = GeneratedColumn<int>(
    'x0',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y0Meta = const VerificationMeta('y0');
  @override
  late final GeneratedColumn<int> y0 = GeneratedColumn<int>(
    'y0',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _x1Meta = const VerificationMeta('x1');
  @override
  late final GeneratedColumn<int> x1 = GeneratedColumn<int>(
    'x1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y1Meta = const VerificationMeta('y1');
  @override
  late final GeneratedColumn<int> y1 = GeneratedColumn<int>(
    'y1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exactMeta = const VerificationMeta('exact');
  @override
  late final GeneratedColumn<int> exact = GeneratedColumn<int>(
    'exact',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    surah,
    ayah,
    word,
    page,
    x0,
    y0,
    x1,
    y1,
    exact,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_box';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordBoxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('x0')) {
      context.handle(_x0Meta, x0.isAcceptableOrUnknown(data['x0']!, _x0Meta));
    } else if (isInserting) {
      context.missing(_x0Meta);
    }
    if (data.containsKey('y0')) {
      context.handle(_y0Meta, y0.isAcceptableOrUnknown(data['y0']!, _y0Meta));
    } else if (isInserting) {
      context.missing(_y0Meta);
    }
    if (data.containsKey('x1')) {
      context.handle(_x1Meta, x1.isAcceptableOrUnknown(data['x1']!, _x1Meta));
    } else if (isInserting) {
      context.missing(_x1Meta);
    }
    if (data.containsKey('y1')) {
      context.handle(_y1Meta, y1.isAcceptableOrUnknown(data['y1']!, _y1Meta));
    } else if (isInserting) {
      context.missing(_y1Meta);
    }
    if (data.containsKey('exact')) {
      context.handle(
        _exactMeta,
        exact.isAcceptableOrUnknown(data['exact']!, _exactMeta),
      );
    } else if (isInserting) {
      context.missing(_exactMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {surah, ayah, word};
  @override
  WordBoxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordBoxRow(
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      x0: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x0'],
      )!,
      y0: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y0'],
      )!,
      x1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x1'],
      )!,
      y1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y1'],
      )!,
      exact: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exact'],
      )!,
    );
  }

  @override
  $WordBoxTable createAlias(String alias) {
    return $WordBoxTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class WordBoxRow extends DataClass implements Insertable<WordBoxRow> {
  final int surah;
  final int ayah;

  /// 1-based among the words of the KFGQPC text.
  final int word;
  final int page;
  final int x0;
  final int y0;
  final int x1;
  final int y1;

  /// 1 when every word of the verse matched its predicted letter groups.
  final int exact;
  const WordBoxRow({
    required this.surah,
    required this.ayah,
    required this.word,
    required this.page,
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
    required this.exact,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['word'] = Variable<int>(word);
    map['page'] = Variable<int>(page);
    map['x0'] = Variable<int>(x0);
    map['y0'] = Variable<int>(y0);
    map['x1'] = Variable<int>(x1);
    map['y1'] = Variable<int>(y1);
    map['exact'] = Variable<int>(exact);
    return map;
  }

  WordBoxCompanion toCompanion(bool nullToAbsent) {
    return WordBoxCompanion(
      surah: Value(surah),
      ayah: Value(ayah),
      word: Value(word),
      page: Value(page),
      x0: Value(x0),
      y0: Value(y0),
      x1: Value(x1),
      y1: Value(y1),
      exact: Value(exact),
    );
  }

  factory WordBoxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordBoxRow(
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      word: serializer.fromJson<int>(json['word']),
      page: serializer.fromJson<int>(json['page']),
      x0: serializer.fromJson<int>(json['x0']),
      y0: serializer.fromJson<int>(json['y0']),
      x1: serializer.fromJson<int>(json['x1']),
      y1: serializer.fromJson<int>(json['y1']),
      exact: serializer.fromJson<int>(json['exact']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'word': serializer.toJson<int>(word),
      'page': serializer.toJson<int>(page),
      'x0': serializer.toJson<int>(x0),
      'y0': serializer.toJson<int>(y0),
      'x1': serializer.toJson<int>(x1),
      'y1': serializer.toJson<int>(y1),
      'exact': serializer.toJson<int>(exact),
    };
  }

  WordBoxRow copyWith({
    int? surah,
    int? ayah,
    int? word,
    int? page,
    int? x0,
    int? y0,
    int? x1,
    int? y1,
    int? exact,
  }) => WordBoxRow(
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    word: word ?? this.word,
    page: page ?? this.page,
    x0: x0 ?? this.x0,
    y0: y0 ?? this.y0,
    x1: x1 ?? this.x1,
    y1: y1 ?? this.y1,
    exact: exact ?? this.exact,
  );
  WordBoxRow copyWithCompanion(WordBoxCompanion data) {
    return WordBoxRow(
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      word: data.word.present ? data.word.value : this.word,
      page: data.page.present ? data.page.value : this.page,
      x0: data.x0.present ? data.x0.value : this.x0,
      y0: data.y0.present ? data.y0.value : this.y0,
      x1: data.x1.present ? data.x1.value : this.x1,
      y1: data.y1.present ? data.y1.value : this.y1,
      exact: data.exact.present ? data.exact.value : this.exact,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordBoxRow(')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('word: $word, ')
          ..write('page: $page, ')
          ..write('x0: $x0, ')
          ..write('y0: $y0, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1, ')
          ..write('exact: $exact')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(surah, ayah, word, page, x0, y0, x1, y1, exact);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordBoxRow &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.word == this.word &&
          other.page == this.page &&
          other.x0 == this.x0 &&
          other.y0 == this.y0 &&
          other.x1 == this.x1 &&
          other.y1 == this.y1 &&
          other.exact == this.exact);
}

class WordBoxCompanion extends UpdateCompanion<WordBoxRow> {
  final Value<int> surah;
  final Value<int> ayah;
  final Value<int> word;
  final Value<int> page;
  final Value<int> x0;
  final Value<int> y0;
  final Value<int> x1;
  final Value<int> y1;
  final Value<int> exact;
  const WordBoxCompanion({
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.word = const Value.absent(),
    this.page = const Value.absent(),
    this.x0 = const Value.absent(),
    this.y0 = const Value.absent(),
    this.x1 = const Value.absent(),
    this.y1 = const Value.absent(),
    this.exact = const Value.absent(),
  });
  WordBoxCompanion.insert({
    required int surah,
    required int ayah,
    required int word,
    required int page,
    required int x0,
    required int y0,
    required int x1,
    required int y1,
    required int exact,
  }) : surah = Value(surah),
       ayah = Value(ayah),
       word = Value(word),
       page = Value(page),
       x0 = Value(x0),
       y0 = Value(y0),
       x1 = Value(x1),
       y1 = Value(y1),
       exact = Value(exact);
  static Insertable<WordBoxRow> custom({
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<int>? word,
    Expression<int>? page,
    Expression<int>? x0,
    Expression<int>? y0,
    Expression<int>? x1,
    Expression<int>? y1,
    Expression<int>? exact,
  }) {
    return RawValuesInsertable({
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (word != null) 'word': word,
      if (page != null) 'page': page,
      if (x0 != null) 'x0': x0,
      if (y0 != null) 'y0': y0,
      if (x1 != null) 'x1': x1,
      if (y1 != null) 'y1': y1,
      if (exact != null) 'exact': exact,
    });
  }

  WordBoxCompanion copyWith({
    Value<int>? surah,
    Value<int>? ayah,
    Value<int>? word,
    Value<int>? page,
    Value<int>? x0,
    Value<int>? y0,
    Value<int>? x1,
    Value<int>? y1,
    Value<int>? exact,
  }) {
    return WordBoxCompanion(
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      word: word ?? this.word,
      page: page ?? this.page,
      x0: x0 ?? this.x0,
      y0: y0 ?? this.y0,
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
      exact: exact ?? this.exact,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (word.present) {
      map['word'] = Variable<int>(word.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (x0.present) {
      map['x0'] = Variable<int>(x0.value);
    }
    if (y0.present) {
      map['y0'] = Variable<int>(y0.value);
    }
    if (x1.present) {
      map['x1'] = Variable<int>(x1.value);
    }
    if (y1.present) {
      map['y1'] = Variable<int>(y1.value);
    }
    if (exact.present) {
      map['exact'] = Variable<int>(exact.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordBoxCompanion(')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('word: $word, ')
          ..write('page: $page, ')
          ..write('x0: $x0, ')
          ..write('y0: $y0, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1, ')
          ..write('exact: $exact')
          ..write(')'))
        .toString();
  }
}

class $LineCutTable extends LineCut with TableInfo<$LineCutTable, LineCutRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LineCutTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _editionMeta = const VerificationMeta(
    'edition',
  );
  @override
  late final GeneratedColumn<String> edition = GeneratedColumn<String>(
    'edition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gapMeta = const VerificationMeta('gap');
  @override
  late final GeneratedColumn<int> gap = GeneratedColumn<int>(
    'gap',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [edition, page, gap, y];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'line_cut';
  @override
  VerificationContext validateIntegrity(
    Insertable<LineCutRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('edition')) {
      context.handle(
        _editionMeta,
        edition.isAcceptableOrUnknown(data['edition']!, _editionMeta),
      );
    } else if (isInserting) {
      context.missing(_editionMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('gap')) {
      context.handle(
        _gapMeta,
        gap.isAcceptableOrUnknown(data['gap']!, _gapMeta),
      );
    } else if (isInserting) {
      context.missing(_gapMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {edition, page, gap};
  @override
  LineCutRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LineCutRow(
      edition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edition'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      gap: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gap'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
    );
  }

  @override
  $LineCutTable createAlias(String alias) {
    return $LineCutTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class LineCutRow extends DataClass implements Insertable<LineCutRow> {
  final String edition;
  final int page;

  /// 0..13: the gap below line [gap].
  final int gap;

  /// Page units (1441) or image pixels (1405).
  final double y;
  const LineCutRow({
    required this.edition,
    required this.page,
    required this.gap,
    required this.y,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['edition'] = Variable<String>(edition);
    map['page'] = Variable<int>(page);
    map['gap'] = Variable<int>(gap);
    map['y'] = Variable<double>(y);
    return map;
  }

  LineCutCompanion toCompanion(bool nullToAbsent) {
    return LineCutCompanion(
      edition: Value(edition),
      page: Value(page),
      gap: Value(gap),
      y: Value(y),
    );
  }

  factory LineCutRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LineCutRow(
      edition: serializer.fromJson<String>(json['edition']),
      page: serializer.fromJson<int>(json['page']),
      gap: serializer.fromJson<int>(json['gap']),
      y: serializer.fromJson<double>(json['y']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'edition': serializer.toJson<String>(edition),
      'page': serializer.toJson<int>(page),
      'gap': serializer.toJson<int>(gap),
      'y': serializer.toJson<double>(y),
    };
  }

  LineCutRow copyWith({String? edition, int? page, int? gap, double? y}) =>
      LineCutRow(
        edition: edition ?? this.edition,
        page: page ?? this.page,
        gap: gap ?? this.gap,
        y: y ?? this.y,
      );
  LineCutRow copyWithCompanion(LineCutCompanion data) {
    return LineCutRow(
      edition: data.edition.present ? data.edition.value : this.edition,
      page: data.page.present ? data.page.value : this.page,
      gap: data.gap.present ? data.gap.value : this.gap,
      y: data.y.present ? data.y.value : this.y,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LineCutRow(')
          ..write('edition: $edition, ')
          ..write('page: $page, ')
          ..write('gap: $gap, ')
          ..write('y: $y')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(edition, page, gap, y);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LineCutRow &&
          other.edition == this.edition &&
          other.page == this.page &&
          other.gap == this.gap &&
          other.y == this.y);
}

class LineCutCompanion extends UpdateCompanion<LineCutRow> {
  final Value<String> edition;
  final Value<int> page;
  final Value<int> gap;
  final Value<double> y;
  const LineCutCompanion({
    this.edition = const Value.absent(),
    this.page = const Value.absent(),
    this.gap = const Value.absent(),
    this.y = const Value.absent(),
  });
  LineCutCompanion.insert({
    required String edition,
    required int page,
    required int gap,
    required double y,
  }) : edition = Value(edition),
       page = Value(page),
       gap = Value(gap),
       y = Value(y);
  static Insertable<LineCutRow> custom({
    Expression<String>? edition,
    Expression<int>? page,
    Expression<int>? gap,
    Expression<double>? y,
  }) {
    return RawValuesInsertable({
      if (edition != null) 'edition': edition,
      if (page != null) 'page': page,
      if (gap != null) 'gap': gap,
      if (y != null) 'y': y,
    });
  }

  LineCutCompanion copyWith({
    Value<String>? edition,
    Value<int>? page,
    Value<int>? gap,
    Value<double>? y,
  }) {
    return LineCutCompanion(
      edition: edition ?? this.edition,
      page: page ?? this.page,
      gap: gap ?? this.gap,
      y: y ?? this.y,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (edition.present) {
      map['edition'] = Variable<String>(edition.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (gap.present) {
      map['gap'] = Variable<int>(gap.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LineCutCompanion(')
          ..write('edition: $edition, ')
          ..write('page: $page, ')
          ..write('gap: $gap, ')
          ..write('y: $y')
          ..write(')'))
        .toString();
  }
}

class $LineOverflowTable extends LineOverflow
    with TableInfo<$LineOverflowTable, LineOverflowRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LineOverflowTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineMeta = const VerificationMeta('line');
  @override
  late final GeneratedColumn<int> line = GeneratedColumn<int>(
    'line',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [page, line, path];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'line_overflow';
  @override
  VerificationContext validateIntegrity(
    Insertable<LineOverflowRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('line')) {
      context.handle(
        _lineMeta,
        line.isAcceptableOrUnknown(data['line']!, _lineMeta),
      );
    } else if (isInserting) {
      context.missing(_lineMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {page, line, path};
  @override
  LineOverflowRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LineOverflowRow(
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      line: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
    );
  }

  @override
  $LineOverflowTable createAlias(String alias) {
    return $LineOverflowTable(attachedDatabase, alias);
  }
}

class LineOverflowRow extends DataClass implements Insertable<LineOverflowRow> {
  final int page;
  final int line;
  final String path;
  const LineOverflowRow({
    required this.page,
    required this.line,
    required this.path,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['page'] = Variable<int>(page);
    map['line'] = Variable<int>(line);
    map['path'] = Variable<String>(path);
    return map;
  }

  LineOverflowCompanion toCompanion(bool nullToAbsent) {
    return LineOverflowCompanion(
      page: Value(page),
      line: Value(line),
      path: Value(path),
    );
  }

  factory LineOverflowRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LineOverflowRow(
      page: serializer.fromJson<int>(json['page']),
      line: serializer.fromJson<int>(json['line']),
      path: serializer.fromJson<String>(json['path']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'page': serializer.toJson<int>(page),
      'line': serializer.toJson<int>(line),
      'path': serializer.toJson<String>(path),
    };
  }

  LineOverflowRow copyWith({int? page, int? line, String? path}) =>
      LineOverflowRow(
        page: page ?? this.page,
        line: line ?? this.line,
        path: path ?? this.path,
      );
  LineOverflowRow copyWithCompanion(LineOverflowCompanion data) {
    return LineOverflowRow(
      page: data.page.present ? data.page.value : this.page,
      line: data.line.present ? data.line.value : this.line,
      path: data.path.present ? data.path.value : this.path,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LineOverflowRow(')
          ..write('page: $page, ')
          ..write('line: $line, ')
          ..write('path: $path')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(page, line, path);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LineOverflowRow &&
          other.page == this.page &&
          other.line == this.line &&
          other.path == this.path);
}

class LineOverflowCompanion extends UpdateCompanion<LineOverflowRow> {
  final Value<int> page;
  final Value<int> line;
  final Value<String> path;
  final Value<int> rowid;
  const LineOverflowCompanion({
    this.page = const Value.absent(),
    this.line = const Value.absent(),
    this.path = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LineOverflowCompanion.insert({
    required int page,
    required int line,
    required String path,
    this.rowid = const Value.absent(),
  }) : page = Value(page),
       line = Value(line),
       path = Value(path);
  static Insertable<LineOverflowRow> custom({
    Expression<int>? page,
    Expression<int>? line,
    Expression<String>? path,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (page != null) 'page': page,
      if (line != null) 'line': line,
      if (path != null) 'path': path,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LineOverflowCompanion copyWith({
    Value<int>? page,
    Value<int>? line,
    Value<String>? path,
    Value<int>? rowid,
  }) {
    return LineOverflowCompanion(
      page: page ?? this.page,
      line: line ?? this.line,
      path: path ?? this.path,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (line.present) {
      map['line'] = Variable<int>(line.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LineOverflowCompanion(')
          ..write('page: $page, ')
          ..write('line: $line, ')
          ..write('path: $path, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LineOverflow1405Table extends LineOverflow1405
    with TableInfo<$LineOverflow1405Table, OldOverflowRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LineOverflow1405Table(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineMeta = const VerificationMeta('line');
  @override
  late final GeneratedColumn<int> line = GeneratedColumn<int>(
    'line',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _x0Meta = const VerificationMeta('x0');
  @override
  late final GeneratedColumn<int> x0 = GeneratedColumn<int>(
    'x0',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y0Meta = const VerificationMeta('y0');
  @override
  late final GeneratedColumn<int> y0 = GeneratedColumn<int>(
    'y0',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _x1Meta = const VerificationMeta('x1');
  @override
  late final GeneratedColumn<int> x1 = GeneratedColumn<int>(
    'x1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y1Meta = const VerificationMeta('y1');
  @override
  late final GeneratedColumn<int> y1 = GeneratedColumn<int>(
    'y1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [page, line, x0, y0, x1, y1];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'line_overflow_1405';
  @override
  VerificationContext validateIntegrity(
    Insertable<OldOverflowRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('line')) {
      context.handle(
        _lineMeta,
        line.isAcceptableOrUnknown(data['line']!, _lineMeta),
      );
    } else if (isInserting) {
      context.missing(_lineMeta);
    }
    if (data.containsKey('x0')) {
      context.handle(_x0Meta, x0.isAcceptableOrUnknown(data['x0']!, _x0Meta));
    } else if (isInserting) {
      context.missing(_x0Meta);
    }
    if (data.containsKey('y0')) {
      context.handle(_y0Meta, y0.isAcceptableOrUnknown(data['y0']!, _y0Meta));
    } else if (isInserting) {
      context.missing(_y0Meta);
    }
    if (data.containsKey('x1')) {
      context.handle(_x1Meta, x1.isAcceptableOrUnknown(data['x1']!, _x1Meta));
    } else if (isInserting) {
      context.missing(_x1Meta);
    }
    if (data.containsKey('y1')) {
      context.handle(_y1Meta, y1.isAcceptableOrUnknown(data['y1']!, _y1Meta));
    } else if (isInserting) {
      context.missing(_y1Meta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {page, line, x0, y0};
  @override
  OldOverflowRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OldOverflowRow(
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      line: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line'],
      )!,
      x0: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x0'],
      )!,
      y0: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y0'],
      )!,
      x1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x1'],
      )!,
      y1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y1'],
      )!,
    );
  }

  @override
  $LineOverflow1405Table createAlias(String alias) {
    return $LineOverflow1405Table(attachedDatabase, alias);
  }
}

class OldOverflowRow extends DataClass implements Insertable<OldOverflowRow> {
  final int page;
  final int line;
  final int x0;
  final int y0;
  final int x1;
  final int y1;
  const OldOverflowRow({
    required this.page,
    required this.line,
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['page'] = Variable<int>(page);
    map['line'] = Variable<int>(line);
    map['x0'] = Variable<int>(x0);
    map['y0'] = Variable<int>(y0);
    map['x1'] = Variable<int>(x1);
    map['y1'] = Variable<int>(y1);
    return map;
  }

  LineOverflow1405Companion toCompanion(bool nullToAbsent) {
    return LineOverflow1405Companion(
      page: Value(page),
      line: Value(line),
      x0: Value(x0),
      y0: Value(y0),
      x1: Value(x1),
      y1: Value(y1),
    );
  }

  factory OldOverflowRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OldOverflowRow(
      page: serializer.fromJson<int>(json['page']),
      line: serializer.fromJson<int>(json['line']),
      x0: serializer.fromJson<int>(json['x0']),
      y0: serializer.fromJson<int>(json['y0']),
      x1: serializer.fromJson<int>(json['x1']),
      y1: serializer.fromJson<int>(json['y1']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'page': serializer.toJson<int>(page),
      'line': serializer.toJson<int>(line),
      'x0': serializer.toJson<int>(x0),
      'y0': serializer.toJson<int>(y0),
      'x1': serializer.toJson<int>(x1),
      'y1': serializer.toJson<int>(y1),
    };
  }

  OldOverflowRow copyWith({
    int? page,
    int? line,
    int? x0,
    int? y0,
    int? x1,
    int? y1,
  }) => OldOverflowRow(
    page: page ?? this.page,
    line: line ?? this.line,
    x0: x0 ?? this.x0,
    y0: y0 ?? this.y0,
    x1: x1 ?? this.x1,
    y1: y1 ?? this.y1,
  );
  OldOverflowRow copyWithCompanion(LineOverflow1405Companion data) {
    return OldOverflowRow(
      page: data.page.present ? data.page.value : this.page,
      line: data.line.present ? data.line.value : this.line,
      x0: data.x0.present ? data.x0.value : this.x0,
      y0: data.y0.present ? data.y0.value : this.y0,
      x1: data.x1.present ? data.x1.value : this.x1,
      y1: data.y1.present ? data.y1.value : this.y1,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OldOverflowRow(')
          ..write('page: $page, ')
          ..write('line: $line, ')
          ..write('x0: $x0, ')
          ..write('y0: $y0, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(page, line, x0, y0, x1, y1);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OldOverflowRow &&
          other.page == this.page &&
          other.line == this.line &&
          other.x0 == this.x0 &&
          other.y0 == this.y0 &&
          other.x1 == this.x1 &&
          other.y1 == this.y1);
}

class LineOverflow1405Companion extends UpdateCompanion<OldOverflowRow> {
  final Value<int> page;
  final Value<int> line;
  final Value<int> x0;
  final Value<int> y0;
  final Value<int> x1;
  final Value<int> y1;
  final Value<int> rowid;
  const LineOverflow1405Companion({
    this.page = const Value.absent(),
    this.line = const Value.absent(),
    this.x0 = const Value.absent(),
    this.y0 = const Value.absent(),
    this.x1 = const Value.absent(),
    this.y1 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LineOverflow1405Companion.insert({
    required int page,
    required int line,
    required int x0,
    required int y0,
    required int x1,
    required int y1,
    this.rowid = const Value.absent(),
  }) : page = Value(page),
       line = Value(line),
       x0 = Value(x0),
       y0 = Value(y0),
       x1 = Value(x1),
       y1 = Value(y1);
  static Insertable<OldOverflowRow> custom({
    Expression<int>? page,
    Expression<int>? line,
    Expression<int>? x0,
    Expression<int>? y0,
    Expression<int>? x1,
    Expression<int>? y1,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (page != null) 'page': page,
      if (line != null) 'line': line,
      if (x0 != null) 'x0': x0,
      if (y0 != null) 'y0': y0,
      if (x1 != null) 'x1': x1,
      if (y1 != null) 'y1': y1,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LineOverflow1405Companion copyWith({
    Value<int>? page,
    Value<int>? line,
    Value<int>? x0,
    Value<int>? y0,
    Value<int>? x1,
    Value<int>? y1,
    Value<int>? rowid,
  }) {
    return LineOverflow1405Companion(
      page: page ?? this.page,
      line: line ?? this.line,
      x0: x0 ?? this.x0,
      y0: y0 ?? this.y0,
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (line.present) {
      map['line'] = Variable<int>(line.value);
    }
    if (x0.present) {
      map['x0'] = Variable<int>(x0.value);
    }
    if (y0.present) {
      map['y0'] = Variable<int>(y0.value);
    }
    if (x1.present) {
      map['x1'] = Variable<int>(x1.value);
    }
    if (y1.present) {
      map['y1'] = Variable<int>(y1.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LineOverflow1405Companion(')
          ..write('page: $page, ')
          ..write('line: $line, ')
          ..write('x0: $x0, ')
          ..write('y0: $y0, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CommentaryEditionTable extends CommentaryEdition
    with TableInfo<$CommentaryEditionTable, CommentaryEditionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommentaryEditionTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceId,
    kind,
    language,
    direction,
    nameAr,
    nameEn,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'commentary_edition';
  @override
  VerificationContext validateIntegrity(
    Insertable<CommentaryEditionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
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
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    } else if (isInserting) {
      context.missing(_nameArMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId};
  @override
  CommentaryEditionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CommentaryEditionRow(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CommentaryEditionTable createAlias(String alias) {
    return $CommentaryEditionTable(attachedDatabase, alias);
  }
}

class CommentaryEditionRow extends DataClass
    implements Insertable<CommentaryEditionRow> {
  final int sourceId;

  /// `tafsir` or `translation`.
  final String kind;
  final String language;

  /// `rtl` or `ltr`.
  final String direction;
  final String nameAr;
  final String nameEn;
  final int sortOrder;
  const CommentaryEditionRow({
    required this.sourceId,
    required this.kind,
    required this.language,
    required this.direction,
    required this.nameAr,
    required this.nameEn,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    map['kind'] = Variable<String>(kind);
    map['language'] = Variable<String>(language);
    map['direction'] = Variable<String>(direction);
    map['name_ar'] = Variable<String>(nameAr);
    map['name_en'] = Variable<String>(nameEn);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CommentaryEditionCompanion toCompanion(bool nullToAbsent) {
    return CommentaryEditionCompanion(
      sourceId: Value(sourceId),
      kind: Value(kind),
      language: Value(language),
      direction: Value(direction),
      nameAr: Value(nameAr),
      nameEn: Value(nameEn),
      sortOrder: Value(sortOrder),
    );
  }

  factory CommentaryEditionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CommentaryEditionRow(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      kind: serializer.fromJson<String>(json['kind']),
      language: serializer.fromJson<String>(json['language']),
      direction: serializer.fromJson<String>(json['direction']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'kind': serializer.toJson<String>(kind),
      'language': serializer.toJson<String>(language),
      'direction': serializer.toJson<String>(direction),
      'nameAr': serializer.toJson<String>(nameAr),
      'nameEn': serializer.toJson<String>(nameEn),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CommentaryEditionRow copyWith({
    int? sourceId,
    String? kind,
    String? language,
    String? direction,
    String? nameAr,
    String? nameEn,
    int? sortOrder,
  }) => CommentaryEditionRow(
    sourceId: sourceId ?? this.sourceId,
    kind: kind ?? this.kind,
    language: language ?? this.language,
    direction: direction ?? this.direction,
    nameAr: nameAr ?? this.nameAr,
    nameEn: nameEn ?? this.nameEn,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CommentaryEditionRow copyWithCompanion(CommentaryEditionCompanion data) {
    return CommentaryEditionRow(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      kind: data.kind.present ? data.kind.value : this.kind,
      language: data.language.present ? data.language.value : this.language,
      direction: data.direction.present ? data.direction.value : this.direction,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CommentaryEditionRow(')
          ..write('sourceId: $sourceId, ')
          ..write('kind: $kind, ')
          ..write('language: $language, ')
          ..write('direction: $direction, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sourceId,
    kind,
    language,
    direction,
    nameAr,
    nameEn,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommentaryEditionRow &&
          other.sourceId == this.sourceId &&
          other.kind == this.kind &&
          other.language == this.language &&
          other.direction == this.direction &&
          other.nameAr == this.nameAr &&
          other.nameEn == this.nameEn &&
          other.sortOrder == this.sortOrder);
}

class CommentaryEditionCompanion extends UpdateCompanion<CommentaryEditionRow> {
  final Value<int> sourceId;
  final Value<String> kind;
  final Value<String> language;
  final Value<String> direction;
  final Value<String> nameAr;
  final Value<String> nameEn;
  final Value<int> sortOrder;
  const CommentaryEditionCompanion({
    this.sourceId = const Value.absent(),
    this.kind = const Value.absent(),
    this.language = const Value.absent(),
    this.direction = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  CommentaryEditionCompanion.insert({
    this.sourceId = const Value.absent(),
    required String kind,
    required String language,
    required String direction,
    required String nameAr,
    required String nameEn,
    required int sortOrder,
  }) : kind = Value(kind),
       language = Value(language),
       direction = Value(direction),
       nameAr = Value(nameAr),
       nameEn = Value(nameEn),
       sortOrder = Value(sortOrder);
  static Insertable<CommentaryEditionRow> custom({
    Expression<int>? sourceId,
    Expression<String>? kind,
    Expression<String>? language,
    Expression<String>? direction,
    Expression<String>? nameAr,
    Expression<String>? nameEn,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (kind != null) 'kind': kind,
      if (language != null) 'language': language,
      if (direction != null) 'direction': direction,
      if (nameAr != null) 'name_ar': nameAr,
      if (nameEn != null) 'name_en': nameEn,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  CommentaryEditionCompanion copyWith({
    Value<int>? sourceId,
    Value<String>? kind,
    Value<String>? language,
    Value<String>? direction,
    Value<String>? nameAr,
    Value<String>? nameEn,
    Value<int>? sortOrder,
  }) {
    return CommentaryEditionCompanion(
      sourceId: sourceId ?? this.sourceId,
      kind: kind ?? this.kind,
      language: language ?? this.language,
      direction: direction ?? this.direction,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommentaryEditionCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('kind: $kind, ')
          ..write('language: $language, ')
          ..write('direction: $direction, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $CommentaryTable extends Commentary
    with TableInfo<$CommentaryTable, CommentaryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommentaryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _footnotesMeta = const VerificationMeta(
    'footnotes',
  );
  @override
  late final GeneratedColumn<String> footnotes = GeneratedColumn<String>(
    'footnotes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceId,
    surah,
    ayah,
    body,
    footnotes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'commentary';
  @override
  VerificationContext validateIntegrity(
    Insertable<CommentaryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['text']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('footnotes')) {
      context.handle(
        _footnotesMeta,
        footnotes.isAcceptableOrUnknown(data['footnotes']!, _footnotesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, surah, ayah};
  @override
  CommentaryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CommentaryRow(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      footnotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}footnotes'],
      ),
    );
  }

  @override
  $CommentaryTable createAlias(String alias) {
    return $CommentaryTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class CommentaryRow extends DataClass implements Insertable<CommentaryRow> {
  final int sourceId;
  final int surah;
  final int ayah;
  final String body;
  final String? footnotes;
  const CommentaryRow({
    required this.sourceId,
    required this.surah,
    required this.ayah,
    required this.body,
    this.footnotes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['text'] = Variable<String>(body);
    if (!nullToAbsent || footnotes != null) {
      map['footnotes'] = Variable<String>(footnotes);
    }
    return map;
  }

  CommentaryCompanion toCompanion(bool nullToAbsent) {
    return CommentaryCompanion(
      sourceId: Value(sourceId),
      surah: Value(surah),
      ayah: Value(ayah),
      body: Value(body),
      footnotes: footnotes == null && nullToAbsent
          ? const Value.absent()
          : Value(footnotes),
    );
  }

  factory CommentaryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CommentaryRow(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      body: serializer.fromJson<String>(json['body']),
      footnotes: serializer.fromJson<String?>(json['footnotes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'body': serializer.toJson<String>(body),
      'footnotes': serializer.toJson<String?>(footnotes),
    };
  }

  CommentaryRow copyWith({
    int? sourceId,
    int? surah,
    int? ayah,
    String? body,
    Value<String?> footnotes = const Value.absent(),
  }) => CommentaryRow(
    sourceId: sourceId ?? this.sourceId,
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    body: body ?? this.body,
    footnotes: footnotes.present ? footnotes.value : this.footnotes,
  );
  CommentaryRow copyWithCompanion(CommentaryCompanion data) {
    return CommentaryRow(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      body: data.body.present ? data.body.value : this.body,
      footnotes: data.footnotes.present ? data.footnotes.value : this.footnotes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CommentaryRow(')
          ..write('sourceId: $sourceId, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('body: $body, ')
          ..write('footnotes: $footnotes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceId, surah, ayah, body, footnotes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommentaryRow &&
          other.sourceId == this.sourceId &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.body == this.body &&
          other.footnotes == this.footnotes);
}

class CommentaryCompanion extends UpdateCompanion<CommentaryRow> {
  final Value<int> sourceId;
  final Value<int> surah;
  final Value<int> ayah;
  final Value<String> body;
  final Value<String?> footnotes;
  const CommentaryCompanion({
    this.sourceId = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.body = const Value.absent(),
    this.footnotes = const Value.absent(),
  });
  CommentaryCompanion.insert({
    required int sourceId,
    required int surah,
    required int ayah,
    required String body,
    this.footnotes = const Value.absent(),
  }) : sourceId = Value(sourceId),
       surah = Value(surah),
       ayah = Value(ayah),
       body = Value(body);
  static Insertable<CommentaryRow> custom({
    Expression<int>? sourceId,
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<String>? body,
    Expression<String>? footnotes,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (body != null) 'text': body,
      if (footnotes != null) 'footnotes': footnotes,
    });
  }

  CommentaryCompanion copyWith({
    Value<int>? sourceId,
    Value<int>? surah,
    Value<int>? ayah,
    Value<String>? body,
    Value<String?>? footnotes,
  }) {
    return CommentaryCompanion(
      sourceId: sourceId ?? this.sourceId,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      body: body ?? this.body,
      footnotes: footnotes ?? this.footnotes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (body.present) {
      map['text'] = Variable<String>(body.value);
    }
    if (footnotes.present) {
      map['footnotes'] = Variable<String>(footnotes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommentaryCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('body: $body, ')
          ..write('footnotes: $footnotes')
          ..write(')'))
        .toString();
  }
}

class $ReciterTable extends Reciter with TableInfo<$ReciterTable, ReciterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReciterTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
    'style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderUrlMeta = const VerificationMeta(
    'folderUrl',
  );
  @override
  late final GeneratedColumn<String> folderUrl = GeneratedColumn<String>(
    'folder_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nameAr,
    nameEn,
    style,
    folderUrl,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reciter';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReciterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    } else if (isInserting) {
      context.missing(_nameArMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('style')) {
      context.handle(
        _styleMeta,
        style.isAcceptableOrUnknown(data['style']!, _styleMeta),
      );
    } else if (isInserting) {
      context.missing(_styleMeta);
    }
    if (data.containsKey('folder_url')) {
      context.handle(
        _folderUrlMeta,
        folderUrl.isAcceptableOrUnknown(data['folder_url']!, _folderUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_folderUrlMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReciterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReciterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      style: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style'],
      )!,
      folderUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_url'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $ReciterTable createAlias(String alias) {
    return $ReciterTable(attachedDatabase, alias);
  }
}

class ReciterRow extends DataClass implements Insertable<ReciterRow> {
  final int id;
  final String nameAr;
  final String nameEn;

  /// `murattal`, and only that: the mujawwad readings are not offered.
  final String style;

  /// A surah's file is this URL followed by `NNN.mp3`.
  final String folderUrl;
  final int sourceId;
  const ReciterRow({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.style,
    required this.folderUrl,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name_ar'] = Variable<String>(nameAr);
    map['name_en'] = Variable<String>(nameEn);
    map['style'] = Variable<String>(style);
    map['folder_url'] = Variable<String>(folderUrl);
    map['source_id'] = Variable<int>(sourceId);
    return map;
  }

  ReciterCompanion toCompanion(bool nullToAbsent) {
    return ReciterCompanion(
      id: Value(id),
      nameAr: Value(nameAr),
      nameEn: Value(nameEn),
      style: Value(style),
      folderUrl: Value(folderUrl),
      sourceId: Value(sourceId),
    );
  }

  factory ReciterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReciterRow(
      id: serializer.fromJson<int>(json['id']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      style: serializer.fromJson<String>(json['style']),
      folderUrl: serializer.fromJson<String>(json['folderUrl']),
      sourceId: serializer.fromJson<int>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nameAr': serializer.toJson<String>(nameAr),
      'nameEn': serializer.toJson<String>(nameEn),
      'style': serializer.toJson<String>(style),
      'folderUrl': serializer.toJson<String>(folderUrl),
      'sourceId': serializer.toJson<int>(sourceId),
    };
  }

  ReciterRow copyWith({
    int? id,
    String? nameAr,
    String? nameEn,
    String? style,
    String? folderUrl,
    int? sourceId,
  }) => ReciterRow(
    id: id ?? this.id,
    nameAr: nameAr ?? this.nameAr,
    nameEn: nameEn ?? this.nameEn,
    style: style ?? this.style,
    folderUrl: folderUrl ?? this.folderUrl,
    sourceId: sourceId ?? this.sourceId,
  );
  ReciterRow copyWithCompanion(ReciterCompanion data) {
    return ReciterRow(
      id: data.id.present ? data.id.value : this.id,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      style: data.style.present ? data.style.value : this.style,
      folderUrl: data.folderUrl.present ? data.folderUrl.value : this.folderUrl,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReciterRow(')
          ..write('id: $id, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('style: $style, ')
          ..write('folderUrl: $folderUrl, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nameAr, nameEn, style, folderUrl, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReciterRow &&
          other.id == this.id &&
          other.nameAr == this.nameAr &&
          other.nameEn == this.nameEn &&
          other.style == this.style &&
          other.folderUrl == this.folderUrl &&
          other.sourceId == this.sourceId);
}

class ReciterCompanion extends UpdateCompanion<ReciterRow> {
  final Value<int> id;
  final Value<String> nameAr;
  final Value<String> nameEn;
  final Value<String> style;
  final Value<String> folderUrl;
  final Value<int> sourceId;
  const ReciterCompanion({
    this.id = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.style = const Value.absent(),
    this.folderUrl = const Value.absent(),
    this.sourceId = const Value.absent(),
  });
  ReciterCompanion.insert({
    this.id = const Value.absent(),
    required String nameAr,
    required String nameEn,
    required String style,
    required String folderUrl,
    required int sourceId,
  }) : nameAr = Value(nameAr),
       nameEn = Value(nameEn),
       style = Value(style),
       folderUrl = Value(folderUrl),
       sourceId = Value(sourceId);
  static Insertable<ReciterRow> custom({
    Expression<int>? id,
    Expression<String>? nameAr,
    Expression<String>? nameEn,
    Expression<String>? style,
    Expression<String>? folderUrl,
    Expression<int>? sourceId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameAr != null) 'name_ar': nameAr,
      if (nameEn != null) 'name_en': nameEn,
      if (style != null) 'style': style,
      if (folderUrl != null) 'folder_url': folderUrl,
      if (sourceId != null) 'source_id': sourceId,
    });
  }

  ReciterCompanion copyWith({
    Value<int>? id,
    Value<String>? nameAr,
    Value<String>? nameEn,
    Value<String>? style,
    Value<String>? folderUrl,
    Value<int>? sourceId,
  }) {
    return ReciterCompanion(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      style: style ?? this.style,
      folderUrl: folderUrl ?? this.folderUrl,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    if (folderUrl.present) {
      map['folder_url'] = Variable<String>(folderUrl.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReciterCompanion(')
          ..write('id: $id, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('style: $style, ')
          ..write('folderUrl: $folderUrl, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }
}

class $AyahTimingTable extends AyahTiming
    with TableInfo<$AyahTimingTable, AyahTimingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AyahTimingTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _reciterMeta = const VerificationMeta(
    'reciter',
  );
  @override
  late final GeneratedColumn<int> reciter = GeneratedColumn<int>(
    'reciter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMsMeta = const VerificationMeta(
    'startMs',
  );
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
    'start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMsMeta = const VerificationMeta('endMs');
  @override
  late final GeneratedColumn<int> endMs = GeneratedColumn<int>(
    'end_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [reciter, surah, ayah, startMs, endMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ayah_timing';
  @override
  VerificationContext validateIntegrity(
    Insertable<AyahTimingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('reciter')) {
      context.handle(
        _reciterMeta,
        reciter.isAcceptableOrUnknown(data['reciter']!, _reciterMeta),
      );
    } else if (isInserting) {
      context.missing(_reciterMeta);
    }
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('start_ms')) {
      context.handle(
        _startMsMeta,
        startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta),
      );
    } else if (isInserting) {
      context.missing(_startMsMeta);
    }
    if (data.containsKey('end_ms')) {
      context.handle(
        _endMsMeta,
        endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta),
      );
    } else if (isInserting) {
      context.missing(_endMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {reciter, surah, ayah};
  @override
  AyahTimingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AyahTimingRow(
      reciter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reciter'],
      )!,
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      )!,
      startMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ms'],
      )!,
      endMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_ms'],
      )!,
    );
  }

  @override
  $AyahTimingTable createAlias(String alias) {
    return $AyahTimingTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class AyahTimingRow extends DataClass implements Insertable<AyahTimingRow> {
  final int reciter;
  final int surah;
  final int ayah;
  final int startMs;
  final int endMs;
  const AyahTimingRow({
    required this.reciter,
    required this.surah,
    required this.ayah,
    required this.startMs,
    required this.endMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['reciter'] = Variable<int>(reciter);
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['start_ms'] = Variable<int>(startMs);
    map['end_ms'] = Variable<int>(endMs);
    return map;
  }

  AyahTimingCompanion toCompanion(bool nullToAbsent) {
    return AyahTimingCompanion(
      reciter: Value(reciter),
      surah: Value(surah),
      ayah: Value(ayah),
      startMs: Value(startMs),
      endMs: Value(endMs),
    );
  }

  factory AyahTimingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AyahTimingRow(
      reciter: serializer.fromJson<int>(json['reciter']),
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      startMs: serializer.fromJson<int>(json['startMs']),
      endMs: serializer.fromJson<int>(json['endMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'reciter': serializer.toJson<int>(reciter),
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'startMs': serializer.toJson<int>(startMs),
      'endMs': serializer.toJson<int>(endMs),
    };
  }

  AyahTimingRow copyWith({
    int? reciter,
    int? surah,
    int? ayah,
    int? startMs,
    int? endMs,
  }) => AyahTimingRow(
    reciter: reciter ?? this.reciter,
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    startMs: startMs ?? this.startMs,
    endMs: endMs ?? this.endMs,
  );
  AyahTimingRow copyWithCompanion(AyahTimingCompanion data) {
    return AyahTimingRow(
      reciter: data.reciter.present ? data.reciter.value : this.reciter,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AyahTimingRow(')
          ..write('reciter: $reciter, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(reciter, surah, ayah, startMs, endMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AyahTimingRow &&
          other.reciter == this.reciter &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs);
}

class AyahTimingCompanion extends UpdateCompanion<AyahTimingRow> {
  final Value<int> reciter;
  final Value<int> surah;
  final Value<int> ayah;
  final Value<int> startMs;
  final Value<int> endMs;
  const AyahTimingCompanion({
    this.reciter = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
  });
  AyahTimingCompanion.insert({
    required int reciter,
    required int surah,
    required int ayah,
    required int startMs,
    required int endMs,
  }) : reciter = Value(reciter),
       surah = Value(surah),
       ayah = Value(ayah),
       startMs = Value(startMs),
       endMs = Value(endMs);
  static Insertable<AyahTimingRow> custom({
    Expression<int>? reciter,
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<int>? startMs,
    Expression<int>? endMs,
  }) {
    return RawValuesInsertable({
      if (reciter != null) 'reciter': reciter,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
    });
  }

  AyahTimingCompanion copyWith({
    Value<int>? reciter,
    Value<int>? surah,
    Value<int>? ayah,
    Value<int>? startMs,
    Value<int>? endMs,
  }) {
    return AyahTimingCompanion(
      reciter: reciter ?? this.reciter,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (reciter.present) {
      map['reciter'] = Variable<int>(reciter.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = Variable<int>(endMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AyahTimingCompanion(')
          ..write('reciter: $reciter, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs')
          ..write(')'))
        .toString();
  }
}

class $WordTimingTable extends WordTiming
    with TableInfo<$WordTimingTable, WordTimingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordTimingTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _reciterMeta = const VerificationMeta(
    'reciter',
  );
  @override
  late final GeneratedColumn<int> reciter = GeneratedColumn<int>(
    'reciter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<int> word = GeneratedColumn<int>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMsMeta = const VerificationMeta(
    'startMs',
  );
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
    'start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMsMeta = const VerificationMeta('endMs');
  @override
  late final GeneratedColumn<int> endMs = GeneratedColumn<int>(
    'end_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    reciter,
    surah,
    ayah,
    word,
    startMs,
    endMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_timing';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordTimingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('reciter')) {
      context.handle(
        _reciterMeta,
        reciter.isAcceptableOrUnknown(data['reciter']!, _reciterMeta),
      );
    } else if (isInserting) {
      context.missing(_reciterMeta);
    }
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('start_ms')) {
      context.handle(
        _startMsMeta,
        startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta),
      );
    } else if (isInserting) {
      context.missing(_startMsMeta);
    }
    if (data.containsKey('end_ms')) {
      context.handle(
        _endMsMeta,
        endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta),
      );
    } else if (isInserting) {
      context.missing(_endMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {reciter, surah, ayah, word};
  @override
  WordTimingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordTimingRow(
      reciter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reciter'],
      )!,
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word'],
      )!,
      startMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ms'],
      )!,
      endMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_ms'],
      )!,
    );
  }

  @override
  $WordTimingTable createAlias(String alias) {
    return $WordTimingTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class WordTimingRow extends DataClass implements Insertable<WordTimingRow> {
  final int reciter;
  final int surah;
  final int ayah;
  final int word;
  final int startMs;
  final int endMs;
  const WordTimingRow({
    required this.reciter,
    required this.surah,
    required this.ayah,
    required this.word,
    required this.startMs,
    required this.endMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['reciter'] = Variable<int>(reciter);
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['word'] = Variable<int>(word);
    map['start_ms'] = Variable<int>(startMs);
    map['end_ms'] = Variable<int>(endMs);
    return map;
  }

  WordTimingCompanion toCompanion(bool nullToAbsent) {
    return WordTimingCompanion(
      reciter: Value(reciter),
      surah: Value(surah),
      ayah: Value(ayah),
      word: Value(word),
      startMs: Value(startMs),
      endMs: Value(endMs),
    );
  }

  factory WordTimingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordTimingRow(
      reciter: serializer.fromJson<int>(json['reciter']),
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      word: serializer.fromJson<int>(json['word']),
      startMs: serializer.fromJson<int>(json['startMs']),
      endMs: serializer.fromJson<int>(json['endMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'reciter': serializer.toJson<int>(reciter),
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'word': serializer.toJson<int>(word),
      'startMs': serializer.toJson<int>(startMs),
      'endMs': serializer.toJson<int>(endMs),
    };
  }

  WordTimingRow copyWith({
    int? reciter,
    int? surah,
    int? ayah,
    int? word,
    int? startMs,
    int? endMs,
  }) => WordTimingRow(
    reciter: reciter ?? this.reciter,
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    word: word ?? this.word,
    startMs: startMs ?? this.startMs,
    endMs: endMs ?? this.endMs,
  );
  WordTimingRow copyWithCompanion(WordTimingCompanion data) {
    return WordTimingRow(
      reciter: data.reciter.present ? data.reciter.value : this.reciter,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      word: data.word.present ? data.word.value : this.word,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordTimingRow(')
          ..write('reciter: $reciter, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('word: $word, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(reciter, surah, ayah, word, startMs, endMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordTimingRow &&
          other.reciter == this.reciter &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.word == this.word &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs);
}

class WordTimingCompanion extends UpdateCompanion<WordTimingRow> {
  final Value<int> reciter;
  final Value<int> surah;
  final Value<int> ayah;
  final Value<int> word;
  final Value<int> startMs;
  final Value<int> endMs;
  const WordTimingCompanion({
    this.reciter = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.word = const Value.absent(),
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
  });
  WordTimingCompanion.insert({
    required int reciter,
    required int surah,
    required int ayah,
    required int word,
    required int startMs,
    required int endMs,
  }) : reciter = Value(reciter),
       surah = Value(surah),
       ayah = Value(ayah),
       word = Value(word),
       startMs = Value(startMs),
       endMs = Value(endMs);
  static Insertable<WordTimingRow> custom({
    Expression<int>? reciter,
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<int>? word,
    Expression<int>? startMs,
    Expression<int>? endMs,
  }) {
    return RawValuesInsertable({
      if (reciter != null) 'reciter': reciter,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (word != null) 'word': word,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
    });
  }

  WordTimingCompanion copyWith({
    Value<int>? reciter,
    Value<int>? surah,
    Value<int>? ayah,
    Value<int>? word,
    Value<int>? startMs,
    Value<int>? endMs,
  }) {
    return WordTimingCompanion(
      reciter: reciter ?? this.reciter,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      word: word ?? this.word,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (reciter.present) {
      map['reciter'] = Variable<int>(reciter.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (word.present) {
      map['word'] = Variable<int>(word.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = Variable<int>(endMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordTimingCompanion(')
          ..write('reciter: $reciter, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('word: $word, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs')
          ..write(')'))
        .toString();
  }
}

class $AyahSpeechTable extends AyahSpeech
    with TableInfo<$AyahSpeechTable, AyahSpeechRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AyahSpeechTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _reciterMeta = const VerificationMeta(
    'reciter',
  );
  @override
  late final GeneratedColumn<int> reciter = GeneratedColumn<int>(
    'reciter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMsMeta = const VerificationMeta(
    'startMs',
  );
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
    'start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMsMeta = const VerificationMeta('endMs');
  @override
  late final GeneratedColumn<int> endMs = GeneratedColumn<int>(
    'end_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [reciter, surah, ayah, startMs, endMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ayah_speech';
  @override
  VerificationContext validateIntegrity(
    Insertable<AyahSpeechRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('reciter')) {
      context.handle(
        _reciterMeta,
        reciter.isAcceptableOrUnknown(data['reciter']!, _reciterMeta),
      );
    } else if (isInserting) {
      context.missing(_reciterMeta);
    }
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('start_ms')) {
      context.handle(
        _startMsMeta,
        startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta),
      );
    } else if (isInserting) {
      context.missing(_startMsMeta);
    }
    if (data.containsKey('end_ms')) {
      context.handle(
        _endMsMeta,
        endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta),
      );
    } else if (isInserting) {
      context.missing(_endMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {reciter, surah, ayah};
  @override
  AyahSpeechRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AyahSpeechRow(
      reciter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reciter'],
      )!,
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      )!,
      startMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ms'],
      )!,
      endMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_ms'],
      )!,
    );
  }

  @override
  $AyahSpeechTable createAlias(String alias) {
    return $AyahSpeechTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class AyahSpeechRow extends DataClass implements Insertable<AyahSpeechRow> {
  final int reciter;
  final int surah;
  final int ayah;
  final int startMs;
  final int endMs;
  const AyahSpeechRow({
    required this.reciter,
    required this.surah,
    required this.ayah,
    required this.startMs,
    required this.endMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['reciter'] = Variable<int>(reciter);
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['start_ms'] = Variable<int>(startMs);
    map['end_ms'] = Variable<int>(endMs);
    return map;
  }

  AyahSpeechCompanion toCompanion(bool nullToAbsent) {
    return AyahSpeechCompanion(
      reciter: Value(reciter),
      surah: Value(surah),
      ayah: Value(ayah),
      startMs: Value(startMs),
      endMs: Value(endMs),
    );
  }

  factory AyahSpeechRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AyahSpeechRow(
      reciter: serializer.fromJson<int>(json['reciter']),
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      startMs: serializer.fromJson<int>(json['startMs']),
      endMs: serializer.fromJson<int>(json['endMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'reciter': serializer.toJson<int>(reciter),
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'startMs': serializer.toJson<int>(startMs),
      'endMs': serializer.toJson<int>(endMs),
    };
  }

  AyahSpeechRow copyWith({
    int? reciter,
    int? surah,
    int? ayah,
    int? startMs,
    int? endMs,
  }) => AyahSpeechRow(
    reciter: reciter ?? this.reciter,
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    startMs: startMs ?? this.startMs,
    endMs: endMs ?? this.endMs,
  );
  AyahSpeechRow copyWithCompanion(AyahSpeechCompanion data) {
    return AyahSpeechRow(
      reciter: data.reciter.present ? data.reciter.value : this.reciter,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AyahSpeechRow(')
          ..write('reciter: $reciter, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(reciter, surah, ayah, startMs, endMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AyahSpeechRow &&
          other.reciter == this.reciter &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs);
}

class AyahSpeechCompanion extends UpdateCompanion<AyahSpeechRow> {
  final Value<int> reciter;
  final Value<int> surah;
  final Value<int> ayah;
  final Value<int> startMs;
  final Value<int> endMs;
  const AyahSpeechCompanion({
    this.reciter = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
  });
  AyahSpeechCompanion.insert({
    required int reciter,
    required int surah,
    required int ayah,
    required int startMs,
    required int endMs,
  }) : reciter = Value(reciter),
       surah = Value(surah),
       ayah = Value(ayah),
       startMs = Value(startMs),
       endMs = Value(endMs);
  static Insertable<AyahSpeechRow> custom({
    Expression<int>? reciter,
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<int>? startMs,
    Expression<int>? endMs,
  }) {
    return RawValuesInsertable({
      if (reciter != null) 'reciter': reciter,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
    });
  }

  AyahSpeechCompanion copyWith({
    Value<int>? reciter,
    Value<int>? surah,
    Value<int>? ayah,
    Value<int>? startMs,
    Value<int>? endMs,
  }) {
    return AyahSpeechCompanion(
      reciter: reciter ?? this.reciter,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (reciter.present) {
      map['reciter'] = Variable<int>(reciter.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = Variable<int>(endMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AyahSpeechCompanion(')
          ..write('reciter: $reciter, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs')
          ..write(')'))
        .toString();
  }
}

class $ShamarlyPageTable extends ShamarlyPage
    with TableInfo<$ShamarlyPageTable, ShamarlyPageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShamarlyPageTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _linesMeta = const VerificationMeta('lines');
  @override
  late final GeneratedColumn<int> lines = GeneratedColumn<int>(
    'lines',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gridTopMeta = const VerificationMeta(
    'gridTop',
  );
  @override
  late final GeneratedColumn<double> gridTop = GeneratedColumn<double>(
    'grid_top',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pitchMeta = const VerificationMeta('pitch');
  @override
  late final GeneratedColumn<double> pitch = GeneratedColumn<double>(
    'pitch',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [page, kind, lines, gridTop, pitch];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shamarly_page';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShamarlyPageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
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
    if (data.containsKey('lines')) {
      context.handle(
        _linesMeta,
        lines.isAcceptableOrUnknown(data['lines']!, _linesMeta),
      );
    } else if (isInserting) {
      context.missing(_linesMeta);
    }
    if (data.containsKey('grid_top')) {
      context.handle(
        _gridTopMeta,
        gridTop.isAcceptableOrUnknown(data['grid_top']!, _gridTopMeta),
      );
    }
    if (data.containsKey('pitch')) {
      context.handle(
        _pitchMeta,
        pitch.isAcceptableOrUnknown(data['pitch']!, _pitchMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {page};
  @override
  ShamarlyPageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShamarlyPageRow(
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      lines: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lines'],
      )!,
      gridTop: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grid_top'],
      ),
      pitch: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pitch'],
      ),
    );
  }

  @override
  $ShamarlyPageTable createAlias(String alias) {
    return $ShamarlyPageTable(attachedDatabase, alias);
  }
}

class ShamarlyPageRow extends DataClass implements Insertable<ShamarlyPageRow> {
  final int page;
  final String kind;
  final int lines;
  final double? gridTop;
  final double? pitch;
  const ShamarlyPageRow({
    required this.page,
    required this.kind,
    required this.lines,
    this.gridTop,
    this.pitch,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['page'] = Variable<int>(page);
    map['kind'] = Variable<String>(kind);
    map['lines'] = Variable<int>(lines);
    if (!nullToAbsent || gridTop != null) {
      map['grid_top'] = Variable<double>(gridTop);
    }
    if (!nullToAbsent || pitch != null) {
      map['pitch'] = Variable<double>(pitch);
    }
    return map;
  }

  ShamarlyPageCompanion toCompanion(bool nullToAbsent) {
    return ShamarlyPageCompanion(
      page: Value(page),
      kind: Value(kind),
      lines: Value(lines),
      gridTop: gridTop == null && nullToAbsent
          ? const Value.absent()
          : Value(gridTop),
      pitch: pitch == null && nullToAbsent
          ? const Value.absent()
          : Value(pitch),
    );
  }

  factory ShamarlyPageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShamarlyPageRow(
      page: serializer.fromJson<int>(json['page']),
      kind: serializer.fromJson<String>(json['kind']),
      lines: serializer.fromJson<int>(json['lines']),
      gridTop: serializer.fromJson<double?>(json['gridTop']),
      pitch: serializer.fromJson<double?>(json['pitch']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'page': serializer.toJson<int>(page),
      'kind': serializer.toJson<String>(kind),
      'lines': serializer.toJson<int>(lines),
      'gridTop': serializer.toJson<double?>(gridTop),
      'pitch': serializer.toJson<double?>(pitch),
    };
  }

  ShamarlyPageRow copyWith({
    int? page,
    String? kind,
    int? lines,
    Value<double?> gridTop = const Value.absent(),
    Value<double?> pitch = const Value.absent(),
  }) => ShamarlyPageRow(
    page: page ?? this.page,
    kind: kind ?? this.kind,
    lines: lines ?? this.lines,
    gridTop: gridTop.present ? gridTop.value : this.gridTop,
    pitch: pitch.present ? pitch.value : this.pitch,
  );
  ShamarlyPageRow copyWithCompanion(ShamarlyPageCompanion data) {
    return ShamarlyPageRow(
      page: data.page.present ? data.page.value : this.page,
      kind: data.kind.present ? data.kind.value : this.kind,
      lines: data.lines.present ? data.lines.value : this.lines,
      gridTop: data.gridTop.present ? data.gridTop.value : this.gridTop,
      pitch: data.pitch.present ? data.pitch.value : this.pitch,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShamarlyPageRow(')
          ..write('page: $page, ')
          ..write('kind: $kind, ')
          ..write('lines: $lines, ')
          ..write('gridTop: $gridTop, ')
          ..write('pitch: $pitch')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(page, kind, lines, gridTop, pitch);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShamarlyPageRow &&
          other.page == this.page &&
          other.kind == this.kind &&
          other.lines == this.lines &&
          other.gridTop == this.gridTop &&
          other.pitch == this.pitch);
}

class ShamarlyPageCompanion extends UpdateCompanion<ShamarlyPageRow> {
  final Value<int> page;
  final Value<String> kind;
  final Value<int> lines;
  final Value<double?> gridTop;
  final Value<double?> pitch;
  const ShamarlyPageCompanion({
    this.page = const Value.absent(),
    this.kind = const Value.absent(),
    this.lines = const Value.absent(),
    this.gridTop = const Value.absent(),
    this.pitch = const Value.absent(),
  });
  ShamarlyPageCompanion.insert({
    this.page = const Value.absent(),
    required String kind,
    required int lines,
    this.gridTop = const Value.absent(),
    this.pitch = const Value.absent(),
  }) : kind = Value(kind),
       lines = Value(lines);
  static Insertable<ShamarlyPageRow> custom({
    Expression<int>? page,
    Expression<String>? kind,
    Expression<int>? lines,
    Expression<double>? gridTop,
    Expression<double>? pitch,
  }) {
    return RawValuesInsertable({
      if (page != null) 'page': page,
      if (kind != null) 'kind': kind,
      if (lines != null) 'lines': lines,
      if (gridTop != null) 'grid_top': gridTop,
      if (pitch != null) 'pitch': pitch,
    });
  }

  ShamarlyPageCompanion copyWith({
    Value<int>? page,
    Value<String>? kind,
    Value<int>? lines,
    Value<double?>? gridTop,
    Value<double?>? pitch,
  }) {
    return ShamarlyPageCompanion(
      page: page ?? this.page,
      kind: kind ?? this.kind,
      lines: lines ?? this.lines,
      gridTop: gridTop ?? this.gridTop,
      pitch: pitch ?? this.pitch,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (lines.present) {
      map['lines'] = Variable<int>(lines.value);
    }
    if (gridTop.present) {
      map['grid_top'] = Variable<double>(gridTop.value);
    }
    if (pitch.present) {
      map['pitch'] = Variable<double>(pitch.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShamarlyPageCompanion(')
          ..write('page: $page, ')
          ..write('kind: $kind, ')
          ..write('lines: $lines, ')
          ..write('gridTop: $gridTop, ')
          ..write('pitch: $pitch')
          ..write(')'))
        .toString();
  }
}

class $ShamarlyLineTable extends ShamarlyLine
    with TableInfo<$ShamarlyLineTable, ShamarlyLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShamarlyLineTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineMeta = const VerificationMeta('line');
  @override
  late final GeneratedColumn<int> line = GeneratedColumn<int>(
    'line',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _y0Meta = const VerificationMeta('y0');
  @override
  late final GeneratedColumn<int> y0 = GeneratedColumn<int>(
    'y0',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y1Meta = const VerificationMeta('y1');
  @override
  late final GeneratedColumn<int> y1 = GeneratedColumn<int>(
    'y1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [page, line, kind, surah, y0, y1];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shamarly_line';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShamarlyLineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('line')) {
      context.handle(
        _lineMeta,
        line.isAcceptableOrUnknown(data['line']!, _lineMeta),
      );
    } else if (isInserting) {
      context.missing(_lineMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    }
    if (data.containsKey('y0')) {
      context.handle(_y0Meta, y0.isAcceptableOrUnknown(data['y0']!, _y0Meta));
    } else if (isInserting) {
      context.missing(_y0Meta);
    }
    if (data.containsKey('y1')) {
      context.handle(_y1Meta, y1.isAcceptableOrUnknown(data['y1']!, _y1Meta));
    } else if (isInserting) {
      context.missing(_y1Meta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {page, line};
  @override
  ShamarlyLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShamarlyLineRow(
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      line: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      ),
      y0: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y0'],
      )!,
      y1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y1'],
      )!,
    );
  }

  @override
  $ShamarlyLineTable createAlias(String alias) {
    return $ShamarlyLineTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class ShamarlyLineRow extends DataClass implements Insertable<ShamarlyLineRow> {
  final int page;
  final int line;
  final String kind;
  final int? surah;
  final int y0;
  final int y1;
  const ShamarlyLineRow({
    required this.page,
    required this.line,
    required this.kind,
    this.surah,
    required this.y0,
    required this.y1,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['page'] = Variable<int>(page);
    map['line'] = Variable<int>(line);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || surah != null) {
      map['surah'] = Variable<int>(surah);
    }
    map['y0'] = Variable<int>(y0);
    map['y1'] = Variable<int>(y1);
    return map;
  }

  ShamarlyLineCompanion toCompanion(bool nullToAbsent) {
    return ShamarlyLineCompanion(
      page: Value(page),
      line: Value(line),
      kind: Value(kind),
      surah: surah == null && nullToAbsent
          ? const Value.absent()
          : Value(surah),
      y0: Value(y0),
      y1: Value(y1),
    );
  }

  factory ShamarlyLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShamarlyLineRow(
      page: serializer.fromJson<int>(json['page']),
      line: serializer.fromJson<int>(json['line']),
      kind: serializer.fromJson<String>(json['kind']),
      surah: serializer.fromJson<int?>(json['surah']),
      y0: serializer.fromJson<int>(json['y0']),
      y1: serializer.fromJson<int>(json['y1']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'page': serializer.toJson<int>(page),
      'line': serializer.toJson<int>(line),
      'kind': serializer.toJson<String>(kind),
      'surah': serializer.toJson<int?>(surah),
      'y0': serializer.toJson<int>(y0),
      'y1': serializer.toJson<int>(y1),
    };
  }

  ShamarlyLineRow copyWith({
    int? page,
    int? line,
    String? kind,
    Value<int?> surah = const Value.absent(),
    int? y0,
    int? y1,
  }) => ShamarlyLineRow(
    page: page ?? this.page,
    line: line ?? this.line,
    kind: kind ?? this.kind,
    surah: surah.present ? surah.value : this.surah,
    y0: y0 ?? this.y0,
    y1: y1 ?? this.y1,
  );
  ShamarlyLineRow copyWithCompanion(ShamarlyLineCompanion data) {
    return ShamarlyLineRow(
      page: data.page.present ? data.page.value : this.page,
      line: data.line.present ? data.line.value : this.line,
      kind: data.kind.present ? data.kind.value : this.kind,
      surah: data.surah.present ? data.surah.value : this.surah,
      y0: data.y0.present ? data.y0.value : this.y0,
      y1: data.y1.present ? data.y1.value : this.y1,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShamarlyLineRow(')
          ..write('page: $page, ')
          ..write('line: $line, ')
          ..write('kind: $kind, ')
          ..write('surah: $surah, ')
          ..write('y0: $y0, ')
          ..write('y1: $y1')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(page, line, kind, surah, y0, y1);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShamarlyLineRow &&
          other.page == this.page &&
          other.line == this.line &&
          other.kind == this.kind &&
          other.surah == this.surah &&
          other.y0 == this.y0 &&
          other.y1 == this.y1);
}

class ShamarlyLineCompanion extends UpdateCompanion<ShamarlyLineRow> {
  final Value<int> page;
  final Value<int> line;
  final Value<String> kind;
  final Value<int?> surah;
  final Value<int> y0;
  final Value<int> y1;
  const ShamarlyLineCompanion({
    this.page = const Value.absent(),
    this.line = const Value.absent(),
    this.kind = const Value.absent(),
    this.surah = const Value.absent(),
    this.y0 = const Value.absent(),
    this.y1 = const Value.absent(),
  });
  ShamarlyLineCompanion.insert({
    required int page,
    required int line,
    required String kind,
    this.surah = const Value.absent(),
    required int y0,
    required int y1,
  }) : page = Value(page),
       line = Value(line),
       kind = Value(kind),
       y0 = Value(y0),
       y1 = Value(y1);
  static Insertable<ShamarlyLineRow> custom({
    Expression<int>? page,
    Expression<int>? line,
    Expression<String>? kind,
    Expression<int>? surah,
    Expression<int>? y0,
    Expression<int>? y1,
  }) {
    return RawValuesInsertable({
      if (page != null) 'page': page,
      if (line != null) 'line': line,
      if (kind != null) 'kind': kind,
      if (surah != null) 'surah': surah,
      if (y0 != null) 'y0': y0,
      if (y1 != null) 'y1': y1,
    });
  }

  ShamarlyLineCompanion copyWith({
    Value<int>? page,
    Value<int>? line,
    Value<String>? kind,
    Value<int?>? surah,
    Value<int>? y0,
    Value<int>? y1,
  }) {
    return ShamarlyLineCompanion(
      page: page ?? this.page,
      line: line ?? this.line,
      kind: kind ?? this.kind,
      surah: surah ?? this.surah,
      y0: y0 ?? this.y0,
      y1: y1 ?? this.y1,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (line.present) {
      map['line'] = Variable<int>(line.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (y0.present) {
      map['y0'] = Variable<int>(y0.value);
    }
    if (y1.present) {
      map['y1'] = Variable<int>(y1.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShamarlyLineCompanion(')
          ..write('page: $page, ')
          ..write('line: $line, ')
          ..write('kind: $kind, ')
          ..write('surah: $surah, ')
          ..write('y0: $y0, ')
          ..write('y1: $y1')
          ..write(')'))
        .toString();
  }
}

class $ShamarlyLineOverflowTable extends ShamarlyLineOverflow
    with TableInfo<$ShamarlyLineOverflowTable, ShamarlyOverflowRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShamarlyLineOverflowTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineMeta = const VerificationMeta('line');
  @override
  late final GeneratedColumn<int> line = GeneratedColumn<int>(
    'line',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _x0Meta = const VerificationMeta('x0');
  @override
  late final GeneratedColumn<int> x0 = GeneratedColumn<int>(
    'x0',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y0Meta = const VerificationMeta('y0');
  @override
  late final GeneratedColumn<int> y0 = GeneratedColumn<int>(
    'y0',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _x1Meta = const VerificationMeta('x1');
  @override
  late final GeneratedColumn<int> x1 = GeneratedColumn<int>(
    'x1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y1Meta = const VerificationMeta('y1');
  @override
  late final GeneratedColumn<int> y1 = GeneratedColumn<int>(
    'y1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [page, line, x0, y0, x1, y1];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shamarly_line_overflow';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShamarlyOverflowRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('line')) {
      context.handle(
        _lineMeta,
        line.isAcceptableOrUnknown(data['line']!, _lineMeta),
      );
    } else if (isInserting) {
      context.missing(_lineMeta);
    }
    if (data.containsKey('x0')) {
      context.handle(_x0Meta, x0.isAcceptableOrUnknown(data['x0']!, _x0Meta));
    } else if (isInserting) {
      context.missing(_x0Meta);
    }
    if (data.containsKey('y0')) {
      context.handle(_y0Meta, y0.isAcceptableOrUnknown(data['y0']!, _y0Meta));
    } else if (isInserting) {
      context.missing(_y0Meta);
    }
    if (data.containsKey('x1')) {
      context.handle(_x1Meta, x1.isAcceptableOrUnknown(data['x1']!, _x1Meta));
    } else if (isInserting) {
      context.missing(_x1Meta);
    }
    if (data.containsKey('y1')) {
      context.handle(_y1Meta, y1.isAcceptableOrUnknown(data['y1']!, _y1Meta));
    } else if (isInserting) {
      context.missing(_y1Meta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {page, line, x0, y0};
  @override
  ShamarlyOverflowRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShamarlyOverflowRow(
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      line: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line'],
      )!,
      x0: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x0'],
      )!,
      y0: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y0'],
      )!,
      x1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x1'],
      )!,
      y1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y1'],
      )!,
    );
  }

  @override
  $ShamarlyLineOverflowTable createAlias(String alias) {
    return $ShamarlyLineOverflowTable(attachedDatabase, alias);
  }
}

class ShamarlyOverflowRow extends DataClass
    implements Insertable<ShamarlyOverflowRow> {
  final int page;
  final int line;
  final int x0;
  final int y0;
  final int x1;
  final int y1;
  const ShamarlyOverflowRow({
    required this.page,
    required this.line,
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['page'] = Variable<int>(page);
    map['line'] = Variable<int>(line);
    map['x0'] = Variable<int>(x0);
    map['y0'] = Variable<int>(y0);
    map['x1'] = Variable<int>(x1);
    map['y1'] = Variable<int>(y1);
    return map;
  }

  ShamarlyLineOverflowCompanion toCompanion(bool nullToAbsent) {
    return ShamarlyLineOverflowCompanion(
      page: Value(page),
      line: Value(line),
      x0: Value(x0),
      y0: Value(y0),
      x1: Value(x1),
      y1: Value(y1),
    );
  }

  factory ShamarlyOverflowRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShamarlyOverflowRow(
      page: serializer.fromJson<int>(json['page']),
      line: serializer.fromJson<int>(json['line']),
      x0: serializer.fromJson<int>(json['x0']),
      y0: serializer.fromJson<int>(json['y0']),
      x1: serializer.fromJson<int>(json['x1']),
      y1: serializer.fromJson<int>(json['y1']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'page': serializer.toJson<int>(page),
      'line': serializer.toJson<int>(line),
      'x0': serializer.toJson<int>(x0),
      'y0': serializer.toJson<int>(y0),
      'x1': serializer.toJson<int>(x1),
      'y1': serializer.toJson<int>(y1),
    };
  }

  ShamarlyOverflowRow copyWith({
    int? page,
    int? line,
    int? x0,
    int? y0,
    int? x1,
    int? y1,
  }) => ShamarlyOverflowRow(
    page: page ?? this.page,
    line: line ?? this.line,
    x0: x0 ?? this.x0,
    y0: y0 ?? this.y0,
    x1: x1 ?? this.x1,
    y1: y1 ?? this.y1,
  );
  ShamarlyOverflowRow copyWithCompanion(ShamarlyLineOverflowCompanion data) {
    return ShamarlyOverflowRow(
      page: data.page.present ? data.page.value : this.page,
      line: data.line.present ? data.line.value : this.line,
      x0: data.x0.present ? data.x0.value : this.x0,
      y0: data.y0.present ? data.y0.value : this.y0,
      x1: data.x1.present ? data.x1.value : this.x1,
      y1: data.y1.present ? data.y1.value : this.y1,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShamarlyOverflowRow(')
          ..write('page: $page, ')
          ..write('line: $line, ')
          ..write('x0: $x0, ')
          ..write('y0: $y0, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(page, line, x0, y0, x1, y1);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShamarlyOverflowRow &&
          other.page == this.page &&
          other.line == this.line &&
          other.x0 == this.x0 &&
          other.y0 == this.y0 &&
          other.x1 == this.x1 &&
          other.y1 == this.y1);
}

class ShamarlyLineOverflowCompanion
    extends UpdateCompanion<ShamarlyOverflowRow> {
  final Value<int> page;
  final Value<int> line;
  final Value<int> x0;
  final Value<int> y0;
  final Value<int> x1;
  final Value<int> y1;
  final Value<int> rowid;
  const ShamarlyLineOverflowCompanion({
    this.page = const Value.absent(),
    this.line = const Value.absent(),
    this.x0 = const Value.absent(),
    this.y0 = const Value.absent(),
    this.x1 = const Value.absent(),
    this.y1 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShamarlyLineOverflowCompanion.insert({
    required int page,
    required int line,
    required int x0,
    required int y0,
    required int x1,
    required int y1,
    this.rowid = const Value.absent(),
  }) : page = Value(page),
       line = Value(line),
       x0 = Value(x0),
       y0 = Value(y0),
       x1 = Value(x1),
       y1 = Value(y1);
  static Insertable<ShamarlyOverflowRow> custom({
    Expression<int>? page,
    Expression<int>? line,
    Expression<int>? x0,
    Expression<int>? y0,
    Expression<int>? x1,
    Expression<int>? y1,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (page != null) 'page': page,
      if (line != null) 'line': line,
      if (x0 != null) 'x0': x0,
      if (y0 != null) 'y0': y0,
      if (x1 != null) 'x1': x1,
      if (y1 != null) 'y1': y1,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShamarlyLineOverflowCompanion copyWith({
    Value<int>? page,
    Value<int>? line,
    Value<int>? x0,
    Value<int>? y0,
    Value<int>? x1,
    Value<int>? y1,
    Value<int>? rowid,
  }) {
    return ShamarlyLineOverflowCompanion(
      page: page ?? this.page,
      line: line ?? this.line,
      x0: x0 ?? this.x0,
      y0: y0 ?? this.y0,
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (line.present) {
      map['line'] = Variable<int>(line.value);
    }
    if (x0.present) {
      map['x0'] = Variable<int>(x0.value);
    }
    if (y0.present) {
      map['y0'] = Variable<int>(y0.value);
    }
    if (x1.present) {
      map['x1'] = Variable<int>(x1.value);
    }
    if (y1.present) {
      map['y1'] = Variable<int>(y1.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShamarlyLineOverflowCompanion(')
          ..write('page: $page, ')
          ..write('line: $line, ')
          ..write('x0: $x0, ')
          ..write('y0: $y0, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShamarlyHeaderTable extends ShamarlyHeader
    with TableInfo<$ShamarlyHeaderTable, ShamarlyHeaderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShamarlyHeaderTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstLineMeta = const VerificationMeta(
    'firstLine',
  );
  @override
  late final GeneratedColumn<int> firstLine = GeneratedColumn<int>(
    'first_line',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _x0Meta = const VerificationMeta('x0');
  @override
  late final GeneratedColumn<int> x0 = GeneratedColumn<int>(
    'x0',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y0Meta = const VerificationMeta('y0');
  @override
  late final GeneratedColumn<int> y0 = GeneratedColumn<int>(
    'y0',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _x1Meta = const VerificationMeta('x1');
  @override
  late final GeneratedColumn<int> x1 = GeneratedColumn<int>(
    'x1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y1Meta = const VerificationMeta('y1');
  @override
  late final GeneratedColumn<int> y1 = GeneratedColumn<int>(
    'y1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    surah,
    page,
    firstLine,
    x0,
    y0,
    x1,
    y1,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shamarly_header';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShamarlyHeaderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('first_line')) {
      context.handle(
        _firstLineMeta,
        firstLine.isAcceptableOrUnknown(data['first_line']!, _firstLineMeta),
      );
    }
    if (data.containsKey('x0')) {
      context.handle(_x0Meta, x0.isAcceptableOrUnknown(data['x0']!, _x0Meta));
    } else if (isInserting) {
      context.missing(_x0Meta);
    }
    if (data.containsKey('y0')) {
      context.handle(_y0Meta, y0.isAcceptableOrUnknown(data['y0']!, _y0Meta));
    } else if (isInserting) {
      context.missing(_y0Meta);
    }
    if (data.containsKey('x1')) {
      context.handle(_x1Meta, x1.isAcceptableOrUnknown(data['x1']!, _x1Meta));
    } else if (isInserting) {
      context.missing(_x1Meta);
    }
    if (data.containsKey('y1')) {
      context.handle(_y1Meta, y1.isAcceptableOrUnknown(data['y1']!, _y1Meta));
    } else if (isInserting) {
      context.missing(_y1Meta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {surah};
  @override
  ShamarlyHeaderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShamarlyHeaderRow(
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      firstLine: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_line'],
      ),
      x0: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x0'],
      )!,
      y0: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y0'],
      )!,
      x1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x1'],
      )!,
      y1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y1'],
      )!,
    );
  }

  @override
  $ShamarlyHeaderTable createAlias(String alias) {
    return $ShamarlyHeaderTable(attachedDatabase, alias);
  }
}

class ShamarlyHeaderRow extends DataClass
    implements Insertable<ShamarlyHeaderRow> {
  final int surah;
  final int page;
  final int? firstLine;
  final int x0;
  final int y0;
  final int x1;
  final int y1;
  const ShamarlyHeaderRow({
    required this.surah,
    required this.page,
    this.firstLine,
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['surah'] = Variable<int>(surah);
    map['page'] = Variable<int>(page);
    if (!nullToAbsent || firstLine != null) {
      map['first_line'] = Variable<int>(firstLine);
    }
    map['x0'] = Variable<int>(x0);
    map['y0'] = Variable<int>(y0);
    map['x1'] = Variable<int>(x1);
    map['y1'] = Variable<int>(y1);
    return map;
  }

  ShamarlyHeaderCompanion toCompanion(bool nullToAbsent) {
    return ShamarlyHeaderCompanion(
      surah: Value(surah),
      page: Value(page),
      firstLine: firstLine == null && nullToAbsent
          ? const Value.absent()
          : Value(firstLine),
      x0: Value(x0),
      y0: Value(y0),
      x1: Value(x1),
      y1: Value(y1),
    );
  }

  factory ShamarlyHeaderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShamarlyHeaderRow(
      surah: serializer.fromJson<int>(json['surah']),
      page: serializer.fromJson<int>(json['page']),
      firstLine: serializer.fromJson<int?>(json['firstLine']),
      x0: serializer.fromJson<int>(json['x0']),
      y0: serializer.fromJson<int>(json['y0']),
      x1: serializer.fromJson<int>(json['x1']),
      y1: serializer.fromJson<int>(json['y1']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'surah': serializer.toJson<int>(surah),
      'page': serializer.toJson<int>(page),
      'firstLine': serializer.toJson<int?>(firstLine),
      'x0': serializer.toJson<int>(x0),
      'y0': serializer.toJson<int>(y0),
      'x1': serializer.toJson<int>(x1),
      'y1': serializer.toJson<int>(y1),
    };
  }

  ShamarlyHeaderRow copyWith({
    int? surah,
    int? page,
    Value<int?> firstLine = const Value.absent(),
    int? x0,
    int? y0,
    int? x1,
    int? y1,
  }) => ShamarlyHeaderRow(
    surah: surah ?? this.surah,
    page: page ?? this.page,
    firstLine: firstLine.present ? firstLine.value : this.firstLine,
    x0: x0 ?? this.x0,
    y0: y0 ?? this.y0,
    x1: x1 ?? this.x1,
    y1: y1 ?? this.y1,
  );
  ShamarlyHeaderRow copyWithCompanion(ShamarlyHeaderCompanion data) {
    return ShamarlyHeaderRow(
      surah: data.surah.present ? data.surah.value : this.surah,
      page: data.page.present ? data.page.value : this.page,
      firstLine: data.firstLine.present ? data.firstLine.value : this.firstLine,
      x0: data.x0.present ? data.x0.value : this.x0,
      y0: data.y0.present ? data.y0.value : this.y0,
      x1: data.x1.present ? data.x1.value : this.x1,
      y1: data.y1.present ? data.y1.value : this.y1,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShamarlyHeaderRow(')
          ..write('surah: $surah, ')
          ..write('page: $page, ')
          ..write('firstLine: $firstLine, ')
          ..write('x0: $x0, ')
          ..write('y0: $y0, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(surah, page, firstLine, x0, y0, x1, y1);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShamarlyHeaderRow &&
          other.surah == this.surah &&
          other.page == this.page &&
          other.firstLine == this.firstLine &&
          other.x0 == this.x0 &&
          other.y0 == this.y0 &&
          other.x1 == this.x1 &&
          other.y1 == this.y1);
}

class ShamarlyHeaderCompanion extends UpdateCompanion<ShamarlyHeaderRow> {
  final Value<int> surah;
  final Value<int> page;
  final Value<int?> firstLine;
  final Value<int> x0;
  final Value<int> y0;
  final Value<int> x1;
  final Value<int> y1;
  const ShamarlyHeaderCompanion({
    this.surah = const Value.absent(),
    this.page = const Value.absent(),
    this.firstLine = const Value.absent(),
    this.x0 = const Value.absent(),
    this.y0 = const Value.absent(),
    this.x1 = const Value.absent(),
    this.y1 = const Value.absent(),
  });
  ShamarlyHeaderCompanion.insert({
    this.surah = const Value.absent(),
    required int page,
    this.firstLine = const Value.absent(),
    required int x0,
    required int y0,
    required int x1,
    required int y1,
  }) : page = Value(page),
       x0 = Value(x0),
       y0 = Value(y0),
       x1 = Value(x1),
       y1 = Value(y1);
  static Insertable<ShamarlyHeaderRow> custom({
    Expression<int>? surah,
    Expression<int>? page,
    Expression<int>? firstLine,
    Expression<int>? x0,
    Expression<int>? y0,
    Expression<int>? x1,
    Expression<int>? y1,
  }) {
    return RawValuesInsertable({
      if (surah != null) 'surah': surah,
      if (page != null) 'page': page,
      if (firstLine != null) 'first_line': firstLine,
      if (x0 != null) 'x0': x0,
      if (y0 != null) 'y0': y0,
      if (x1 != null) 'x1': x1,
      if (y1 != null) 'y1': y1,
    });
  }

  ShamarlyHeaderCompanion copyWith({
    Value<int>? surah,
    Value<int>? page,
    Value<int?>? firstLine,
    Value<int>? x0,
    Value<int>? y0,
    Value<int>? x1,
    Value<int>? y1,
  }) {
    return ShamarlyHeaderCompanion(
      surah: surah ?? this.surah,
      page: page ?? this.page,
      firstLine: firstLine ?? this.firstLine,
      x0: x0 ?? this.x0,
      y0: y0 ?? this.y0,
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (firstLine.present) {
      map['first_line'] = Variable<int>(firstLine.value);
    }
    if (x0.present) {
      map['x0'] = Variable<int>(x0.value);
    }
    if (y0.present) {
      map['y0'] = Variable<int>(y0.value);
    }
    if (x1.present) {
      map['x1'] = Variable<int>(x1.value);
    }
    if (y1.present) {
      map['y1'] = Variable<int>(y1.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShamarlyHeaderCompanion(')
          ..write('surah: $surah, ')
          ..write('page: $page, ')
          ..write('firstLine: $firstLine, ')
          ..write('x0: $x0, ')
          ..write('y0: $y0, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1')
          ..write(')'))
        .toString();
  }
}

class $ShamarlyMarkerTable extends ShamarlyMarker
    with TableInfo<$ShamarlyMarkerTable, ShamarlyMarkerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShamarlyMarkerTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineMeta = const VerificationMeta('line');
  @override
  late final GeneratedColumn<int> line = GeneratedColumn<int>(
    'line',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _x0Meta = const VerificationMeta('x0');
  @override
  late final GeneratedColumn<int> x0 = GeneratedColumn<int>(
    'x0',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y0Meta = const VerificationMeta('y0');
  @override
  late final GeneratedColumn<int> y0 = GeneratedColumn<int>(
    'y0',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _x1Meta = const VerificationMeta('x1');
  @override
  late final GeneratedColumn<int> x1 = GeneratedColumn<int>(
    'x1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y1Meta = const VerificationMeta('y1');
  @override
  late final GeneratedColumn<int> y1 = GeneratedColumn<int>(
    'y1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    surah,
    ayah,
    page,
    line,
    x0,
    y0,
    x1,
    y1,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shamarly_marker';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShamarlyMarkerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('line')) {
      context.handle(
        _lineMeta,
        line.isAcceptableOrUnknown(data['line']!, _lineMeta),
      );
    } else if (isInserting) {
      context.missing(_lineMeta);
    }
    if (data.containsKey('x0')) {
      context.handle(_x0Meta, x0.isAcceptableOrUnknown(data['x0']!, _x0Meta));
    } else if (isInserting) {
      context.missing(_x0Meta);
    }
    if (data.containsKey('y0')) {
      context.handle(_y0Meta, y0.isAcceptableOrUnknown(data['y0']!, _y0Meta));
    } else if (isInserting) {
      context.missing(_y0Meta);
    }
    if (data.containsKey('x1')) {
      context.handle(_x1Meta, x1.isAcceptableOrUnknown(data['x1']!, _x1Meta));
    } else if (isInserting) {
      context.missing(_x1Meta);
    }
    if (data.containsKey('y1')) {
      context.handle(_y1Meta, y1.isAcceptableOrUnknown(data['y1']!, _y1Meta));
    } else if (isInserting) {
      context.missing(_y1Meta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {surah, ayah};
  @override
  ShamarlyMarkerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShamarlyMarkerRow(
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      line: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line'],
      )!,
      x0: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x0'],
      )!,
      y0: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y0'],
      )!,
      x1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x1'],
      )!,
      y1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y1'],
      )!,
    );
  }

  @override
  $ShamarlyMarkerTable createAlias(String alias) {
    return $ShamarlyMarkerTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class ShamarlyMarkerRow extends DataClass
    implements Insertable<ShamarlyMarkerRow> {
  final int surah;
  final int ayah;
  final int page;
  final int line;
  final int x0;
  final int y0;
  final int x1;
  final int y1;
  const ShamarlyMarkerRow({
    required this.surah,
    required this.ayah,
    required this.page,
    required this.line,
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['page'] = Variable<int>(page);
    map['line'] = Variable<int>(line);
    map['x0'] = Variable<int>(x0);
    map['y0'] = Variable<int>(y0);
    map['x1'] = Variable<int>(x1);
    map['y1'] = Variable<int>(y1);
    return map;
  }

  ShamarlyMarkerCompanion toCompanion(bool nullToAbsent) {
    return ShamarlyMarkerCompanion(
      surah: Value(surah),
      ayah: Value(ayah),
      page: Value(page),
      line: Value(line),
      x0: Value(x0),
      y0: Value(y0),
      x1: Value(x1),
      y1: Value(y1),
    );
  }

  factory ShamarlyMarkerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShamarlyMarkerRow(
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      page: serializer.fromJson<int>(json['page']),
      line: serializer.fromJson<int>(json['line']),
      x0: serializer.fromJson<int>(json['x0']),
      y0: serializer.fromJson<int>(json['y0']),
      x1: serializer.fromJson<int>(json['x1']),
      y1: serializer.fromJson<int>(json['y1']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'page': serializer.toJson<int>(page),
      'line': serializer.toJson<int>(line),
      'x0': serializer.toJson<int>(x0),
      'y0': serializer.toJson<int>(y0),
      'x1': serializer.toJson<int>(x1),
      'y1': serializer.toJson<int>(y1),
    };
  }

  ShamarlyMarkerRow copyWith({
    int? surah,
    int? ayah,
    int? page,
    int? line,
    int? x0,
    int? y0,
    int? x1,
    int? y1,
  }) => ShamarlyMarkerRow(
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    page: page ?? this.page,
    line: line ?? this.line,
    x0: x0 ?? this.x0,
    y0: y0 ?? this.y0,
    x1: x1 ?? this.x1,
    y1: y1 ?? this.y1,
  );
  ShamarlyMarkerRow copyWithCompanion(ShamarlyMarkerCompanion data) {
    return ShamarlyMarkerRow(
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      page: data.page.present ? data.page.value : this.page,
      line: data.line.present ? data.line.value : this.line,
      x0: data.x0.present ? data.x0.value : this.x0,
      y0: data.y0.present ? data.y0.value : this.y0,
      x1: data.x1.present ? data.x1.value : this.x1,
      y1: data.y1.present ? data.y1.value : this.y1,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShamarlyMarkerRow(')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('page: $page, ')
          ..write('line: $line, ')
          ..write('x0: $x0, ')
          ..write('y0: $y0, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(surah, ayah, page, line, x0, y0, x1, y1);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShamarlyMarkerRow &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.page == this.page &&
          other.line == this.line &&
          other.x0 == this.x0 &&
          other.y0 == this.y0 &&
          other.x1 == this.x1 &&
          other.y1 == this.y1);
}

class ShamarlyMarkerCompanion extends UpdateCompanion<ShamarlyMarkerRow> {
  final Value<int> surah;
  final Value<int> ayah;
  final Value<int> page;
  final Value<int> line;
  final Value<int> x0;
  final Value<int> y0;
  final Value<int> x1;
  final Value<int> y1;
  const ShamarlyMarkerCompanion({
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.page = const Value.absent(),
    this.line = const Value.absent(),
    this.x0 = const Value.absent(),
    this.y0 = const Value.absent(),
    this.x1 = const Value.absent(),
    this.y1 = const Value.absent(),
  });
  ShamarlyMarkerCompanion.insert({
    required int surah,
    required int ayah,
    required int page,
    required int line,
    required int x0,
    required int y0,
    required int x1,
    required int y1,
  }) : surah = Value(surah),
       ayah = Value(ayah),
       page = Value(page),
       line = Value(line),
       x0 = Value(x0),
       y0 = Value(y0),
       x1 = Value(x1),
       y1 = Value(y1);
  static Insertable<ShamarlyMarkerRow> custom({
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<int>? page,
    Expression<int>? line,
    Expression<int>? x0,
    Expression<int>? y0,
    Expression<int>? x1,
    Expression<int>? y1,
  }) {
    return RawValuesInsertable({
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (page != null) 'page': page,
      if (line != null) 'line': line,
      if (x0 != null) 'x0': x0,
      if (y0 != null) 'y0': y0,
      if (x1 != null) 'x1': x1,
      if (y1 != null) 'y1': y1,
    });
  }

  ShamarlyMarkerCompanion copyWith({
    Value<int>? surah,
    Value<int>? ayah,
    Value<int>? page,
    Value<int>? line,
    Value<int>? x0,
    Value<int>? y0,
    Value<int>? x1,
    Value<int>? y1,
  }) {
    return ShamarlyMarkerCompanion(
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      page: page ?? this.page,
      line: line ?? this.line,
      x0: x0 ?? this.x0,
      y0: y0 ?? this.y0,
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (line.present) {
      map['line'] = Variable<int>(line.value);
    }
    if (x0.present) {
      map['x0'] = Variable<int>(x0.value);
    }
    if (y0.present) {
      map['y0'] = Variable<int>(y0.value);
    }
    if (x1.present) {
      map['x1'] = Variable<int>(x1.value);
    }
    if (y1.present) {
      map['y1'] = Variable<int>(y1.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShamarlyMarkerCompanion(')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('page: $page, ')
          ..write('line: $line, ')
          ..write('x0: $x0, ')
          ..write('y0: $y0, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1')
          ..write(')'))
        .toString();
  }
}

class $ShamarlyVerseBoxTable extends ShamarlyVerseBox
    with TableInfo<$ShamarlyVerseBoxTable, ShamarlyVerseBoxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShamarlyVerseBoxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partMeta = const VerificationMeta('part');
  @override
  late final GeneratedColumn<int> part = GeneratedColumn<int>(
    'part',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineMeta = const VerificationMeta('line');
  @override
  late final GeneratedColumn<int> line = GeneratedColumn<int>(
    'line',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _x0Meta = const VerificationMeta('x0');
  @override
  late final GeneratedColumn<int> x0 = GeneratedColumn<int>(
    'x0',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y0Meta = const VerificationMeta('y0');
  @override
  late final GeneratedColumn<int> y0 = GeneratedColumn<int>(
    'y0',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _x1Meta = const VerificationMeta('x1');
  @override
  late final GeneratedColumn<int> x1 = GeneratedColumn<int>(
    'x1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y1Meta = const VerificationMeta('y1');
  @override
  late final GeneratedColumn<int> y1 = GeneratedColumn<int>(
    'y1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    surah,
    ayah,
    part,
    page,
    line,
    x0,
    y0,
    x1,
    y1,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shamarly_verse_box';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShamarlyVerseBoxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('part')) {
      context.handle(
        _partMeta,
        part.isAcceptableOrUnknown(data['part']!, _partMeta),
      );
    } else if (isInserting) {
      context.missing(_partMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('line')) {
      context.handle(
        _lineMeta,
        line.isAcceptableOrUnknown(data['line']!, _lineMeta),
      );
    } else if (isInserting) {
      context.missing(_lineMeta);
    }
    if (data.containsKey('x0')) {
      context.handle(_x0Meta, x0.isAcceptableOrUnknown(data['x0']!, _x0Meta));
    } else if (isInserting) {
      context.missing(_x0Meta);
    }
    if (data.containsKey('y0')) {
      context.handle(_y0Meta, y0.isAcceptableOrUnknown(data['y0']!, _y0Meta));
    } else if (isInserting) {
      context.missing(_y0Meta);
    }
    if (data.containsKey('x1')) {
      context.handle(_x1Meta, x1.isAcceptableOrUnknown(data['x1']!, _x1Meta));
    } else if (isInserting) {
      context.missing(_x1Meta);
    }
    if (data.containsKey('y1')) {
      context.handle(_y1Meta, y1.isAcceptableOrUnknown(data['y1']!, _y1Meta));
    } else if (isInserting) {
      context.missing(_y1Meta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {surah, ayah, part};
  @override
  ShamarlyVerseBoxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShamarlyVerseBoxRow(
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      )!,
      part: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}part'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      line: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line'],
      )!,
      x0: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x0'],
      )!,
      y0: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y0'],
      )!,
      x1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x1'],
      )!,
      y1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y1'],
      )!,
    );
  }

  @override
  $ShamarlyVerseBoxTable createAlias(String alias) {
    return $ShamarlyVerseBoxTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class ShamarlyVerseBoxRow extends DataClass
    implements Insertable<ShamarlyVerseBoxRow> {
  final int surah;
  final int ayah;

  /// 0.. in reading order.
  final int part;
  final int page;
  final int line;
  final int x0;
  final int y0;
  final int x1;
  final int y1;
  const ShamarlyVerseBoxRow({
    required this.surah,
    required this.ayah,
    required this.part,
    required this.page,
    required this.line,
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['part'] = Variable<int>(part);
    map['page'] = Variable<int>(page);
    map['line'] = Variable<int>(line);
    map['x0'] = Variable<int>(x0);
    map['y0'] = Variable<int>(y0);
    map['x1'] = Variable<int>(x1);
    map['y1'] = Variable<int>(y1);
    return map;
  }

  ShamarlyVerseBoxCompanion toCompanion(bool nullToAbsent) {
    return ShamarlyVerseBoxCompanion(
      surah: Value(surah),
      ayah: Value(ayah),
      part: Value(part),
      page: Value(page),
      line: Value(line),
      x0: Value(x0),
      y0: Value(y0),
      x1: Value(x1),
      y1: Value(y1),
    );
  }

  factory ShamarlyVerseBoxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShamarlyVerseBoxRow(
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      part: serializer.fromJson<int>(json['part']),
      page: serializer.fromJson<int>(json['page']),
      line: serializer.fromJson<int>(json['line']),
      x0: serializer.fromJson<int>(json['x0']),
      y0: serializer.fromJson<int>(json['y0']),
      x1: serializer.fromJson<int>(json['x1']),
      y1: serializer.fromJson<int>(json['y1']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'part': serializer.toJson<int>(part),
      'page': serializer.toJson<int>(page),
      'line': serializer.toJson<int>(line),
      'x0': serializer.toJson<int>(x0),
      'y0': serializer.toJson<int>(y0),
      'x1': serializer.toJson<int>(x1),
      'y1': serializer.toJson<int>(y1),
    };
  }

  ShamarlyVerseBoxRow copyWith({
    int? surah,
    int? ayah,
    int? part,
    int? page,
    int? line,
    int? x0,
    int? y0,
    int? x1,
    int? y1,
  }) => ShamarlyVerseBoxRow(
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    part: part ?? this.part,
    page: page ?? this.page,
    line: line ?? this.line,
    x0: x0 ?? this.x0,
    y0: y0 ?? this.y0,
    x1: x1 ?? this.x1,
    y1: y1 ?? this.y1,
  );
  ShamarlyVerseBoxRow copyWithCompanion(ShamarlyVerseBoxCompanion data) {
    return ShamarlyVerseBoxRow(
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      part: data.part.present ? data.part.value : this.part,
      page: data.page.present ? data.page.value : this.page,
      line: data.line.present ? data.line.value : this.line,
      x0: data.x0.present ? data.x0.value : this.x0,
      y0: data.y0.present ? data.y0.value : this.y0,
      x1: data.x1.present ? data.x1.value : this.x1,
      y1: data.y1.present ? data.y1.value : this.y1,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShamarlyVerseBoxRow(')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('part: $part, ')
          ..write('page: $page, ')
          ..write('line: $line, ')
          ..write('x0: $x0, ')
          ..write('y0: $y0, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(surah, ayah, part, page, line, x0, y0, x1, y1);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShamarlyVerseBoxRow &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.part == this.part &&
          other.page == this.page &&
          other.line == this.line &&
          other.x0 == this.x0 &&
          other.y0 == this.y0 &&
          other.x1 == this.x1 &&
          other.y1 == this.y1);
}

class ShamarlyVerseBoxCompanion extends UpdateCompanion<ShamarlyVerseBoxRow> {
  final Value<int> surah;
  final Value<int> ayah;
  final Value<int> part;
  final Value<int> page;
  final Value<int> line;
  final Value<int> x0;
  final Value<int> y0;
  final Value<int> x1;
  final Value<int> y1;
  const ShamarlyVerseBoxCompanion({
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.part = const Value.absent(),
    this.page = const Value.absent(),
    this.line = const Value.absent(),
    this.x0 = const Value.absent(),
    this.y0 = const Value.absent(),
    this.x1 = const Value.absent(),
    this.y1 = const Value.absent(),
  });
  ShamarlyVerseBoxCompanion.insert({
    required int surah,
    required int ayah,
    required int part,
    required int page,
    required int line,
    required int x0,
    required int y0,
    required int x1,
    required int y1,
  }) : surah = Value(surah),
       ayah = Value(ayah),
       part = Value(part),
       page = Value(page),
       line = Value(line),
       x0 = Value(x0),
       y0 = Value(y0),
       x1 = Value(x1),
       y1 = Value(y1);
  static Insertable<ShamarlyVerseBoxRow> custom({
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<int>? part,
    Expression<int>? page,
    Expression<int>? line,
    Expression<int>? x0,
    Expression<int>? y0,
    Expression<int>? x1,
    Expression<int>? y1,
  }) {
    return RawValuesInsertable({
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (part != null) 'part': part,
      if (page != null) 'page': page,
      if (line != null) 'line': line,
      if (x0 != null) 'x0': x0,
      if (y0 != null) 'y0': y0,
      if (x1 != null) 'x1': x1,
      if (y1 != null) 'y1': y1,
    });
  }

  ShamarlyVerseBoxCompanion copyWith({
    Value<int>? surah,
    Value<int>? ayah,
    Value<int>? part,
    Value<int>? page,
    Value<int>? line,
    Value<int>? x0,
    Value<int>? y0,
    Value<int>? x1,
    Value<int>? y1,
  }) {
    return ShamarlyVerseBoxCompanion(
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      part: part ?? this.part,
      page: page ?? this.page,
      line: line ?? this.line,
      x0: x0 ?? this.x0,
      y0: y0 ?? this.y0,
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (part.present) {
      map['part'] = Variable<int>(part.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (line.present) {
      map['line'] = Variable<int>(line.value);
    }
    if (x0.present) {
      map['x0'] = Variable<int>(x0.value);
    }
    if (y0.present) {
      map['y0'] = Variable<int>(y0.value);
    }
    if (x1.present) {
      map['x1'] = Variable<int>(x1.value);
    }
    if (y1.present) {
      map['y1'] = Variable<int>(y1.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShamarlyVerseBoxCompanion(')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('part: $part, ')
          ..write('page: $page, ')
          ..write('line: $line, ')
          ..write('x0: $x0, ')
          ..write('y0: $y0, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1')
          ..write(')'))
        .toString();
  }
}

class $ShamarlyWordBoxTable extends ShamarlyWordBox
    with TableInfo<$ShamarlyWordBoxTable, ShamarlyWordBoxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShamarlyWordBoxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<int> word = GeneratedColumn<int>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineMeta = const VerificationMeta('line');
  @override
  late final GeneratedColumn<int> line = GeneratedColumn<int>(
    'line',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _x0Meta = const VerificationMeta('x0');
  @override
  late final GeneratedColumn<int> x0 = GeneratedColumn<int>(
    'x0',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y0Meta = const VerificationMeta('y0');
  @override
  late final GeneratedColumn<int> y0 = GeneratedColumn<int>(
    'y0',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _x1Meta = const VerificationMeta('x1');
  @override
  late final GeneratedColumn<int> x1 = GeneratedColumn<int>(
    'x1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y1Meta = const VerificationMeta('y1');
  @override
  late final GeneratedColumn<int> y1 = GeneratedColumn<int>(
    'y1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    surah,
    ayah,
    word,
    page,
    line,
    x0,
    y0,
    x1,
    y1,
    level,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shamarly_word_box';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShamarlyWordBoxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('line')) {
      context.handle(
        _lineMeta,
        line.isAcceptableOrUnknown(data['line']!, _lineMeta),
      );
    } else if (isInserting) {
      context.missing(_lineMeta);
    }
    if (data.containsKey('x0')) {
      context.handle(_x0Meta, x0.isAcceptableOrUnknown(data['x0']!, _x0Meta));
    } else if (isInserting) {
      context.missing(_x0Meta);
    }
    if (data.containsKey('y0')) {
      context.handle(_y0Meta, y0.isAcceptableOrUnknown(data['y0']!, _y0Meta));
    } else if (isInserting) {
      context.missing(_y0Meta);
    }
    if (data.containsKey('x1')) {
      context.handle(_x1Meta, x1.isAcceptableOrUnknown(data['x1']!, _x1Meta));
    } else if (isInserting) {
      context.missing(_x1Meta);
    }
    if (data.containsKey('y1')) {
      context.handle(_y1Meta, y1.isAcceptableOrUnknown(data['y1']!, _y1Meta));
    } else if (isInserting) {
      context.missing(_y1Meta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {surah, ayah, word};
  @override
  ShamarlyWordBoxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShamarlyWordBoxRow(
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      line: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line'],
      )!,
      x0: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x0'],
      )!,
      y0: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y0'],
      )!,
      x1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x1'],
      )!,
      y1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y1'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
    );
  }

  @override
  $ShamarlyWordBoxTable createAlias(String alias) {
    return $ShamarlyWordBoxTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class ShamarlyWordBoxRow extends DataClass
    implements Insertable<ShamarlyWordBoxRow> {
  final int surah;
  final int ayah;

  /// Numbered as in [WordBox].
  final int word;
  final int page;
  final int line;
  final int x0;
  final int y0;
  final int x1;
  final int y1;

  /// How sure the split into words is: 2 stable, 1 not yet reviewed.
  final int level;
  const ShamarlyWordBoxRow({
    required this.surah,
    required this.ayah,
    required this.word,
    required this.page,
    required this.line,
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
    required this.level,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['word'] = Variable<int>(word);
    map['page'] = Variable<int>(page);
    map['line'] = Variable<int>(line);
    map['x0'] = Variable<int>(x0);
    map['y0'] = Variable<int>(y0);
    map['x1'] = Variable<int>(x1);
    map['y1'] = Variable<int>(y1);
    map['level'] = Variable<int>(level);
    return map;
  }

  ShamarlyWordBoxCompanion toCompanion(bool nullToAbsent) {
    return ShamarlyWordBoxCompanion(
      surah: Value(surah),
      ayah: Value(ayah),
      word: Value(word),
      page: Value(page),
      line: Value(line),
      x0: Value(x0),
      y0: Value(y0),
      x1: Value(x1),
      y1: Value(y1),
      level: Value(level),
    );
  }

  factory ShamarlyWordBoxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShamarlyWordBoxRow(
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      word: serializer.fromJson<int>(json['word']),
      page: serializer.fromJson<int>(json['page']),
      line: serializer.fromJson<int>(json['line']),
      x0: serializer.fromJson<int>(json['x0']),
      y0: serializer.fromJson<int>(json['y0']),
      x1: serializer.fromJson<int>(json['x1']),
      y1: serializer.fromJson<int>(json['y1']),
      level: serializer.fromJson<int>(json['level']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'word': serializer.toJson<int>(word),
      'page': serializer.toJson<int>(page),
      'line': serializer.toJson<int>(line),
      'x0': serializer.toJson<int>(x0),
      'y0': serializer.toJson<int>(y0),
      'x1': serializer.toJson<int>(x1),
      'y1': serializer.toJson<int>(y1),
      'level': serializer.toJson<int>(level),
    };
  }

  ShamarlyWordBoxRow copyWith({
    int? surah,
    int? ayah,
    int? word,
    int? page,
    int? line,
    int? x0,
    int? y0,
    int? x1,
    int? y1,
    int? level,
  }) => ShamarlyWordBoxRow(
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    word: word ?? this.word,
    page: page ?? this.page,
    line: line ?? this.line,
    x0: x0 ?? this.x0,
    y0: y0 ?? this.y0,
    x1: x1 ?? this.x1,
    y1: y1 ?? this.y1,
    level: level ?? this.level,
  );
  ShamarlyWordBoxRow copyWithCompanion(ShamarlyWordBoxCompanion data) {
    return ShamarlyWordBoxRow(
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      word: data.word.present ? data.word.value : this.word,
      page: data.page.present ? data.page.value : this.page,
      line: data.line.present ? data.line.value : this.line,
      x0: data.x0.present ? data.x0.value : this.x0,
      y0: data.y0.present ? data.y0.value : this.y0,
      x1: data.x1.present ? data.x1.value : this.x1,
      y1: data.y1.present ? data.y1.value : this.y1,
      level: data.level.present ? data.level.value : this.level,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShamarlyWordBoxRow(')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('word: $word, ')
          ..write('page: $page, ')
          ..write('line: $line, ')
          ..write('x0: $x0, ')
          ..write('y0: $y0, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1, ')
          ..write('level: $level')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(surah, ayah, word, page, line, x0, y0, x1, y1, level);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShamarlyWordBoxRow &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.word == this.word &&
          other.page == this.page &&
          other.line == this.line &&
          other.x0 == this.x0 &&
          other.y0 == this.y0 &&
          other.x1 == this.x1 &&
          other.y1 == this.y1 &&
          other.level == this.level);
}

class ShamarlyWordBoxCompanion extends UpdateCompanion<ShamarlyWordBoxRow> {
  final Value<int> surah;
  final Value<int> ayah;
  final Value<int> word;
  final Value<int> page;
  final Value<int> line;
  final Value<int> x0;
  final Value<int> y0;
  final Value<int> x1;
  final Value<int> y1;
  final Value<int> level;
  const ShamarlyWordBoxCompanion({
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.word = const Value.absent(),
    this.page = const Value.absent(),
    this.line = const Value.absent(),
    this.x0 = const Value.absent(),
    this.y0 = const Value.absent(),
    this.x1 = const Value.absent(),
    this.y1 = const Value.absent(),
    this.level = const Value.absent(),
  });
  ShamarlyWordBoxCompanion.insert({
    required int surah,
    required int ayah,
    required int word,
    required int page,
    required int line,
    required int x0,
    required int y0,
    required int x1,
    required int y1,
    required int level,
  }) : surah = Value(surah),
       ayah = Value(ayah),
       word = Value(word),
       page = Value(page),
       line = Value(line),
       x0 = Value(x0),
       y0 = Value(y0),
       x1 = Value(x1),
       y1 = Value(y1),
       level = Value(level);
  static Insertable<ShamarlyWordBoxRow> custom({
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<int>? word,
    Expression<int>? page,
    Expression<int>? line,
    Expression<int>? x0,
    Expression<int>? y0,
    Expression<int>? x1,
    Expression<int>? y1,
    Expression<int>? level,
  }) {
    return RawValuesInsertable({
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (word != null) 'word': word,
      if (page != null) 'page': page,
      if (line != null) 'line': line,
      if (x0 != null) 'x0': x0,
      if (y0 != null) 'y0': y0,
      if (x1 != null) 'x1': x1,
      if (y1 != null) 'y1': y1,
      if (level != null) 'level': level,
    });
  }

  ShamarlyWordBoxCompanion copyWith({
    Value<int>? surah,
    Value<int>? ayah,
    Value<int>? word,
    Value<int>? page,
    Value<int>? line,
    Value<int>? x0,
    Value<int>? y0,
    Value<int>? x1,
    Value<int>? y1,
    Value<int>? level,
  }) {
    return ShamarlyWordBoxCompanion(
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      word: word ?? this.word,
      page: page ?? this.page,
      line: line ?? this.line,
      x0: x0 ?? this.x0,
      y0: y0 ?? this.y0,
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
      level: level ?? this.level,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (word.present) {
      map['word'] = Variable<int>(word.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (line.present) {
      map['line'] = Variable<int>(line.value);
    }
    if (x0.present) {
      map['x0'] = Variable<int>(x0.value);
    }
    if (y0.present) {
      map['y0'] = Variable<int>(y0.value);
    }
    if (x1.present) {
      map['x1'] = Variable<int>(x1.value);
    }
    if (y1.present) {
      map['y1'] = Variable<int>(y1.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShamarlyWordBoxCompanion(')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('word: $word, ')
          ..write('page: $page, ')
          ..write('line: $line, ')
          ..write('x0: $x0, ')
          ..write('y0: $y0, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1, ')
          ..write('level: $level')
          ..write(')'))
        .toString();
  }
}

class $ShamarlyCatchwordTable extends ShamarlyCatchword
    with TableInfo<$ShamarlyCatchwordTable, ShamarlyCatchwordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShamarlyCatchwordTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _x0Meta = const VerificationMeta('x0');
  @override
  late final GeneratedColumn<int> x0 = GeneratedColumn<int>(
    'x0',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y0Meta = const VerificationMeta('y0');
  @override
  late final GeneratedColumn<int> y0 = GeneratedColumn<int>(
    'y0',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _x1Meta = const VerificationMeta('x1');
  @override
  late final GeneratedColumn<int> x1 = GeneratedColumn<int>(
    'x1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y1Meta = const VerificationMeta('y1');
  @override
  late final GeneratedColumn<int> y1 = GeneratedColumn<int>(
    'y1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordsMeta = const VerificationMeta('words');
  @override
  late final GeneratedColumn<int> words = GeneratedColumn<int>(
    'words',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eraseMeta = const VerificationMeta('erase');
  @override
  late final GeneratedColumn<String> erase = GeneratedColumn<String>(
    'erase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [page, x0, y0, x1, y1, words, erase];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shamarly_catchword';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShamarlyCatchwordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    }
    if (data.containsKey('x0')) {
      context.handle(_x0Meta, x0.isAcceptableOrUnknown(data['x0']!, _x0Meta));
    } else if (isInserting) {
      context.missing(_x0Meta);
    }
    if (data.containsKey('y0')) {
      context.handle(_y0Meta, y0.isAcceptableOrUnknown(data['y0']!, _y0Meta));
    } else if (isInserting) {
      context.missing(_y0Meta);
    }
    if (data.containsKey('x1')) {
      context.handle(_x1Meta, x1.isAcceptableOrUnknown(data['x1']!, _x1Meta));
    } else if (isInserting) {
      context.missing(_x1Meta);
    }
    if (data.containsKey('y1')) {
      context.handle(_y1Meta, y1.isAcceptableOrUnknown(data['y1']!, _y1Meta));
    } else if (isInserting) {
      context.missing(_y1Meta);
    }
    if (data.containsKey('words')) {
      context.handle(
        _wordsMeta,
        words.isAcceptableOrUnknown(data['words']!, _wordsMeta),
      );
    } else if (isInserting) {
      context.missing(_wordsMeta);
    }
    if (data.containsKey('erase')) {
      context.handle(
        _eraseMeta,
        erase.isAcceptableOrUnknown(data['erase']!, _eraseMeta),
      );
    } else if (isInserting) {
      context.missing(_eraseMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {page};
  @override
  ShamarlyCatchwordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShamarlyCatchwordRow(
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      x0: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x0'],
      )!,
      y0: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y0'],
      )!,
      x1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x1'],
      )!,
      y1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y1'],
      )!,
      words: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}words'],
      )!,
      erase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}erase'],
      )!,
    );
  }

  @override
  $ShamarlyCatchwordTable createAlias(String alias) {
    return $ShamarlyCatchwordTable(attachedDatabase, alias);
  }
}

class ShamarlyCatchwordRow extends DataClass
    implements Insertable<ShamarlyCatchwordRow> {
  final int page;
  final int x0;
  final int y0;
  final int x1;
  final int y1;

  /// Whole words in the box: 1 or 2.
  final int words;
  final String erase;
  const ShamarlyCatchwordRow({
    required this.page,
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
    required this.words,
    required this.erase,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['page'] = Variable<int>(page);
    map['x0'] = Variable<int>(x0);
    map['y0'] = Variable<int>(y0);
    map['x1'] = Variable<int>(x1);
    map['y1'] = Variable<int>(y1);
    map['words'] = Variable<int>(words);
    map['erase'] = Variable<String>(erase);
    return map;
  }

  ShamarlyCatchwordCompanion toCompanion(bool nullToAbsent) {
    return ShamarlyCatchwordCompanion(
      page: Value(page),
      x0: Value(x0),
      y0: Value(y0),
      x1: Value(x1),
      y1: Value(y1),
      words: Value(words),
      erase: Value(erase),
    );
  }

  factory ShamarlyCatchwordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShamarlyCatchwordRow(
      page: serializer.fromJson<int>(json['page']),
      x0: serializer.fromJson<int>(json['x0']),
      y0: serializer.fromJson<int>(json['y0']),
      x1: serializer.fromJson<int>(json['x1']),
      y1: serializer.fromJson<int>(json['y1']),
      words: serializer.fromJson<int>(json['words']),
      erase: serializer.fromJson<String>(json['erase']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'page': serializer.toJson<int>(page),
      'x0': serializer.toJson<int>(x0),
      'y0': serializer.toJson<int>(y0),
      'x1': serializer.toJson<int>(x1),
      'y1': serializer.toJson<int>(y1),
      'words': serializer.toJson<int>(words),
      'erase': serializer.toJson<String>(erase),
    };
  }

  ShamarlyCatchwordRow copyWith({
    int? page,
    int? x0,
    int? y0,
    int? x1,
    int? y1,
    int? words,
    String? erase,
  }) => ShamarlyCatchwordRow(
    page: page ?? this.page,
    x0: x0 ?? this.x0,
    y0: y0 ?? this.y0,
    x1: x1 ?? this.x1,
    y1: y1 ?? this.y1,
    words: words ?? this.words,
    erase: erase ?? this.erase,
  );
  ShamarlyCatchwordRow copyWithCompanion(ShamarlyCatchwordCompanion data) {
    return ShamarlyCatchwordRow(
      page: data.page.present ? data.page.value : this.page,
      x0: data.x0.present ? data.x0.value : this.x0,
      y0: data.y0.present ? data.y0.value : this.y0,
      x1: data.x1.present ? data.x1.value : this.x1,
      y1: data.y1.present ? data.y1.value : this.y1,
      words: data.words.present ? data.words.value : this.words,
      erase: data.erase.present ? data.erase.value : this.erase,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShamarlyCatchwordRow(')
          ..write('page: $page, ')
          ..write('x0: $x0, ')
          ..write('y0: $y0, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1, ')
          ..write('words: $words, ')
          ..write('erase: $erase')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(page, x0, y0, x1, y1, words, erase);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShamarlyCatchwordRow &&
          other.page == this.page &&
          other.x0 == this.x0 &&
          other.y0 == this.y0 &&
          other.x1 == this.x1 &&
          other.y1 == this.y1 &&
          other.words == this.words &&
          other.erase == this.erase);
}

class ShamarlyCatchwordCompanion extends UpdateCompanion<ShamarlyCatchwordRow> {
  final Value<int> page;
  final Value<int> x0;
  final Value<int> y0;
  final Value<int> x1;
  final Value<int> y1;
  final Value<int> words;
  final Value<String> erase;
  const ShamarlyCatchwordCompanion({
    this.page = const Value.absent(),
    this.x0 = const Value.absent(),
    this.y0 = const Value.absent(),
    this.x1 = const Value.absent(),
    this.y1 = const Value.absent(),
    this.words = const Value.absent(),
    this.erase = const Value.absent(),
  });
  ShamarlyCatchwordCompanion.insert({
    this.page = const Value.absent(),
    required int x0,
    required int y0,
    required int x1,
    required int y1,
    required int words,
    required String erase,
  }) : x0 = Value(x0),
       y0 = Value(y0),
       x1 = Value(x1),
       y1 = Value(y1),
       words = Value(words),
       erase = Value(erase);
  static Insertable<ShamarlyCatchwordRow> custom({
    Expression<int>? page,
    Expression<int>? x0,
    Expression<int>? y0,
    Expression<int>? x1,
    Expression<int>? y1,
    Expression<int>? words,
    Expression<String>? erase,
  }) {
    return RawValuesInsertable({
      if (page != null) 'page': page,
      if (x0 != null) 'x0': x0,
      if (y0 != null) 'y0': y0,
      if (x1 != null) 'x1': x1,
      if (y1 != null) 'y1': y1,
      if (words != null) 'words': words,
      if (erase != null) 'erase': erase,
    });
  }

  ShamarlyCatchwordCompanion copyWith({
    Value<int>? page,
    Value<int>? x0,
    Value<int>? y0,
    Value<int>? x1,
    Value<int>? y1,
    Value<int>? words,
    Value<String>? erase,
  }) {
    return ShamarlyCatchwordCompanion(
      page: page ?? this.page,
      x0: x0 ?? this.x0,
      y0: y0 ?? this.y0,
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
      words: words ?? this.words,
      erase: erase ?? this.erase,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (x0.present) {
      map['x0'] = Variable<int>(x0.value);
    }
    if (y0.present) {
      map['y0'] = Variable<int>(y0.value);
    }
    if (x1.present) {
      map['x1'] = Variable<int>(x1.value);
    }
    if (y1.present) {
      map['y1'] = Variable<int>(y1.value);
    }
    if (words.present) {
      map['words'] = Variable<int>(words.value);
    }
    if (erase.present) {
      map['erase'] = Variable<String>(erase.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShamarlyCatchwordCompanion(')
          ..write('page: $page, ')
          ..write('x0: $x0, ')
          ..write('y0: $y0, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1, ')
          ..write('words: $words, ')
          ..write('erase: $erase')
          ..write(')'))
        .toString();
  }
}

class $WordRootTable extends WordRoot
    with TableInfo<$WordRootTable, WordRootRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordRootTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<int> word = GeneratedColumn<int>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rootMeta = const VerificationMeta('root');
  @override
  late final GeneratedColumn<String> root = GeneratedColumn<String>(
    'root',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lemmaMeta = const VerificationMeta('lemma');
  @override
  late final GeneratedColumn<String> lemma = GeneratedColumn<String>(
    'lemma',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posMeta = const VerificationMeta('pos');
  @override
  late final GeneratedColumn<String> pos = GeneratedColumn<String>(
    'pos',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [surah, ayah, word, root, lemma, pos];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_root';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordRootRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('root')) {
      context.handle(
        _rootMeta,
        root.isAcceptableOrUnknown(data['root']!, _rootMeta),
      );
    }
    if (data.containsKey('lemma')) {
      context.handle(
        _lemmaMeta,
        lemma.isAcceptableOrUnknown(data['lemma']!, _lemmaMeta),
      );
    }
    if (data.containsKey('pos')) {
      context.handle(
        _posMeta,
        pos.isAcceptableOrUnknown(data['pos']!, _posMeta),
      );
    } else if (isInserting) {
      context.missing(_posMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {surah, ayah, word};
  @override
  WordRootRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordRootRow(
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word'],
      )!,
      root: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root'],
      ),
      lemma: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lemma'],
      ),
      pos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pos'],
      )!,
    );
  }

  @override
  $WordRootTable createAlias(String alias) {
    return $WordRootTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class WordRootRow extends DataClass implements Insertable<WordRootRow> {
  final int surah;
  final int ayah;
  final int word;

  /// Arabic letters separated by spaces, as the corpus shows them
  /// («ر ح م»); null for words without a root.
  final String? root;
  final String? lemma;

  /// The corpus's part-of-speech tag (N, V, PN, ADJ, ...).
  final String pos;
  const WordRootRow({
    required this.surah,
    required this.ayah,
    required this.word,
    this.root,
    this.lemma,
    required this.pos,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['word'] = Variable<int>(word);
    if (!nullToAbsent || root != null) {
      map['root'] = Variable<String>(root);
    }
    if (!nullToAbsent || lemma != null) {
      map['lemma'] = Variable<String>(lemma);
    }
    map['pos'] = Variable<String>(pos);
    return map;
  }

  WordRootCompanion toCompanion(bool nullToAbsent) {
    return WordRootCompanion(
      surah: Value(surah),
      ayah: Value(ayah),
      word: Value(word),
      root: root == null && nullToAbsent ? const Value.absent() : Value(root),
      lemma: lemma == null && nullToAbsent
          ? const Value.absent()
          : Value(lemma),
      pos: Value(pos),
    );
  }

  factory WordRootRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordRootRow(
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      word: serializer.fromJson<int>(json['word']),
      root: serializer.fromJson<String?>(json['root']),
      lemma: serializer.fromJson<String?>(json['lemma']),
      pos: serializer.fromJson<String>(json['pos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'word': serializer.toJson<int>(word),
      'root': serializer.toJson<String?>(root),
      'lemma': serializer.toJson<String?>(lemma),
      'pos': serializer.toJson<String>(pos),
    };
  }

  WordRootRow copyWith({
    int? surah,
    int? ayah,
    int? word,
    Value<String?> root = const Value.absent(),
    Value<String?> lemma = const Value.absent(),
    String? pos,
  }) => WordRootRow(
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    word: word ?? this.word,
    root: root.present ? root.value : this.root,
    lemma: lemma.present ? lemma.value : this.lemma,
    pos: pos ?? this.pos,
  );
  WordRootRow copyWithCompanion(WordRootCompanion data) {
    return WordRootRow(
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      word: data.word.present ? data.word.value : this.word,
      root: data.root.present ? data.root.value : this.root,
      lemma: data.lemma.present ? data.lemma.value : this.lemma,
      pos: data.pos.present ? data.pos.value : this.pos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordRootRow(')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('word: $word, ')
          ..write('root: $root, ')
          ..write('lemma: $lemma, ')
          ..write('pos: $pos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(surah, ayah, word, root, lemma, pos);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordRootRow &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.word == this.word &&
          other.root == this.root &&
          other.lemma == this.lemma &&
          other.pos == this.pos);
}

class WordRootCompanion extends UpdateCompanion<WordRootRow> {
  final Value<int> surah;
  final Value<int> ayah;
  final Value<int> word;
  final Value<String?> root;
  final Value<String?> lemma;
  final Value<String> pos;
  const WordRootCompanion({
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.word = const Value.absent(),
    this.root = const Value.absent(),
    this.lemma = const Value.absent(),
    this.pos = const Value.absent(),
  });
  WordRootCompanion.insert({
    required int surah,
    required int ayah,
    required int word,
    this.root = const Value.absent(),
    this.lemma = const Value.absent(),
    required String pos,
  }) : surah = Value(surah),
       ayah = Value(ayah),
       word = Value(word),
       pos = Value(pos);
  static Insertable<WordRootRow> custom({
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<int>? word,
    Expression<String>? root,
    Expression<String>? lemma,
    Expression<String>? pos,
  }) {
    return RawValuesInsertable({
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (word != null) 'word': word,
      if (root != null) 'root': root,
      if (lemma != null) 'lemma': lemma,
      if (pos != null) 'pos': pos,
    });
  }

  WordRootCompanion copyWith({
    Value<int>? surah,
    Value<int>? ayah,
    Value<int>? word,
    Value<String?>? root,
    Value<String?>? lemma,
    Value<String>? pos,
  }) {
    return WordRootCompanion(
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      word: word ?? this.word,
      root: root ?? this.root,
      lemma: lemma ?? this.lemma,
      pos: pos ?? this.pos,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (word.present) {
      map['word'] = Variable<int>(word.value);
    }
    if (root.present) {
      map['root'] = Variable<String>(root.value);
    }
    if (lemma.present) {
      map['lemma'] = Variable<String>(lemma.value);
    }
    if (pos.present) {
      map['pos'] = Variable<String>(pos.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordRootCompanion(')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('word: $word, ')
          ..write('root: $root, ')
          ..write('lemma: $lemma, ')
          ..write('pos: $pos')
          ..write(')'))
        .toString();
  }
}

class $GharibTable extends Gharib with TableInfo<$GharibTable, GharibRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GharibTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordMeta = const VerificationMeta('ord');
  @override
  late final GeneratedColumn<int> ord = GeneratedColumn<int>(
    'ord',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordFromMeta = const VerificationMeta(
    'wordFrom',
  );
  @override
  late final GeneratedColumn<int> wordFrom = GeneratedColumn<int>(
    'word_from',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordToMeta = const VerificationMeta('wordTo');
  @override
  late final GeneratedColumn<int> wordTo = GeneratedColumn<int>(
    'word_to',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phraseMeta = const VerificationMeta('phrase');
  @override
  late final GeneratedColumn<String> phrase = GeneratedColumn<String>(
    'phrase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    surah,
    ayah,
    ord,
    wordFrom,
    wordTo,
    phrase,
    body,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gharib';
  @override
  VerificationContext validateIntegrity(
    Insertable<GharibRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('ord')) {
      context.handle(
        _ordMeta,
        ord.isAcceptableOrUnknown(data['ord']!, _ordMeta),
      );
    } else if (isInserting) {
      context.missing(_ordMeta);
    }
    if (data.containsKey('word_from')) {
      context.handle(
        _wordFromMeta,
        wordFrom.isAcceptableOrUnknown(data['word_from']!, _wordFromMeta),
      );
    }
    if (data.containsKey('word_to')) {
      context.handle(
        _wordToMeta,
        wordTo.isAcceptableOrUnknown(data['word_to']!, _wordToMeta),
      );
    }
    if (data.containsKey('phrase')) {
      context.handle(
        _phraseMeta,
        phrase.isAcceptableOrUnknown(data['phrase']!, _phraseMeta),
      );
    } else if (isInserting) {
      context.missing(_phraseMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['text']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {surah, ayah, ord};
  @override
  GharibRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GharibRow(
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      )!,
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      )!,
      ord: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ord'],
      )!,
      wordFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_from'],
      ),
      wordTo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_to'],
      ),
      phrase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phrase'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
    );
  }

  @override
  $GharibTable createAlias(String alias) {
    return $GharibTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class GharibRow extends DataClass implements Insertable<GharibRow> {
  final int surah;
  final int ayah;

  /// Order of the entry within its verse, as in the book.
  final int ord;
  final int? wordFrom;
  final int? wordTo;
  final String phrase;
  final String body;
  const GharibRow({
    required this.surah,
    required this.ayah,
    required this.ord,
    this.wordFrom,
    this.wordTo,
    required this.phrase,
    required this.body,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['ord'] = Variable<int>(ord);
    if (!nullToAbsent || wordFrom != null) {
      map['word_from'] = Variable<int>(wordFrom);
    }
    if (!nullToAbsent || wordTo != null) {
      map['word_to'] = Variable<int>(wordTo);
    }
    map['phrase'] = Variable<String>(phrase);
    map['text'] = Variable<String>(body);
    return map;
  }

  GharibCompanion toCompanion(bool nullToAbsent) {
    return GharibCompanion(
      surah: Value(surah),
      ayah: Value(ayah),
      ord: Value(ord),
      wordFrom: wordFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(wordFrom),
      wordTo: wordTo == null && nullToAbsent
          ? const Value.absent()
          : Value(wordTo),
      phrase: Value(phrase),
      body: Value(body),
    );
  }

  factory GharibRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GharibRow(
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      ord: serializer.fromJson<int>(json['ord']),
      wordFrom: serializer.fromJson<int?>(json['wordFrom']),
      wordTo: serializer.fromJson<int?>(json['wordTo']),
      phrase: serializer.fromJson<String>(json['phrase']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'ord': serializer.toJson<int>(ord),
      'wordFrom': serializer.toJson<int?>(wordFrom),
      'wordTo': serializer.toJson<int?>(wordTo),
      'phrase': serializer.toJson<String>(phrase),
      'body': serializer.toJson<String>(body),
    };
  }

  GharibRow copyWith({
    int? surah,
    int? ayah,
    int? ord,
    Value<int?> wordFrom = const Value.absent(),
    Value<int?> wordTo = const Value.absent(),
    String? phrase,
    String? body,
  }) => GharibRow(
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    ord: ord ?? this.ord,
    wordFrom: wordFrom.present ? wordFrom.value : this.wordFrom,
    wordTo: wordTo.present ? wordTo.value : this.wordTo,
    phrase: phrase ?? this.phrase,
    body: body ?? this.body,
  );
  GharibRow copyWithCompanion(GharibCompanion data) {
    return GharibRow(
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      ord: data.ord.present ? data.ord.value : this.ord,
      wordFrom: data.wordFrom.present ? data.wordFrom.value : this.wordFrom,
      wordTo: data.wordTo.present ? data.wordTo.value : this.wordTo,
      phrase: data.phrase.present ? data.phrase.value : this.phrase,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GharibRow(')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('ord: $ord, ')
          ..write('wordFrom: $wordFrom, ')
          ..write('wordTo: $wordTo, ')
          ..write('phrase: $phrase, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(surah, ayah, ord, wordFrom, wordTo, phrase, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GharibRow &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.ord == this.ord &&
          other.wordFrom == this.wordFrom &&
          other.wordTo == this.wordTo &&
          other.phrase == this.phrase &&
          other.body == this.body);
}

class GharibCompanion extends UpdateCompanion<GharibRow> {
  final Value<int> surah;
  final Value<int> ayah;
  final Value<int> ord;
  final Value<int?> wordFrom;
  final Value<int?> wordTo;
  final Value<String> phrase;
  final Value<String> body;
  const GharibCompanion({
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.ord = const Value.absent(),
    this.wordFrom = const Value.absent(),
    this.wordTo = const Value.absent(),
    this.phrase = const Value.absent(),
    this.body = const Value.absent(),
  });
  GharibCompanion.insert({
    required int surah,
    required int ayah,
    required int ord,
    this.wordFrom = const Value.absent(),
    this.wordTo = const Value.absent(),
    required String phrase,
    required String body,
  }) : surah = Value(surah),
       ayah = Value(ayah),
       ord = Value(ord),
       phrase = Value(phrase),
       body = Value(body);
  static Insertable<GharibRow> custom({
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<int>? ord,
    Expression<int>? wordFrom,
    Expression<int>? wordTo,
    Expression<String>? phrase,
    Expression<String>? body,
  }) {
    return RawValuesInsertable({
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (ord != null) 'ord': ord,
      if (wordFrom != null) 'word_from': wordFrom,
      if (wordTo != null) 'word_to': wordTo,
      if (phrase != null) 'phrase': phrase,
      if (body != null) 'text': body,
    });
  }

  GharibCompanion copyWith({
    Value<int>? surah,
    Value<int>? ayah,
    Value<int>? ord,
    Value<int?>? wordFrom,
    Value<int?>? wordTo,
    Value<String>? phrase,
    Value<String>? body,
  }) {
    return GharibCompanion(
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      ord: ord ?? this.ord,
      wordFrom: wordFrom ?? this.wordFrom,
      wordTo: wordTo ?? this.wordTo,
      phrase: phrase ?? this.phrase,
      body: body ?? this.body,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (ord.present) {
      map['ord'] = Variable<int>(ord.value);
    }
    if (wordFrom.present) {
      map['word_from'] = Variable<int>(wordFrom.value);
    }
    if (wordTo.present) {
      map['word_to'] = Variable<int>(wordTo.value);
    }
    if (phrase.present) {
      map['phrase'] = Variable<String>(phrase.value);
    }
    if (body.present) {
      map['text'] = Variable<String>(body.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GharibCompanion(')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('ord: $ord, ')
          ..write('wordFrom: $wordFrom, ')
          ..write('wordTo: $wordTo, ')
          ..write('phrase: $phrase, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }
}

class $MutashabihTable extends Mutashabih
    with TableInfo<$MutashabihTable, MutashabihRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MutashabihTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _srcFromMeta = const VerificationMeta(
    'srcFrom',
  );
  @override
  late final GeneratedColumn<int> srcFrom = GeneratedColumn<int>(
    'src_from',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _srcToMeta = const VerificationMeta('srcTo');
  @override
  late final GeneratedColumn<int> srcTo = GeneratedColumn<int>(
    'src_to',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mutFromMeta = const VerificationMeta(
    'mutFrom',
  );
  @override
  late final GeneratedColumn<int> mutFrom = GeneratedColumn<int>(
    'mut_from',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mutToMeta = const VerificationMeta('mutTo');
  @override
  late final GeneratedColumn<int> mutTo = GeneratedColumn<int>(
    'mut_to',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextMeta = const VerificationMeta(
    'context',
  );
  @override
  late final GeneratedColumn<int> context = GeneratedColumn<int>(
    'context',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    srcFrom,
    srcTo,
    mutFrom,
    mutTo,
    context,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mutashabih';
  @override
  VerificationContext validateIntegrity(
    Insertable<MutashabihRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('src_from')) {
      context.handle(
        _srcFromMeta,
        srcFrom.isAcceptableOrUnknown(data['src_from']!, _srcFromMeta),
      );
    } else if (isInserting) {
      context.missing(_srcFromMeta);
    }
    if (data.containsKey('src_to')) {
      context.handle(
        _srcToMeta,
        srcTo.isAcceptableOrUnknown(data['src_to']!, _srcToMeta),
      );
    } else if (isInserting) {
      context.missing(_srcToMeta);
    }
    if (data.containsKey('mut_from')) {
      context.handle(
        _mutFromMeta,
        mutFrom.isAcceptableOrUnknown(data['mut_from']!, _mutFromMeta),
      );
    } else if (isInserting) {
      context.missing(_mutFromMeta);
    }
    if (data.containsKey('mut_to')) {
      context.handle(
        _mutToMeta,
        mutTo.isAcceptableOrUnknown(data['mut_to']!, _mutToMeta),
      );
    } else if (isInserting) {
      context.missing(_mutToMeta);
    }
    if (data.containsKey('context')) {
      context.handle(
        _contextMeta,
        this.context.isAcceptableOrUnknown(data['context']!, _contextMeta),
      );
    } else if (isInserting) {
      context.missing(_contextMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MutashabihRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MutashabihRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      srcFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}src_from'],
      )!,
      srcTo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}src_to'],
      )!,
      mutFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mut_from'],
      )!,
      mutTo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mut_to'],
      )!,
      context: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}context'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $MutashabihTable createAlias(String alias) {
    return $MutashabihTable(attachedDatabase, alias);
  }
}

class MutashabihRow extends DataClass implements Insertable<MutashabihRow> {
  final int id;
  final int srcFrom;
  final int srcTo;
  final int mutFrom;
  final int mutTo;

  /// 1 when the start of the following verse tells the passages apart.
  final int context;
  final int sourceId;
  const MutashabihRow({
    required this.id,
    required this.srcFrom,
    required this.srcTo,
    required this.mutFrom,
    required this.mutTo,
    required this.context,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['src_from'] = Variable<int>(srcFrom);
    map['src_to'] = Variable<int>(srcTo);
    map['mut_from'] = Variable<int>(mutFrom);
    map['mut_to'] = Variable<int>(mutTo);
    map['context'] = Variable<int>(context);
    map['source_id'] = Variable<int>(sourceId);
    return map;
  }

  MutashabihCompanion toCompanion(bool nullToAbsent) {
    return MutashabihCompanion(
      id: Value(id),
      srcFrom: Value(srcFrom),
      srcTo: Value(srcTo),
      mutFrom: Value(mutFrom),
      mutTo: Value(mutTo),
      context: Value(context),
      sourceId: Value(sourceId),
    );
  }

  factory MutashabihRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MutashabihRow(
      id: serializer.fromJson<int>(json['id']),
      srcFrom: serializer.fromJson<int>(json['srcFrom']),
      srcTo: serializer.fromJson<int>(json['srcTo']),
      mutFrom: serializer.fromJson<int>(json['mutFrom']),
      mutTo: serializer.fromJson<int>(json['mutTo']),
      context: serializer.fromJson<int>(json['context']),
      sourceId: serializer.fromJson<int>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'srcFrom': serializer.toJson<int>(srcFrom),
      'srcTo': serializer.toJson<int>(srcTo),
      'mutFrom': serializer.toJson<int>(mutFrom),
      'mutTo': serializer.toJson<int>(mutTo),
      'context': serializer.toJson<int>(context),
      'sourceId': serializer.toJson<int>(sourceId),
    };
  }

  MutashabihRow copyWith({
    int? id,
    int? srcFrom,
    int? srcTo,
    int? mutFrom,
    int? mutTo,
    int? context,
    int? sourceId,
  }) => MutashabihRow(
    id: id ?? this.id,
    srcFrom: srcFrom ?? this.srcFrom,
    srcTo: srcTo ?? this.srcTo,
    mutFrom: mutFrom ?? this.mutFrom,
    mutTo: mutTo ?? this.mutTo,
    context: context ?? this.context,
    sourceId: sourceId ?? this.sourceId,
  );
  MutashabihRow copyWithCompanion(MutashabihCompanion data) {
    return MutashabihRow(
      id: data.id.present ? data.id.value : this.id,
      srcFrom: data.srcFrom.present ? data.srcFrom.value : this.srcFrom,
      srcTo: data.srcTo.present ? data.srcTo.value : this.srcTo,
      mutFrom: data.mutFrom.present ? data.mutFrom.value : this.mutFrom,
      mutTo: data.mutTo.present ? data.mutTo.value : this.mutTo,
      context: data.context.present ? data.context.value : this.context,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MutashabihRow(')
          ..write('id: $id, ')
          ..write('srcFrom: $srcFrom, ')
          ..write('srcTo: $srcTo, ')
          ..write('mutFrom: $mutFrom, ')
          ..write('mutTo: $mutTo, ')
          ..write('context: $context, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, srcFrom, srcTo, mutFrom, mutTo, context, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MutashabihRow &&
          other.id == this.id &&
          other.srcFrom == this.srcFrom &&
          other.srcTo == this.srcTo &&
          other.mutFrom == this.mutFrom &&
          other.mutTo == this.mutTo &&
          other.context == this.context &&
          other.sourceId == this.sourceId);
}

class MutashabihCompanion extends UpdateCompanion<MutashabihRow> {
  final Value<int> id;
  final Value<int> srcFrom;
  final Value<int> srcTo;
  final Value<int> mutFrom;
  final Value<int> mutTo;
  final Value<int> context;
  final Value<int> sourceId;
  const MutashabihCompanion({
    this.id = const Value.absent(),
    this.srcFrom = const Value.absent(),
    this.srcTo = const Value.absent(),
    this.mutFrom = const Value.absent(),
    this.mutTo = const Value.absent(),
    this.context = const Value.absent(),
    this.sourceId = const Value.absent(),
  });
  MutashabihCompanion.insert({
    this.id = const Value.absent(),
    required int srcFrom,
    required int srcTo,
    required int mutFrom,
    required int mutTo,
    required int context,
    required int sourceId,
  }) : srcFrom = Value(srcFrom),
       srcTo = Value(srcTo),
       mutFrom = Value(mutFrom),
       mutTo = Value(mutTo),
       context = Value(context),
       sourceId = Value(sourceId);
  static Insertable<MutashabihRow> custom({
    Expression<int>? id,
    Expression<int>? srcFrom,
    Expression<int>? srcTo,
    Expression<int>? mutFrom,
    Expression<int>? mutTo,
    Expression<int>? context,
    Expression<int>? sourceId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (srcFrom != null) 'src_from': srcFrom,
      if (srcTo != null) 'src_to': srcTo,
      if (mutFrom != null) 'mut_from': mutFrom,
      if (mutTo != null) 'mut_to': mutTo,
      if (context != null) 'context': context,
      if (sourceId != null) 'source_id': sourceId,
    });
  }

  MutashabihCompanion copyWith({
    Value<int>? id,
    Value<int>? srcFrom,
    Value<int>? srcTo,
    Value<int>? mutFrom,
    Value<int>? mutTo,
    Value<int>? context,
    Value<int>? sourceId,
  }) {
    return MutashabihCompanion(
      id: id ?? this.id,
      srcFrom: srcFrom ?? this.srcFrom,
      srcTo: srcTo ?? this.srcTo,
      mutFrom: mutFrom ?? this.mutFrom,
      mutTo: mutTo ?? this.mutTo,
      context: context ?? this.context,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (srcFrom.present) {
      map['src_from'] = Variable<int>(srcFrom.value);
    }
    if (srcTo.present) {
      map['src_to'] = Variable<int>(srcTo.value);
    }
    if (mutFrom.present) {
      map['mut_from'] = Variable<int>(mutFrom.value);
    }
    if (mutTo.present) {
      map['mut_to'] = Variable<int>(mutTo.value);
    }
    if (context.present) {
      map['context'] = Variable<int>(context.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MutashabihCompanion(')
          ..write('id: $id, ')
          ..write('srcFrom: $srcFrom, ')
          ..write('srcTo: $srcTo, ')
          ..write('mutFrom: $mutFrom, ')
          ..write('mutTo: $mutTo, ')
          ..write('context: $context, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }
}

abstract class _$ContentDatabase extends GeneratedDatabase {
  _$ContentDatabase(QueryExecutor e) : super(e);
  $ContentDatabaseManager get managers => $ContentDatabaseManager(this);
  late final $SurahTable surah = $SurahTable(this);
  late final $AyahTable ayah = $AyahTable(this);
  late final $AyahPolygonTable ayahPolygon = $AyahPolygonTable(this);
  late final $SourceTable source = $SourceTable(this);
  late final $WordBoxTable wordBox = $WordBoxTable(this);
  late final $LineCutTable lineCut = $LineCutTable(this);
  late final $LineOverflowTable lineOverflow = $LineOverflowTable(this);
  late final $LineOverflow1405Table lineOverflow1405 = $LineOverflow1405Table(
    this,
  );
  late final $CommentaryEditionTable commentaryEdition =
      $CommentaryEditionTable(this);
  late final $CommentaryTable commentary = $CommentaryTable(this);
  late final $ReciterTable reciter = $ReciterTable(this);
  late final $AyahTimingTable ayahTiming = $AyahTimingTable(this);
  late final $WordTimingTable wordTiming = $WordTimingTable(this);
  late final $AyahSpeechTable ayahSpeech = $AyahSpeechTable(this);
  late final $ShamarlyPageTable shamarlyPage = $ShamarlyPageTable(this);
  late final $ShamarlyLineTable shamarlyLine = $ShamarlyLineTable(this);
  late final $ShamarlyLineOverflowTable shamarlyLineOverflow =
      $ShamarlyLineOverflowTable(this);
  late final $ShamarlyHeaderTable shamarlyHeader = $ShamarlyHeaderTable(this);
  late final $ShamarlyMarkerTable shamarlyMarker = $ShamarlyMarkerTable(this);
  late final $ShamarlyVerseBoxTable shamarlyVerseBox = $ShamarlyVerseBoxTable(
    this,
  );
  late final $ShamarlyWordBoxTable shamarlyWordBox = $ShamarlyWordBoxTable(
    this,
  );
  late final $ShamarlyCatchwordTable shamarlyCatchword =
      $ShamarlyCatchwordTable(this);
  late final $WordRootTable wordRoot = $WordRootTable(this);
  late final $GharibTable gharib = $GharibTable(this);
  late final $MutashabihTable mutashabih = $MutashabihTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    surah,
    ayah,
    ayahPolygon,
    source,
    wordBox,
    lineCut,
    lineOverflow,
    lineOverflow1405,
    commentaryEdition,
    commentary,
    reciter,
    ayahTiming,
    wordTiming,
    ayahSpeech,
    shamarlyPage,
    shamarlyLine,
    shamarlyLineOverflow,
    shamarlyHeader,
    shamarlyMarker,
    shamarlyVerseBox,
    shamarlyWordBox,
    shamarlyCatchword,
    wordRoot,
    gharib,
    mutashabih,
  ];
}

typedef $$SurahTableCreateCompanionBuilder = SurahCompanion Function({
  Value<int> id,
  required String nameAr,
  required String nameEn,
  required String meaningEn,
  required String revelation,
  required int revelationOrder,
  required int ayahCount,
  required int startPage,
  required int startPage1405,
  required int sourceId,
  required int startPageShamarly,
});
typedef $$SurahTableUpdateCompanionBuilder = SurahCompanion Function({
  Value<int> id,
  Value<String> nameAr,
  Value<String> nameEn,
  Value<String> meaningEn,
  Value<String> revelation,
  Value<int> revelationOrder,
  Value<int> ayahCount,
  Value<int> startPage,
  Value<int> startPage1405,
  Value<int> sourceId,
  Value<int> startPageShamarly,
});

class $$SurahTableFilterComposer
    extends Composer<_$ContentDatabase, $SurahTable> {
  $$SurahTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaningEn => $composableBuilder(
    column: $table.meaningEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revelation => $composableBuilder(
    column: $table.revelation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revelationOrder => $composableBuilder(
    column: $table.revelationOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startPage => $composableBuilder(
    column: $table.startPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startPage1405 => $composableBuilder(
    column: $table.startPage1405,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startPageShamarly => $composableBuilder(
    column: $table.startPageShamarly,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SurahTableOrderingComposer
    extends Composer<_$ContentDatabase, $SurahTable> {
  $$SurahTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaningEn => $composableBuilder(
    column: $table.meaningEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revelation => $composableBuilder(
    column: $table.revelation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revelationOrder => $composableBuilder(
    column: $table.revelationOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startPage => $composableBuilder(
    column: $table.startPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startPage1405 => $composableBuilder(
    column: $table.startPage1405,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startPageShamarly => $composableBuilder(
    column: $table.startPageShamarly,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SurahTableAnnotationComposer
    extends Composer<_$ContentDatabase, $SurahTable> {
  $$SurahTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get meaningEn =>
      $composableBuilder(column: $table.meaningEn, builder: (column) => column);

  GeneratedColumn<String> get revelation => $composableBuilder(
    column: $table.revelation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revelationOrder => $composableBuilder(
    column: $table.revelationOrder,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ayahCount =>
      $composableBuilder(column: $table.ayahCount, builder: (column) => column);

  GeneratedColumn<int> get startPage =>
      $composableBuilder(column: $table.startPage, builder: (column) => column);

  GeneratedColumn<int> get startPage1405 => $composableBuilder(
    column: $table.startPage1405,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<int> get startPageShamarly => $composableBuilder(
    column: $table.startPageShamarly,
    builder: (column) => column,
  );
}

class $$SurahTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $SurahTable,
          SurahRow,
          $$SurahTableFilterComposer,
          $$SurahTableOrderingComposer,
          $$SurahTableAnnotationComposer,
          $$SurahTableCreateCompanionBuilder,
          $$SurahTableUpdateCompanionBuilder,
          (SurahRow, BaseReferences<_$ContentDatabase, $SurahTable, SurahRow>),
          SurahRow,
          PrefetchHooks Function()
        > {
  $$SurahTableTableManager(_$ContentDatabase db, $SurahTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurahTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurahTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurahTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nameAr = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> meaningEn = const Value.absent(),
                Value<String> revelation = const Value.absent(),
                Value<int> revelationOrder = const Value.absent(),
                Value<int> ayahCount = const Value.absent(),
                Value<int> startPage = const Value.absent(),
                Value<int> startPage1405 = const Value.absent(),
                Value<int> sourceId = const Value.absent(),
                Value<int> startPageShamarly = const Value.absent(),
              }) => SurahCompanion(
                id: id,
                nameAr: nameAr,
                nameEn: nameEn,
                meaningEn: meaningEn,
                revelation: revelation,
                revelationOrder: revelationOrder,
                ayahCount: ayahCount,
                startPage: startPage,
                startPage1405: startPage1405,
                sourceId: sourceId,
                startPageShamarly: startPageShamarly,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nameAr,
                required String nameEn,
                required String meaningEn,
                required String revelation,
                required int revelationOrder,
                required int ayahCount,
                required int startPage,
                required int startPage1405,
                required int sourceId,
                required int startPageShamarly,
              }) => SurahCompanion.insert(
                id: id,
                nameAr: nameAr,
                nameEn: nameEn,
                meaningEn: meaningEn,
                revelation: revelation,
                revelationOrder: revelationOrder,
                ayahCount: ayahCount,
                startPage: startPage,
                startPage1405: startPage1405,
                sourceId: sourceId,
                startPageShamarly: startPageShamarly,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SurahTable, SurahRow>(table),
                  BaseReferences<_$ContentDatabase, $SurahTable, SurahRow>(
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

typedef $$SurahTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $SurahTable,
      SurahRow,
      $$SurahTableFilterComposer,
      $$SurahTableOrderingComposer,
      $$SurahTableAnnotationComposer,
      $$SurahTableCreateCompanionBuilder,
      $$SurahTableUpdateCompanionBuilder,
      (SurahRow, BaseReferences<_$ContentDatabase, $SurahTable, SurahRow>),
      SurahRow,
      PrefetchHooks Function()
    >;
typedef $$AyahTableCreateCompanionBuilder = AyahCompanion Function({
  Value<int> id,
  required int surah,
  required int number,
  required String verseText,
  required String displayText,
  required int basmalaPrefix,
  required String textSearch,
  required int searchBasmalaPrefix,
  required int juz,
  required int hizbQuarter,
  required int manzil,
  required int page,
  required int page1405,
  Value<String?> sajda,
  required int textSourceId,
  required int displaySourceId,
  required int pageSourceId,
  required int pageShamarly,
  required int pageShamarlyEnd,
});
typedef $$AyahTableUpdateCompanionBuilder = AyahCompanion Function({
  Value<int> id,
  Value<int> surah,
  Value<int> number,
  Value<String> verseText,
  Value<String> displayText,
  Value<int> basmalaPrefix,
  Value<String> textSearch,
  Value<int> searchBasmalaPrefix,
  Value<int> juz,
  Value<int> hizbQuarter,
  Value<int> manzil,
  Value<int> page,
  Value<int> page1405,
  Value<String?> sajda,
  Value<int> textSourceId,
  Value<int> displaySourceId,
  Value<int> pageSourceId,
  Value<int> pageShamarly,
  Value<int> pageShamarlyEnd,
});

class $$AyahTableFilterComposer
    extends Composer<_$ContentDatabase, $AyahTable> {
  $$AyahTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verseText => $composableBuilder(
    column: $table.verseText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayText => $composableBuilder(
    column: $table.displayText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get basmalaPrefix => $composableBuilder(
    column: $table.basmalaPrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textSearch => $composableBuilder(
    column: $table.textSearch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get searchBasmalaPrefix => $composableBuilder(
    column: $table.searchBasmalaPrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get juz => $composableBuilder(
    column: $table.juz,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hizbQuarter => $composableBuilder(
    column: $table.hizbQuarter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get manzil => $composableBuilder(
    column: $table.manzil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page1405 => $composableBuilder(
    column: $table.page1405,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sajda => $composableBuilder(
    column: $table.sajda,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get textSourceId => $composableBuilder(
    column: $table.textSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displaySourceId => $composableBuilder(
    column: $table.displaySourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageSourceId => $composableBuilder(
    column: $table.pageSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageShamarly => $composableBuilder(
    column: $table.pageShamarly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageShamarlyEnd => $composableBuilder(
    column: $table.pageShamarlyEnd,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AyahTableOrderingComposer
    extends Composer<_$ContentDatabase, $AyahTable> {
  $$AyahTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verseText => $composableBuilder(
    column: $table.verseText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayText => $composableBuilder(
    column: $table.displayText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get basmalaPrefix => $composableBuilder(
    column: $table.basmalaPrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textSearch => $composableBuilder(
    column: $table.textSearch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get searchBasmalaPrefix => $composableBuilder(
    column: $table.searchBasmalaPrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get juz => $composableBuilder(
    column: $table.juz,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hizbQuarter => $composableBuilder(
    column: $table.hizbQuarter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get manzil => $composableBuilder(
    column: $table.manzil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page1405 => $composableBuilder(
    column: $table.page1405,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sajda => $composableBuilder(
    column: $table.sajda,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get textSourceId => $composableBuilder(
    column: $table.textSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displaySourceId => $composableBuilder(
    column: $table.displaySourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageSourceId => $composableBuilder(
    column: $table.pageSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageShamarly => $composableBuilder(
    column: $table.pageShamarly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageShamarlyEnd => $composableBuilder(
    column: $table.pageShamarlyEnd,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AyahTableAnnotationComposer
    extends Composer<_$ContentDatabase, $AyahTable> {
  $$AyahTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get verseText =>
      $composableBuilder(column: $table.verseText, builder: (column) => column);

  GeneratedColumn<String> get displayText => $composableBuilder(
    column: $table.displayText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get basmalaPrefix => $composableBuilder(
    column: $table.basmalaPrefix,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textSearch => $composableBuilder(
    column: $table.textSearch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get searchBasmalaPrefix => $composableBuilder(
    column: $table.searchBasmalaPrefix,
    builder: (column) => column,
  );

  GeneratedColumn<int> get juz =>
      $composableBuilder(column: $table.juz, builder: (column) => column);

  GeneratedColumn<int> get hizbQuarter => $composableBuilder(
    column: $table.hizbQuarter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get manzil =>
      $composableBuilder(column: $table.manzil, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get page1405 =>
      $composableBuilder(column: $table.page1405, builder: (column) => column);

  GeneratedColumn<String> get sajda =>
      $composableBuilder(column: $table.sajda, builder: (column) => column);

  GeneratedColumn<int> get textSourceId => $composableBuilder(
    column: $table.textSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get displaySourceId => $composableBuilder(
    column: $table.displaySourceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageSourceId => $composableBuilder(
    column: $table.pageSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageShamarly => $composableBuilder(
    column: $table.pageShamarly,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageShamarlyEnd => $composableBuilder(
    column: $table.pageShamarlyEnd,
    builder: (column) => column,
  );
}

class $$AyahTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $AyahTable,
          AyahRow,
          $$AyahTableFilterComposer,
          $$AyahTableOrderingComposer,
          $$AyahTableAnnotationComposer,
          $$AyahTableCreateCompanionBuilder,
          $$AyahTableUpdateCompanionBuilder,
          (AyahRow, BaseReferences<_$ContentDatabase, $AyahTable, AyahRow>),
          AyahRow,
          PrefetchHooks Function()
        > {
  $$AyahTableTableManager(_$ContentDatabase db, $AyahTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AyahTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AyahTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AyahTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> surah = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<String> verseText = const Value.absent(),
                Value<String> displayText = const Value.absent(),
                Value<int> basmalaPrefix = const Value.absent(),
                Value<String> textSearch = const Value.absent(),
                Value<int> searchBasmalaPrefix = const Value.absent(),
                Value<int> juz = const Value.absent(),
                Value<int> hizbQuarter = const Value.absent(),
                Value<int> manzil = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<int> page1405 = const Value.absent(),
                Value<String?> sajda = const Value.absent(),
                Value<int> textSourceId = const Value.absent(),
                Value<int> displaySourceId = const Value.absent(),
                Value<int> pageSourceId = const Value.absent(),
                Value<int> pageShamarly = const Value.absent(),
                Value<int> pageShamarlyEnd = const Value.absent(),
              }) => AyahCompanion(
                id: id,
                surah: surah,
                number: number,
                verseText: verseText,
                displayText: displayText,
                basmalaPrefix: basmalaPrefix,
                textSearch: textSearch,
                searchBasmalaPrefix: searchBasmalaPrefix,
                juz: juz,
                hizbQuarter: hizbQuarter,
                manzil: manzil,
                page: page,
                page1405: page1405,
                sajda: sajda,
                textSourceId: textSourceId,
                displaySourceId: displaySourceId,
                pageSourceId: pageSourceId,
                pageShamarly: pageShamarly,
                pageShamarlyEnd: pageShamarlyEnd,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int surah,
                required int number,
                required String verseText,
                required String displayText,
                required int basmalaPrefix,
                required String textSearch,
                required int searchBasmalaPrefix,
                required int juz,
                required int hizbQuarter,
                required int manzil,
                required int page,
                required int page1405,
                Value<String?> sajda = const Value.absent(),
                required int textSourceId,
                required int displaySourceId,
                required int pageSourceId,
                required int pageShamarly,
                required int pageShamarlyEnd,
              }) => AyahCompanion.insert(
                id: id,
                surah: surah,
                number: number,
                verseText: verseText,
                displayText: displayText,
                basmalaPrefix: basmalaPrefix,
                textSearch: textSearch,
                searchBasmalaPrefix: searchBasmalaPrefix,
                juz: juz,
                hizbQuarter: hizbQuarter,
                manzil: manzil,
                page: page,
                page1405: page1405,
                sajda: sajda,
                textSourceId: textSourceId,
                displaySourceId: displaySourceId,
                pageSourceId: pageSourceId,
                pageShamarly: pageShamarly,
                pageShamarlyEnd: pageShamarlyEnd,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AyahTable, AyahRow>(table),
                  BaseReferences<_$ContentDatabase, $AyahTable, AyahRow>(
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

typedef $$AyahTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $AyahTable,
      AyahRow,
      $$AyahTableFilterComposer,
      $$AyahTableOrderingComposer,
      $$AyahTableAnnotationComposer,
      $$AyahTableCreateCompanionBuilder,
      $$AyahTableUpdateCompanionBuilder,
      (AyahRow, BaseReferences<_$ContentDatabase, $AyahTable, AyahRow>),
      AyahRow,
      PrefetchHooks Function()
    >;
typedef $$AyahPolygonTableCreateCompanionBuilder =
    AyahPolygonCompanion Function({
      required int page,
      required int surah,
      required int number,
      required String path,
      Value<double?> markerX,
      Value<double?> markerY,
      Value<int> rowid,
    });
typedef $$AyahPolygonTableUpdateCompanionBuilder =
    AyahPolygonCompanion Function({
      Value<int> page,
      Value<int> surah,
      Value<int> number,
      Value<String> path,
      Value<double?> markerX,
      Value<double?> markerY,
      Value<int> rowid,
    });

class $$AyahPolygonTableFilterComposer
    extends Composer<_$ContentDatabase, $AyahPolygonTable> {
  $$AyahPolygonTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get markerX => $composableBuilder(
    column: $table.markerX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get markerY => $composableBuilder(
    column: $table.markerY,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AyahPolygonTableOrderingComposer
    extends Composer<_$ContentDatabase, $AyahPolygonTable> {
  $$AyahPolygonTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get markerX => $composableBuilder(
    column: $table.markerX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get markerY => $composableBuilder(
    column: $table.markerY,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AyahPolygonTableAnnotationComposer
    extends Composer<_$ContentDatabase, $AyahPolygonTable> {
  $$AyahPolygonTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<double> get markerX =>
      $composableBuilder(column: $table.markerX, builder: (column) => column);

  GeneratedColumn<double> get markerY =>
      $composableBuilder(column: $table.markerY, builder: (column) => column);
}

class $$AyahPolygonTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $AyahPolygonTable,
          AyahPolygonRow,
          $$AyahPolygonTableFilterComposer,
          $$AyahPolygonTableOrderingComposer,
          $$AyahPolygonTableAnnotationComposer,
          $$AyahPolygonTableCreateCompanionBuilder,
          $$AyahPolygonTableUpdateCompanionBuilder,
          (
            AyahPolygonRow,
            BaseReferences<
              _$ContentDatabase,
              $AyahPolygonTable,
              AyahPolygonRow
            >,
          ),
          AyahPolygonRow,
          PrefetchHooks Function()
        > {
  $$AyahPolygonTableTableManager(_$ContentDatabase db, $AyahPolygonTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AyahPolygonTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AyahPolygonTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AyahPolygonTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> page = const Value.absent(),
                Value<int> surah = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<double?> markerX = const Value.absent(),
                Value<double?> markerY = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AyahPolygonCompanion(
                page: page,
                surah: surah,
                number: number,
                path: path,
                markerX: markerX,
                markerY: markerY,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int page,
                required int surah,
                required int number,
                required String path,
                Value<double?> markerX = const Value.absent(),
                Value<double?> markerY = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AyahPolygonCompanion.insert(
                page: page,
                surah: surah,
                number: number,
                path: path,
                markerX: markerX,
                markerY: markerY,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AyahPolygonTable, AyahPolygonRow>(table),
                  BaseReferences<
                    _$ContentDatabase,
                    $AyahPolygonTable,
                    AyahPolygonRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AyahPolygonTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $AyahPolygonTable,
      AyahPolygonRow,
      $$AyahPolygonTableFilterComposer,
      $$AyahPolygonTableOrderingComposer,
      $$AyahPolygonTableAnnotationComposer,
      $$AyahPolygonTableCreateCompanionBuilder,
      $$AyahPolygonTableUpdateCompanionBuilder,
      (
        AyahPolygonRow,
        BaseReferences<_$ContentDatabase, $AyahPolygonTable, AyahPolygonRow>,
      ),
      AyahPolygonRow,
      PrefetchHooks Function()
    >;
typedef $$SourceTableCreateCompanionBuilder = SourceCompanion Function({
  Value<int> id,
  required String key,
  required String title,
  required String publisher,
  Value<String?> version,
  required String license,
  required String url,
  required String attribution,
  Value<String?> notice,
  required String sha256,
  required String retrievedAt,
});
typedef $$SourceTableUpdateCompanionBuilder = SourceCompanion Function({
  Value<int> id,
  Value<String> key,
  Value<String> title,
  Value<String> publisher,
  Value<String?> version,
  Value<String> license,
  Value<String> url,
  Value<String> attribution,
  Value<String?> notice,
  Value<String> sha256,
  Value<String> retrievedAt,
});

class $$SourceTableFilterComposer
    extends Composer<_$ContentDatabase, $SourceTable> {
  $$SourceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get license => $composableBuilder(
    column: $table.license,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notice => $composableBuilder(
    column: $table.notice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get retrievedAt => $composableBuilder(
    column: $table.retrievedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SourceTableOrderingComposer
    extends Composer<_$ContentDatabase, $SourceTable> {
  $$SourceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get license => $composableBuilder(
    column: $table.license,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notice => $composableBuilder(
    column: $table.notice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get retrievedAt => $composableBuilder(
    column: $table.retrievedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourceTableAnnotationComposer
    extends Composer<_$ContentDatabase, $SourceTable> {
  $$SourceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get publisher =>
      $composableBuilder(column: $table.publisher, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get license =>
      $composableBuilder(column: $table.license, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notice =>
      $composableBuilder(column: $table.notice, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get retrievedAt => $composableBuilder(
    column: $table.retrievedAt,
    builder: (column) => column,
  );
}

class $$SourceTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $SourceTable,
          SourceRow,
          $$SourceTableFilterComposer,
          $$SourceTableOrderingComposer,
          $$SourceTableAnnotationComposer,
          $$SourceTableCreateCompanionBuilder,
          $$SourceTableUpdateCompanionBuilder,
          (
            SourceRow,
            BaseReferences<_$ContentDatabase, $SourceTable, SourceRow>,
          ),
          SourceRow,
          PrefetchHooks Function()
        > {
  $$SourceTableTableManager(_$ContentDatabase db, $SourceTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> publisher = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<String> license = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> attribution = const Value.absent(),
                Value<String?> notice = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<String> retrievedAt = const Value.absent(),
              }) => SourceCompanion(
                id: id,
                key: key,
                title: title,
                publisher: publisher,
                version: version,
                license: license,
                url: url,
                attribution: attribution,
                notice: notice,
                sha256: sha256,
                retrievedAt: retrievedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String key,
                required String title,
                required String publisher,
                Value<String?> version = const Value.absent(),
                required String license,
                required String url,
                required String attribution,
                Value<String?> notice = const Value.absent(),
                required String sha256,
                required String retrievedAt,
              }) => SourceCompanion.insert(
                id: id,
                key: key,
                title: title,
                publisher: publisher,
                version: version,
                license: license,
                url: url,
                attribution: attribution,
                notice: notice,
                sha256: sha256,
                retrievedAt: retrievedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SourceTable, SourceRow>(table),
                  BaseReferences<_$ContentDatabase, $SourceTable, SourceRow>(
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

typedef $$SourceTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $SourceTable,
      SourceRow,
      $$SourceTableFilterComposer,
      $$SourceTableOrderingComposer,
      $$SourceTableAnnotationComposer,
      $$SourceTableCreateCompanionBuilder,
      $$SourceTableUpdateCompanionBuilder,
      (SourceRow, BaseReferences<_$ContentDatabase, $SourceTable, SourceRow>),
      SourceRow,
      PrefetchHooks Function()
    >;
typedef $$WordBoxTableCreateCompanionBuilder = WordBoxCompanion Function({
  required int surah,
  required int ayah,
  required int word,
  required int page,
  required int x0,
  required int y0,
  required int x1,
  required int y1,
  required int exact,
});
typedef $$WordBoxTableUpdateCompanionBuilder = WordBoxCompanion Function({
  Value<int> surah,
  Value<int> ayah,
  Value<int> word,
  Value<int> page,
  Value<int> x0,
  Value<int> y0,
  Value<int> x1,
  Value<int> y1,
  Value<int> exact,
});

class $$WordBoxTableFilterComposer
    extends Composer<_$ContentDatabase, $WordBoxTable> {
  $$WordBoxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x0 => $composableBuilder(
    column: $table.x0,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exact => $composableBuilder(
    column: $table.exact,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordBoxTableOrderingComposer
    extends Composer<_$ContentDatabase, $WordBoxTable> {
  $$WordBoxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x0 => $composableBuilder(
    column: $table.x0,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exact => $composableBuilder(
    column: $table.exact,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordBoxTableAnnotationComposer
    extends Composer<_$ContentDatabase, $WordBoxTable> {
  $$WordBoxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<int> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get x0 =>
      $composableBuilder(column: $table.x0, builder: (column) => column);

  GeneratedColumn<int> get y0 =>
      $composableBuilder(column: $table.y0, builder: (column) => column);

  GeneratedColumn<int> get x1 =>
      $composableBuilder(column: $table.x1, builder: (column) => column);

  GeneratedColumn<int> get y1 =>
      $composableBuilder(column: $table.y1, builder: (column) => column);

  GeneratedColumn<int> get exact =>
      $composableBuilder(column: $table.exact, builder: (column) => column);
}

class $$WordBoxTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $WordBoxTable,
          WordBoxRow,
          $$WordBoxTableFilterComposer,
          $$WordBoxTableOrderingComposer,
          $$WordBoxTableAnnotationComposer,
          $$WordBoxTableCreateCompanionBuilder,
          $$WordBoxTableUpdateCompanionBuilder,
          (
            WordBoxRow,
            BaseReferences<_$ContentDatabase, $WordBoxTable, WordBoxRow>,
          ),
          WordBoxRow,
          PrefetchHooks Function()
        > {
  $$WordBoxTableTableManager(_$ContentDatabase db, $WordBoxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordBoxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordBoxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordBoxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<int> word = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<int> x0 = const Value.absent(),
                Value<int> y0 = const Value.absent(),
                Value<int> x1 = const Value.absent(),
                Value<int> y1 = const Value.absent(),
                Value<int> exact = const Value.absent(),
              }) => WordBoxCompanion(
                surah: surah,
                ayah: ayah,
                word: word,
                page: page,
                x0: x0,
                y0: y0,
                x1: x1,
                y1: y1,
                exact: exact,
              ),
          createCompanionCallback:
              ({
                required int surah,
                required int ayah,
                required int word,
                required int page,
                required int x0,
                required int y0,
                required int x1,
                required int y1,
                required int exact,
              }) => WordBoxCompanion.insert(
                surah: surah,
                ayah: ayah,
                word: word,
                page: page,
                x0: x0,
                y0: y0,
                x1: x1,
                y1: y1,
                exact: exact,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WordBoxTable, WordBoxRow>(table),
                  BaseReferences<_$ContentDatabase, $WordBoxTable, WordBoxRow>(
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

typedef $$WordBoxTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $WordBoxTable,
      WordBoxRow,
      $$WordBoxTableFilterComposer,
      $$WordBoxTableOrderingComposer,
      $$WordBoxTableAnnotationComposer,
      $$WordBoxTableCreateCompanionBuilder,
      $$WordBoxTableUpdateCompanionBuilder,
      (
        WordBoxRow,
        BaseReferences<_$ContentDatabase, $WordBoxTable, WordBoxRow>,
      ),
      WordBoxRow,
      PrefetchHooks Function()
    >;
typedef $$LineCutTableCreateCompanionBuilder = LineCutCompanion Function({
  required String edition,
  required int page,
  required int gap,
  required double y,
});
typedef $$LineCutTableUpdateCompanionBuilder = LineCutCompanion Function({
  Value<String> edition,
  Value<int> page,
  Value<int> gap,
  Value<double> y,
});

class $$LineCutTableFilterComposer
    extends Composer<_$ContentDatabase, $LineCutTable> {
  $$LineCutTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get edition => $composableBuilder(
    column: $table.edition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gap => $composableBuilder(
    column: $table.gap,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LineCutTableOrderingComposer
    extends Composer<_$ContentDatabase, $LineCutTable> {
  $$LineCutTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get edition => $composableBuilder(
    column: $table.edition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gap => $composableBuilder(
    column: $table.gap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LineCutTableAnnotationComposer
    extends Composer<_$ContentDatabase, $LineCutTable> {
  $$LineCutTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get edition =>
      $composableBuilder(column: $table.edition, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get gap =>
      $composableBuilder(column: $table.gap, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);
}

class $$LineCutTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $LineCutTable,
          LineCutRow,
          $$LineCutTableFilterComposer,
          $$LineCutTableOrderingComposer,
          $$LineCutTableAnnotationComposer,
          $$LineCutTableCreateCompanionBuilder,
          $$LineCutTableUpdateCompanionBuilder,
          (
            LineCutRow,
            BaseReferences<_$ContentDatabase, $LineCutTable, LineCutRow>,
          ),
          LineCutRow,
          PrefetchHooks Function()
        > {
  $$LineCutTableTableManager(_$ContentDatabase db, $LineCutTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LineCutTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LineCutTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LineCutTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> edition = const Value.absent(),
            Value<int> page = const Value.absent(),
            Value<int> gap = const Value.absent(),
            Value<double> y = const Value.absent(),
          }) => LineCutCompanion(edition: edition, page: page, gap: gap, y: y),
          createCompanionCallback:
              ({
                required String edition,
                required int page,
                required int gap,
                required double y,
              }) => LineCutCompanion.insert(
                edition: edition,
                page: page,
                gap: gap,
                y: y,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LineCutTable, LineCutRow>(table),
                  BaseReferences<_$ContentDatabase, $LineCutTable, LineCutRow>(
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

typedef $$LineCutTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $LineCutTable,
      LineCutRow,
      $$LineCutTableFilterComposer,
      $$LineCutTableOrderingComposer,
      $$LineCutTableAnnotationComposer,
      $$LineCutTableCreateCompanionBuilder,
      $$LineCutTableUpdateCompanionBuilder,
      (
        LineCutRow,
        BaseReferences<_$ContentDatabase, $LineCutTable, LineCutRow>,
      ),
      LineCutRow,
      PrefetchHooks Function()
    >;
typedef $$LineOverflowTableCreateCompanionBuilder =
    LineOverflowCompanion Function({
      required int page,
      required int line,
      required String path,
      Value<int> rowid,
    });
typedef $$LineOverflowTableUpdateCompanionBuilder =
    LineOverflowCompanion Function({
      Value<int> page,
      Value<int> line,
      Value<String> path,
      Value<int> rowid,
    });

class $$LineOverflowTableFilterComposer
    extends Composer<_$ContentDatabase, $LineOverflowTable> {
  $$LineOverflowTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LineOverflowTableOrderingComposer
    extends Composer<_$ContentDatabase, $LineOverflowTable> {
  $$LineOverflowTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LineOverflowTableAnnotationComposer
    extends Composer<_$ContentDatabase, $LineOverflowTable> {
  $$LineOverflowTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get line =>
      $composableBuilder(column: $table.line, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);
}

class $$LineOverflowTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $LineOverflowTable,
          LineOverflowRow,
          $$LineOverflowTableFilterComposer,
          $$LineOverflowTableOrderingComposer,
          $$LineOverflowTableAnnotationComposer,
          $$LineOverflowTableCreateCompanionBuilder,
          $$LineOverflowTableUpdateCompanionBuilder,
          (
            LineOverflowRow,
            BaseReferences<
              _$ContentDatabase,
              $LineOverflowTable,
              LineOverflowRow
            >,
          ),
          LineOverflowRow,
          PrefetchHooks Function()
        > {
  $$LineOverflowTableTableManager(
    _$ContentDatabase db,
    $LineOverflowTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LineOverflowTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LineOverflowTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LineOverflowTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> page = const Value.absent(),
                Value<int> line = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LineOverflowCompanion(
                page: page,
                line: line,
                path: path,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int page,
                required int line,
                required String path,
                Value<int> rowid = const Value.absent(),
              }) => LineOverflowCompanion.insert(
                page: page,
                line: line,
                path: path,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LineOverflowTable, LineOverflowRow>(table),
                  BaseReferences<
                    _$ContentDatabase,
                    $LineOverflowTable,
                    LineOverflowRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LineOverflowTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $LineOverflowTable,
      LineOverflowRow,
      $$LineOverflowTableFilterComposer,
      $$LineOverflowTableOrderingComposer,
      $$LineOverflowTableAnnotationComposer,
      $$LineOverflowTableCreateCompanionBuilder,
      $$LineOverflowTableUpdateCompanionBuilder,
      (
        LineOverflowRow,
        BaseReferences<_$ContentDatabase, $LineOverflowTable, LineOverflowRow>,
      ),
      LineOverflowRow,
      PrefetchHooks Function()
    >;
typedef $$LineOverflow1405TableCreateCompanionBuilder =
    LineOverflow1405Companion Function({
      required int page,
      required int line,
      required int x0,
      required int y0,
      required int x1,
      required int y1,
      Value<int> rowid,
    });
typedef $$LineOverflow1405TableUpdateCompanionBuilder =
    LineOverflow1405Companion Function({
      Value<int> page,
      Value<int> line,
      Value<int> x0,
      Value<int> y0,
      Value<int> x1,
      Value<int> y1,
      Value<int> rowid,
    });

class $$LineOverflow1405TableFilterComposer
    extends Composer<_$ContentDatabase, $LineOverflow1405Table> {
  $$LineOverflow1405TableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x0 => $composableBuilder(
    column: $table.x0,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LineOverflow1405TableOrderingComposer
    extends Composer<_$ContentDatabase, $LineOverflow1405Table> {
  $$LineOverflow1405TableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x0 => $composableBuilder(
    column: $table.x0,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LineOverflow1405TableAnnotationComposer
    extends Composer<_$ContentDatabase, $LineOverflow1405Table> {
  $$LineOverflow1405TableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get line =>
      $composableBuilder(column: $table.line, builder: (column) => column);

  GeneratedColumn<int> get x0 =>
      $composableBuilder(column: $table.x0, builder: (column) => column);

  GeneratedColumn<int> get y0 =>
      $composableBuilder(column: $table.y0, builder: (column) => column);

  GeneratedColumn<int> get x1 =>
      $composableBuilder(column: $table.x1, builder: (column) => column);

  GeneratedColumn<int> get y1 =>
      $composableBuilder(column: $table.y1, builder: (column) => column);
}

class $$LineOverflow1405TableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $LineOverflow1405Table,
          OldOverflowRow,
          $$LineOverflow1405TableFilterComposer,
          $$LineOverflow1405TableOrderingComposer,
          $$LineOverflow1405TableAnnotationComposer,
          $$LineOverflow1405TableCreateCompanionBuilder,
          $$LineOverflow1405TableUpdateCompanionBuilder,
          (
            OldOverflowRow,
            BaseReferences<
              _$ContentDatabase,
              $LineOverflow1405Table,
              OldOverflowRow
            >,
          ),
          OldOverflowRow,
          PrefetchHooks Function()
        > {
  $$LineOverflow1405TableTableManager(
    _$ContentDatabase db,
    $LineOverflow1405Table table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LineOverflow1405TableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LineOverflow1405TableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LineOverflow1405TableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> page = const Value.absent(),
                Value<int> line = const Value.absent(),
                Value<int> x0 = const Value.absent(),
                Value<int> y0 = const Value.absent(),
                Value<int> x1 = const Value.absent(),
                Value<int> y1 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LineOverflow1405Companion(
                page: page,
                line: line,
                x0: x0,
                y0: y0,
                x1: x1,
                y1: y1,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int page,
                required int line,
                required int x0,
                required int y0,
                required int x1,
                required int y1,
                Value<int> rowid = const Value.absent(),
              }) => LineOverflow1405Companion.insert(
                page: page,
                line: line,
                x0: x0,
                y0: y0,
                x1: x1,
                y1: y1,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LineOverflow1405Table, OldOverflowRow>(table),
                  BaseReferences<
                    _$ContentDatabase,
                    $LineOverflow1405Table,
                    OldOverflowRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LineOverflow1405TableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $LineOverflow1405Table,
      OldOverflowRow,
      $$LineOverflow1405TableFilterComposer,
      $$LineOverflow1405TableOrderingComposer,
      $$LineOverflow1405TableAnnotationComposer,
      $$LineOverflow1405TableCreateCompanionBuilder,
      $$LineOverflow1405TableUpdateCompanionBuilder,
      (
        OldOverflowRow,
        BaseReferences<
          _$ContentDatabase,
          $LineOverflow1405Table,
          OldOverflowRow
        >,
      ),
      OldOverflowRow,
      PrefetchHooks Function()
    >;
typedef $$CommentaryEditionTableCreateCompanionBuilder =
    CommentaryEditionCompanion Function({
      Value<int> sourceId,
      required String kind,
      required String language,
      required String direction,
      required String nameAr,
      required String nameEn,
      required int sortOrder,
    });
typedef $$CommentaryEditionTableUpdateCompanionBuilder =
    CommentaryEditionCompanion Function({
      Value<int> sourceId,
      Value<String> kind,
      Value<String> language,
      Value<String> direction,
      Value<String> nameAr,
      Value<String> nameEn,
      Value<int> sortOrder,
    });

class $$CommentaryEditionTableFilterComposer
    extends Composer<_$ContentDatabase, $CommentaryEditionTable> {
  $$CommentaryEditionTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CommentaryEditionTableOrderingComposer
    extends Composer<_$ContentDatabase, $CommentaryEditionTable> {
  $$CommentaryEditionTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CommentaryEditionTableAnnotationComposer
    extends Composer<_$ContentDatabase, $CommentaryEditionTable> {
  $$CommentaryEditionTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CommentaryEditionTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $CommentaryEditionTable,
          CommentaryEditionRow,
          $$CommentaryEditionTableFilterComposer,
          $$CommentaryEditionTableOrderingComposer,
          $$CommentaryEditionTableAnnotationComposer,
          $$CommentaryEditionTableCreateCompanionBuilder,
          $$CommentaryEditionTableUpdateCompanionBuilder,
          (
            CommentaryEditionRow,
            BaseReferences<
              _$ContentDatabase,
              $CommentaryEditionTable,
              CommentaryEditionRow
            >,
          ),
          CommentaryEditionRow,
          PrefetchHooks Function()
        > {
  $$CommentaryEditionTableTableManager(
    _$ContentDatabase db,
    $CommentaryEditionTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CommentaryEditionTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CommentaryEditionTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CommentaryEditionTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String> nameAr = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CommentaryEditionCompanion(
                sourceId: sourceId,
                kind: kind,
                language: language,
                direction: direction,
                nameAr: nameAr,
                nameEn: nameEn,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                required String kind,
                required String language,
                required String direction,
                required String nameAr,
                required String nameEn,
                required int sortOrder,
              }) => CommentaryEditionCompanion.insert(
                sourceId: sourceId,
                kind: kind,
                language: language,
                direction: direction,
                nameAr: nameAr,
                nameEn: nameEn,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CommentaryEditionTable, CommentaryEditionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$ContentDatabase,
                    $CommentaryEditionTable,
                    CommentaryEditionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CommentaryEditionTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $CommentaryEditionTable,
      CommentaryEditionRow,
      $$CommentaryEditionTableFilterComposer,
      $$CommentaryEditionTableOrderingComposer,
      $$CommentaryEditionTableAnnotationComposer,
      $$CommentaryEditionTableCreateCompanionBuilder,
      $$CommentaryEditionTableUpdateCompanionBuilder,
      (
        CommentaryEditionRow,
        BaseReferences<
          _$ContentDatabase,
          $CommentaryEditionTable,
          CommentaryEditionRow
        >,
      ),
      CommentaryEditionRow,
      PrefetchHooks Function()
    >;
typedef $$CommentaryTableCreateCompanionBuilder = CommentaryCompanion Function({
  required int sourceId,
  required int surah,
  required int ayah,
  required String body,
  Value<String?> footnotes,
});
typedef $$CommentaryTableUpdateCompanionBuilder = CommentaryCompanion Function({
  Value<int> sourceId,
  Value<int> surah,
  Value<int> ayah,
  Value<String> body,
  Value<String?> footnotes,
});

class $$CommentaryTableFilterComposer
    extends Composer<_$ContentDatabase, $CommentaryTable> {
  $$CommentaryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get footnotes => $composableBuilder(
    column: $table.footnotes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CommentaryTableOrderingComposer
    extends Composer<_$ContentDatabase, $CommentaryTable> {
  $$CommentaryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get footnotes => $composableBuilder(
    column: $table.footnotes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CommentaryTableAnnotationComposer
    extends Composer<_$ContentDatabase, $CommentaryTable> {
  $$CommentaryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get footnotes =>
      $composableBuilder(column: $table.footnotes, builder: (column) => column);
}

class $$CommentaryTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $CommentaryTable,
          CommentaryRow,
          $$CommentaryTableFilterComposer,
          $$CommentaryTableOrderingComposer,
          $$CommentaryTableAnnotationComposer,
          $$CommentaryTableCreateCompanionBuilder,
          $$CommentaryTableUpdateCompanionBuilder,
          (
            CommentaryRow,
            BaseReferences<_$ContentDatabase, $CommentaryTable, CommentaryRow>,
          ),
          CommentaryRow,
          PrefetchHooks Function()
        > {
  $$CommentaryTableTableManager(_$ContentDatabase db, $CommentaryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CommentaryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CommentaryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CommentaryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> footnotes = const Value.absent(),
              }) => CommentaryCompanion(
                sourceId: sourceId,
                surah: surah,
                ayah: ayah,
                body: body,
                footnotes: footnotes,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required int surah,
                required int ayah,
                required String body,
                Value<String?> footnotes = const Value.absent(),
              }) => CommentaryCompanion.insert(
                sourceId: sourceId,
                surah: surah,
                ayah: ayah,
                body: body,
                footnotes: footnotes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CommentaryTable, CommentaryRow>(table),
                  BaseReferences<
                    _$ContentDatabase,
                    $CommentaryTable,
                    CommentaryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CommentaryTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $CommentaryTable,
      CommentaryRow,
      $$CommentaryTableFilterComposer,
      $$CommentaryTableOrderingComposer,
      $$CommentaryTableAnnotationComposer,
      $$CommentaryTableCreateCompanionBuilder,
      $$CommentaryTableUpdateCompanionBuilder,
      (
        CommentaryRow,
        BaseReferences<_$ContentDatabase, $CommentaryTable, CommentaryRow>,
      ),
      CommentaryRow,
      PrefetchHooks Function()
    >;
typedef $$ReciterTableCreateCompanionBuilder = ReciterCompanion Function({
  Value<int> id,
  required String nameAr,
  required String nameEn,
  required String style,
  required String folderUrl,
  required int sourceId,
});
typedef $$ReciterTableUpdateCompanionBuilder = ReciterCompanion Function({
  Value<int> id,
  Value<String> nameAr,
  Value<String> nameEn,
  Value<String> style,
  Value<String> folderUrl,
  Value<int> sourceId,
});

class $$ReciterTableFilterComposer
    extends Composer<_$ContentDatabase, $ReciterTable> {
  $$ReciterTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderUrl => $composableBuilder(
    column: $table.folderUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReciterTableOrderingComposer
    extends Composer<_$ContentDatabase, $ReciterTable> {
  $$ReciterTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderUrl => $composableBuilder(
    column: $table.folderUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReciterTableAnnotationComposer
    extends Composer<_$ContentDatabase, $ReciterTable> {
  $$ReciterTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<String> get folderUrl =>
      $composableBuilder(column: $table.folderUrl, builder: (column) => column);

  GeneratedColumn<int> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);
}

class $$ReciterTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $ReciterTable,
          ReciterRow,
          $$ReciterTableFilterComposer,
          $$ReciterTableOrderingComposer,
          $$ReciterTableAnnotationComposer,
          $$ReciterTableCreateCompanionBuilder,
          $$ReciterTableUpdateCompanionBuilder,
          (
            ReciterRow,
            BaseReferences<_$ContentDatabase, $ReciterTable, ReciterRow>,
          ),
          ReciterRow,
          PrefetchHooks Function()
        > {
  $$ReciterTableTableManager(_$ContentDatabase db, $ReciterTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReciterTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReciterTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReciterTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nameAr = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> style = const Value.absent(),
                Value<String> folderUrl = const Value.absent(),
                Value<int> sourceId = const Value.absent(),
              }) => ReciterCompanion(
                id: id,
                nameAr: nameAr,
                nameEn: nameEn,
                style: style,
                folderUrl: folderUrl,
                sourceId: sourceId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nameAr,
                required String nameEn,
                required String style,
                required String folderUrl,
                required int sourceId,
              }) => ReciterCompanion.insert(
                id: id,
                nameAr: nameAr,
                nameEn: nameEn,
                style: style,
                folderUrl: folderUrl,
                sourceId: sourceId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReciterTable, ReciterRow>(table),
                  BaseReferences<_$ContentDatabase, $ReciterTable, ReciterRow>(
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

typedef $$ReciterTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $ReciterTable,
      ReciterRow,
      $$ReciterTableFilterComposer,
      $$ReciterTableOrderingComposer,
      $$ReciterTableAnnotationComposer,
      $$ReciterTableCreateCompanionBuilder,
      $$ReciterTableUpdateCompanionBuilder,
      (
        ReciterRow,
        BaseReferences<_$ContentDatabase, $ReciterTable, ReciterRow>,
      ),
      ReciterRow,
      PrefetchHooks Function()
    >;
typedef $$AyahTimingTableCreateCompanionBuilder = AyahTimingCompanion Function({
  required int reciter,
  required int surah,
  required int ayah,
  required int startMs,
  required int endMs,
});
typedef $$AyahTimingTableUpdateCompanionBuilder = AyahTimingCompanion Function({
  Value<int> reciter,
  Value<int> surah,
  Value<int> ayah,
  Value<int> startMs,
  Value<int> endMs,
});

class $$AyahTimingTableFilterComposer
    extends Composer<_$ContentDatabase, $AyahTimingTable> {
  $$AyahTimingTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get reciter => $composableBuilder(
    column: $table.reciter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AyahTimingTableOrderingComposer
    extends Composer<_$ContentDatabase, $AyahTimingTable> {
  $$AyahTimingTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get reciter => $composableBuilder(
    column: $table.reciter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AyahTimingTableAnnotationComposer
    extends Composer<_$ContentDatabase, $AyahTimingTable> {
  $$AyahTimingTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get reciter =>
      $composableBuilder(column: $table.reciter, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);
}

class $$AyahTimingTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $AyahTimingTable,
          AyahTimingRow,
          $$AyahTimingTableFilterComposer,
          $$AyahTimingTableOrderingComposer,
          $$AyahTimingTableAnnotationComposer,
          $$AyahTimingTableCreateCompanionBuilder,
          $$AyahTimingTableUpdateCompanionBuilder,
          (
            AyahTimingRow,
            BaseReferences<_$ContentDatabase, $AyahTimingTable, AyahTimingRow>,
          ),
          AyahTimingRow,
          PrefetchHooks Function()
        > {
  $$AyahTimingTableTableManager(_$ContentDatabase db, $AyahTimingTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AyahTimingTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AyahTimingTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AyahTimingTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> reciter = const Value.absent(),
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<int> startMs = const Value.absent(),
                Value<int> endMs = const Value.absent(),
              }) => AyahTimingCompanion(
                reciter: reciter,
                surah: surah,
                ayah: ayah,
                startMs: startMs,
                endMs: endMs,
              ),
          createCompanionCallback:
              ({
                required int reciter,
                required int surah,
                required int ayah,
                required int startMs,
                required int endMs,
              }) => AyahTimingCompanion.insert(
                reciter: reciter,
                surah: surah,
                ayah: ayah,
                startMs: startMs,
                endMs: endMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AyahTimingTable, AyahTimingRow>(table),
                  BaseReferences<
                    _$ContentDatabase,
                    $AyahTimingTable,
                    AyahTimingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AyahTimingTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $AyahTimingTable,
      AyahTimingRow,
      $$AyahTimingTableFilterComposer,
      $$AyahTimingTableOrderingComposer,
      $$AyahTimingTableAnnotationComposer,
      $$AyahTimingTableCreateCompanionBuilder,
      $$AyahTimingTableUpdateCompanionBuilder,
      (
        AyahTimingRow,
        BaseReferences<_$ContentDatabase, $AyahTimingTable, AyahTimingRow>,
      ),
      AyahTimingRow,
      PrefetchHooks Function()
    >;
typedef $$WordTimingTableCreateCompanionBuilder = WordTimingCompanion Function({
  required int reciter,
  required int surah,
  required int ayah,
  required int word,
  required int startMs,
  required int endMs,
});
typedef $$WordTimingTableUpdateCompanionBuilder = WordTimingCompanion Function({
  Value<int> reciter,
  Value<int> surah,
  Value<int> ayah,
  Value<int> word,
  Value<int> startMs,
  Value<int> endMs,
});

class $$WordTimingTableFilterComposer
    extends Composer<_$ContentDatabase, $WordTimingTable> {
  $$WordTimingTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get reciter => $composableBuilder(
    column: $table.reciter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordTimingTableOrderingComposer
    extends Composer<_$ContentDatabase, $WordTimingTable> {
  $$WordTimingTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get reciter => $composableBuilder(
    column: $table.reciter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordTimingTableAnnotationComposer
    extends Composer<_$ContentDatabase, $WordTimingTable> {
  $$WordTimingTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get reciter =>
      $composableBuilder(column: $table.reciter, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<int> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);
}

class $$WordTimingTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $WordTimingTable,
          WordTimingRow,
          $$WordTimingTableFilterComposer,
          $$WordTimingTableOrderingComposer,
          $$WordTimingTableAnnotationComposer,
          $$WordTimingTableCreateCompanionBuilder,
          $$WordTimingTableUpdateCompanionBuilder,
          (
            WordTimingRow,
            BaseReferences<_$ContentDatabase, $WordTimingTable, WordTimingRow>,
          ),
          WordTimingRow,
          PrefetchHooks Function()
        > {
  $$WordTimingTableTableManager(_$ContentDatabase db, $WordTimingTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordTimingTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordTimingTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordTimingTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> reciter = const Value.absent(),
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<int> word = const Value.absent(),
                Value<int> startMs = const Value.absent(),
                Value<int> endMs = const Value.absent(),
              }) => WordTimingCompanion(
                reciter: reciter,
                surah: surah,
                ayah: ayah,
                word: word,
                startMs: startMs,
                endMs: endMs,
              ),
          createCompanionCallback:
              ({
                required int reciter,
                required int surah,
                required int ayah,
                required int word,
                required int startMs,
                required int endMs,
              }) => WordTimingCompanion.insert(
                reciter: reciter,
                surah: surah,
                ayah: ayah,
                word: word,
                startMs: startMs,
                endMs: endMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WordTimingTable, WordTimingRow>(table),
                  BaseReferences<
                    _$ContentDatabase,
                    $WordTimingTable,
                    WordTimingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordTimingTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $WordTimingTable,
      WordTimingRow,
      $$WordTimingTableFilterComposer,
      $$WordTimingTableOrderingComposer,
      $$WordTimingTableAnnotationComposer,
      $$WordTimingTableCreateCompanionBuilder,
      $$WordTimingTableUpdateCompanionBuilder,
      (
        WordTimingRow,
        BaseReferences<_$ContentDatabase, $WordTimingTable, WordTimingRow>,
      ),
      WordTimingRow,
      PrefetchHooks Function()
    >;
typedef $$AyahSpeechTableCreateCompanionBuilder = AyahSpeechCompanion Function({
  required int reciter,
  required int surah,
  required int ayah,
  required int startMs,
  required int endMs,
});
typedef $$AyahSpeechTableUpdateCompanionBuilder = AyahSpeechCompanion Function({
  Value<int> reciter,
  Value<int> surah,
  Value<int> ayah,
  Value<int> startMs,
  Value<int> endMs,
});

class $$AyahSpeechTableFilterComposer
    extends Composer<_$ContentDatabase, $AyahSpeechTable> {
  $$AyahSpeechTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get reciter => $composableBuilder(
    column: $table.reciter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AyahSpeechTableOrderingComposer
    extends Composer<_$ContentDatabase, $AyahSpeechTable> {
  $$AyahSpeechTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get reciter => $composableBuilder(
    column: $table.reciter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AyahSpeechTableAnnotationComposer
    extends Composer<_$ContentDatabase, $AyahSpeechTable> {
  $$AyahSpeechTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get reciter =>
      $composableBuilder(column: $table.reciter, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);
}

class $$AyahSpeechTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $AyahSpeechTable,
          AyahSpeechRow,
          $$AyahSpeechTableFilterComposer,
          $$AyahSpeechTableOrderingComposer,
          $$AyahSpeechTableAnnotationComposer,
          $$AyahSpeechTableCreateCompanionBuilder,
          $$AyahSpeechTableUpdateCompanionBuilder,
          (
            AyahSpeechRow,
            BaseReferences<_$ContentDatabase, $AyahSpeechTable, AyahSpeechRow>,
          ),
          AyahSpeechRow,
          PrefetchHooks Function()
        > {
  $$AyahSpeechTableTableManager(_$ContentDatabase db, $AyahSpeechTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AyahSpeechTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AyahSpeechTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AyahSpeechTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> reciter = const Value.absent(),
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<int> startMs = const Value.absent(),
                Value<int> endMs = const Value.absent(),
              }) => AyahSpeechCompanion(
                reciter: reciter,
                surah: surah,
                ayah: ayah,
                startMs: startMs,
                endMs: endMs,
              ),
          createCompanionCallback:
              ({
                required int reciter,
                required int surah,
                required int ayah,
                required int startMs,
                required int endMs,
              }) => AyahSpeechCompanion.insert(
                reciter: reciter,
                surah: surah,
                ayah: ayah,
                startMs: startMs,
                endMs: endMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AyahSpeechTable, AyahSpeechRow>(table),
                  BaseReferences<
                    _$ContentDatabase,
                    $AyahSpeechTable,
                    AyahSpeechRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AyahSpeechTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $AyahSpeechTable,
      AyahSpeechRow,
      $$AyahSpeechTableFilterComposer,
      $$AyahSpeechTableOrderingComposer,
      $$AyahSpeechTableAnnotationComposer,
      $$AyahSpeechTableCreateCompanionBuilder,
      $$AyahSpeechTableUpdateCompanionBuilder,
      (
        AyahSpeechRow,
        BaseReferences<_$ContentDatabase, $AyahSpeechTable, AyahSpeechRow>,
      ),
      AyahSpeechRow,
      PrefetchHooks Function()
    >;
typedef $$ShamarlyPageTableCreateCompanionBuilder =
    ShamarlyPageCompanion Function({
      Value<int> page,
      required String kind,
      required int lines,
      Value<double?> gridTop,
      Value<double?> pitch,
    });
typedef $$ShamarlyPageTableUpdateCompanionBuilder =
    ShamarlyPageCompanion Function({
      Value<int> page,
      Value<String> kind,
      Value<int> lines,
      Value<double?> gridTop,
      Value<double?> pitch,
    });

class $$ShamarlyPageTableFilterComposer
    extends Composer<_$ContentDatabase, $ShamarlyPageTable> {
  $$ShamarlyPageTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lines => $composableBuilder(
    column: $table.lines,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gridTop => $composableBuilder(
    column: $table.gridTop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pitch => $composableBuilder(
    column: $table.pitch,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShamarlyPageTableOrderingComposer
    extends Composer<_$ContentDatabase, $ShamarlyPageTable> {
  $$ShamarlyPageTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lines => $composableBuilder(
    column: $table.lines,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gridTop => $composableBuilder(
    column: $table.gridTop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pitch => $composableBuilder(
    column: $table.pitch,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShamarlyPageTableAnnotationComposer
    extends Composer<_$ContentDatabase, $ShamarlyPageTable> {
  $$ShamarlyPageTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get lines =>
      $composableBuilder(column: $table.lines, builder: (column) => column);

  GeneratedColumn<double> get gridTop =>
      $composableBuilder(column: $table.gridTop, builder: (column) => column);

  GeneratedColumn<double> get pitch =>
      $composableBuilder(column: $table.pitch, builder: (column) => column);
}

class $$ShamarlyPageTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $ShamarlyPageTable,
          ShamarlyPageRow,
          $$ShamarlyPageTableFilterComposer,
          $$ShamarlyPageTableOrderingComposer,
          $$ShamarlyPageTableAnnotationComposer,
          $$ShamarlyPageTableCreateCompanionBuilder,
          $$ShamarlyPageTableUpdateCompanionBuilder,
          (
            ShamarlyPageRow,
            BaseReferences<
              _$ContentDatabase,
              $ShamarlyPageTable,
              ShamarlyPageRow
            >,
          ),
          ShamarlyPageRow,
          PrefetchHooks Function()
        > {
  $$ShamarlyPageTableTableManager(
    _$ContentDatabase db,
    $ShamarlyPageTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShamarlyPageTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShamarlyPageTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShamarlyPageTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> page = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> lines = const Value.absent(),
                Value<double?> gridTop = const Value.absent(),
                Value<double?> pitch = const Value.absent(),
              }) => ShamarlyPageCompanion(
                page: page,
                kind: kind,
                lines: lines,
                gridTop: gridTop,
                pitch: pitch,
              ),
          createCompanionCallback:
              ({
                Value<int> page = const Value.absent(),
                required String kind,
                required int lines,
                Value<double?> gridTop = const Value.absent(),
                Value<double?> pitch = const Value.absent(),
              }) => ShamarlyPageCompanion.insert(
                page: page,
                kind: kind,
                lines: lines,
                gridTop: gridTop,
                pitch: pitch,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShamarlyPageTable, ShamarlyPageRow>(table),
                  BaseReferences<
                    _$ContentDatabase,
                    $ShamarlyPageTable,
                    ShamarlyPageRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShamarlyPageTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $ShamarlyPageTable,
      ShamarlyPageRow,
      $$ShamarlyPageTableFilterComposer,
      $$ShamarlyPageTableOrderingComposer,
      $$ShamarlyPageTableAnnotationComposer,
      $$ShamarlyPageTableCreateCompanionBuilder,
      $$ShamarlyPageTableUpdateCompanionBuilder,
      (
        ShamarlyPageRow,
        BaseReferences<_$ContentDatabase, $ShamarlyPageTable, ShamarlyPageRow>,
      ),
      ShamarlyPageRow,
      PrefetchHooks Function()
    >;
typedef $$ShamarlyLineTableCreateCompanionBuilder =
    ShamarlyLineCompanion Function({
      required int page,
      required int line,
      required String kind,
      Value<int?> surah,
      required int y0,
      required int y1,
    });
typedef $$ShamarlyLineTableUpdateCompanionBuilder =
    ShamarlyLineCompanion Function({
      Value<int> page,
      Value<int> line,
      Value<String> kind,
      Value<int?> surah,
      Value<int> y0,
      Value<int> y1,
    });

class $$ShamarlyLineTableFilterComposer
    extends Composer<_$ContentDatabase, $ShamarlyLineTable> {
  $$ShamarlyLineTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShamarlyLineTableOrderingComposer
    extends Composer<_$ContentDatabase, $ShamarlyLineTable> {
  $$ShamarlyLineTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShamarlyLineTableAnnotationComposer
    extends Composer<_$ContentDatabase, $ShamarlyLineTable> {
  $$ShamarlyLineTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get line =>
      $composableBuilder(column: $table.line, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get y0 =>
      $composableBuilder(column: $table.y0, builder: (column) => column);

  GeneratedColumn<int> get y1 =>
      $composableBuilder(column: $table.y1, builder: (column) => column);
}

class $$ShamarlyLineTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $ShamarlyLineTable,
          ShamarlyLineRow,
          $$ShamarlyLineTableFilterComposer,
          $$ShamarlyLineTableOrderingComposer,
          $$ShamarlyLineTableAnnotationComposer,
          $$ShamarlyLineTableCreateCompanionBuilder,
          $$ShamarlyLineTableUpdateCompanionBuilder,
          (
            ShamarlyLineRow,
            BaseReferences<
              _$ContentDatabase,
              $ShamarlyLineTable,
              ShamarlyLineRow
            >,
          ),
          ShamarlyLineRow,
          PrefetchHooks Function()
        > {
  $$ShamarlyLineTableTableManager(
    _$ContentDatabase db,
    $ShamarlyLineTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShamarlyLineTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShamarlyLineTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShamarlyLineTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> page = const Value.absent(),
                Value<int> line = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int?> surah = const Value.absent(),
                Value<int> y0 = const Value.absent(),
                Value<int> y1 = const Value.absent(),
              }) => ShamarlyLineCompanion(
                page: page,
                line: line,
                kind: kind,
                surah: surah,
                y0: y0,
                y1: y1,
              ),
          createCompanionCallback:
              ({
                required int page,
                required int line,
                required String kind,
                Value<int?> surah = const Value.absent(),
                required int y0,
                required int y1,
              }) => ShamarlyLineCompanion.insert(
                page: page,
                line: line,
                kind: kind,
                surah: surah,
                y0: y0,
                y1: y1,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShamarlyLineTable, ShamarlyLineRow>(table),
                  BaseReferences<
                    _$ContentDatabase,
                    $ShamarlyLineTable,
                    ShamarlyLineRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShamarlyLineTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $ShamarlyLineTable,
      ShamarlyLineRow,
      $$ShamarlyLineTableFilterComposer,
      $$ShamarlyLineTableOrderingComposer,
      $$ShamarlyLineTableAnnotationComposer,
      $$ShamarlyLineTableCreateCompanionBuilder,
      $$ShamarlyLineTableUpdateCompanionBuilder,
      (
        ShamarlyLineRow,
        BaseReferences<_$ContentDatabase, $ShamarlyLineTable, ShamarlyLineRow>,
      ),
      ShamarlyLineRow,
      PrefetchHooks Function()
    >;
typedef $$ShamarlyLineOverflowTableCreateCompanionBuilder =
    ShamarlyLineOverflowCompanion Function({
      required int page,
      required int line,
      required int x0,
      required int y0,
      required int x1,
      required int y1,
      Value<int> rowid,
    });
typedef $$ShamarlyLineOverflowTableUpdateCompanionBuilder =
    ShamarlyLineOverflowCompanion Function({
      Value<int> page,
      Value<int> line,
      Value<int> x0,
      Value<int> y0,
      Value<int> x1,
      Value<int> y1,
      Value<int> rowid,
    });

class $$ShamarlyLineOverflowTableFilterComposer
    extends Composer<_$ContentDatabase, $ShamarlyLineOverflowTable> {
  $$ShamarlyLineOverflowTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x0 => $composableBuilder(
    column: $table.x0,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShamarlyLineOverflowTableOrderingComposer
    extends Composer<_$ContentDatabase, $ShamarlyLineOverflowTable> {
  $$ShamarlyLineOverflowTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x0 => $composableBuilder(
    column: $table.x0,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShamarlyLineOverflowTableAnnotationComposer
    extends Composer<_$ContentDatabase, $ShamarlyLineOverflowTable> {
  $$ShamarlyLineOverflowTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get line =>
      $composableBuilder(column: $table.line, builder: (column) => column);

  GeneratedColumn<int> get x0 =>
      $composableBuilder(column: $table.x0, builder: (column) => column);

  GeneratedColumn<int> get y0 =>
      $composableBuilder(column: $table.y0, builder: (column) => column);

  GeneratedColumn<int> get x1 =>
      $composableBuilder(column: $table.x1, builder: (column) => column);

  GeneratedColumn<int> get y1 =>
      $composableBuilder(column: $table.y1, builder: (column) => column);
}

class $$ShamarlyLineOverflowTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $ShamarlyLineOverflowTable,
          ShamarlyOverflowRow,
          $$ShamarlyLineOverflowTableFilterComposer,
          $$ShamarlyLineOverflowTableOrderingComposer,
          $$ShamarlyLineOverflowTableAnnotationComposer,
          $$ShamarlyLineOverflowTableCreateCompanionBuilder,
          $$ShamarlyLineOverflowTableUpdateCompanionBuilder,
          (
            ShamarlyOverflowRow,
            BaseReferences<
              _$ContentDatabase,
              $ShamarlyLineOverflowTable,
              ShamarlyOverflowRow
            >,
          ),
          ShamarlyOverflowRow,
          PrefetchHooks Function()
        > {
  $$ShamarlyLineOverflowTableTableManager(
    _$ContentDatabase db,
    $ShamarlyLineOverflowTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShamarlyLineOverflowTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShamarlyLineOverflowTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ShamarlyLineOverflowTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> page = const Value.absent(),
                Value<int> line = const Value.absent(),
                Value<int> x0 = const Value.absent(),
                Value<int> y0 = const Value.absent(),
                Value<int> x1 = const Value.absent(),
                Value<int> y1 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShamarlyLineOverflowCompanion(
                page: page,
                line: line,
                x0: x0,
                y0: y0,
                x1: x1,
                y1: y1,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int page,
                required int line,
                required int x0,
                required int y0,
                required int x1,
                required int y1,
                Value<int> rowid = const Value.absent(),
              }) => ShamarlyLineOverflowCompanion.insert(
                page: page,
                line: line,
                x0: x0,
                y0: y0,
                x1: x1,
                y1: y1,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShamarlyLineOverflowTable, ShamarlyOverflowRow>(
                    table,
                  ),
                  BaseReferences<
                    _$ContentDatabase,
                    $ShamarlyLineOverflowTable,
                    ShamarlyOverflowRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShamarlyLineOverflowTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $ShamarlyLineOverflowTable,
      ShamarlyOverflowRow,
      $$ShamarlyLineOverflowTableFilterComposer,
      $$ShamarlyLineOverflowTableOrderingComposer,
      $$ShamarlyLineOverflowTableAnnotationComposer,
      $$ShamarlyLineOverflowTableCreateCompanionBuilder,
      $$ShamarlyLineOverflowTableUpdateCompanionBuilder,
      (
        ShamarlyOverflowRow,
        BaseReferences<
          _$ContentDatabase,
          $ShamarlyLineOverflowTable,
          ShamarlyOverflowRow
        >,
      ),
      ShamarlyOverflowRow,
      PrefetchHooks Function()
    >;
typedef $$ShamarlyHeaderTableCreateCompanionBuilder =
    ShamarlyHeaderCompanion Function({
      Value<int> surah,
      required int page,
      Value<int?> firstLine,
      required int x0,
      required int y0,
      required int x1,
      required int y1,
    });
typedef $$ShamarlyHeaderTableUpdateCompanionBuilder =
    ShamarlyHeaderCompanion Function({
      Value<int> surah,
      Value<int> page,
      Value<int?> firstLine,
      Value<int> x0,
      Value<int> y0,
      Value<int> x1,
      Value<int> y1,
    });

class $$ShamarlyHeaderTableFilterComposer
    extends Composer<_$ContentDatabase, $ShamarlyHeaderTable> {
  $$ShamarlyHeaderTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstLine => $composableBuilder(
    column: $table.firstLine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x0 => $composableBuilder(
    column: $table.x0,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShamarlyHeaderTableOrderingComposer
    extends Composer<_$ContentDatabase, $ShamarlyHeaderTable> {
  $$ShamarlyHeaderTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstLine => $composableBuilder(
    column: $table.firstLine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x0 => $composableBuilder(
    column: $table.x0,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShamarlyHeaderTableAnnotationComposer
    extends Composer<_$ContentDatabase, $ShamarlyHeaderTable> {
  $$ShamarlyHeaderTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get firstLine =>
      $composableBuilder(column: $table.firstLine, builder: (column) => column);

  GeneratedColumn<int> get x0 =>
      $composableBuilder(column: $table.x0, builder: (column) => column);

  GeneratedColumn<int> get y0 =>
      $composableBuilder(column: $table.y0, builder: (column) => column);

  GeneratedColumn<int> get x1 =>
      $composableBuilder(column: $table.x1, builder: (column) => column);

  GeneratedColumn<int> get y1 =>
      $composableBuilder(column: $table.y1, builder: (column) => column);
}

class $$ShamarlyHeaderTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $ShamarlyHeaderTable,
          ShamarlyHeaderRow,
          $$ShamarlyHeaderTableFilterComposer,
          $$ShamarlyHeaderTableOrderingComposer,
          $$ShamarlyHeaderTableAnnotationComposer,
          $$ShamarlyHeaderTableCreateCompanionBuilder,
          $$ShamarlyHeaderTableUpdateCompanionBuilder,
          (
            ShamarlyHeaderRow,
            BaseReferences<
              _$ContentDatabase,
              $ShamarlyHeaderTable,
              ShamarlyHeaderRow
            >,
          ),
          ShamarlyHeaderRow,
          PrefetchHooks Function()
        > {
  $$ShamarlyHeaderTableTableManager(
    _$ContentDatabase db,
    $ShamarlyHeaderTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShamarlyHeaderTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShamarlyHeaderTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShamarlyHeaderTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> surah = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<int?> firstLine = const Value.absent(),
                Value<int> x0 = const Value.absent(),
                Value<int> y0 = const Value.absent(),
                Value<int> x1 = const Value.absent(),
                Value<int> y1 = const Value.absent(),
              }) => ShamarlyHeaderCompanion(
                surah: surah,
                page: page,
                firstLine: firstLine,
                x0: x0,
                y0: y0,
                x1: x1,
                y1: y1,
              ),
          createCompanionCallback:
              ({
                Value<int> surah = const Value.absent(),
                required int page,
                Value<int?> firstLine = const Value.absent(),
                required int x0,
                required int y0,
                required int x1,
                required int y1,
              }) => ShamarlyHeaderCompanion.insert(
                surah: surah,
                page: page,
                firstLine: firstLine,
                x0: x0,
                y0: y0,
                x1: x1,
                y1: y1,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShamarlyHeaderTable, ShamarlyHeaderRow>(table),
                  BaseReferences<
                    _$ContentDatabase,
                    $ShamarlyHeaderTable,
                    ShamarlyHeaderRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShamarlyHeaderTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $ShamarlyHeaderTable,
      ShamarlyHeaderRow,
      $$ShamarlyHeaderTableFilterComposer,
      $$ShamarlyHeaderTableOrderingComposer,
      $$ShamarlyHeaderTableAnnotationComposer,
      $$ShamarlyHeaderTableCreateCompanionBuilder,
      $$ShamarlyHeaderTableUpdateCompanionBuilder,
      (
        ShamarlyHeaderRow,
        BaseReferences<
          _$ContentDatabase,
          $ShamarlyHeaderTable,
          ShamarlyHeaderRow
        >,
      ),
      ShamarlyHeaderRow,
      PrefetchHooks Function()
    >;
typedef $$ShamarlyMarkerTableCreateCompanionBuilder =
    ShamarlyMarkerCompanion Function({
      required int surah,
      required int ayah,
      required int page,
      required int line,
      required int x0,
      required int y0,
      required int x1,
      required int y1,
    });
typedef $$ShamarlyMarkerTableUpdateCompanionBuilder =
    ShamarlyMarkerCompanion Function({
      Value<int> surah,
      Value<int> ayah,
      Value<int> page,
      Value<int> line,
      Value<int> x0,
      Value<int> y0,
      Value<int> x1,
      Value<int> y1,
    });

class $$ShamarlyMarkerTableFilterComposer
    extends Composer<_$ContentDatabase, $ShamarlyMarkerTable> {
  $$ShamarlyMarkerTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x0 => $composableBuilder(
    column: $table.x0,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShamarlyMarkerTableOrderingComposer
    extends Composer<_$ContentDatabase, $ShamarlyMarkerTable> {
  $$ShamarlyMarkerTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x0 => $composableBuilder(
    column: $table.x0,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShamarlyMarkerTableAnnotationComposer
    extends Composer<_$ContentDatabase, $ShamarlyMarkerTable> {
  $$ShamarlyMarkerTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get line =>
      $composableBuilder(column: $table.line, builder: (column) => column);

  GeneratedColumn<int> get x0 =>
      $composableBuilder(column: $table.x0, builder: (column) => column);

  GeneratedColumn<int> get y0 =>
      $composableBuilder(column: $table.y0, builder: (column) => column);

  GeneratedColumn<int> get x1 =>
      $composableBuilder(column: $table.x1, builder: (column) => column);

  GeneratedColumn<int> get y1 =>
      $composableBuilder(column: $table.y1, builder: (column) => column);
}

class $$ShamarlyMarkerTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $ShamarlyMarkerTable,
          ShamarlyMarkerRow,
          $$ShamarlyMarkerTableFilterComposer,
          $$ShamarlyMarkerTableOrderingComposer,
          $$ShamarlyMarkerTableAnnotationComposer,
          $$ShamarlyMarkerTableCreateCompanionBuilder,
          $$ShamarlyMarkerTableUpdateCompanionBuilder,
          (
            ShamarlyMarkerRow,
            BaseReferences<
              _$ContentDatabase,
              $ShamarlyMarkerTable,
              ShamarlyMarkerRow
            >,
          ),
          ShamarlyMarkerRow,
          PrefetchHooks Function()
        > {
  $$ShamarlyMarkerTableTableManager(
    _$ContentDatabase db,
    $ShamarlyMarkerTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShamarlyMarkerTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShamarlyMarkerTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShamarlyMarkerTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<int> line = const Value.absent(),
                Value<int> x0 = const Value.absent(),
                Value<int> y0 = const Value.absent(),
                Value<int> x1 = const Value.absent(),
                Value<int> y1 = const Value.absent(),
              }) => ShamarlyMarkerCompanion(
                surah: surah,
                ayah: ayah,
                page: page,
                line: line,
                x0: x0,
                y0: y0,
                x1: x1,
                y1: y1,
              ),
          createCompanionCallback:
              ({
                required int surah,
                required int ayah,
                required int page,
                required int line,
                required int x0,
                required int y0,
                required int x1,
                required int y1,
              }) => ShamarlyMarkerCompanion.insert(
                surah: surah,
                ayah: ayah,
                page: page,
                line: line,
                x0: x0,
                y0: y0,
                x1: x1,
                y1: y1,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShamarlyMarkerTable, ShamarlyMarkerRow>(table),
                  BaseReferences<
                    _$ContentDatabase,
                    $ShamarlyMarkerTable,
                    ShamarlyMarkerRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShamarlyMarkerTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $ShamarlyMarkerTable,
      ShamarlyMarkerRow,
      $$ShamarlyMarkerTableFilterComposer,
      $$ShamarlyMarkerTableOrderingComposer,
      $$ShamarlyMarkerTableAnnotationComposer,
      $$ShamarlyMarkerTableCreateCompanionBuilder,
      $$ShamarlyMarkerTableUpdateCompanionBuilder,
      (
        ShamarlyMarkerRow,
        BaseReferences<
          _$ContentDatabase,
          $ShamarlyMarkerTable,
          ShamarlyMarkerRow
        >,
      ),
      ShamarlyMarkerRow,
      PrefetchHooks Function()
    >;
typedef $$ShamarlyVerseBoxTableCreateCompanionBuilder =
    ShamarlyVerseBoxCompanion Function({
      required int surah,
      required int ayah,
      required int part,
      required int page,
      required int line,
      required int x0,
      required int y0,
      required int x1,
      required int y1,
    });
typedef $$ShamarlyVerseBoxTableUpdateCompanionBuilder =
    ShamarlyVerseBoxCompanion Function({
      Value<int> surah,
      Value<int> ayah,
      Value<int> part,
      Value<int> page,
      Value<int> line,
      Value<int> x0,
      Value<int> y0,
      Value<int> x1,
      Value<int> y1,
    });

class $$ShamarlyVerseBoxTableFilterComposer
    extends Composer<_$ContentDatabase, $ShamarlyVerseBoxTable> {
  $$ShamarlyVerseBoxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get part => $composableBuilder(
    column: $table.part,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x0 => $composableBuilder(
    column: $table.x0,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShamarlyVerseBoxTableOrderingComposer
    extends Composer<_$ContentDatabase, $ShamarlyVerseBoxTable> {
  $$ShamarlyVerseBoxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get part => $composableBuilder(
    column: $table.part,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x0 => $composableBuilder(
    column: $table.x0,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShamarlyVerseBoxTableAnnotationComposer
    extends Composer<_$ContentDatabase, $ShamarlyVerseBoxTable> {
  $$ShamarlyVerseBoxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<int> get part =>
      $composableBuilder(column: $table.part, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get line =>
      $composableBuilder(column: $table.line, builder: (column) => column);

  GeneratedColumn<int> get x0 =>
      $composableBuilder(column: $table.x0, builder: (column) => column);

  GeneratedColumn<int> get y0 =>
      $composableBuilder(column: $table.y0, builder: (column) => column);

  GeneratedColumn<int> get x1 =>
      $composableBuilder(column: $table.x1, builder: (column) => column);

  GeneratedColumn<int> get y1 =>
      $composableBuilder(column: $table.y1, builder: (column) => column);
}

class $$ShamarlyVerseBoxTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $ShamarlyVerseBoxTable,
          ShamarlyVerseBoxRow,
          $$ShamarlyVerseBoxTableFilterComposer,
          $$ShamarlyVerseBoxTableOrderingComposer,
          $$ShamarlyVerseBoxTableAnnotationComposer,
          $$ShamarlyVerseBoxTableCreateCompanionBuilder,
          $$ShamarlyVerseBoxTableUpdateCompanionBuilder,
          (
            ShamarlyVerseBoxRow,
            BaseReferences<
              _$ContentDatabase,
              $ShamarlyVerseBoxTable,
              ShamarlyVerseBoxRow
            >,
          ),
          ShamarlyVerseBoxRow,
          PrefetchHooks Function()
        > {
  $$ShamarlyVerseBoxTableTableManager(
    _$ContentDatabase db,
    $ShamarlyVerseBoxTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShamarlyVerseBoxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShamarlyVerseBoxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShamarlyVerseBoxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<int> part = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<int> line = const Value.absent(),
                Value<int> x0 = const Value.absent(),
                Value<int> y0 = const Value.absent(),
                Value<int> x1 = const Value.absent(),
                Value<int> y1 = const Value.absent(),
              }) => ShamarlyVerseBoxCompanion(
                surah: surah,
                ayah: ayah,
                part: part,
                page: page,
                line: line,
                x0: x0,
                y0: y0,
                x1: x1,
                y1: y1,
              ),
          createCompanionCallback:
              ({
                required int surah,
                required int ayah,
                required int part,
                required int page,
                required int line,
                required int x0,
                required int y0,
                required int x1,
                required int y1,
              }) => ShamarlyVerseBoxCompanion.insert(
                surah: surah,
                ayah: ayah,
                part: part,
                page: page,
                line: line,
                x0: x0,
                y0: y0,
                x1: x1,
                y1: y1,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShamarlyVerseBoxTable, ShamarlyVerseBoxRow>(
                    table,
                  ),
                  BaseReferences<
                    _$ContentDatabase,
                    $ShamarlyVerseBoxTable,
                    ShamarlyVerseBoxRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShamarlyVerseBoxTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $ShamarlyVerseBoxTable,
      ShamarlyVerseBoxRow,
      $$ShamarlyVerseBoxTableFilterComposer,
      $$ShamarlyVerseBoxTableOrderingComposer,
      $$ShamarlyVerseBoxTableAnnotationComposer,
      $$ShamarlyVerseBoxTableCreateCompanionBuilder,
      $$ShamarlyVerseBoxTableUpdateCompanionBuilder,
      (
        ShamarlyVerseBoxRow,
        BaseReferences<
          _$ContentDatabase,
          $ShamarlyVerseBoxTable,
          ShamarlyVerseBoxRow
        >,
      ),
      ShamarlyVerseBoxRow,
      PrefetchHooks Function()
    >;
typedef $$ShamarlyWordBoxTableCreateCompanionBuilder =
    ShamarlyWordBoxCompanion Function({
      required int surah,
      required int ayah,
      required int word,
      required int page,
      required int line,
      required int x0,
      required int y0,
      required int x1,
      required int y1,
      required int level,
    });
typedef $$ShamarlyWordBoxTableUpdateCompanionBuilder =
    ShamarlyWordBoxCompanion Function({
      Value<int> surah,
      Value<int> ayah,
      Value<int> word,
      Value<int> page,
      Value<int> line,
      Value<int> x0,
      Value<int> y0,
      Value<int> x1,
      Value<int> y1,
      Value<int> level,
    });

class $$ShamarlyWordBoxTableFilterComposer
    extends Composer<_$ContentDatabase, $ShamarlyWordBoxTable> {
  $$ShamarlyWordBoxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x0 => $composableBuilder(
    column: $table.x0,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShamarlyWordBoxTableOrderingComposer
    extends Composer<_$ContentDatabase, $ShamarlyWordBoxTable> {
  $$ShamarlyWordBoxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x0 => $composableBuilder(
    column: $table.x0,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShamarlyWordBoxTableAnnotationComposer
    extends Composer<_$ContentDatabase, $ShamarlyWordBoxTable> {
  $$ShamarlyWordBoxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<int> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get line =>
      $composableBuilder(column: $table.line, builder: (column) => column);

  GeneratedColumn<int> get x0 =>
      $composableBuilder(column: $table.x0, builder: (column) => column);

  GeneratedColumn<int> get y0 =>
      $composableBuilder(column: $table.y0, builder: (column) => column);

  GeneratedColumn<int> get x1 =>
      $composableBuilder(column: $table.x1, builder: (column) => column);

  GeneratedColumn<int> get y1 =>
      $composableBuilder(column: $table.y1, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);
}

class $$ShamarlyWordBoxTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $ShamarlyWordBoxTable,
          ShamarlyWordBoxRow,
          $$ShamarlyWordBoxTableFilterComposer,
          $$ShamarlyWordBoxTableOrderingComposer,
          $$ShamarlyWordBoxTableAnnotationComposer,
          $$ShamarlyWordBoxTableCreateCompanionBuilder,
          $$ShamarlyWordBoxTableUpdateCompanionBuilder,
          (
            ShamarlyWordBoxRow,
            BaseReferences<
              _$ContentDatabase,
              $ShamarlyWordBoxTable,
              ShamarlyWordBoxRow
            >,
          ),
          ShamarlyWordBoxRow,
          PrefetchHooks Function()
        > {
  $$ShamarlyWordBoxTableTableManager(
    _$ContentDatabase db,
    $ShamarlyWordBoxTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShamarlyWordBoxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShamarlyWordBoxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShamarlyWordBoxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<int> word = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<int> line = const Value.absent(),
                Value<int> x0 = const Value.absent(),
                Value<int> y0 = const Value.absent(),
                Value<int> x1 = const Value.absent(),
                Value<int> y1 = const Value.absent(),
                Value<int> level = const Value.absent(),
              }) => ShamarlyWordBoxCompanion(
                surah: surah,
                ayah: ayah,
                word: word,
                page: page,
                line: line,
                x0: x0,
                y0: y0,
                x1: x1,
                y1: y1,
                level: level,
              ),
          createCompanionCallback:
              ({
                required int surah,
                required int ayah,
                required int word,
                required int page,
                required int line,
                required int x0,
                required int y0,
                required int x1,
                required int y1,
                required int level,
              }) => ShamarlyWordBoxCompanion.insert(
                surah: surah,
                ayah: ayah,
                word: word,
                page: page,
                line: line,
                x0: x0,
                y0: y0,
                x1: x1,
                y1: y1,
                level: level,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShamarlyWordBoxTable, ShamarlyWordBoxRow>(table),
                  BaseReferences<
                    _$ContentDatabase,
                    $ShamarlyWordBoxTable,
                    ShamarlyWordBoxRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShamarlyWordBoxTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $ShamarlyWordBoxTable,
      ShamarlyWordBoxRow,
      $$ShamarlyWordBoxTableFilterComposer,
      $$ShamarlyWordBoxTableOrderingComposer,
      $$ShamarlyWordBoxTableAnnotationComposer,
      $$ShamarlyWordBoxTableCreateCompanionBuilder,
      $$ShamarlyWordBoxTableUpdateCompanionBuilder,
      (
        ShamarlyWordBoxRow,
        BaseReferences<
          _$ContentDatabase,
          $ShamarlyWordBoxTable,
          ShamarlyWordBoxRow
        >,
      ),
      ShamarlyWordBoxRow,
      PrefetchHooks Function()
    >;
typedef $$ShamarlyCatchwordTableCreateCompanionBuilder =
    ShamarlyCatchwordCompanion Function({
      Value<int> page,
      required int x0,
      required int y0,
      required int x1,
      required int y1,
      required int words,
      required String erase,
    });
typedef $$ShamarlyCatchwordTableUpdateCompanionBuilder =
    ShamarlyCatchwordCompanion Function({
      Value<int> page,
      Value<int> x0,
      Value<int> y0,
      Value<int> x1,
      Value<int> y1,
      Value<int> words,
      Value<String> erase,
    });

class $$ShamarlyCatchwordTableFilterComposer
    extends Composer<_$ContentDatabase, $ShamarlyCatchwordTable> {
  $$ShamarlyCatchwordTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x0 => $composableBuilder(
    column: $table.x0,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get words => $composableBuilder(
    column: $table.words,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get erase => $composableBuilder(
    column: $table.erase,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShamarlyCatchwordTableOrderingComposer
    extends Composer<_$ContentDatabase, $ShamarlyCatchwordTable> {
  $$ShamarlyCatchwordTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x0 => $composableBuilder(
    column: $table.x0,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y0 => $composableBuilder(
    column: $table.y0,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get words => $composableBuilder(
    column: $table.words,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get erase => $composableBuilder(
    column: $table.erase,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShamarlyCatchwordTableAnnotationComposer
    extends Composer<_$ContentDatabase, $ShamarlyCatchwordTable> {
  $$ShamarlyCatchwordTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get x0 =>
      $composableBuilder(column: $table.x0, builder: (column) => column);

  GeneratedColumn<int> get y0 =>
      $composableBuilder(column: $table.y0, builder: (column) => column);

  GeneratedColumn<int> get x1 =>
      $composableBuilder(column: $table.x1, builder: (column) => column);

  GeneratedColumn<int> get y1 =>
      $composableBuilder(column: $table.y1, builder: (column) => column);

  GeneratedColumn<int> get words =>
      $composableBuilder(column: $table.words, builder: (column) => column);

  GeneratedColumn<String> get erase =>
      $composableBuilder(column: $table.erase, builder: (column) => column);
}

class $$ShamarlyCatchwordTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $ShamarlyCatchwordTable,
          ShamarlyCatchwordRow,
          $$ShamarlyCatchwordTableFilterComposer,
          $$ShamarlyCatchwordTableOrderingComposer,
          $$ShamarlyCatchwordTableAnnotationComposer,
          $$ShamarlyCatchwordTableCreateCompanionBuilder,
          $$ShamarlyCatchwordTableUpdateCompanionBuilder,
          (
            ShamarlyCatchwordRow,
            BaseReferences<
              _$ContentDatabase,
              $ShamarlyCatchwordTable,
              ShamarlyCatchwordRow
            >,
          ),
          ShamarlyCatchwordRow,
          PrefetchHooks Function()
        > {
  $$ShamarlyCatchwordTableTableManager(
    _$ContentDatabase db,
    $ShamarlyCatchwordTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShamarlyCatchwordTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShamarlyCatchwordTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShamarlyCatchwordTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> page = const Value.absent(),
                Value<int> x0 = const Value.absent(),
                Value<int> y0 = const Value.absent(),
                Value<int> x1 = const Value.absent(),
                Value<int> y1 = const Value.absent(),
                Value<int> words = const Value.absent(),
                Value<String> erase = const Value.absent(),
              }) => ShamarlyCatchwordCompanion(
                page: page,
                x0: x0,
                y0: y0,
                x1: x1,
                y1: y1,
                words: words,
                erase: erase,
              ),
          createCompanionCallback:
              ({
                Value<int> page = const Value.absent(),
                required int x0,
                required int y0,
                required int x1,
                required int y1,
                required int words,
                required String erase,
              }) => ShamarlyCatchwordCompanion.insert(
                page: page,
                x0: x0,
                y0: y0,
                x1: x1,
                y1: y1,
                words: words,
                erase: erase,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShamarlyCatchwordTable, ShamarlyCatchwordRow>(
                    table,
                  ),
                  BaseReferences<
                    _$ContentDatabase,
                    $ShamarlyCatchwordTable,
                    ShamarlyCatchwordRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShamarlyCatchwordTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $ShamarlyCatchwordTable,
      ShamarlyCatchwordRow,
      $$ShamarlyCatchwordTableFilterComposer,
      $$ShamarlyCatchwordTableOrderingComposer,
      $$ShamarlyCatchwordTableAnnotationComposer,
      $$ShamarlyCatchwordTableCreateCompanionBuilder,
      $$ShamarlyCatchwordTableUpdateCompanionBuilder,
      (
        ShamarlyCatchwordRow,
        BaseReferences<
          _$ContentDatabase,
          $ShamarlyCatchwordTable,
          ShamarlyCatchwordRow
        >,
      ),
      ShamarlyCatchwordRow,
      PrefetchHooks Function()
    >;
typedef $$WordRootTableCreateCompanionBuilder = WordRootCompanion Function({
  required int surah,
  required int ayah,
  required int word,
  Value<String?> root,
  Value<String?> lemma,
  required String pos,
});
typedef $$WordRootTableUpdateCompanionBuilder = WordRootCompanion Function({
  Value<int> surah,
  Value<int> ayah,
  Value<int> word,
  Value<String?> root,
  Value<String?> lemma,
  Value<String> pos,
});

class $$WordRootTableFilterComposer
    extends Composer<_$ContentDatabase, $WordRootTable> {
  $$WordRootTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get root => $composableBuilder(
    column: $table.root,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pos => $composableBuilder(
    column: $table.pos,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordRootTableOrderingComposer
    extends Composer<_$ContentDatabase, $WordRootTable> {
  $$WordRootTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get root => $composableBuilder(
    column: $table.root,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pos => $composableBuilder(
    column: $table.pos,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordRootTableAnnotationComposer
    extends Composer<_$ContentDatabase, $WordRootTable> {
  $$WordRootTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<int> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get root =>
      $composableBuilder(column: $table.root, builder: (column) => column);

  GeneratedColumn<String> get lemma =>
      $composableBuilder(column: $table.lemma, builder: (column) => column);

  GeneratedColumn<String> get pos =>
      $composableBuilder(column: $table.pos, builder: (column) => column);
}

class $$WordRootTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $WordRootTable,
          WordRootRow,
          $$WordRootTableFilterComposer,
          $$WordRootTableOrderingComposer,
          $$WordRootTableAnnotationComposer,
          $$WordRootTableCreateCompanionBuilder,
          $$WordRootTableUpdateCompanionBuilder,
          (
            WordRootRow,
            BaseReferences<_$ContentDatabase, $WordRootTable, WordRootRow>,
          ),
          WordRootRow,
          PrefetchHooks Function()
        > {
  $$WordRootTableTableManager(_$ContentDatabase db, $WordRootTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordRootTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordRootTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordRootTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<int> word = const Value.absent(),
                Value<String?> root = const Value.absent(),
                Value<String?> lemma = const Value.absent(),
                Value<String> pos = const Value.absent(),
              }) => WordRootCompanion(
                surah: surah,
                ayah: ayah,
                word: word,
                root: root,
                lemma: lemma,
                pos: pos,
              ),
          createCompanionCallback:
              ({
                required int surah,
                required int ayah,
                required int word,
                Value<String?> root = const Value.absent(),
                Value<String?> lemma = const Value.absent(),
                required String pos,
              }) => WordRootCompanion.insert(
                surah: surah,
                ayah: ayah,
                word: word,
                root: root,
                lemma: lemma,
                pos: pos,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WordRootTable, WordRootRow>(table),
                  BaseReferences<
                    _$ContentDatabase,
                    $WordRootTable,
                    WordRootRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordRootTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $WordRootTable,
      WordRootRow,
      $$WordRootTableFilterComposer,
      $$WordRootTableOrderingComposer,
      $$WordRootTableAnnotationComposer,
      $$WordRootTableCreateCompanionBuilder,
      $$WordRootTableUpdateCompanionBuilder,
      (
        WordRootRow,
        BaseReferences<_$ContentDatabase, $WordRootTable, WordRootRow>,
      ),
      WordRootRow,
      PrefetchHooks Function()
    >;
typedef $$GharibTableCreateCompanionBuilder = GharibCompanion Function({
  required int surah,
  required int ayah,
  required int ord,
  Value<int?> wordFrom,
  Value<int?> wordTo,
  required String phrase,
  required String body,
});
typedef $$GharibTableUpdateCompanionBuilder = GharibCompanion Function({
  Value<int> surah,
  Value<int> ayah,
  Value<int> ord,
  Value<int?> wordFrom,
  Value<int?> wordTo,
  Value<String> phrase,
  Value<String> body,
});

class $$GharibTableFilterComposer
    extends Composer<_$ContentDatabase, $GharibTable> {
  $$GharibTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ord => $composableBuilder(
    column: $table.ord,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordFrom => $composableBuilder(
    column: $table.wordFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordTo => $composableBuilder(
    column: $table.wordTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phrase => $composableBuilder(
    column: $table.phrase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GharibTableOrderingComposer
    extends Composer<_$ContentDatabase, $GharibTable> {
  $$GharibTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ord => $composableBuilder(
    column: $table.ord,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordFrom => $composableBuilder(
    column: $table.wordFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordTo => $composableBuilder(
    column: $table.wordTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phrase => $composableBuilder(
    column: $table.phrase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GharibTableAnnotationComposer
    extends Composer<_$ContentDatabase, $GharibTable> {
  $$GharibTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<int> get ord =>
      $composableBuilder(column: $table.ord, builder: (column) => column);

  GeneratedColumn<int> get wordFrom =>
      $composableBuilder(column: $table.wordFrom, builder: (column) => column);

  GeneratedColumn<int> get wordTo =>
      $composableBuilder(column: $table.wordTo, builder: (column) => column);

  GeneratedColumn<String> get phrase =>
      $composableBuilder(column: $table.phrase, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);
}

class $$GharibTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $GharibTable,
          GharibRow,
          $$GharibTableFilterComposer,
          $$GharibTableOrderingComposer,
          $$GharibTableAnnotationComposer,
          $$GharibTableCreateCompanionBuilder,
          $$GharibTableUpdateCompanionBuilder,
          (
            GharibRow,
            BaseReferences<_$ContentDatabase, $GharibTable, GharibRow>,
          ),
          GharibRow,
          PrefetchHooks Function()
        > {
  $$GharibTableTableManager(_$ContentDatabase db, $GharibTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GharibTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GharibTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GharibTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<int> ord = const Value.absent(),
                Value<int?> wordFrom = const Value.absent(),
                Value<int?> wordTo = const Value.absent(),
                Value<String> phrase = const Value.absent(),
                Value<String> body = const Value.absent(),
              }) => GharibCompanion(
                surah: surah,
                ayah: ayah,
                ord: ord,
                wordFrom: wordFrom,
                wordTo: wordTo,
                phrase: phrase,
                body: body,
              ),
          createCompanionCallback:
              ({
                required int surah,
                required int ayah,
                required int ord,
                Value<int?> wordFrom = const Value.absent(),
                Value<int?> wordTo = const Value.absent(),
                required String phrase,
                required String body,
              }) => GharibCompanion.insert(
                surah: surah,
                ayah: ayah,
                ord: ord,
                wordFrom: wordFrom,
                wordTo: wordTo,
                phrase: phrase,
                body: body,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GharibTable, GharibRow>(table),
                  BaseReferences<_$ContentDatabase, $GharibTable, GharibRow>(
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

typedef $$GharibTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $GharibTable,
      GharibRow,
      $$GharibTableFilterComposer,
      $$GharibTableOrderingComposer,
      $$GharibTableAnnotationComposer,
      $$GharibTableCreateCompanionBuilder,
      $$GharibTableUpdateCompanionBuilder,
      (GharibRow, BaseReferences<_$ContentDatabase, $GharibTable, GharibRow>),
      GharibRow,
      PrefetchHooks Function()
    >;
typedef $$MutashabihTableCreateCompanionBuilder = MutashabihCompanion Function({
  Value<int> id,
  required int srcFrom,
  required int srcTo,
  required int mutFrom,
  required int mutTo,
  required int context,
  required int sourceId,
});
typedef $$MutashabihTableUpdateCompanionBuilder = MutashabihCompanion Function({
  Value<int> id,
  Value<int> srcFrom,
  Value<int> srcTo,
  Value<int> mutFrom,
  Value<int> mutTo,
  Value<int> context,
  Value<int> sourceId,
});

class $$MutashabihTableFilterComposer
    extends Composer<_$ContentDatabase, $MutashabihTable> {
  $$MutashabihTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get srcFrom => $composableBuilder(
    column: $table.srcFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get srcTo => $composableBuilder(
    column: $table.srcTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mutFrom => $composableBuilder(
    column: $table.mutFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mutTo => $composableBuilder(
    column: $table.mutTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MutashabihTableOrderingComposer
    extends Composer<_$ContentDatabase, $MutashabihTable> {
  $$MutashabihTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get srcFrom => $composableBuilder(
    column: $table.srcFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get srcTo => $composableBuilder(
    column: $table.srcTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mutFrom => $composableBuilder(
    column: $table.mutFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mutTo => $composableBuilder(
    column: $table.mutTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MutashabihTableAnnotationComposer
    extends Composer<_$ContentDatabase, $MutashabihTable> {
  $$MutashabihTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get srcFrom =>
      $composableBuilder(column: $table.srcFrom, builder: (column) => column);

  GeneratedColumn<int> get srcTo =>
      $composableBuilder(column: $table.srcTo, builder: (column) => column);

  GeneratedColumn<int> get mutFrom =>
      $composableBuilder(column: $table.mutFrom, builder: (column) => column);

  GeneratedColumn<int> get mutTo =>
      $composableBuilder(column: $table.mutTo, builder: (column) => column);

  GeneratedColumn<int> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);

  GeneratedColumn<int> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);
}

class $$MutashabihTableTableManager
    extends
        RootTableManager<
          _$ContentDatabase,
          $MutashabihTable,
          MutashabihRow,
          $$MutashabihTableFilterComposer,
          $$MutashabihTableOrderingComposer,
          $$MutashabihTableAnnotationComposer,
          $$MutashabihTableCreateCompanionBuilder,
          $$MutashabihTableUpdateCompanionBuilder,
          (
            MutashabihRow,
            BaseReferences<_$ContentDatabase, $MutashabihTable, MutashabihRow>,
          ),
          MutashabihRow,
          PrefetchHooks Function()
        > {
  $$MutashabihTableTableManager(_$ContentDatabase db, $MutashabihTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MutashabihTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MutashabihTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MutashabihTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> srcFrom = const Value.absent(),
                Value<int> srcTo = const Value.absent(),
                Value<int> mutFrom = const Value.absent(),
                Value<int> mutTo = const Value.absent(),
                Value<int> context = const Value.absent(),
                Value<int> sourceId = const Value.absent(),
              }) => MutashabihCompanion(
                id: id,
                srcFrom: srcFrom,
                srcTo: srcTo,
                mutFrom: mutFrom,
                mutTo: mutTo,
                context: context,
                sourceId: sourceId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int srcFrom,
                required int srcTo,
                required int mutFrom,
                required int mutTo,
                required int context,
                required int sourceId,
              }) => MutashabihCompanion.insert(
                id: id,
                srcFrom: srcFrom,
                srcTo: srcTo,
                mutFrom: mutFrom,
                mutTo: mutTo,
                context: context,
                sourceId: sourceId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MutashabihTable, MutashabihRow>(table),
                  BaseReferences<
                    _$ContentDatabase,
                    $MutashabihTable,
                    MutashabihRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MutashabihTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDatabase,
      $MutashabihTable,
      MutashabihRow,
      $$MutashabihTableFilterComposer,
      $$MutashabihTableOrderingComposer,
      $$MutashabihTableAnnotationComposer,
      $$MutashabihTableCreateCompanionBuilder,
      $$MutashabihTableUpdateCompanionBuilder,
      (
        MutashabihRow,
        BaseReferences<_$ContentDatabase, $MutashabihTable, MutashabihRow>,
      ),
      MutashabihRow,
      PrefetchHooks Function()
    >;

class $ContentDatabaseManager {
  final _$ContentDatabase _db;
  $ContentDatabaseManager(this._db);
  $$SurahTableTableManager get surah =>
      $$SurahTableTableManager(_db, _db.surah);
  $$AyahTableTableManager get ayah => $$AyahTableTableManager(_db, _db.ayah);
  $$AyahPolygonTableTableManager get ayahPolygon =>
      $$AyahPolygonTableTableManager(_db, _db.ayahPolygon);
  $$SourceTableTableManager get source =>
      $$SourceTableTableManager(_db, _db.source);
  $$WordBoxTableTableManager get wordBox =>
      $$WordBoxTableTableManager(_db, _db.wordBox);
  $$LineCutTableTableManager get lineCut =>
      $$LineCutTableTableManager(_db, _db.lineCut);
  $$LineOverflowTableTableManager get lineOverflow =>
      $$LineOverflowTableTableManager(_db, _db.lineOverflow);
  $$LineOverflow1405TableTableManager get lineOverflow1405 =>
      $$LineOverflow1405TableTableManager(_db, _db.lineOverflow1405);
  $$CommentaryEditionTableTableManager get commentaryEdition =>
      $$CommentaryEditionTableTableManager(_db, _db.commentaryEdition);
  $$CommentaryTableTableManager get commentary =>
      $$CommentaryTableTableManager(_db, _db.commentary);
  $$ReciterTableTableManager get reciter =>
      $$ReciterTableTableManager(_db, _db.reciter);
  $$AyahTimingTableTableManager get ayahTiming =>
      $$AyahTimingTableTableManager(_db, _db.ayahTiming);
  $$WordTimingTableTableManager get wordTiming =>
      $$WordTimingTableTableManager(_db, _db.wordTiming);
  $$AyahSpeechTableTableManager get ayahSpeech =>
      $$AyahSpeechTableTableManager(_db, _db.ayahSpeech);
  $$ShamarlyPageTableTableManager get shamarlyPage =>
      $$ShamarlyPageTableTableManager(_db, _db.shamarlyPage);
  $$ShamarlyLineTableTableManager get shamarlyLine =>
      $$ShamarlyLineTableTableManager(_db, _db.shamarlyLine);
  $$ShamarlyLineOverflowTableTableManager get shamarlyLineOverflow =>
      $$ShamarlyLineOverflowTableTableManager(_db, _db.shamarlyLineOverflow);
  $$ShamarlyHeaderTableTableManager get shamarlyHeader =>
      $$ShamarlyHeaderTableTableManager(_db, _db.shamarlyHeader);
  $$ShamarlyMarkerTableTableManager get shamarlyMarker =>
      $$ShamarlyMarkerTableTableManager(_db, _db.shamarlyMarker);
  $$ShamarlyVerseBoxTableTableManager get shamarlyVerseBox =>
      $$ShamarlyVerseBoxTableTableManager(_db, _db.shamarlyVerseBox);
  $$ShamarlyWordBoxTableTableManager get shamarlyWordBox =>
      $$ShamarlyWordBoxTableTableManager(_db, _db.shamarlyWordBox);
  $$ShamarlyCatchwordTableTableManager get shamarlyCatchword =>
      $$ShamarlyCatchwordTableTableManager(_db, _db.shamarlyCatchword);
  $$WordRootTableTableManager get wordRoot =>
      $$WordRootTableTableManager(_db, _db.wordRoot);
  $$GharibTableTableManager get gharib =>
      $$GharibTableTableManager(_db, _db.gharib);
  $$MutashabihTableTableManager get mutashabih =>
      $$MutashabihTableTableManager(_db, _db.mutashabih);
}
