// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_database.dart';

// ignore_for_file: type=lint
class $BookmarkSetsTable extends BookmarkSets
    with TableInfo<$BookmarkSetsTable, BookmarkSetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarkSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
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
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    color,
    surah,
    ayah,
    page,
    sortOrder,
    updatedAt,
    kind,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmark_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookmarkSetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
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
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
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
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookmarkSetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookmarkSetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
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
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      ),
    );
  }

  @override
  $BookmarkSetsTable createAlias(String alias) {
    return $BookmarkSetsTable(attachedDatabase, alias);
  }
}

class BookmarkSetRow extends DataClass implements Insertable<BookmarkSetRow> {
  final int id;
  final String name;

  /// ARGB colour.
  final int color;
  final int surah;
  final int ayah;
  final int page;
  final int sortOrder;
  final DateTime updatedAt;

  /// One of [MarkKind] for the four fixed marks; null for the reader's
  /// own named fawasil.
  final String? kind;
  const BookmarkSetRow({
    required this.id,
    required this.name,
    required this.color,
    required this.surah,
    required this.ayah,
    required this.page,
    required this.sortOrder,
    required this.updatedAt,
    this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<int>(color);
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['page'] = Variable<int>(page);
    map['sort_order'] = Variable<int>(sortOrder);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>(kind);
    }
    return map;
  }

  BookmarkSetsCompanion toCompanion(bool nullToAbsent) {
    return BookmarkSetsCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      surah: Value(surah),
      ayah: Value(ayah),
      page: Value(page),
      sortOrder: Value(sortOrder),
      updatedAt: Value(updatedAt),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
    );
  }

  factory BookmarkSetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookmarkSetRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int>(json['color']),
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      page: serializer.fromJson<int>(json['page']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      kind: serializer.fromJson<String?>(json['kind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int>(color),
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'page': serializer.toJson<int>(page),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'kind': serializer.toJson<String?>(kind),
    };
  }

  BookmarkSetRow copyWith({
    int? id,
    String? name,
    int? color,
    int? surah,
    int? ayah,
    int? page,
    int? sortOrder,
    DateTime? updatedAt,
    Value<String?> kind = const Value.absent(),
  }) => BookmarkSetRow(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    page: page ?? this.page,
    sortOrder: sortOrder ?? this.sortOrder,
    updatedAt: updatedAt ?? this.updatedAt,
    kind: kind.present ? kind.value : this.kind,
  );
  BookmarkSetRow copyWithCompanion(BookmarkSetsCompanion data) {
    return BookmarkSetRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      page: data.page.present ? data.page.value : this.page,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkSetRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('page: $page, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    color,
    surah,
    ayah,
    page,
    sortOrder,
    updatedAt,
    kind,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookmarkSetRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.page == this.page &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt &&
          other.kind == this.kind);
}

class BookmarkSetsCompanion extends UpdateCompanion<BookmarkSetRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> color;
  final Value<int> surah;
  final Value<int> ayah;
  final Value<int> page;
  final Value<int> sortOrder;
  final Value<DateTime> updatedAt;
  final Value<String?> kind;
  const BookmarkSetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.page = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.kind = const Value.absent(),
  });
  BookmarkSetsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int color,
    required int surah,
    required int ayah,
    required int page,
    this.sortOrder = const Value.absent(),
    required DateTime updatedAt,
    this.kind = const Value.absent(),
  }) : name = Value(name),
       color = Value(color),
       surah = Value(surah),
       ayah = Value(ayah),
       page = Value(page),
       updatedAt = Value(updatedAt);
  static Insertable<BookmarkSetRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<int>? page,
    Expression<int>? sortOrder,
    Expression<DateTime>? updatedAt,
    Expression<String>? kind,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (page != null) 'page': page,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (kind != null) 'kind': kind,
    });
  }

  BookmarkSetsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? color,
    Value<int>? surah,
    Value<int>? ayah,
    Value<int>? page,
    Value<int>? sortOrder,
    Value<DateTime>? updatedAt,
    Value<String?>? kind,
  }) {
    return BookmarkSetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      page: page ?? this.page,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      kind: kind ?? this.kind,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkSetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('page: $page, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }
}

class $ReadingPositionsTable extends ReadingPositions
    with TableInfo<$ReadingPositionsTable, ReadingPositionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingPositionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
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
  static const VerificationMeta _viewMeta = const VerificationMeta('view');
  @override
  late final GeneratedColumn<String> view = GeneratedColumn<String>(
    'view',
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    edition,
    view,
    surah,
    ayah,
    page,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_positions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingPositionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('edition')) {
      context.handle(
        _editionMeta,
        edition.isAcceptableOrUnknown(data['edition']!, _editionMeta),
      );
    } else if (isInserting) {
      context.missing(_editionMeta);
    }
    if (data.containsKey('view')) {
      context.handle(
        _viewMeta,
        view.isAcceptableOrUnknown(data['view']!, _viewMeta),
      );
    } else if (isInserting) {
      context.missing(_viewMeta);
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
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingPositionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingPositionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      edition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edition'],
      )!,
      view: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}view'],
      )!,
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
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReadingPositionsTable createAlias(String alias) {
    return $ReadingPositionsTable(attachedDatabase, alias);
  }
}

class ReadingPositionRow extends DataClass
    implements Insertable<ReadingPositionRow> {
  final int id;
  final String edition;
  final String view;
  final int surah;
  final int ayah;
  final int page;
  final DateTime updatedAt;
  const ReadingPositionRow({
    required this.id,
    required this.edition,
    required this.view,
    required this.surah,
    required this.ayah,
    required this.page,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['edition'] = Variable<String>(edition);
    map['view'] = Variable<String>(view);
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['page'] = Variable<int>(page);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ReadingPositionsCompanion toCompanion(bool nullToAbsent) {
    return ReadingPositionsCompanion(
      id: Value(id),
      edition: Value(edition),
      view: Value(view),
      surah: Value(surah),
      ayah: Value(ayah),
      page: Value(page),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReadingPositionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingPositionRow(
      id: serializer.fromJson<int>(json['id']),
      edition: serializer.fromJson<String>(json['edition']),
      view: serializer.fromJson<String>(json['view']),
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      page: serializer.fromJson<int>(json['page']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'edition': serializer.toJson<String>(edition),
      'view': serializer.toJson<String>(view),
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'page': serializer.toJson<int>(page),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReadingPositionRow copyWith({
    int? id,
    String? edition,
    String? view,
    int? surah,
    int? ayah,
    int? page,
    DateTime? updatedAt,
  }) => ReadingPositionRow(
    id: id ?? this.id,
    edition: edition ?? this.edition,
    view: view ?? this.view,
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    page: page ?? this.page,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReadingPositionRow copyWithCompanion(ReadingPositionsCompanion data) {
    return ReadingPositionRow(
      id: data.id.present ? data.id.value : this.id,
      edition: data.edition.present ? data.edition.value : this.edition,
      view: data.view.present ? data.view.value : this.view,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      page: data.page.present ? data.page.value : this.page,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingPositionRow(')
          ..write('id: $id, ')
          ..write('edition: $edition, ')
          ..write('view: $view, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('page: $page, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, edition, view, surah, ayah, page, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingPositionRow &&
          other.id == this.id &&
          other.edition == this.edition &&
          other.view == this.view &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.page == this.page &&
          other.updatedAt == this.updatedAt);
}

class ReadingPositionsCompanion extends UpdateCompanion<ReadingPositionRow> {
  final Value<int> id;
  final Value<String> edition;
  final Value<String> view;
  final Value<int> surah;
  final Value<int> ayah;
  final Value<int> page;
  final Value<DateTime> updatedAt;
  const ReadingPositionsCompanion({
    this.id = const Value.absent(),
    this.edition = const Value.absent(),
    this.view = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.page = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ReadingPositionsCompanion.insert({
    this.id = const Value.absent(),
    required String edition,
    required String view,
    required int surah,
    required int ayah,
    required int page,
    required DateTime updatedAt,
  }) : edition = Value(edition),
       view = Value(view),
       surah = Value(surah),
       ayah = Value(ayah),
       page = Value(page),
       updatedAt = Value(updatedAt);
  static Insertable<ReadingPositionRow> custom({
    Expression<int>? id,
    Expression<String>? edition,
    Expression<String>? view,
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<int>? page,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (edition != null) 'edition': edition,
      if (view != null) 'view': view,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (page != null) 'page': page,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ReadingPositionsCompanion copyWith({
    Value<int>? id,
    Value<String>? edition,
    Value<String>? view,
    Value<int>? surah,
    Value<int>? ayah,
    Value<int>? page,
    Value<DateTime>? updatedAt,
  }) {
    return ReadingPositionsCompanion(
      id: id ?? this.id,
      edition: edition ?? this.edition,
      view: view ?? this.view,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      page: page ?? this.page,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (edition.present) {
      map['edition'] = Variable<String>(edition.value);
    }
    if (view.present) {
      map['view'] = Variable<String>(view.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingPositionsCompanion(')
          ..write('id: $id, ')
          ..write('edition: $edition, ')
          ..write('view: $view, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('page: $page, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $KhatmasTable extends Khatmas with TableInfo<$KhatmasTable, KhatmaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KhatmasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: newUuid,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('page'),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<String> targetDate = GeneratedColumn<String>(
    'target_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyPortionMeta = const VerificationMeta(
    'dailyPortion',
  );
  @override
  late final GeneratedColumn<double> dailyPortion = GeneratedColumn<double>(
    'daily_portion',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderTimeMeta = const VerificationMeta(
    'reminderTime',
  );
  @override
  late final GeneratedColumn<int> reminderTime = GeneratedColumn<int>(
    'reminder_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rebasedOnMeta = const VerificationMeta(
    'rebasedOn',
  );
  @override
  late final GeneratedColumn<String> rebasedOn = GeneratedColumn<String>(
    'rebased_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    updatedAt,
    deletedAt,
    id,
    title,
    edition,
    unit,
    startDate,
    targetDate,
    dailyPortion,
    reminderTime,
    rebasedOn,
    completedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'khatma';
  @override
  VerificationContext validateIntegrity(
    Insertable<KhatmaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('edition')) {
      context.handle(
        _editionMeta,
        edition.isAcceptableOrUnknown(data['edition']!, _editionMeta),
      );
    } else if (isInserting) {
      context.missing(_editionMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDateMeta);
    }
    if (data.containsKey('daily_portion')) {
      context.handle(
        _dailyPortionMeta,
        dailyPortion.isAcceptableOrUnknown(
          data['daily_portion']!,
          _dailyPortionMeta,
        ),
      );
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
        _reminderTimeMeta,
        reminderTime.isAcceptableOrUnknown(
          data['reminder_time']!,
          _reminderTimeMeta,
        ),
      );
    }
    if (data.containsKey('rebased_on')) {
      context.handle(
        _rebasedOnMeta,
        rebasedOn.isAcceptableOrUnknown(data['rebased_on']!, _rebasedOnMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KhatmaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KhatmaRow(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      edition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edition'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_date'],
      )!,
      dailyPortion: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}daily_portion'],
      ),
      reminderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_time'],
      ),
      rebasedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rebased_on'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $KhatmasTable createAlias(String alias) {
    return $KhatmasTable(attachedDatabase, alias);
  }
}

class KhatmaRow extends DataClass implements Insertable<KhatmaRow> {
  final String uuid;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int id;
  final String title;

  /// The edition whose pages the plan counts (`MushafEdition.name`).
  final String edition;

  /// `page`, `juz` or `hizb`: what a day's portion is made of.
  final String unit;
  final String startDate;
  final String targetDate;

  /// Units a day, when the plan was made from a daily amount; null when it
  /// was made from an end date.
  final double? dailyPortion;

  /// Daily reminder, minutes after midnight; null for none.
  final int? reminderTime;

  /// The day the rest was spread again over the remaining days (catch-up).
  final String? rebasedOn;
  final DateTime? completedAt;
  final DateTime createdAt;
  const KhatmaRow({
    required this.uuid,
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.title,
    required this.edition,
    required this.unit,
    required this.startDate,
    required this.targetDate,
    this.dailyPortion,
    this.reminderTime,
    this.rebasedOn,
    this.completedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['edition'] = Variable<String>(edition);
    map['unit'] = Variable<String>(unit);
    map['start_date'] = Variable<String>(startDate);
    map['target_date'] = Variable<String>(targetDate);
    if (!nullToAbsent || dailyPortion != null) {
      map['daily_portion'] = Variable<double>(dailyPortion);
    }
    if (!nullToAbsent || reminderTime != null) {
      map['reminder_time'] = Variable<int>(reminderTime);
    }
    if (!nullToAbsent || rebasedOn != null) {
      map['rebased_on'] = Variable<String>(rebasedOn);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  KhatmasCompanion toCompanion(bool nullToAbsent) {
    return KhatmasCompanion(
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      title: Value(title),
      edition: Value(edition),
      unit: Value(unit),
      startDate: Value(startDate),
      targetDate: Value(targetDate),
      dailyPortion: dailyPortion == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyPortion),
      reminderTime: reminderTime == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderTime),
      rebasedOn: rebasedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(rebasedOn),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      createdAt: Value(createdAt),
    );
  }

  factory KhatmaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KhatmaRow(
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      edition: serializer.fromJson<String>(json['edition']),
      unit: serializer.fromJson<String>(json['unit']),
      startDate: serializer.fromJson<String>(json['startDate']),
      targetDate: serializer.fromJson<String>(json['targetDate']),
      dailyPortion: serializer.fromJson<double?>(json['dailyPortion']),
      reminderTime: serializer.fromJson<int?>(json['reminderTime']),
      rebasedOn: serializer.fromJson<String?>(json['rebasedOn']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'edition': serializer.toJson<String>(edition),
      'unit': serializer.toJson<String>(unit),
      'startDate': serializer.toJson<String>(startDate),
      'targetDate': serializer.toJson<String>(targetDate),
      'dailyPortion': serializer.toJson<double?>(dailyPortion),
      'reminderTime': serializer.toJson<int?>(reminderTime),
      'rebasedOn': serializer.toJson<String?>(rebasedOn),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  KhatmaRow copyWith({
    String? uuid,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? id,
    String? title,
    String? edition,
    String? unit,
    String? startDate,
    String? targetDate,
    Value<double?> dailyPortion = const Value.absent(),
    Value<int?> reminderTime = const Value.absent(),
    Value<String?> rebasedOn = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    DateTime? createdAt,
  }) => KhatmaRow(
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    title: title ?? this.title,
    edition: edition ?? this.edition,
    unit: unit ?? this.unit,
    startDate: startDate ?? this.startDate,
    targetDate: targetDate ?? this.targetDate,
    dailyPortion: dailyPortion.present ? dailyPortion.value : this.dailyPortion,
    reminderTime: reminderTime.present ? reminderTime.value : this.reminderTime,
    rebasedOn: rebasedOn.present ? rebasedOn.value : this.rebasedOn,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  KhatmaRow copyWithCompanion(KhatmasCompanion data) {
    return KhatmaRow(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      edition: data.edition.present ? data.edition.value : this.edition,
      unit: data.unit.present ? data.unit.value : this.unit,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      dailyPortion: data.dailyPortion.present
          ? data.dailyPortion.value
          : this.dailyPortion,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      rebasedOn: data.rebasedOn.present ? data.rebasedOn.value : this.rebasedOn,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KhatmaRow(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('edition: $edition, ')
          ..write('unit: $unit, ')
          ..write('startDate: $startDate, ')
          ..write('targetDate: $targetDate, ')
          ..write('dailyPortion: $dailyPortion, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('rebasedOn: $rebasedOn, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    updatedAt,
    deletedAt,
    id,
    title,
    edition,
    unit,
    startDate,
    targetDate,
    dailyPortion,
    reminderTime,
    rebasedOn,
    completedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KhatmaRow &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.title == this.title &&
          other.edition == this.edition &&
          other.unit == this.unit &&
          other.startDate == this.startDate &&
          other.targetDate == this.targetDate &&
          other.dailyPortion == this.dailyPortion &&
          other.reminderTime == this.reminderTime &&
          other.rebasedOn == this.rebasedOn &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt);
}

class KhatmasCompanion extends UpdateCompanion<KhatmaRow> {
  final Value<String> uuid;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> id;
  final Value<String> title;
  final Value<String> edition;
  final Value<String> unit;
  final Value<String> startDate;
  final Value<String> targetDate;
  final Value<double?> dailyPortion;
  final Value<int?> reminderTime;
  final Value<String?> rebasedOn;
  final Value<DateTime?> completedAt;
  final Value<DateTime> createdAt;
  const KhatmasCompanion({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.edition = const Value.absent(),
    this.unit = const Value.absent(),
    this.startDate = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.dailyPortion = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.rebasedOn = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  KhatmasCompanion.insert({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    required String title,
    required String edition,
    this.unit = const Value.absent(),
    required String startDate,
    required String targetDate,
    this.dailyPortion = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.rebasedOn = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : title = Value(title),
       edition = Value(edition),
       startDate = Value(startDate),
       targetDate = Value(targetDate);
  static Insertable<KhatmaRow> custom({
    Expression<String>? uuid,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? edition,
    Expression<String>? unit,
    Expression<String>? startDate,
    Expression<String>? targetDate,
    Expression<double>? dailyPortion,
    Expression<int>? reminderTime,
    Expression<String>? rebasedOn,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (edition != null) 'edition': edition,
      if (unit != null) 'unit': unit,
      if (startDate != null) 'start_date': startDate,
      if (targetDate != null) 'target_date': targetDate,
      if (dailyPortion != null) 'daily_portion': dailyPortion,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (rebasedOn != null) 'rebased_on': rebasedOn,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  KhatmasCompanion copyWith({
    Value<String>? uuid,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? id,
    Value<String>? title,
    Value<String>? edition,
    Value<String>? unit,
    Value<String>? startDate,
    Value<String>? targetDate,
    Value<double?>? dailyPortion,
    Value<int?>? reminderTime,
    Value<String?>? rebasedOn,
    Value<DateTime?>? completedAt,
    Value<DateTime>? createdAt,
  }) {
    return KhatmasCompanion(
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      title: title ?? this.title,
      edition: edition ?? this.edition,
      unit: unit ?? this.unit,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      dailyPortion: dailyPortion ?? this.dailyPortion,
      reminderTime: reminderTime ?? this.reminderTime,
      rebasedOn: rebasedOn ?? this.rebasedOn,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (edition.present) {
      map['edition'] = Variable<String>(edition.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<String>(targetDate.value);
    }
    if (dailyPortion.present) {
      map['daily_portion'] = Variable<double>(dailyPortion.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<int>(reminderTime.value);
    }
    if (rebasedOn.present) {
      map['rebased_on'] = Variable<String>(rebasedOn.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KhatmasCompanion(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('edition: $edition, ')
          ..write('unit: $unit, ')
          ..write('startDate: $startDate, ')
          ..write('targetDate: $targetDate, ')
          ..write('dailyPortion: $dailyPortion, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('rebasedOn: $rebasedOn, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $KhatmaLogsTable extends KhatmaLogs
    with TableInfo<$KhatmaLogsTable, KhatmaLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KhatmaLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: newUuid,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _khatmaUuidMeta = const VerificationMeta(
    'khatmaUuid',
  );
  @override
  late final GeneratedColumn<String> khatmaUuid = GeneratedColumn<String>(
    'khatma_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromPageMeta = const VerificationMeta(
    'fromPage',
  );
  @override
  late final GeneratedColumn<int> fromPage = GeneratedColumn<int>(
    'from_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toPageMeta = const VerificationMeta('toPage');
  @override
  late final GeneratedColumn<int> toPage = GeneratedColumn<int>(
    'to_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    updatedAt,
    deletedAt,
    id,
    khatmaUuid,
    date,
    fromPage,
    toPage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'khatma_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<KhatmaLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('khatma_uuid')) {
      context.handle(
        _khatmaUuidMeta,
        khatmaUuid.isAcceptableOrUnknown(data['khatma_uuid']!, _khatmaUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_khatmaUuidMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('from_page')) {
      context.handle(
        _fromPageMeta,
        fromPage.isAcceptableOrUnknown(data['from_page']!, _fromPageMeta),
      );
    } else if (isInserting) {
      context.missing(_fromPageMeta);
    }
    if (data.containsKey('to_page')) {
      context.handle(
        _toPageMeta,
        toPage.isAcceptableOrUnknown(data['to_page']!, _toPageMeta),
      );
    } else if (isInserting) {
      context.missing(_toPageMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KhatmaLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KhatmaLogRow(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      khatmaUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}khatma_uuid'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      fromPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_page'],
      )!,
      toPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_page'],
      )!,
    );
  }

  @override
  $KhatmaLogsTable createAlias(String alias) {
    return $KhatmaLogsTable(attachedDatabase, alias);
  }
}

class KhatmaLogRow extends DataClass implements Insertable<KhatmaLogRow> {
  final String uuid;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int id;

  /// The khatma's uuid (row ids differ between devices).
  final String khatmaUuid;
  final String date;
  final int fromPage;
  final int toPage;
  const KhatmaLogRow({
    required this.uuid,
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.khatmaUuid,
    required this.date,
    required this.fromPage,
    required this.toPage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<int>(id);
    map['khatma_uuid'] = Variable<String>(khatmaUuid);
    map['date'] = Variable<String>(date);
    map['from_page'] = Variable<int>(fromPage);
    map['to_page'] = Variable<int>(toPage);
    return map;
  }

  KhatmaLogsCompanion toCompanion(bool nullToAbsent) {
    return KhatmaLogsCompanion(
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      khatmaUuid: Value(khatmaUuid),
      date: Value(date),
      fromPage: Value(fromPage),
      toPage: Value(toPage),
    );
  }

  factory KhatmaLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KhatmaLogRow(
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<int>(json['id']),
      khatmaUuid: serializer.fromJson<String>(json['khatmaUuid']),
      date: serializer.fromJson<String>(json['date']),
      fromPage: serializer.fromJson<int>(json['fromPage']),
      toPage: serializer.fromJson<int>(json['toPage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<int>(id),
      'khatmaUuid': serializer.toJson<String>(khatmaUuid),
      'date': serializer.toJson<String>(date),
      'fromPage': serializer.toJson<int>(fromPage),
      'toPage': serializer.toJson<int>(toPage),
    };
  }

  KhatmaLogRow copyWith({
    String? uuid,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? id,
    String? khatmaUuid,
    String? date,
    int? fromPage,
    int? toPage,
  }) => KhatmaLogRow(
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    khatmaUuid: khatmaUuid ?? this.khatmaUuid,
    date: date ?? this.date,
    fromPage: fromPage ?? this.fromPage,
    toPage: toPage ?? this.toPage,
  );
  KhatmaLogRow copyWithCompanion(KhatmaLogsCompanion data) {
    return KhatmaLogRow(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      khatmaUuid: data.khatmaUuid.present
          ? data.khatmaUuid.value
          : this.khatmaUuid,
      date: data.date.present ? data.date.value : this.date,
      fromPage: data.fromPage.present ? data.fromPage.value : this.fromPage,
      toPage: data.toPage.present ? data.toPage.value : this.toPage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KhatmaLogRow(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('khatmaUuid: $khatmaUuid, ')
          ..write('date: $date, ')
          ..write('fromPage: $fromPage, ')
          ..write('toPage: $toPage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    updatedAt,
    deletedAt,
    id,
    khatmaUuid,
    date,
    fromPage,
    toPage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KhatmaLogRow &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.khatmaUuid == this.khatmaUuid &&
          other.date == this.date &&
          other.fromPage == this.fromPage &&
          other.toPage == this.toPage);
}

class KhatmaLogsCompanion extends UpdateCompanion<KhatmaLogRow> {
  final Value<String> uuid;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> id;
  final Value<String> khatmaUuid;
  final Value<String> date;
  final Value<int> fromPage;
  final Value<int> toPage;
  const KhatmaLogsCompanion({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.khatmaUuid = const Value.absent(),
    this.date = const Value.absent(),
    this.fromPage = const Value.absent(),
    this.toPage = const Value.absent(),
  });
  KhatmaLogsCompanion.insert({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    required String khatmaUuid,
    required String date,
    required int fromPage,
    required int toPage,
  }) : khatmaUuid = Value(khatmaUuid),
       date = Value(date),
       fromPage = Value(fromPage),
       toPage = Value(toPage);
  static Insertable<KhatmaLogRow> custom({
    Expression<String>? uuid,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? id,
    Expression<String>? khatmaUuid,
    Expression<String>? date,
    Expression<int>? fromPage,
    Expression<int>? toPage,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (khatmaUuid != null) 'khatma_uuid': khatmaUuid,
      if (date != null) 'date': date,
      if (fromPage != null) 'from_page': fromPage,
      if (toPage != null) 'to_page': toPage,
    });
  }

  KhatmaLogsCompanion copyWith({
    Value<String>? uuid,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? id,
    Value<String>? khatmaUuid,
    Value<String>? date,
    Value<int>? fromPage,
    Value<int>? toPage,
  }) {
    return KhatmaLogsCompanion(
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      khatmaUuid: khatmaUuid ?? this.khatmaUuid,
      date: date ?? this.date,
      fromPage: fromPage ?? this.fromPage,
      toPage: toPage ?? this.toPage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (khatmaUuid.present) {
      map['khatma_uuid'] = Variable<String>(khatmaUuid.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (fromPage.present) {
      map['from_page'] = Variable<int>(fromPage.value);
    }
    if (toPage.present) {
      map['to_page'] = Variable<int>(toPage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KhatmaLogsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('khatmaUuid: $khatmaUuid, ')
          ..write('date: $date, ')
          ..write('fromPage: $fromPage, ')
          ..write('toPage: $toPage')
          ..write(')'))
        .toString();
  }
}

class $ReadingSessionsTable extends ReadingSessions
    with TableInfo<$ReadingSessionsTable, ReadingSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: newUuid,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pagesMeta = const VerificationMeta('pages');
  @override
  late final GeneratedColumn<int> pages = GeneratedColumn<int>(
    'pages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('page'),
  );
  static const VerificationMeta _editionMeta = const VerificationMeta(
    'edition',
  );
  @override
  late final GeneratedColumn<String> edition = GeneratedColumn<String>(
    'edition',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    updatedAt,
    deletedAt,
    id,
    startedAt,
    endedAt,
    pages,
    mode,
    edition,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_session';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('pages')) {
      context.handle(
        _pagesMeta,
        pages.isAcceptableOrUnknown(data['pages']!, _pagesMeta),
      );
    } else if (isInserting) {
      context.missing(_pagesMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('edition')) {
      context.handle(
        _editionMeta,
        edition.isAcceptableOrUnknown(data['edition']!, _editionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingSessionRow(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      pages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pages'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      edition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edition'],
      ),
    );
  }

  @override
  $ReadingSessionsTable createAlias(String alias) {
    return $ReadingSessionsTable(attachedDatabase, alias);
  }
}

class ReadingSessionRow extends DataClass
    implements Insertable<ReadingSessionRow> {
  final String uuid;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int id;
  final DateTime startedAt;
  final DateTime endedAt;

  /// Pages that stayed on screen long enough to count as read.
  final int pages;

  /// `page` (the page view).
  final String mode;
  final String? edition;
  const ReadingSessionRow({
    required this.uuid,
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.pages,
    required this.mode,
    this.edition,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['pages'] = Variable<int>(pages);
    map['mode'] = Variable<String>(mode);
    if (!nullToAbsent || edition != null) {
      map['edition'] = Variable<String>(edition);
    }
    return map;
  }

  ReadingSessionsCompanion toCompanion(bool nullToAbsent) {
    return ReadingSessionsCompanion(
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      pages: Value(pages),
      mode: Value(mode),
      edition: edition == null && nullToAbsent
          ? const Value.absent()
          : Value(edition),
    );
  }

  factory ReadingSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingSessionRow(
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      pages: serializer.fromJson<int>(json['pages']),
      mode: serializer.fromJson<String>(json['mode']),
      edition: serializer.fromJson<String?>(json['edition']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'pages': serializer.toJson<int>(pages),
      'mode': serializer.toJson<String>(mode),
      'edition': serializer.toJson<String?>(edition),
    };
  }

  ReadingSessionRow copyWith({
    String? uuid,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? id,
    DateTime? startedAt,
    DateTime? endedAt,
    int? pages,
    String? mode,
    Value<String?> edition = const Value.absent(),
  }) => ReadingSessionRow(
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    pages: pages ?? this.pages,
    mode: mode ?? this.mode,
    edition: edition.present ? edition.value : this.edition,
  );
  ReadingSessionRow copyWithCompanion(ReadingSessionsCompanion data) {
    return ReadingSessionRow(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      pages: data.pages.present ? data.pages.value : this.pages,
      mode: data.mode.present ? data.mode.value : this.mode,
      edition: data.edition.present ? data.edition.value : this.edition,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionRow(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('pages: $pages, ')
          ..write('mode: $mode, ')
          ..write('edition: $edition')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    updatedAt,
    deletedAt,
    id,
    startedAt,
    endedAt,
    pages,
    mode,
    edition,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingSessionRow &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.pages == this.pages &&
          other.mode == this.mode &&
          other.edition == this.edition);
}

class ReadingSessionsCompanion extends UpdateCompanion<ReadingSessionRow> {
  final Value<String> uuid;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<int> pages;
  final Value<String> mode;
  final Value<String?> edition;
  const ReadingSessionsCompanion({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.pages = const Value.absent(),
    this.mode = const Value.absent(),
    this.edition = const Value.absent(),
  });
  ReadingSessionsCompanion.insert({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    required DateTime startedAt,
    required DateTime endedAt,
    required int pages,
    this.mode = const Value.absent(),
    this.edition = const Value.absent(),
  }) : startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       pages = Value(pages);
  static Insertable<ReadingSessionRow> custom({
    Expression<String>? uuid,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? pages,
    Expression<String>? mode,
    Expression<String>? edition,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (pages != null) 'pages': pages,
      if (mode != null) 'mode': mode,
      if (edition != null) 'edition': edition,
    });
  }

  ReadingSessionsCompanion copyWith({
    Value<String>? uuid,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<int>? pages,
    Value<String>? mode,
    Value<String?>? edition,
  }) {
    return ReadingSessionsCompanion(
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      pages: pages ?? this.pages,
      mode: mode ?? this.mode,
      edition: edition ?? this.edition,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (pages.present) {
      map['pages'] = Variable<int>(pages.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (edition.present) {
      map['edition'] = Variable<String>(edition.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('pages: $pages, ')
          ..write('mode: $mode, ')
          ..write('edition: $edition')
          ..write(')'))
        .toString();
  }
}

class $ListeningSessionsTable extends ListeningSessions
    with TableInfo<$ListeningSessionsTable, ListeningSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListeningSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: newUuid,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondsMeta = const VerificationMeta(
    'seconds',
  );
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>(
    'seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reciterIdMeta = const VerificationMeta(
    'reciterId',
  );
  @override
  late final GeneratedColumn<int> reciterId = GeneratedColumn<int>(
    'reciter_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    updatedAt,
    deletedAt,
    id,
    startedAt,
    seconds,
    reciterId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listening_session';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListeningSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('seconds')) {
      context.handle(
        _secondsMeta,
        seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta),
      );
    } else if (isInserting) {
      context.missing(_secondsMeta);
    }
    if (data.containsKey('reciter_id')) {
      context.handle(
        _reciterIdMeta,
        reciterId.isAcceptableOrUnknown(data['reciter_id']!, _reciterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reciterIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListeningSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListeningSessionRow(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      seconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds'],
      )!,
      reciterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reciter_id'],
      )!,
    );
  }

  @override
  $ListeningSessionsTable createAlias(String alias) {
    return $ListeningSessionsTable(attachedDatabase, alias);
  }
}

class ListeningSessionRow extends DataClass
    implements Insertable<ListeningSessionRow> {
  final String uuid;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int id;
  final DateTime startedAt;
  final int seconds;
  final int reciterId;
  const ListeningSessionRow({
    required this.uuid,
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.startedAt,
    required this.seconds,
    required this.reciterId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['seconds'] = Variable<int>(seconds);
    map['reciter_id'] = Variable<int>(reciterId);
    return map;
  }

  ListeningSessionsCompanion toCompanion(bool nullToAbsent) {
    return ListeningSessionsCompanion(
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      startedAt: Value(startedAt),
      seconds: Value(seconds),
      reciterId: Value(reciterId),
    );
  }

  factory ListeningSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListeningSessionRow(
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      seconds: serializer.fromJson<int>(json['seconds']),
      reciterId: serializer.fromJson<int>(json['reciterId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'seconds': serializer.toJson<int>(seconds),
      'reciterId': serializer.toJson<int>(reciterId),
    };
  }

  ListeningSessionRow copyWith({
    String? uuid,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? id,
    DateTime? startedAt,
    int? seconds,
    int? reciterId,
  }) => ListeningSessionRow(
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    seconds: seconds ?? this.seconds,
    reciterId: reciterId ?? this.reciterId,
  );
  ListeningSessionRow copyWithCompanion(ListeningSessionsCompanion data) {
    return ListeningSessionRow(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
      reciterId: data.reciterId.present ? data.reciterId.value : this.reciterId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListeningSessionRow(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('seconds: $seconds, ')
          ..write('reciterId: $reciterId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    updatedAt,
    deletedAt,
    id,
    startedAt,
    seconds,
    reciterId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListeningSessionRow &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.seconds == this.seconds &&
          other.reciterId == this.reciterId);
}

class ListeningSessionsCompanion extends UpdateCompanion<ListeningSessionRow> {
  final Value<String> uuid;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<int> seconds;
  final Value<int> reciterId;
  const ListeningSessionsCompanion({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.seconds = const Value.absent(),
    this.reciterId = const Value.absent(),
  });
  ListeningSessionsCompanion.insert({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    required DateTime startedAt,
    required int seconds,
    required int reciterId,
  }) : startedAt = Value(startedAt),
       seconds = Value(seconds),
       reciterId = Value(reciterId);
  static Insertable<ListeningSessionRow> custom({
    Expression<String>? uuid,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<int>? seconds,
    Expression<int>? reciterId,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (seconds != null) 'seconds': seconds,
      if (reciterId != null) 'reciter_id': reciterId,
    });
  }

  ListeningSessionsCompanion copyWith({
    Value<String>? uuid,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<int>? seconds,
    Value<int>? reciterId,
  }) {
    return ListeningSessionsCompanion(
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      seconds: seconds ?? this.seconds,
      reciterId: reciterId ?? this.reciterId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    if (reciterId.present) {
      map['reciter_id'] = Variable<int>(reciterId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListeningSessionsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('seconds: $seconds, ')
          ..write('reciterId: $reciterId')
          ..write(')'))
        .toString();
  }
}

class $ReflectionsTable extends Reflections
    with TableInfo<$ReflectionsTable, ReflectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReflectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: newUuid,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    updatedAt,
    deletedAt,
    id,
    surah,
    ayah,
    body,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reflection';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReflectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReflectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReflectionRow(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
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
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReflectionsTable createAlias(String alias) {
    return $ReflectionsTable(attachedDatabase, alias);
  }
}

class ReflectionRow extends DataClass implements Insertable<ReflectionRow> {
  final String uuid;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int id;
  final int surah;
  final int ayah;
  final String body;
  final DateTime createdAt;
  const ReflectionRow({
    required this.uuid,
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.surah,
    required this.ayah,
    required this.body,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<int>(id);
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['text'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReflectionsCompanion toCompanion(bool nullToAbsent) {
    return ReflectionsCompanion(
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      surah: Value(surah),
      ayah: Value(ayah),
      body: Value(body),
      createdAt: Value(createdAt),
    );
  }

  factory ReflectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReflectionRow(
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<int>(json['id']),
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<int>(id),
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReflectionRow copyWith({
    String? uuid,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? id,
    int? surah,
    int? ayah,
    String? body,
    DateTime? createdAt,
  }) => ReflectionRow(
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
  );
  ReflectionRow copyWithCompanion(ReflectionsCompanion data) {
    return ReflectionRow(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReflectionRow(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(uuid, updatedAt, deletedAt, id, surah, ayah, body, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReflectionRow &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.body == this.body &&
          other.createdAt == this.createdAt);
}

class ReflectionsCompanion extends UpdateCompanion<ReflectionRow> {
  final Value<String> uuid;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> id;
  final Value<int> surah;
  final Value<int> ayah;
  final Value<String> body;
  final Value<DateTime> createdAt;
  const ReflectionsCompanion({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReflectionsCompanion.insert({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    required int surah,
    required int ayah,
    required String body,
    this.createdAt = const Value.absent(),
  }) : surah = Value(surah),
       ayah = Value(ayah),
       body = Value(body);
  static Insertable<ReflectionRow> custom({
    Expression<String>? uuid,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? id,
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (body != null) 'text': body,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReflectionsCompanion copyWith({
    Value<String>? uuid,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? id,
    Value<int>? surah,
    Value<int>? ayah,
    Value<String>? body,
    Value<DateTime>? createdAt,
  }) {
    return ReflectionsCompanion(
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
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
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReflectionsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowUuidMeta = const VerificationMeta(
    'rowUuid',
  );
  @override
  late final GeneratedColumn<String> rowUuid = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entity,
    rowUuid,
    op,
    payload,
    createdAt,
  ];
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
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('table_name')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['table_name']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowUuidMeta,
        rowUuid.isAcceptableOrUnknown(data['row_id']!, _rowUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_rowUuidMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {entity, rowUuid},
  ];
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_name'],
      )!,
      rowUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final int id;
  final String entity;
  final String rowUuid;

  /// `upsert` or `delete`.
  final String op;

  /// The row as JSON.
  final String payload;
  final DateTime createdAt;
  const OutboxRow({
    required this.id,
    required this.entity,
    required this.rowUuid,
    required this.op,
    required this.payload,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['table_name'] = Variable<String>(entity);
    map['row_id'] = Variable<String>(rowUuid);
    map['op'] = Variable<String>(op);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      id: Value(id),
      entity: Value(entity),
      rowUuid: Value(rowUuid),
      op: Value(op),
      payload: Value(payload),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      id: serializer.fromJson<int>(json['id']),
      entity: serializer.fromJson<String>(json['entity']),
      rowUuid: serializer.fromJson<String>(json['rowUuid']),
      op: serializer.fromJson<String>(json['op']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entity': serializer.toJson<String>(entity),
      'rowUuid': serializer.toJson<String>(rowUuid),
      'op': serializer.toJson<String>(op),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxRow copyWith({
    int? id,
    String? entity,
    String? rowUuid,
    String? op,
    String? payload,
    DateTime? createdAt,
  }) => OutboxRow(
    id: id ?? this.id,
    entity: entity ?? this.entity,
    rowUuid: rowUuid ?? this.rowUuid,
    op: op ?? this.op,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxRow copyWithCompanion(OutboxCompanion data) {
    return OutboxRow(
      id: data.id.present ? data.id.value : this.id,
      entity: data.entity.present ? data.entity.value : this.entity,
      rowUuid: data.rowUuid.present ? data.rowUuid.value : this.rowUuid,
      op: data.op.present ? data.op.value : this.op,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('rowUuid: $rowUuid, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entity, rowUuid, op, payload, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.id == this.id &&
          other.entity == this.entity &&
          other.rowUuid == this.rowUuid &&
          other.op == this.op &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt);
}

class OutboxCompanion extends UpdateCompanion<OutboxRow> {
  final Value<int> id;
  final Value<String> entity;
  final Value<String> rowUuid;
  final Value<String> op;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  const OutboxCompanion({
    this.id = const Value.absent(),
    this.entity = const Value.absent(),
    this.rowUuid = const Value.absent(),
    this.op = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.id = const Value.absent(),
    required String entity,
    required String rowUuid,
    required String op,
    required String payload,
    this.createdAt = const Value.absent(),
  }) : entity = Value(entity),
       rowUuid = Value(rowUuid),
       op = Value(op),
       payload = Value(payload);
  static Insertable<OutboxRow> custom({
    Expression<int>? id,
    Expression<String>? entity,
    Expression<String>? rowUuid,
    Expression<String>? op,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entity != null) 'table_name': entity,
      if (rowUuid != null) 'row_id': rowUuid,
      if (op != null) 'op': op,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? id,
    Value<String>? entity,
    Value<String>? rowUuid,
    Value<String>? op,
    Value<String>? payload,
    Value<DateTime>? createdAt,
  }) {
    return OutboxCompanion(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      rowUuid: rowUuid ?? this.rowUuid,
      op: op ?? this.op,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entity.present) {
      map['table_name'] = Variable<String>(entity.value);
    }
    if (rowUuid.present) {
      map['row_id'] = Variable<String>(rowUuid.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('rowUuid: $rowUuid, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserDatabase extends GeneratedDatabase {
  _$UserDatabase(QueryExecutor e) : super(e);
  $UserDatabaseManager get managers => $UserDatabaseManager(this);
  late final $BookmarkSetsTable bookmarkSets = $BookmarkSetsTable(this);
  late final $ReadingPositionsTable readingPositions = $ReadingPositionsTable(
    this,
  );
  late final $KhatmasTable khatmas = $KhatmasTable(this);
  late final $KhatmaLogsTable khatmaLogs = $KhatmaLogsTable(this);
  late final $ReadingSessionsTable readingSessions = $ReadingSessionsTable(
    this,
  );
  late final $ListeningSessionsTable listeningSessions =
      $ListeningSessionsTable(this);
  late final $ReflectionsTable reflections = $ReflectionsTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    bookmarkSets,
    readingPositions,
    khatmas,
    khatmaLogs,
    readingSessions,
    listeningSessions,
    reflections,
    outbox,
  ];
}

typedef $$BookmarkSetsTableCreateCompanionBuilder =
    BookmarkSetsCompanion Function({
      Value<int> id,
      required String name,
      required int color,
      required int surah,
      required int ayah,
      required int page,
      Value<int> sortOrder,
      required DateTime updatedAt,
      Value<String?> kind,
    });
typedef $$BookmarkSetsTableUpdateCompanionBuilder =
    BookmarkSetsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> color,
      Value<int> surah,
      Value<int> ayah,
      Value<int> page,
      Value<int> sortOrder,
      Value<DateTime> updatedAt,
      Value<String?> kind,
    });

class $$BookmarkSetsTableFilterComposer
    extends Composer<_$UserDatabase, $BookmarkSetsTable> {
  $$BookmarkSetsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
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

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookmarkSetsTableOrderingComposer
    extends Composer<_$UserDatabase, $BookmarkSetsTable> {
  $$BookmarkSetsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
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

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookmarkSetsTableAnnotationComposer
    extends Composer<_$UserDatabase, $BookmarkSetsTable> {
  $$BookmarkSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);
}

class $$BookmarkSetsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $BookmarkSetsTable,
          BookmarkSetRow,
          $$BookmarkSetsTableFilterComposer,
          $$BookmarkSetsTableOrderingComposer,
          $$BookmarkSetsTableAnnotationComposer,
          $$BookmarkSetsTableCreateCompanionBuilder,
          $$BookmarkSetsTableUpdateCompanionBuilder,
          (
            BookmarkSetRow,
            BaseReferences<_$UserDatabase, $BookmarkSetsTable, BookmarkSetRow>,
          ),
          BookmarkSetRow,
          PrefetchHooks Function()
        > {
  $$BookmarkSetsTableTableManager(_$UserDatabase db, $BookmarkSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarkSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarkSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarkSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> kind = const Value.absent(),
              }) => BookmarkSetsCompanion(
                id: id,
                name: name,
                color: color,
                surah: surah,
                ayah: ayah,
                page: page,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                kind: kind,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int color,
                required int surah,
                required int ayah,
                required int page,
                Value<int> sortOrder = const Value.absent(),
                required DateTime updatedAt,
                Value<String?> kind = const Value.absent(),
              }) => BookmarkSetsCompanion.insert(
                id: id,
                name: name,
                color: color,
                surah: surah,
                ayah: ayah,
                page: page,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                kind: kind,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookmarkSetsTable, BookmarkSetRow>(table),
                  BaseReferences<
                    _$UserDatabase,
                    $BookmarkSetsTable,
                    BookmarkSetRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookmarkSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $BookmarkSetsTable,
      BookmarkSetRow,
      $$BookmarkSetsTableFilterComposer,
      $$BookmarkSetsTableOrderingComposer,
      $$BookmarkSetsTableAnnotationComposer,
      $$BookmarkSetsTableCreateCompanionBuilder,
      $$BookmarkSetsTableUpdateCompanionBuilder,
      (
        BookmarkSetRow,
        BaseReferences<_$UserDatabase, $BookmarkSetsTable, BookmarkSetRow>,
      ),
      BookmarkSetRow,
      PrefetchHooks Function()
    >;
typedef $$ReadingPositionsTableCreateCompanionBuilder =
    ReadingPositionsCompanion Function({
      Value<int> id,
      required String edition,
      required String view,
      required int surah,
      required int ayah,
      required int page,
      required DateTime updatedAt,
    });
typedef $$ReadingPositionsTableUpdateCompanionBuilder =
    ReadingPositionsCompanion Function({
      Value<int> id,
      Value<String> edition,
      Value<String> view,
      Value<int> surah,
      Value<int> ayah,
      Value<int> page,
      Value<DateTime> updatedAt,
    });

class $$ReadingPositionsTableFilterComposer
    extends Composer<_$UserDatabase, $ReadingPositionsTable> {
  $$ReadingPositionsTableFilterComposer({
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

  ColumnFilters<String> get edition => $composableBuilder(
    column: $table.edition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get view => $composableBuilder(
    column: $table.view,
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

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingPositionsTableOrderingComposer
    extends Composer<_$UserDatabase, $ReadingPositionsTable> {
  $$ReadingPositionsTableOrderingComposer({
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

  ColumnOrderings<String> get edition => $composableBuilder(
    column: $table.edition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get view => $composableBuilder(
    column: $table.view,
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

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingPositionsTableAnnotationComposer
    extends Composer<_$UserDatabase, $ReadingPositionsTable> {
  $$ReadingPositionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get edition =>
      $composableBuilder(column: $table.edition, builder: (column) => column);

  GeneratedColumn<String> get view =>
      $composableBuilder(column: $table.view, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReadingPositionsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $ReadingPositionsTable,
          ReadingPositionRow,
          $$ReadingPositionsTableFilterComposer,
          $$ReadingPositionsTableOrderingComposer,
          $$ReadingPositionsTableAnnotationComposer,
          $$ReadingPositionsTableCreateCompanionBuilder,
          $$ReadingPositionsTableUpdateCompanionBuilder,
          (
            ReadingPositionRow,
            BaseReferences<
              _$UserDatabase,
              $ReadingPositionsTable,
              ReadingPositionRow
            >,
          ),
          ReadingPositionRow,
          PrefetchHooks Function()
        > {
  $$ReadingPositionsTableTableManager(
    _$UserDatabase db,
    $ReadingPositionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingPositionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingPositionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingPositionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> edition = const Value.absent(),
                Value<String> view = const Value.absent(),
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ReadingPositionsCompanion(
                id: id,
                edition: edition,
                view: view,
                surah: surah,
                ayah: ayah,
                page: page,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String edition,
                required String view,
                required int surah,
                required int ayah,
                required int page,
                required DateTime updatedAt,
              }) => ReadingPositionsCompanion.insert(
                id: id,
                edition: edition,
                view: view,
                surah: surah,
                ayah: ayah,
                page: page,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingPositionsTable, ReadingPositionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$UserDatabase,
                    $ReadingPositionsTable,
                    ReadingPositionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingPositionsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $ReadingPositionsTable,
      ReadingPositionRow,
      $$ReadingPositionsTableFilterComposer,
      $$ReadingPositionsTableOrderingComposer,
      $$ReadingPositionsTableAnnotationComposer,
      $$ReadingPositionsTableCreateCompanionBuilder,
      $$ReadingPositionsTableUpdateCompanionBuilder,
      (
        ReadingPositionRow,
        BaseReferences<
          _$UserDatabase,
          $ReadingPositionsTable,
          ReadingPositionRow
        >,
      ),
      ReadingPositionRow,
      PrefetchHooks Function()
    >;
typedef $$KhatmasTableCreateCompanionBuilder = KhatmasCompanion Function({
  Value<String> uuid,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> id,
  required String title,
  required String edition,
  Value<String> unit,
  required String startDate,
  required String targetDate,
  Value<double?> dailyPortion,
  Value<int?> reminderTime,
  Value<String?> rebasedOn,
  Value<DateTime?> completedAt,
  Value<DateTime> createdAt,
});
typedef $$KhatmasTableUpdateCompanionBuilder = KhatmasCompanion Function({
  Value<String> uuid,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> id,
  Value<String> title,
  Value<String> edition,
  Value<String> unit,
  Value<String> startDate,
  Value<String> targetDate,
  Value<double?> dailyPortion,
  Value<int?> reminderTime,
  Value<String?> rebasedOn,
  Value<DateTime?> completedAt,
  Value<DateTime> createdAt,
});

class $$KhatmasTableFilterComposer
    extends Composer<_$UserDatabase, $KhatmasTable> {
  $$KhatmasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get edition => $composableBuilder(
    column: $table.edition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dailyPortion => $composableBuilder(
    column: $table.dailyPortion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rebasedOn => $composableBuilder(
    column: $table.rebasedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KhatmasTableOrderingComposer
    extends Composer<_$UserDatabase, $KhatmasTable> {
  $$KhatmasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get edition => $composableBuilder(
    column: $table.edition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dailyPortion => $composableBuilder(
    column: $table.dailyPortion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rebasedOn => $composableBuilder(
    column: $table.rebasedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KhatmasTableAnnotationComposer
    extends Composer<_$UserDatabase, $KhatmasTable> {
  $$KhatmasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get edition =>
      $composableBuilder(column: $table.edition, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dailyPortion => $composableBuilder(
    column: $table.dailyPortion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rebasedOn =>
      $composableBuilder(column: $table.rebasedOn, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$KhatmasTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $KhatmasTable,
          KhatmaRow,
          $$KhatmasTableFilterComposer,
          $$KhatmasTableOrderingComposer,
          $$KhatmasTableAnnotationComposer,
          $$KhatmasTableCreateCompanionBuilder,
          $$KhatmasTableUpdateCompanionBuilder,
          (KhatmaRow, BaseReferences<_$UserDatabase, $KhatmasTable, KhatmaRow>),
          KhatmaRow,
          PrefetchHooks Function()
        > {
  $$KhatmasTableTableManager(_$UserDatabase db, $KhatmasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KhatmasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KhatmasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KhatmasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> edition = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> targetDate = const Value.absent(),
                Value<double?> dailyPortion = const Value.absent(),
                Value<int?> reminderTime = const Value.absent(),
                Value<String?> rebasedOn = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => KhatmasCompanion(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                title: title,
                edition: edition,
                unit: unit,
                startDate: startDate,
                targetDate: targetDate,
                dailyPortion: dailyPortion,
                reminderTime: reminderTime,
                rebasedOn: rebasedOn,
                completedAt: completedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                required String title,
                required String edition,
                Value<String> unit = const Value.absent(),
                required String startDate,
                required String targetDate,
                Value<double?> dailyPortion = const Value.absent(),
                Value<int?> reminderTime = const Value.absent(),
                Value<String?> rebasedOn = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => KhatmasCompanion.insert(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                title: title,
                edition: edition,
                unit: unit,
                startDate: startDate,
                targetDate: targetDate,
                dailyPortion: dailyPortion,
                reminderTime: reminderTime,
                rebasedOn: rebasedOn,
                completedAt: completedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KhatmasTable, KhatmaRow>(table),
                  BaseReferences<_$UserDatabase, $KhatmasTable, KhatmaRow>(
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

typedef $$KhatmasTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $KhatmasTable,
      KhatmaRow,
      $$KhatmasTableFilterComposer,
      $$KhatmasTableOrderingComposer,
      $$KhatmasTableAnnotationComposer,
      $$KhatmasTableCreateCompanionBuilder,
      $$KhatmasTableUpdateCompanionBuilder,
      (KhatmaRow, BaseReferences<_$UserDatabase, $KhatmasTable, KhatmaRow>),
      KhatmaRow,
      PrefetchHooks Function()
    >;
typedef $$KhatmaLogsTableCreateCompanionBuilder = KhatmaLogsCompanion Function({
  Value<String> uuid,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> id,
  required String khatmaUuid,
  required String date,
  required int fromPage,
  required int toPage,
});
typedef $$KhatmaLogsTableUpdateCompanionBuilder = KhatmaLogsCompanion Function({
  Value<String> uuid,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> id,
  Value<String> khatmaUuid,
  Value<String> date,
  Value<int> fromPage,
  Value<int> toPage,
});

class $$KhatmaLogsTableFilterComposer
    extends Composer<_$UserDatabase, $KhatmaLogsTable> {
  $$KhatmaLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get khatmaUuid => $composableBuilder(
    column: $table.khatmaUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fromPage => $composableBuilder(
    column: $table.fromPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toPage => $composableBuilder(
    column: $table.toPage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KhatmaLogsTableOrderingComposer
    extends Composer<_$UserDatabase, $KhatmaLogsTable> {
  $$KhatmaLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get khatmaUuid => $composableBuilder(
    column: $table.khatmaUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fromPage => $composableBuilder(
    column: $table.fromPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toPage => $composableBuilder(
    column: $table.toPage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KhatmaLogsTableAnnotationComposer
    extends Composer<_$UserDatabase, $KhatmaLogsTable> {
  $$KhatmaLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get khatmaUuid => $composableBuilder(
    column: $table.khatmaUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get fromPage =>
      $composableBuilder(column: $table.fromPage, builder: (column) => column);

  GeneratedColumn<int> get toPage =>
      $composableBuilder(column: $table.toPage, builder: (column) => column);
}

class $$KhatmaLogsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $KhatmaLogsTable,
          KhatmaLogRow,
          $$KhatmaLogsTableFilterComposer,
          $$KhatmaLogsTableOrderingComposer,
          $$KhatmaLogsTableAnnotationComposer,
          $$KhatmaLogsTableCreateCompanionBuilder,
          $$KhatmaLogsTableUpdateCompanionBuilder,
          (
            KhatmaLogRow,
            BaseReferences<_$UserDatabase, $KhatmaLogsTable, KhatmaLogRow>,
          ),
          KhatmaLogRow,
          PrefetchHooks Function()
        > {
  $$KhatmaLogsTableTableManager(_$UserDatabase db, $KhatmaLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KhatmaLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KhatmaLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KhatmaLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<String> khatmaUuid = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> fromPage = const Value.absent(),
                Value<int> toPage = const Value.absent(),
              }) => KhatmaLogsCompanion(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                khatmaUuid: khatmaUuid,
                date: date,
                fromPage: fromPage,
                toPage: toPage,
              ),
          createCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                required String khatmaUuid,
                required String date,
                required int fromPage,
                required int toPage,
              }) => KhatmaLogsCompanion.insert(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                khatmaUuid: khatmaUuid,
                date: date,
                fromPage: fromPage,
                toPage: toPage,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KhatmaLogsTable, KhatmaLogRow>(table),
                  BaseReferences<
                    _$UserDatabase,
                    $KhatmaLogsTable,
                    KhatmaLogRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KhatmaLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $KhatmaLogsTable,
      KhatmaLogRow,
      $$KhatmaLogsTableFilterComposer,
      $$KhatmaLogsTableOrderingComposer,
      $$KhatmaLogsTableAnnotationComposer,
      $$KhatmaLogsTableCreateCompanionBuilder,
      $$KhatmaLogsTableUpdateCompanionBuilder,
      (
        KhatmaLogRow,
        BaseReferences<_$UserDatabase, $KhatmaLogsTable, KhatmaLogRow>,
      ),
      KhatmaLogRow,
      PrefetchHooks Function()
    >;
typedef $$ReadingSessionsTableCreateCompanionBuilder =
    ReadingSessionsCompanion Function({
      Value<String> uuid,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> id,
      required DateTime startedAt,
      required DateTime endedAt,
      required int pages,
      Value<String> mode,
      Value<String?> edition,
    });
typedef $$ReadingSessionsTableUpdateCompanionBuilder =
    ReadingSessionsCompanion Function({
      Value<String> uuid,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> id,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
      Value<int> pages,
      Value<String> mode,
      Value<String?> edition,
    });

class $$ReadingSessionsTableFilterComposer
    extends Composer<_$UserDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pages => $composableBuilder(
    column: $table.pages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get edition => $composableBuilder(
    column: $table.edition,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingSessionsTableOrderingComposer
    extends Composer<_$UserDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pages => $composableBuilder(
    column: $table.pages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get edition => $composableBuilder(
    column: $table.edition,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingSessionsTableAnnotationComposer
    extends Composer<_$UserDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get pages =>
      $composableBuilder(column: $table.pages, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get edition =>
      $composableBuilder(column: $table.edition, builder: (column) => column);
}

class $$ReadingSessionsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $ReadingSessionsTable,
          ReadingSessionRow,
          $$ReadingSessionsTableFilterComposer,
          $$ReadingSessionsTableOrderingComposer,
          $$ReadingSessionsTableAnnotationComposer,
          $$ReadingSessionsTableCreateCompanionBuilder,
          $$ReadingSessionsTableUpdateCompanionBuilder,
          (
            ReadingSessionRow,
            BaseReferences<
              _$UserDatabase,
              $ReadingSessionsTable,
              ReadingSessionRow
            >,
          ),
          ReadingSessionRow,
          PrefetchHooks Function()
        > {
  $$ReadingSessionsTableTableManager(
    _$UserDatabase db,
    $ReadingSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<int> pages = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String?> edition = const Value.absent(),
              }) => ReadingSessionsCompanion(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                pages: pages,
                mode: mode,
                edition: edition,
              ),
          createCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                required DateTime endedAt,
                required int pages,
                Value<String> mode = const Value.absent(),
                Value<String?> edition = const Value.absent(),
              }) => ReadingSessionsCompanion.insert(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                pages: pages,
                mode: mode,
                edition: edition,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingSessionsTable, ReadingSessionRow>(table),
                  BaseReferences<
                    _$UserDatabase,
                    $ReadingSessionsTable,
                    ReadingSessionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $ReadingSessionsTable,
      ReadingSessionRow,
      $$ReadingSessionsTableFilterComposer,
      $$ReadingSessionsTableOrderingComposer,
      $$ReadingSessionsTableAnnotationComposer,
      $$ReadingSessionsTableCreateCompanionBuilder,
      $$ReadingSessionsTableUpdateCompanionBuilder,
      (
        ReadingSessionRow,
        BaseReferences<
          _$UserDatabase,
          $ReadingSessionsTable,
          ReadingSessionRow
        >,
      ),
      ReadingSessionRow,
      PrefetchHooks Function()
    >;
typedef $$ListeningSessionsTableCreateCompanionBuilder =
    ListeningSessionsCompanion Function({
      Value<String> uuid,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> id,
      required DateTime startedAt,
      required int seconds,
      required int reciterId,
    });
typedef $$ListeningSessionsTableUpdateCompanionBuilder =
    ListeningSessionsCompanion Function({
      Value<String> uuid,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> id,
      Value<DateTime> startedAt,
      Value<int> seconds,
      Value<int> reciterId,
    });

class $$ListeningSessionsTableFilterComposer
    extends Composer<_$UserDatabase, $ListeningSessionsTable> {
  $$ListeningSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reciterId => $composableBuilder(
    column: $table.reciterId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ListeningSessionsTableOrderingComposer
    extends Composer<_$UserDatabase, $ListeningSessionsTable> {
  $$ListeningSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reciterId => $composableBuilder(
    column: $table.reciterId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ListeningSessionsTableAnnotationComposer
    extends Composer<_$UserDatabase, $ListeningSessionsTable> {
  $$ListeningSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);

  GeneratedColumn<int> get reciterId =>
      $composableBuilder(column: $table.reciterId, builder: (column) => column);
}

class $$ListeningSessionsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $ListeningSessionsTable,
          ListeningSessionRow,
          $$ListeningSessionsTableFilterComposer,
          $$ListeningSessionsTableOrderingComposer,
          $$ListeningSessionsTableAnnotationComposer,
          $$ListeningSessionsTableCreateCompanionBuilder,
          $$ListeningSessionsTableUpdateCompanionBuilder,
          (
            ListeningSessionRow,
            BaseReferences<
              _$UserDatabase,
              $ListeningSessionsTable,
              ListeningSessionRow
            >,
          ),
          ListeningSessionRow,
          PrefetchHooks Function()
        > {
  $$ListeningSessionsTableTableManager(
    _$UserDatabase db,
    $ListeningSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListeningSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListeningSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListeningSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> seconds = const Value.absent(),
                Value<int> reciterId = const Value.absent(),
              }) => ListeningSessionsCompanion(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                startedAt: startedAt,
                seconds: seconds,
                reciterId: reciterId,
              ),
          createCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                required int seconds,
                required int reciterId,
              }) => ListeningSessionsCompanion.insert(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                startedAt: startedAt,
                seconds: seconds,
                reciterId: reciterId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ListeningSessionsTable, ListeningSessionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$UserDatabase,
                    $ListeningSessionsTable,
                    ListeningSessionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ListeningSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $ListeningSessionsTable,
      ListeningSessionRow,
      $$ListeningSessionsTableFilterComposer,
      $$ListeningSessionsTableOrderingComposer,
      $$ListeningSessionsTableAnnotationComposer,
      $$ListeningSessionsTableCreateCompanionBuilder,
      $$ListeningSessionsTableUpdateCompanionBuilder,
      (
        ListeningSessionRow,
        BaseReferences<
          _$UserDatabase,
          $ListeningSessionsTable,
          ListeningSessionRow
        >,
      ),
      ListeningSessionRow,
      PrefetchHooks Function()
    >;
typedef $$ReflectionsTableCreateCompanionBuilder =
    ReflectionsCompanion Function({
      Value<String> uuid,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> id,
      required int surah,
      required int ayah,
      required String body,
      Value<DateTime> createdAt,
    });
typedef $$ReflectionsTableUpdateCompanionBuilder =
    ReflectionsCompanion Function({
      Value<String> uuid,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> id,
      Value<int> surah,
      Value<int> ayah,
      Value<String> body,
      Value<DateTime> createdAt,
    });

class $$ReflectionsTableFilterComposer
    extends Composer<_$UserDatabase, $ReflectionsTable> {
  $$ReflectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReflectionsTableOrderingComposer
    extends Composer<_$UserDatabase, $ReflectionsTable> {
  $$ReflectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReflectionsTableAnnotationComposer
    extends Composer<_$UserDatabase, $ReflectionsTable> {
  $$ReflectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReflectionsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $ReflectionsTable,
          ReflectionRow,
          $$ReflectionsTableFilterComposer,
          $$ReflectionsTableOrderingComposer,
          $$ReflectionsTableAnnotationComposer,
          $$ReflectionsTableCreateCompanionBuilder,
          $$ReflectionsTableUpdateCompanionBuilder,
          (
            ReflectionRow,
            BaseReferences<_$UserDatabase, $ReflectionsTable, ReflectionRow>,
          ),
          ReflectionRow,
          PrefetchHooks Function()
        > {
  $$ReflectionsTableTableManager(_$UserDatabase db, $ReflectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReflectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReflectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReflectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReflectionsCompanion(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                surah: surah,
                ayah: ayah,
                body: body,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                required int surah,
                required int ayah,
                required String body,
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReflectionsCompanion.insert(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                surah: surah,
                ayah: ayah,
                body: body,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReflectionsTable, ReflectionRow>(table),
                  BaseReferences<
                    _$UserDatabase,
                    $ReflectionsTable,
                    ReflectionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReflectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $ReflectionsTable,
      ReflectionRow,
      $$ReflectionsTableFilterComposer,
      $$ReflectionsTableOrderingComposer,
      $$ReflectionsTableAnnotationComposer,
      $$ReflectionsTableCreateCompanionBuilder,
      $$ReflectionsTableUpdateCompanionBuilder,
      (
        ReflectionRow,
        BaseReferences<_$UserDatabase, $ReflectionsTable, ReflectionRow>,
      ),
      ReflectionRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  Value<int> id,
  required String entity,
  required String rowUuid,
  required String op,
  required String payload,
  Value<DateTime> createdAt,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<int> id,
  Value<String> entity,
  Value<String> rowUuid,
  Value<String> op,
  Value<String> payload,
  Value<DateTime> createdAt,
});

class $$OutboxTableFilterComposer
    extends Composer<_$UserDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
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

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowUuid => $composableBuilder(
    column: $table.rowUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$UserDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
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

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowUuid => $composableBuilder(
    column: $table.rowUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$UserDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get rowUuid =>
      $composableBuilder(column: $table.rowUuid, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $OutboxTable,
          OutboxRow,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxRow, BaseReferences<_$UserDatabase, $OutboxTable, OutboxRow>),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$UserDatabase db, $OutboxTable table)
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
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> rowUuid = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OutboxCompanion(
                id: id,
                entity: entity,
                rowUuid: rowUuid,
                op: op,
                payload: payload,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entity,
                required String rowUuid,
                required String op,
                required String payload,
                Value<DateTime> createdAt = const Value.absent(),
              }) => OutboxCompanion.insert(
                id: id,
                entity: entity,
                rowUuid: rowUuid,
                op: op,
                payload: payload,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxRow>(table),
                  BaseReferences<_$UserDatabase, $OutboxTable, OutboxRow>(
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
      _$UserDatabase,
      $OutboxTable,
      OutboxRow,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$UserDatabase, $OutboxTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;

class $UserDatabaseManager {
  final _$UserDatabase _db;
  $UserDatabaseManager(this._db);
  $$BookmarkSetsTableTableManager get bookmarkSets =>
      $$BookmarkSetsTableTableManager(_db, _db.bookmarkSets);
  $$ReadingPositionsTableTableManager get readingPositions =>
      $$ReadingPositionsTableTableManager(_db, _db.readingPositions);
  $$KhatmasTableTableManager get khatmas =>
      $$KhatmasTableTableManager(_db, _db.khatmas);
  $$KhatmaLogsTableTableManager get khatmaLogs =>
      $$KhatmaLogsTableTableManager(_db, _db.khatmaLogs);
  $$ReadingSessionsTableTableManager get readingSessions =>
      $$ReadingSessionsTableTableManager(_db, _db.readingSessions);
  $$ListeningSessionsTableTableManager get listeningSessions =>
      $$ListeningSessionsTableTableManager(_db, _db.listeningSessions);
  $$ReflectionsTableTableManager get reflections =>
      $$ReflectionsTableTableManager(_db, _db.reflections);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
}
