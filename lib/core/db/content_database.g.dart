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
    meaningEn,
    revelation,
    revelationOrder,
    ayahCount,
    startPage,
    sourceId,
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
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
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
  final int startPage;
  final int sourceId;
  const SurahRow({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.meaningEn,
    required this.revelation,
    required this.revelationOrder,
    required this.ayahCount,
    required this.startPage,
    required this.sourceId,
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
    map['source_id'] = Variable<int>(sourceId);
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
      sourceId: Value(sourceId),
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
      'meaningEn': serializer.toJson<String>(meaningEn),
      'revelation': serializer.toJson<String>(revelation),
      'revelationOrder': serializer.toJson<int>(revelationOrder),
      'ayahCount': serializer.toJson<int>(ayahCount),
      'startPage': serializer.toJson<int>(startPage),
      'sourceId': serializer.toJson<int>(sourceId),
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
    int? sourceId,
  }) => SurahRow(
    id: id ?? this.id,
    nameAr: nameAr ?? this.nameAr,
    nameEn: nameEn ?? this.nameEn,
    meaningEn: meaningEn ?? this.meaningEn,
    revelation: revelation ?? this.revelation,
    revelationOrder: revelationOrder ?? this.revelationOrder,
    ayahCount: ayahCount ?? this.ayahCount,
    startPage: startPage ?? this.startPage,
    sourceId: sourceId ?? this.sourceId,
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
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
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
          ..write('sourceId: $sourceId')
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
    sourceId,
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
          other.sourceId == this.sourceId);
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
  final Value<int> sourceId;
  const SurahCompanion({
    this.id = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.meaningEn = const Value.absent(),
    this.revelation = const Value.absent(),
    this.revelationOrder = const Value.absent(),
    this.ayahCount = const Value.absent(),
    this.startPage = const Value.absent(),
    this.sourceId = const Value.absent(),
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
    required int sourceId,
  }) : nameAr = Value(nameAr),
       nameEn = Value(nameEn),
       meaningEn = Value(meaningEn),
       revelation = Value(revelation),
       revelationOrder = Value(revelationOrder),
       ayahCount = Value(ayahCount),
       startPage = Value(startPage),
       sourceId = Value(sourceId);
  static Insertable<SurahRow> custom({
    Expression<int>? id,
    Expression<String>? nameAr,
    Expression<String>? nameEn,
    Expression<String>? meaningEn,
    Expression<String>? revelation,
    Expression<int>? revelationOrder,
    Expression<int>? ayahCount,
    Expression<int>? startPage,
    Expression<int>? sourceId,
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
      if (sourceId != null) 'source_id': sourceId,
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
    Value<int>? sourceId,
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
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
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
          ..write('sourceId: $sourceId')
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    surah,
    number,
    verseText,
    basmalaPrefix,
    textSearch,
    searchBasmalaPrefix,
    juz,
    hizbQuarter,
    manzil,
    page,
    sajda,
    textSourceId,
    pageSourceId,
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
      sajda: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sajda'],
      ),
      textSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}text_source_id'],
      )!,
      pageSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_source_id'],
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

  /// Tanzil Uthmani text, verbatim (may start with the basmala).
  final String verseText;

  /// Characters of the basmala before verse 1 in the Tanzil file.
  final int basmalaPrefix;
  final String textSearch;
  final int searchBasmalaPrefix;
  final int juz;
  final int hizbQuarter;
  final int manzil;
  final int page;
  final String? sajda;
  final int textSourceId;
  final int pageSourceId;
  const AyahRow({
    required this.id,
    required this.surah,
    required this.number,
    required this.verseText,
    required this.basmalaPrefix,
    required this.textSearch,
    required this.searchBasmalaPrefix,
    required this.juz,
    required this.hizbQuarter,
    required this.manzil,
    required this.page,
    this.sajda,
    required this.textSourceId,
    required this.pageSourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surah'] = Variable<int>(surah);
    map['number'] = Variable<int>(number);
    map['text'] = Variable<String>(verseText);
    map['basmala_prefix'] = Variable<int>(basmalaPrefix);
    map['text_search'] = Variable<String>(textSearch);
    map['search_basmala_prefix'] = Variable<int>(searchBasmalaPrefix);
    map['juz'] = Variable<int>(juz);
    map['hizb_quarter'] = Variable<int>(hizbQuarter);
    map['manzil'] = Variable<int>(manzil);
    map['page'] = Variable<int>(page);
    if (!nullToAbsent || sajda != null) {
      map['sajda'] = Variable<String>(sajda);
    }
    map['text_source_id'] = Variable<int>(textSourceId);
    map['page_source_id'] = Variable<int>(pageSourceId);
    return map;
  }

  AyahCompanion toCompanion(bool nullToAbsent) {
    return AyahCompanion(
      id: Value(id),
      surah: Value(surah),
      number: Value(number),
      verseText: Value(verseText),
      basmalaPrefix: Value(basmalaPrefix),
      textSearch: Value(textSearch),
      searchBasmalaPrefix: Value(searchBasmalaPrefix),
      juz: Value(juz),
      hizbQuarter: Value(hizbQuarter),
      manzil: Value(manzil),
      page: Value(page),
      sajda: sajda == null && nullToAbsent
          ? const Value.absent()
          : Value(sajda),
      textSourceId: Value(textSourceId),
      pageSourceId: Value(pageSourceId),
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
      basmalaPrefix: serializer.fromJson<int>(json['basmalaPrefix']),
      textSearch: serializer.fromJson<String>(json['textSearch']),
      searchBasmalaPrefix: serializer.fromJson<int>(
        json['searchBasmalaPrefix'],
      ),
      juz: serializer.fromJson<int>(json['juz']),
      hizbQuarter: serializer.fromJson<int>(json['hizbQuarter']),
      manzil: serializer.fromJson<int>(json['manzil']),
      page: serializer.fromJson<int>(json['page']),
      sajda: serializer.fromJson<String?>(json['sajda']),
      textSourceId: serializer.fromJson<int>(json['textSourceId']),
      pageSourceId: serializer.fromJson<int>(json['pageSourceId']),
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
      'basmalaPrefix': serializer.toJson<int>(basmalaPrefix),
      'textSearch': serializer.toJson<String>(textSearch),
      'searchBasmalaPrefix': serializer.toJson<int>(searchBasmalaPrefix),
      'juz': serializer.toJson<int>(juz),
      'hizbQuarter': serializer.toJson<int>(hizbQuarter),
      'manzil': serializer.toJson<int>(manzil),
      'page': serializer.toJson<int>(page),
      'sajda': serializer.toJson<String?>(sajda),
      'textSourceId': serializer.toJson<int>(textSourceId),
      'pageSourceId': serializer.toJson<int>(pageSourceId),
    };
  }

  AyahRow copyWith({
    int? id,
    int? surah,
    int? number,
    String? verseText,
    int? basmalaPrefix,
    String? textSearch,
    int? searchBasmalaPrefix,
    int? juz,
    int? hizbQuarter,
    int? manzil,
    int? page,
    Value<String?> sajda = const Value.absent(),
    int? textSourceId,
    int? pageSourceId,
  }) => AyahRow(
    id: id ?? this.id,
    surah: surah ?? this.surah,
    number: number ?? this.number,
    verseText: verseText ?? this.verseText,
    basmalaPrefix: basmalaPrefix ?? this.basmalaPrefix,
    textSearch: textSearch ?? this.textSearch,
    searchBasmalaPrefix: searchBasmalaPrefix ?? this.searchBasmalaPrefix,
    juz: juz ?? this.juz,
    hizbQuarter: hizbQuarter ?? this.hizbQuarter,
    manzil: manzil ?? this.manzil,
    page: page ?? this.page,
    sajda: sajda.present ? sajda.value : this.sajda,
    textSourceId: textSourceId ?? this.textSourceId,
    pageSourceId: pageSourceId ?? this.pageSourceId,
  );
  AyahRow copyWithCompanion(AyahCompanion data) {
    return AyahRow(
      id: data.id.present ? data.id.value : this.id,
      surah: data.surah.present ? data.surah.value : this.surah,
      number: data.number.present ? data.number.value : this.number,
      verseText: data.verseText.present ? data.verseText.value : this.verseText,
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
      sajda: data.sajda.present ? data.sajda.value : this.sajda,
      textSourceId: data.textSourceId.present
          ? data.textSourceId.value
          : this.textSourceId,
      pageSourceId: data.pageSourceId.present
          ? data.pageSourceId.value
          : this.pageSourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AyahRow(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('number: $number, ')
          ..write('verseText: $verseText, ')
          ..write('basmalaPrefix: $basmalaPrefix, ')
          ..write('textSearch: $textSearch, ')
          ..write('searchBasmalaPrefix: $searchBasmalaPrefix, ')
          ..write('juz: $juz, ')
          ..write('hizbQuarter: $hizbQuarter, ')
          ..write('manzil: $manzil, ')
          ..write('page: $page, ')
          ..write('sajda: $sajda, ')
          ..write('textSourceId: $textSourceId, ')
          ..write('pageSourceId: $pageSourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    surah,
    number,
    verseText,
    basmalaPrefix,
    textSearch,
    searchBasmalaPrefix,
    juz,
    hizbQuarter,
    manzil,
    page,
    sajda,
    textSourceId,
    pageSourceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AyahRow &&
          other.id == this.id &&
          other.surah == this.surah &&
          other.number == this.number &&
          other.verseText == this.verseText &&
          other.basmalaPrefix == this.basmalaPrefix &&
          other.textSearch == this.textSearch &&
          other.searchBasmalaPrefix == this.searchBasmalaPrefix &&
          other.juz == this.juz &&
          other.hizbQuarter == this.hizbQuarter &&
          other.manzil == this.manzil &&
          other.page == this.page &&
          other.sajda == this.sajda &&
          other.textSourceId == this.textSourceId &&
          other.pageSourceId == this.pageSourceId);
}

class AyahCompanion extends UpdateCompanion<AyahRow> {
  final Value<int> id;
  final Value<int> surah;
  final Value<int> number;
  final Value<String> verseText;
  final Value<int> basmalaPrefix;
  final Value<String> textSearch;
  final Value<int> searchBasmalaPrefix;
  final Value<int> juz;
  final Value<int> hizbQuarter;
  final Value<int> manzil;
  final Value<int> page;
  final Value<String?> sajda;
  final Value<int> textSourceId;
  final Value<int> pageSourceId;
  const AyahCompanion({
    this.id = const Value.absent(),
    this.surah = const Value.absent(),
    this.number = const Value.absent(),
    this.verseText = const Value.absent(),
    this.basmalaPrefix = const Value.absent(),
    this.textSearch = const Value.absent(),
    this.searchBasmalaPrefix = const Value.absent(),
    this.juz = const Value.absent(),
    this.hizbQuarter = const Value.absent(),
    this.manzil = const Value.absent(),
    this.page = const Value.absent(),
    this.sajda = const Value.absent(),
    this.textSourceId = const Value.absent(),
    this.pageSourceId = const Value.absent(),
  });
  AyahCompanion.insert({
    this.id = const Value.absent(),
    required int surah,
    required int number,
    required String verseText,
    required int basmalaPrefix,
    required String textSearch,
    required int searchBasmalaPrefix,
    required int juz,
    required int hizbQuarter,
    required int manzil,
    required int page,
    this.sajda = const Value.absent(),
    required int textSourceId,
    required int pageSourceId,
  }) : surah = Value(surah),
       number = Value(number),
       verseText = Value(verseText),
       basmalaPrefix = Value(basmalaPrefix),
       textSearch = Value(textSearch),
       searchBasmalaPrefix = Value(searchBasmalaPrefix),
       juz = Value(juz),
       hizbQuarter = Value(hizbQuarter),
       manzil = Value(manzil),
       page = Value(page),
       textSourceId = Value(textSourceId),
       pageSourceId = Value(pageSourceId);
  static Insertable<AyahRow> custom({
    Expression<int>? id,
    Expression<int>? surah,
    Expression<int>? number,
    Expression<String>? verseText,
    Expression<int>? basmalaPrefix,
    Expression<String>? textSearch,
    Expression<int>? searchBasmalaPrefix,
    Expression<int>? juz,
    Expression<int>? hizbQuarter,
    Expression<int>? manzil,
    Expression<int>? page,
    Expression<String>? sajda,
    Expression<int>? textSourceId,
    Expression<int>? pageSourceId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surah != null) 'surah': surah,
      if (number != null) 'number': number,
      if (verseText != null) 'text': verseText,
      if (basmalaPrefix != null) 'basmala_prefix': basmalaPrefix,
      if (textSearch != null) 'text_search': textSearch,
      if (searchBasmalaPrefix != null)
        'search_basmala_prefix': searchBasmalaPrefix,
      if (juz != null) 'juz': juz,
      if (hizbQuarter != null) 'hizb_quarter': hizbQuarter,
      if (manzil != null) 'manzil': manzil,
      if (page != null) 'page': page,
      if (sajda != null) 'sajda': sajda,
      if (textSourceId != null) 'text_source_id': textSourceId,
      if (pageSourceId != null) 'page_source_id': pageSourceId,
    });
  }

  AyahCompanion copyWith({
    Value<int>? id,
    Value<int>? surah,
    Value<int>? number,
    Value<String>? verseText,
    Value<int>? basmalaPrefix,
    Value<String>? textSearch,
    Value<int>? searchBasmalaPrefix,
    Value<int>? juz,
    Value<int>? hizbQuarter,
    Value<int>? manzil,
    Value<int>? page,
    Value<String?>? sajda,
    Value<int>? textSourceId,
    Value<int>? pageSourceId,
  }) {
    return AyahCompanion(
      id: id ?? this.id,
      surah: surah ?? this.surah,
      number: number ?? this.number,
      verseText: verseText ?? this.verseText,
      basmalaPrefix: basmalaPrefix ?? this.basmalaPrefix,
      textSearch: textSearch ?? this.textSearch,
      searchBasmalaPrefix: searchBasmalaPrefix ?? this.searchBasmalaPrefix,
      juz: juz ?? this.juz,
      hizbQuarter: hizbQuarter ?? this.hizbQuarter,
      manzil: manzil ?? this.manzil,
      page: page ?? this.page,
      sajda: sajda ?? this.sajda,
      textSourceId: textSourceId ?? this.textSourceId,
      pageSourceId: pageSourceId ?? this.pageSourceId,
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
    if (sajda.present) {
      map['sajda'] = Variable<String>(sajda.value);
    }
    if (textSourceId.present) {
      map['text_source_id'] = Variable<int>(textSourceId.value);
    }
    if (pageSourceId.present) {
      map['page_source_id'] = Variable<int>(pageSourceId.value);
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
          ..write('basmalaPrefix: $basmalaPrefix, ')
          ..write('textSearch: $textSearch, ')
          ..write('searchBasmalaPrefix: $searchBasmalaPrefix, ')
          ..write('juz: $juz, ')
          ..write('hizbQuarter: $hizbQuarter, ')
          ..write('manzil: $manzil, ')
          ..write('page: $page, ')
          ..write('sajda: $sajda, ')
          ..write('textSourceId: $textSourceId, ')
          ..write('pageSourceId: $pageSourceId')
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

abstract class _$ContentDatabase extends GeneratedDatabase {
  _$ContentDatabase(QueryExecutor e) : super(e);
  $ContentDatabaseManager get managers => $ContentDatabaseManager(this);
  late final $SurahTable surah = $SurahTable(this);
  late final $AyahTable ayah = $AyahTable(this);
  late final $AyahPolygonTable ayahPolygon = $AyahPolygonTable(this);
  late final $SourceTable source = $SourceTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    surah,
    ayah,
    ayahPolygon,
    source,
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
  required int sourceId,
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
  Value<int> sourceId,
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

  ColumnFilters<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
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

  ColumnOrderings<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
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

  GeneratedColumn<int> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);
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
                Value<int> sourceId = const Value.absent(),
              }) => SurahCompanion(
                id: id,
                nameAr: nameAr,
                nameEn: nameEn,
                meaningEn: meaningEn,
                revelation: revelation,
                revelationOrder: revelationOrder,
                ayahCount: ayahCount,
                startPage: startPage,
                sourceId: sourceId,
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
                required int sourceId,
              }) => SurahCompanion.insert(
                id: id,
                nameAr: nameAr,
                nameEn: nameEn,
                meaningEn: meaningEn,
                revelation: revelation,
                revelationOrder: revelationOrder,
                ayahCount: ayahCount,
                startPage: startPage,
                sourceId: sourceId,
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
  required int basmalaPrefix,
  required String textSearch,
  required int searchBasmalaPrefix,
  required int juz,
  required int hizbQuarter,
  required int manzil,
  required int page,
  Value<String?> sajda,
  required int textSourceId,
  required int pageSourceId,
});
typedef $$AyahTableUpdateCompanionBuilder = AyahCompanion Function({
  Value<int> id,
  Value<int> surah,
  Value<int> number,
  Value<String> verseText,
  Value<int> basmalaPrefix,
  Value<String> textSearch,
  Value<int> searchBasmalaPrefix,
  Value<int> juz,
  Value<int> hizbQuarter,
  Value<int> manzil,
  Value<int> page,
  Value<String?> sajda,
  Value<int> textSourceId,
  Value<int> pageSourceId,
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

  ColumnFilters<String> get sajda => $composableBuilder(
    column: $table.sajda,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get textSourceId => $composableBuilder(
    column: $table.textSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageSourceId => $composableBuilder(
    column: $table.pageSourceId,
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

  ColumnOrderings<String> get sajda => $composableBuilder(
    column: $table.sajda,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get textSourceId => $composableBuilder(
    column: $table.textSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageSourceId => $composableBuilder(
    column: $table.pageSourceId,
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

  GeneratedColumn<String> get sajda =>
      $composableBuilder(column: $table.sajda, builder: (column) => column);

  GeneratedColumn<int> get textSourceId => $composableBuilder(
    column: $table.textSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageSourceId => $composableBuilder(
    column: $table.pageSourceId,
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
                Value<int> basmalaPrefix = const Value.absent(),
                Value<String> textSearch = const Value.absent(),
                Value<int> searchBasmalaPrefix = const Value.absent(),
                Value<int> juz = const Value.absent(),
                Value<int> hizbQuarter = const Value.absent(),
                Value<int> manzil = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<String?> sajda = const Value.absent(),
                Value<int> textSourceId = const Value.absent(),
                Value<int> pageSourceId = const Value.absent(),
              }) => AyahCompanion(
                id: id,
                surah: surah,
                number: number,
                verseText: verseText,
                basmalaPrefix: basmalaPrefix,
                textSearch: textSearch,
                searchBasmalaPrefix: searchBasmalaPrefix,
                juz: juz,
                hizbQuarter: hizbQuarter,
                manzil: manzil,
                page: page,
                sajda: sajda,
                textSourceId: textSourceId,
                pageSourceId: pageSourceId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int surah,
                required int number,
                required String verseText,
                required int basmalaPrefix,
                required String textSearch,
                required int searchBasmalaPrefix,
                required int juz,
                required int hizbQuarter,
                required int manzil,
                required int page,
                Value<String?> sajda = const Value.absent(),
                required int textSourceId,
                required int pageSourceId,
              }) => AyahCompanion.insert(
                id: id,
                surah: surah,
                number: number,
                verseText: verseText,
                basmalaPrefix: basmalaPrefix,
                textSearch: textSearch,
                searchBasmalaPrefix: searchBasmalaPrefix,
                juz: juz,
                hizbQuarter: hizbQuarter,
                manzil: manzil,
                page: page,
                sajda: sajda,
                textSourceId: textSourceId,
                pageSourceId: pageSourceId,
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
}
