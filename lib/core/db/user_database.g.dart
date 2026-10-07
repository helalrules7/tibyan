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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('fullQuran'),
  );
  static const VerificationMeta _rangeStartMeta = const VerificationMeta(
    'rangeStart',
  );
  @override
  late final GeneratedColumn<int> rangeStart = GeneratedColumn<int>(
    'range_start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rangeEndMeta = const VerificationMeta(
    'rangeEnd',
  );
  @override
  late final GeneratedColumn<int> rangeEnd = GeneratedColumn<int>(
    'range_end',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<int> startAt = GeneratedColumn<int>(
    'start_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pacingModeMeta = const VerificationMeta(
    'pacingMode',
  );
  @override
  late final GeneratedColumn<String> pacingMode = GeneratedColumn<String>(
    'pacing_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('endDate'),
  );
  static const VerificationMeta _scheduleModeMeta = const VerificationMeta(
    'scheduleMode',
  );
  @override
  late final GeneratedColumn<String> scheduleMode = GeneratedColumn<String>(
    'schedule_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('adaptive'),
  );
  static const VerificationMeta _dailyWeightMeta = const VerificationMeta(
    'dailyWeight',
  );
  @override
  late final GeneratedColumn<double> dailyWeight = GeneratedColumn<double>(
    'daily_weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restWeekdaysMeta = const VerificationMeta(
    'restWeekdays',
  );
  @override
  late final GeneratedColumn<String> restWeekdays = GeneratedColumn<String>(
    'rest_weekdays',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _countingModeMeta = const VerificationMeta(
    'countingMode',
  );
  @override
  late final GeneratedColumn<String> countingMode = GeneratedColumn<String>(
    'counting_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('auto'),
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _autoRestartMeta = const VerificationMeta(
    'autoRestart',
  );
  @override
  late final GeneratedColumn<bool> autoRestart = GeneratedColumn<bool>(
    'auto_restart',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_restart" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _presetIdMeta = const VerificationMeta(
    'presetId',
  );
  @override
  late final GeneratedColumn<String> presetId = GeneratedColumn<String>(
    'preset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aheadChoiceMeta = const VerificationMeta(
    'aheadChoice',
  );
  @override
  late final GeneratedColumn<String> aheadChoice = GeneratedColumn<String>(
    'ahead_choice',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderKindsMeta = const VerificationMeta(
    'reminderKinds',
  );
  @override
  late final GeneratedColumn<String> reminderKinds = GeneratedColumn<String>(
    'reminder_kinds',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _recoveryMeta = const VerificationMeta(
    'recovery',
  );
  @override
  late final GeneratedColumn<String> recovery = GeneratedColumn<String>(
    'recovery',
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
    kind,
    rangeStart,
    rangeEnd,
    startAt,
    pacingMode,
    scheduleMode,
    dailyWeight,
    restWeekdays,
    countingMode,
    isPrimary,
    status,
    autoRestart,
    presetId,
    aheadChoice,
    reminderKinds,
    recovery,
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
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('range_start')) {
      context.handle(
        _rangeStartMeta,
        rangeStart.isAcceptableOrUnknown(data['range_start']!, _rangeStartMeta),
      );
    }
    if (data.containsKey('range_end')) {
      context.handle(
        _rangeEndMeta,
        rangeEnd.isAcceptableOrUnknown(data['range_end']!, _rangeEndMeta),
      );
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    }
    if (data.containsKey('pacing_mode')) {
      context.handle(
        _pacingModeMeta,
        pacingMode.isAcceptableOrUnknown(data['pacing_mode']!, _pacingModeMeta),
      );
    }
    if (data.containsKey('schedule_mode')) {
      context.handle(
        _scheduleModeMeta,
        scheduleMode.isAcceptableOrUnknown(
          data['schedule_mode']!,
          _scheduleModeMeta,
        ),
      );
    }
    if (data.containsKey('daily_weight')) {
      context.handle(
        _dailyWeightMeta,
        dailyWeight.isAcceptableOrUnknown(
          data['daily_weight']!,
          _dailyWeightMeta,
        ),
      );
    }
    if (data.containsKey('rest_weekdays')) {
      context.handle(
        _restWeekdaysMeta,
        restWeekdays.isAcceptableOrUnknown(
          data['rest_weekdays']!,
          _restWeekdaysMeta,
        ),
      );
    }
    if (data.containsKey('counting_mode')) {
      context.handle(
        _countingModeMeta,
        countingMode.isAcceptableOrUnknown(
          data['counting_mode']!,
          _countingModeMeta,
        ),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('auto_restart')) {
      context.handle(
        _autoRestartMeta,
        autoRestart.isAcceptableOrUnknown(
          data['auto_restart']!,
          _autoRestartMeta,
        ),
      );
    }
    if (data.containsKey('preset_id')) {
      context.handle(
        _presetIdMeta,
        presetId.isAcceptableOrUnknown(data['preset_id']!, _presetIdMeta),
      );
    }
    if (data.containsKey('ahead_choice')) {
      context.handle(
        _aheadChoiceMeta,
        aheadChoice.isAcceptableOrUnknown(
          data['ahead_choice']!,
          _aheadChoiceMeta,
        ),
      );
    }
    if (data.containsKey('reminder_kinds')) {
      context.handle(
        _reminderKindsMeta,
        reminderKinds.isAcceptableOrUnknown(
          data['reminder_kinds']!,
          _reminderKindsMeta,
        ),
      );
    }
    if (data.containsKey('recovery')) {
      context.handle(
        _recoveryMeta,
        recovery.isAcceptableOrUnknown(data['recovery']!, _recoveryMeta),
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
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      rangeStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}range_start'],
      ),
      rangeEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}range_end'],
      ),
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_at'],
      ),
      pacingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pacing_mode'],
      )!,
      scheduleMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_mode'],
      )!,
      dailyWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}daily_weight'],
      ),
      restWeekdays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rest_weekdays'],
      )!,
      countingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counting_mode'],
      )!,
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      autoRestart: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_restart'],
      )!,
      presetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preset_id'],
      ),
      aheadChoice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ahead_choice'],
      ),
      reminderKinds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_kinds'],
      )!,
      recovery: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recovery'],
      ),
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
  /// Since v5 the day the plan's pace is counted from.
  final String? rebasedOn;
  final DateTime? completedAt;
  final DateTime createdAt;

  /// `fullQuran`, `partial`, `dailyWird` or `custom`.
  final String kind;

  /// The verses of the khatma (`ayah.id`), and where reading starts.
  final int? rangeStart;
  final int? rangeEnd;
  final int? startAt;

  /// `duration`, `endDate`, `dailyAmount` or `openEnded`.
  final String pacingMode;

  /// `adaptive` or `fixed`.
  final String scheduleMode;

  /// The planned amount a day, in Madina pages (verse weights).
  final double? dailyWeight;

  /// Rest weekdays (`DateTime.weekday`, 1 = Monday), comma separated:
  /// `5` for Friday.
  final String restWeekdays;

  /// `auto`, `ask` or `manual`.
  final String countingMode;
  final bool isPrimary;

  /// `active`, `paused`, `completed` or `cancelled`. Replaces reading it
  /// from [completedAt] and `deletedAt`, which are still written.
  final String status;
  final bool autoRestart;

  /// The preset it was made from (`ramadan_30`…).
  final String? presetId;

  /// The answer to «finish early, or a lighter portion?»: null (not asked
  /// yet), `finishEarly` or `lighter`.
  final String? aheadChoice;

  /// Notification kinds on for this khatma, comma separated.
  final String reminderKinds;

  /// A catch-up the reader chose (JSON), or null.
  final String? recovery;
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
    required this.kind,
    this.rangeStart,
    this.rangeEnd,
    this.startAt,
    required this.pacingMode,
    required this.scheduleMode,
    this.dailyWeight,
    required this.restWeekdays,
    required this.countingMode,
    required this.isPrimary,
    required this.status,
    required this.autoRestart,
    this.presetId,
    this.aheadChoice,
    required this.reminderKinds,
    this.recovery,
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
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || rangeStart != null) {
      map['range_start'] = Variable<int>(rangeStart);
    }
    if (!nullToAbsent || rangeEnd != null) {
      map['range_end'] = Variable<int>(rangeEnd);
    }
    if (!nullToAbsent || startAt != null) {
      map['start_at'] = Variable<int>(startAt);
    }
    map['pacing_mode'] = Variable<String>(pacingMode);
    map['schedule_mode'] = Variable<String>(scheduleMode);
    if (!nullToAbsent || dailyWeight != null) {
      map['daily_weight'] = Variable<double>(dailyWeight);
    }
    map['rest_weekdays'] = Variable<String>(restWeekdays);
    map['counting_mode'] = Variable<String>(countingMode);
    map['is_primary'] = Variable<bool>(isPrimary);
    map['status'] = Variable<String>(status);
    map['auto_restart'] = Variable<bool>(autoRestart);
    if (!nullToAbsent || presetId != null) {
      map['preset_id'] = Variable<String>(presetId);
    }
    if (!nullToAbsent || aheadChoice != null) {
      map['ahead_choice'] = Variable<String>(aheadChoice);
    }
    map['reminder_kinds'] = Variable<String>(reminderKinds);
    if (!nullToAbsent || recovery != null) {
      map['recovery'] = Variable<String>(recovery);
    }
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
      kind: Value(kind),
      rangeStart: rangeStart == null && nullToAbsent
          ? const Value.absent()
          : Value(rangeStart),
      rangeEnd: rangeEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(rangeEnd),
      startAt: startAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startAt),
      pacingMode: Value(pacingMode),
      scheduleMode: Value(scheduleMode),
      dailyWeight: dailyWeight == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyWeight),
      restWeekdays: Value(restWeekdays),
      countingMode: Value(countingMode),
      isPrimary: Value(isPrimary),
      status: Value(status),
      autoRestart: Value(autoRestart),
      presetId: presetId == null && nullToAbsent
          ? const Value.absent()
          : Value(presetId),
      aheadChoice: aheadChoice == null && nullToAbsent
          ? const Value.absent()
          : Value(aheadChoice),
      reminderKinds: Value(reminderKinds),
      recovery: recovery == null && nullToAbsent
          ? const Value.absent()
          : Value(recovery),
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
      kind: serializer.fromJson<String>(json['kind']),
      rangeStart: serializer.fromJson<int?>(json['rangeStart']),
      rangeEnd: serializer.fromJson<int?>(json['rangeEnd']),
      startAt: serializer.fromJson<int?>(json['startAt']),
      pacingMode: serializer.fromJson<String>(json['pacingMode']),
      scheduleMode: serializer.fromJson<String>(json['scheduleMode']),
      dailyWeight: serializer.fromJson<double?>(json['dailyWeight']),
      restWeekdays: serializer.fromJson<String>(json['restWeekdays']),
      countingMode: serializer.fromJson<String>(json['countingMode']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      status: serializer.fromJson<String>(json['status']),
      autoRestart: serializer.fromJson<bool>(json['autoRestart']),
      presetId: serializer.fromJson<String?>(json['presetId']),
      aheadChoice: serializer.fromJson<String?>(json['aheadChoice']),
      reminderKinds: serializer.fromJson<String>(json['reminderKinds']),
      recovery: serializer.fromJson<String?>(json['recovery']),
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
      'kind': serializer.toJson<String>(kind),
      'rangeStart': serializer.toJson<int?>(rangeStart),
      'rangeEnd': serializer.toJson<int?>(rangeEnd),
      'startAt': serializer.toJson<int?>(startAt),
      'pacingMode': serializer.toJson<String>(pacingMode),
      'scheduleMode': serializer.toJson<String>(scheduleMode),
      'dailyWeight': serializer.toJson<double?>(dailyWeight),
      'restWeekdays': serializer.toJson<String>(restWeekdays),
      'countingMode': serializer.toJson<String>(countingMode),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'status': serializer.toJson<String>(status),
      'autoRestart': serializer.toJson<bool>(autoRestart),
      'presetId': serializer.toJson<String?>(presetId),
      'aheadChoice': serializer.toJson<String?>(aheadChoice),
      'reminderKinds': serializer.toJson<String>(reminderKinds),
      'recovery': serializer.toJson<String?>(recovery),
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
    String? kind,
    Value<int?> rangeStart = const Value.absent(),
    Value<int?> rangeEnd = const Value.absent(),
    Value<int?> startAt = const Value.absent(),
    String? pacingMode,
    String? scheduleMode,
    Value<double?> dailyWeight = const Value.absent(),
    String? restWeekdays,
    String? countingMode,
    bool? isPrimary,
    String? status,
    bool? autoRestart,
    Value<String?> presetId = const Value.absent(),
    Value<String?> aheadChoice = const Value.absent(),
    String? reminderKinds,
    Value<String?> recovery = const Value.absent(),
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
    kind: kind ?? this.kind,
    rangeStart: rangeStart.present ? rangeStart.value : this.rangeStart,
    rangeEnd: rangeEnd.present ? rangeEnd.value : this.rangeEnd,
    startAt: startAt.present ? startAt.value : this.startAt,
    pacingMode: pacingMode ?? this.pacingMode,
    scheduleMode: scheduleMode ?? this.scheduleMode,
    dailyWeight: dailyWeight.present ? dailyWeight.value : this.dailyWeight,
    restWeekdays: restWeekdays ?? this.restWeekdays,
    countingMode: countingMode ?? this.countingMode,
    isPrimary: isPrimary ?? this.isPrimary,
    status: status ?? this.status,
    autoRestart: autoRestart ?? this.autoRestart,
    presetId: presetId.present ? presetId.value : this.presetId,
    aheadChoice: aheadChoice.present ? aheadChoice.value : this.aheadChoice,
    reminderKinds: reminderKinds ?? this.reminderKinds,
    recovery: recovery.present ? recovery.value : this.recovery,
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
      kind: data.kind.present ? data.kind.value : this.kind,
      rangeStart: data.rangeStart.present
          ? data.rangeStart.value
          : this.rangeStart,
      rangeEnd: data.rangeEnd.present ? data.rangeEnd.value : this.rangeEnd,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      pacingMode: data.pacingMode.present
          ? data.pacingMode.value
          : this.pacingMode,
      scheduleMode: data.scheduleMode.present
          ? data.scheduleMode.value
          : this.scheduleMode,
      dailyWeight: data.dailyWeight.present
          ? data.dailyWeight.value
          : this.dailyWeight,
      restWeekdays: data.restWeekdays.present
          ? data.restWeekdays.value
          : this.restWeekdays,
      countingMode: data.countingMode.present
          ? data.countingMode.value
          : this.countingMode,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      status: data.status.present ? data.status.value : this.status,
      autoRestart: data.autoRestart.present
          ? data.autoRestart.value
          : this.autoRestart,
      presetId: data.presetId.present ? data.presetId.value : this.presetId,
      aheadChoice: data.aheadChoice.present
          ? data.aheadChoice.value
          : this.aheadChoice,
      reminderKinds: data.reminderKinds.present
          ? data.reminderKinds.value
          : this.reminderKinds,
      recovery: data.recovery.present ? data.recovery.value : this.recovery,
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
          ..write('createdAt: $createdAt, ')
          ..write('kind: $kind, ')
          ..write('rangeStart: $rangeStart, ')
          ..write('rangeEnd: $rangeEnd, ')
          ..write('startAt: $startAt, ')
          ..write('pacingMode: $pacingMode, ')
          ..write('scheduleMode: $scheduleMode, ')
          ..write('dailyWeight: $dailyWeight, ')
          ..write('restWeekdays: $restWeekdays, ')
          ..write('countingMode: $countingMode, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('status: $status, ')
          ..write('autoRestart: $autoRestart, ')
          ..write('presetId: $presetId, ')
          ..write('aheadChoice: $aheadChoice, ')
          ..write('reminderKinds: $reminderKinds, ')
          ..write('recovery: $recovery')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
    kind,
    rangeStart,
    rangeEnd,
    startAt,
    pacingMode,
    scheduleMode,
    dailyWeight,
    restWeekdays,
    countingMode,
    isPrimary,
    status,
    autoRestart,
    presetId,
    aheadChoice,
    reminderKinds,
    recovery,
  ]);
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
          other.createdAt == this.createdAt &&
          other.kind == this.kind &&
          other.rangeStart == this.rangeStart &&
          other.rangeEnd == this.rangeEnd &&
          other.startAt == this.startAt &&
          other.pacingMode == this.pacingMode &&
          other.scheduleMode == this.scheduleMode &&
          other.dailyWeight == this.dailyWeight &&
          other.restWeekdays == this.restWeekdays &&
          other.countingMode == this.countingMode &&
          other.isPrimary == this.isPrimary &&
          other.status == this.status &&
          other.autoRestart == this.autoRestart &&
          other.presetId == this.presetId &&
          other.aheadChoice == this.aheadChoice &&
          other.reminderKinds == this.reminderKinds &&
          other.recovery == this.recovery);
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
  final Value<String> kind;
  final Value<int?> rangeStart;
  final Value<int?> rangeEnd;
  final Value<int?> startAt;
  final Value<String> pacingMode;
  final Value<String> scheduleMode;
  final Value<double?> dailyWeight;
  final Value<String> restWeekdays;
  final Value<String> countingMode;
  final Value<bool> isPrimary;
  final Value<String> status;
  final Value<bool> autoRestart;
  final Value<String?> presetId;
  final Value<String?> aheadChoice;
  final Value<String> reminderKinds;
  final Value<String?> recovery;
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
    this.kind = const Value.absent(),
    this.rangeStart = const Value.absent(),
    this.rangeEnd = const Value.absent(),
    this.startAt = const Value.absent(),
    this.pacingMode = const Value.absent(),
    this.scheduleMode = const Value.absent(),
    this.dailyWeight = const Value.absent(),
    this.restWeekdays = const Value.absent(),
    this.countingMode = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.status = const Value.absent(),
    this.autoRestart = const Value.absent(),
    this.presetId = const Value.absent(),
    this.aheadChoice = const Value.absent(),
    this.reminderKinds = const Value.absent(),
    this.recovery = const Value.absent(),
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
    this.kind = const Value.absent(),
    this.rangeStart = const Value.absent(),
    this.rangeEnd = const Value.absent(),
    this.startAt = const Value.absent(),
    this.pacingMode = const Value.absent(),
    this.scheduleMode = const Value.absent(),
    this.dailyWeight = const Value.absent(),
    this.restWeekdays = const Value.absent(),
    this.countingMode = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.status = const Value.absent(),
    this.autoRestart = const Value.absent(),
    this.presetId = const Value.absent(),
    this.aheadChoice = const Value.absent(),
    this.reminderKinds = const Value.absent(),
    this.recovery = const Value.absent(),
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
    Expression<String>? kind,
    Expression<int>? rangeStart,
    Expression<int>? rangeEnd,
    Expression<int>? startAt,
    Expression<String>? pacingMode,
    Expression<String>? scheduleMode,
    Expression<double>? dailyWeight,
    Expression<String>? restWeekdays,
    Expression<String>? countingMode,
    Expression<bool>? isPrimary,
    Expression<String>? status,
    Expression<bool>? autoRestart,
    Expression<String>? presetId,
    Expression<String>? aheadChoice,
    Expression<String>? reminderKinds,
    Expression<String>? recovery,
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
      if (kind != null) 'kind': kind,
      if (rangeStart != null) 'range_start': rangeStart,
      if (rangeEnd != null) 'range_end': rangeEnd,
      if (startAt != null) 'start_at': startAt,
      if (pacingMode != null) 'pacing_mode': pacingMode,
      if (scheduleMode != null) 'schedule_mode': scheduleMode,
      if (dailyWeight != null) 'daily_weight': dailyWeight,
      if (restWeekdays != null) 'rest_weekdays': restWeekdays,
      if (countingMode != null) 'counting_mode': countingMode,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (status != null) 'status': status,
      if (autoRestart != null) 'auto_restart': autoRestart,
      if (presetId != null) 'preset_id': presetId,
      if (aheadChoice != null) 'ahead_choice': aheadChoice,
      if (reminderKinds != null) 'reminder_kinds': reminderKinds,
      if (recovery != null) 'recovery': recovery,
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
    Value<String>? kind,
    Value<int?>? rangeStart,
    Value<int?>? rangeEnd,
    Value<int?>? startAt,
    Value<String>? pacingMode,
    Value<String>? scheduleMode,
    Value<double?>? dailyWeight,
    Value<String>? restWeekdays,
    Value<String>? countingMode,
    Value<bool>? isPrimary,
    Value<String>? status,
    Value<bool>? autoRestart,
    Value<String?>? presetId,
    Value<String?>? aheadChoice,
    Value<String>? reminderKinds,
    Value<String?>? recovery,
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
      kind: kind ?? this.kind,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      startAt: startAt ?? this.startAt,
      pacingMode: pacingMode ?? this.pacingMode,
      scheduleMode: scheduleMode ?? this.scheduleMode,
      dailyWeight: dailyWeight ?? this.dailyWeight,
      restWeekdays: restWeekdays ?? this.restWeekdays,
      countingMode: countingMode ?? this.countingMode,
      isPrimary: isPrimary ?? this.isPrimary,
      status: status ?? this.status,
      autoRestart: autoRestart ?? this.autoRestart,
      presetId: presetId ?? this.presetId,
      aheadChoice: aheadChoice ?? this.aheadChoice,
      reminderKinds: reminderKinds ?? this.reminderKinds,
      recovery: recovery ?? this.recovery,
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
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rangeStart.present) {
      map['range_start'] = Variable<int>(rangeStart.value);
    }
    if (rangeEnd.present) {
      map['range_end'] = Variable<int>(rangeEnd.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<int>(startAt.value);
    }
    if (pacingMode.present) {
      map['pacing_mode'] = Variable<String>(pacingMode.value);
    }
    if (scheduleMode.present) {
      map['schedule_mode'] = Variable<String>(scheduleMode.value);
    }
    if (dailyWeight.present) {
      map['daily_weight'] = Variable<double>(dailyWeight.value);
    }
    if (restWeekdays.present) {
      map['rest_weekdays'] = Variable<String>(restWeekdays.value);
    }
    if (countingMode.present) {
      map['counting_mode'] = Variable<String>(countingMode.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (autoRestart.present) {
      map['auto_restart'] = Variable<bool>(autoRestart.value);
    }
    if (presetId.present) {
      map['preset_id'] = Variable<String>(presetId.value);
    }
    if (aheadChoice.present) {
      map['ahead_choice'] = Variable<String>(aheadChoice.value);
    }
    if (reminderKinds.present) {
      map['reminder_kinds'] = Variable<String>(reminderKinds.value);
    }
    if (recovery.present) {
      map['recovery'] = Variable<String>(recovery.value);
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
          ..write('createdAt: $createdAt, ')
          ..write('kind: $kind, ')
          ..write('rangeStart: $rangeStart, ')
          ..write('rangeEnd: $rangeEnd, ')
          ..write('startAt: $startAt, ')
          ..write('pacingMode: $pacingMode, ')
          ..write('scheduleMode: $scheduleMode, ')
          ..write('dailyWeight: $dailyWeight, ')
          ..write('restWeekdays: $restWeekdays, ')
          ..write('countingMode: $countingMode, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('status: $status, ')
          ..write('autoRestart: $autoRestart, ')
          ..write('presetId: $presetId, ')
          ..write('aheadChoice: $aheadChoice, ')
          ..write('reminderKinds: $reminderKinds, ')
          ..write('recovery: $recovery')
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
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('reader'),
  );
  static const VerificationMeta _entryPointMeta = const VerificationMeta(
    'entryPoint',
  );
  @override
  late final GeneratedColumn<String> entryPoint = GeneratedColumn<String>(
    'entry_point',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('other'),
  );
  static const VerificationMeta _activeSecondsMeta = const VerificationMeta(
    'activeSeconds',
  );
  @override
  late final GeneratedColumn<int> activeSeconds = GeneratedColumn<int>(
    'active_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rangesMeta = const VerificationMeta('ranges');
  @override
  late final GeneratedColumn<String> ranges = GeneratedColumn<String>(
    'ranges',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    source,
    entryPoint,
    activeSeconds,
    ranges,
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
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('entry_point')) {
      context.handle(
        _entryPointMeta,
        entryPoint.isAcceptableOrUnknown(data['entry_point']!, _entryPointMeta),
      );
    }
    if (data.containsKey('active_seconds')) {
      context.handle(
        _activeSecondsMeta,
        activeSeconds.isAcceptableOrUnknown(
          data['active_seconds']!,
          _activeSecondsMeta,
        ),
      );
    }
    if (data.containsKey('ranges')) {
      context.handle(
        _rangesMeta,
        ranges.isAcceptableOrUnknown(data['ranges']!, _rangesMeta),
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
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      entryPoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_point'],
      )!,
      activeSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_seconds'],
      ),
      ranges: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ranges'],
      )!,
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

  /// How it was read: `page` (the page view), `scroll` (auto-scroll),
  /// `verse` («آية آية») or `continuous`.
  final String mode;
  final String? edition;

  /// `reader`, `audio` or `manual`.
  final String source;

  /// Where the reading was opened from (`EntryPoint.name`).
  final String entryPoint;

  /// Time spent reading, idle stretches left out.
  final int? activeSeconds;

  /// The verses read (JSON runs of `ayah.id`).
  final String ranges;
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
    required this.source,
    required this.entryPoint,
    this.activeSeconds,
    required this.ranges,
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
    map['source'] = Variable<String>(source);
    map['entry_point'] = Variable<String>(entryPoint);
    if (!nullToAbsent || activeSeconds != null) {
      map['active_seconds'] = Variable<int>(activeSeconds);
    }
    map['ranges'] = Variable<String>(ranges);
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
      source: Value(source),
      entryPoint: Value(entryPoint),
      activeSeconds: activeSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(activeSeconds),
      ranges: Value(ranges),
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
      source: serializer.fromJson<String>(json['source']),
      entryPoint: serializer.fromJson<String>(json['entryPoint']),
      activeSeconds: serializer.fromJson<int?>(json['activeSeconds']),
      ranges: serializer.fromJson<String>(json['ranges']),
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
      'source': serializer.toJson<String>(source),
      'entryPoint': serializer.toJson<String>(entryPoint),
      'activeSeconds': serializer.toJson<int?>(activeSeconds),
      'ranges': serializer.toJson<String>(ranges),
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
    String? source,
    String? entryPoint,
    Value<int?> activeSeconds = const Value.absent(),
    String? ranges,
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
    source: source ?? this.source,
    entryPoint: entryPoint ?? this.entryPoint,
    activeSeconds: activeSeconds.present
        ? activeSeconds.value
        : this.activeSeconds,
    ranges: ranges ?? this.ranges,
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
      source: data.source.present ? data.source.value : this.source,
      entryPoint: data.entryPoint.present
          ? data.entryPoint.value
          : this.entryPoint,
      activeSeconds: data.activeSeconds.present
          ? data.activeSeconds.value
          : this.activeSeconds,
      ranges: data.ranges.present ? data.ranges.value : this.ranges,
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
          ..write('edition: $edition, ')
          ..write('source: $source, ')
          ..write('entryPoint: $entryPoint, ')
          ..write('activeSeconds: $activeSeconds, ')
          ..write('ranges: $ranges')
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
    source,
    entryPoint,
    activeSeconds,
    ranges,
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
          other.edition == this.edition &&
          other.source == this.source &&
          other.entryPoint == this.entryPoint &&
          other.activeSeconds == this.activeSeconds &&
          other.ranges == this.ranges);
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
  final Value<String> source;
  final Value<String> entryPoint;
  final Value<int?> activeSeconds;
  final Value<String> ranges;
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
    this.source = const Value.absent(),
    this.entryPoint = const Value.absent(),
    this.activeSeconds = const Value.absent(),
    this.ranges = const Value.absent(),
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
    this.source = const Value.absent(),
    this.entryPoint = const Value.absent(),
    this.activeSeconds = const Value.absent(),
    this.ranges = const Value.absent(),
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
    Expression<String>? source,
    Expression<String>? entryPoint,
    Expression<int>? activeSeconds,
    Expression<String>? ranges,
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
      if (source != null) 'source': source,
      if (entryPoint != null) 'entry_point': entryPoint,
      if (activeSeconds != null) 'active_seconds': activeSeconds,
      if (ranges != null) 'ranges': ranges,
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
    Value<String>? source,
    Value<String>? entryPoint,
    Value<int?>? activeSeconds,
    Value<String>? ranges,
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
      source: source ?? this.source,
      entryPoint: entryPoint ?? this.entryPoint,
      activeSeconds: activeSeconds ?? this.activeSeconds,
      ranges: ranges ?? this.ranges,
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
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (entryPoint.present) {
      map['entry_point'] = Variable<String>(entryPoint.value);
    }
    if (activeSeconds.present) {
      map['active_seconds'] = Variable<int>(activeSeconds.value);
    }
    if (ranges.present) {
      map['ranges'] = Variable<String>(ranges.value);
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
          ..write('edition: $edition, ')
          ..write('source: $source, ')
          ..write('entryPoint: $entryPoint, ')
          ..write('activeSeconds: $activeSeconds, ')
          ..write('ranges: $ranges')
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

class $SrsItemsTable extends SrsItems
    with TableInfo<$SrsItemsTable, SrsItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SrsItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromRefMeta = const VerificationMeta(
    'fromRef',
  );
  @override
  late final GeneratedColumn<String> fromRef = GeneratedColumn<String>(
    'from_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toRefMeta = const VerificationMeta('toRef');
  @override
  late final GeneratedColumn<String> toRef = GeneratedColumn<String>(
    'to_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stabilityMeta = const VerificationMeta(
    'stability',
  );
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
    'stability',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReviewAtMeta = const VerificationMeta(
    'lastReviewAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewAt = GeneratedColumn<DateTime>(
    'last_review_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    updatedAt,
    deletedAt,
    id,
    unit,
    fromRef,
    toRef,
    stability,
    difficulty,
    dueAt,
    reps,
    lapses,
    lastReviewAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'srs_item';
  @override
  VerificationContext validateIntegrity(
    Insertable<SrsItemRow> instance, {
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
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('from_ref')) {
      context.handle(
        _fromRefMeta,
        fromRef.isAcceptableOrUnknown(data['from_ref']!, _fromRefMeta),
      );
    } else if (isInserting) {
      context.missing(_fromRefMeta);
    }
    if (data.containsKey('to_ref')) {
      context.handle(
        _toRefMeta,
        toRef.isAcceptableOrUnknown(data['to_ref']!, _toRefMeta),
      );
    } else if (isInserting) {
      context.missing(_toRefMeta);
    }
    if (data.containsKey('stability')) {
      context.handle(
        _stabilityMeta,
        stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta),
      );
    } else if (isInserting) {
      context.missing(_stabilityMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    if (data.containsKey('last_review_at')) {
      context.handle(
        _lastReviewAtMeta,
        lastReviewAt.isAcceptableOrUnknown(
          data['last_review_at']!,
          _lastReviewAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SrsItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SrsItemRow(
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
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      fromRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_ref'],
      )!,
      toRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_ref'],
      )!,
      stability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      lastReviewAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_review_at'],
      ),
    );
  }

  @override
  $SrsItemsTable createAlias(String alias) {
    return $SrsItemsTable(attachedDatabase, alias);
  }
}

class SrsItemRow extends DataClass implements Insertable<SrsItemRow> {
  final String uuid;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int id;

  /// `page`, `quarter` or `surah`.
  final String unit;

  /// First and last verse, `surah:ayah`.
  final String fromRef;
  final String toRef;

  /// FSRS memory state: days to 90% recall, and difficulty 1..10.
  final double stability;
  final double difficulty;
  final DateTime dueAt;
  final int reps;
  final int lapses;
  final DateTime? lastReviewAt;
  const SrsItemRow({
    required this.uuid,
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.unit,
    required this.fromRef,
    required this.toRef,
    required this.stability,
    required this.difficulty,
    required this.dueAt,
    required this.reps,
    required this.lapses,
    this.lastReviewAt,
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
    map['unit'] = Variable<String>(unit);
    map['from_ref'] = Variable<String>(fromRef);
    map['to_ref'] = Variable<String>(toRef);
    map['stability'] = Variable<double>(stability);
    map['difficulty'] = Variable<double>(difficulty);
    map['due_at'] = Variable<DateTime>(dueAt);
    map['reps'] = Variable<int>(reps);
    map['lapses'] = Variable<int>(lapses);
    if (!nullToAbsent || lastReviewAt != null) {
      map['last_review_at'] = Variable<DateTime>(lastReviewAt);
    }
    return map;
  }

  SrsItemsCompanion toCompanion(bool nullToAbsent) {
    return SrsItemsCompanion(
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      unit: Value(unit),
      fromRef: Value(fromRef),
      toRef: Value(toRef),
      stability: Value(stability),
      difficulty: Value(difficulty),
      dueAt: Value(dueAt),
      reps: Value(reps),
      lapses: Value(lapses),
      lastReviewAt: lastReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewAt),
    );
  }

  factory SrsItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SrsItemRow(
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<int>(json['id']),
      unit: serializer.fromJson<String>(json['unit']),
      fromRef: serializer.fromJson<String>(json['fromRef']),
      toRef: serializer.fromJson<String>(json['toRef']),
      stability: serializer.fromJson<double>(json['stability']),
      difficulty: serializer.fromJson<double>(json['difficulty']),
      dueAt: serializer.fromJson<DateTime>(json['dueAt']),
      reps: serializer.fromJson<int>(json['reps']),
      lapses: serializer.fromJson<int>(json['lapses']),
      lastReviewAt: serializer.fromJson<DateTime?>(json['lastReviewAt']),
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
      'unit': serializer.toJson<String>(unit),
      'fromRef': serializer.toJson<String>(fromRef),
      'toRef': serializer.toJson<String>(toRef),
      'stability': serializer.toJson<double>(stability),
      'difficulty': serializer.toJson<double>(difficulty),
      'dueAt': serializer.toJson<DateTime>(dueAt),
      'reps': serializer.toJson<int>(reps),
      'lapses': serializer.toJson<int>(lapses),
      'lastReviewAt': serializer.toJson<DateTime?>(lastReviewAt),
    };
  }

  SrsItemRow copyWith({
    String? uuid,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? id,
    String? unit,
    String? fromRef,
    String? toRef,
    double? stability,
    double? difficulty,
    DateTime? dueAt,
    int? reps,
    int? lapses,
    Value<DateTime?> lastReviewAt = const Value.absent(),
  }) => SrsItemRow(
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    unit: unit ?? this.unit,
    fromRef: fromRef ?? this.fromRef,
    toRef: toRef ?? this.toRef,
    stability: stability ?? this.stability,
    difficulty: difficulty ?? this.difficulty,
    dueAt: dueAt ?? this.dueAt,
    reps: reps ?? this.reps,
    lapses: lapses ?? this.lapses,
    lastReviewAt: lastReviewAt.present ? lastReviewAt.value : this.lastReviewAt,
  );
  SrsItemRow copyWithCompanion(SrsItemsCompanion data) {
    return SrsItemRow(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      unit: data.unit.present ? data.unit.value : this.unit,
      fromRef: data.fromRef.present ? data.fromRef.value : this.fromRef,
      toRef: data.toRef.present ? data.toRef.value : this.toRef,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      lastReviewAt: data.lastReviewAt.present
          ? data.lastReviewAt.value
          : this.lastReviewAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SrsItemRow(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('unit: $unit, ')
          ..write('fromRef: $fromRef, ')
          ..write('toRef: $toRef, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('dueAt: $dueAt, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('lastReviewAt: $lastReviewAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    updatedAt,
    deletedAt,
    id,
    unit,
    fromRef,
    toRef,
    stability,
    difficulty,
    dueAt,
    reps,
    lapses,
    lastReviewAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SrsItemRow &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.unit == this.unit &&
          other.fromRef == this.fromRef &&
          other.toRef == this.toRef &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.dueAt == this.dueAt &&
          other.reps == this.reps &&
          other.lapses == this.lapses &&
          other.lastReviewAt == this.lastReviewAt);
}

class SrsItemsCompanion extends UpdateCompanion<SrsItemRow> {
  final Value<String> uuid;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> id;
  final Value<String> unit;
  final Value<String> fromRef;
  final Value<String> toRef;
  final Value<double> stability;
  final Value<double> difficulty;
  final Value<DateTime> dueAt;
  final Value<int> reps;
  final Value<int> lapses;
  final Value<DateTime?> lastReviewAt;
  const SrsItemsCompanion({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.unit = const Value.absent(),
    this.fromRef = const Value.absent(),
    this.toRef = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.lastReviewAt = const Value.absent(),
  });
  SrsItemsCompanion.insert({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    required String unit,
    required String fromRef,
    required String toRef,
    required double stability,
    required double difficulty,
    required DateTime dueAt,
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.lastReviewAt = const Value.absent(),
  }) : unit = Value(unit),
       fromRef = Value(fromRef),
       toRef = Value(toRef),
       stability = Value(stability),
       difficulty = Value(difficulty),
       dueAt = Value(dueAt);
  static Insertable<SrsItemRow> custom({
    Expression<String>? uuid,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? id,
    Expression<String>? unit,
    Expression<String>? fromRef,
    Expression<String>? toRef,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<DateTime>? dueAt,
    Expression<int>? reps,
    Expression<int>? lapses,
    Expression<DateTime>? lastReviewAt,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (unit != null) 'unit': unit,
      if (fromRef != null) 'from_ref': fromRef,
      if (toRef != null) 'to_ref': toRef,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (dueAt != null) 'due_at': dueAt,
      if (reps != null) 'reps': reps,
      if (lapses != null) 'lapses': lapses,
      if (lastReviewAt != null) 'last_review_at': lastReviewAt,
    });
  }

  SrsItemsCompanion copyWith({
    Value<String>? uuid,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? id,
    Value<String>? unit,
    Value<String>? fromRef,
    Value<String>? toRef,
    Value<double>? stability,
    Value<double>? difficulty,
    Value<DateTime>? dueAt,
    Value<int>? reps,
    Value<int>? lapses,
    Value<DateTime?>? lastReviewAt,
  }) {
    return SrsItemsCompanion(
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      unit: unit ?? this.unit,
      fromRef: fromRef ?? this.fromRef,
      toRef: toRef ?? this.toRef,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      dueAt: dueAt ?? this.dueAt,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      lastReviewAt: lastReviewAt ?? this.lastReviewAt,
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
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (fromRef.present) {
      map['from_ref'] = Variable<String>(fromRef.value);
    }
    if (toRef.present) {
      map['to_ref'] = Variable<String>(toRef.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (lastReviewAt.present) {
      map['last_review_at'] = Variable<DateTime>(lastReviewAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SrsItemsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('unit: $unit, ')
          ..write('fromRef: $fromRef, ')
          ..write('toRef: $toRef, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('dueAt: $dueAt, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('lastReviewAt: $lastReviewAt')
          ..write(')'))
        .toString();
  }
}

class $MemorizationsTable extends Memorizations
    with TableInfo<$MemorizationsTable, MemorizationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemorizationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refMeta = const VerificationMeta('ref');
  @override
  late final GeneratedColumn<String> ref = GeneratedColumn<String>(
    'ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strengthMeta = const VerificationMeta(
    'strength',
  );
  @override
  late final GeneratedColumn<int> strength = GeneratedColumn<int>(
    'strength',
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
    unit,
    ref,
    strength,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memorization';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemorizationRow> instance, {
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
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('ref')) {
      context.handle(
        _refMeta,
        ref.isAcceptableOrUnknown(data['ref']!, _refMeta),
      );
    } else if (isInserting) {
      context.missing(_refMeta);
    }
    if (data.containsKey('strength')) {
      context.handle(
        _strengthMeta,
        strength.isAcceptableOrUnknown(data['strength']!, _strengthMeta),
      );
    } else if (isInserting) {
      context.missing(_strengthMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemorizationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemorizationRow(
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
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      ref: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref'],
      )!,
      strength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}strength'],
      )!,
    );
  }

  @override
  $MemorizationsTable createAlias(String alias) {
    return $MemorizationsTable(attachedDatabase, alias);
  }
}

class MemorizationRow extends DataClass implements Insertable<MemorizationRow> {
  final String uuid;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int id;
  final String unit;
  final String ref;
  final int strength;
  const MemorizationRow({
    required this.uuid,
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.unit,
    required this.ref,
    required this.strength,
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
    map['unit'] = Variable<String>(unit);
    map['ref'] = Variable<String>(ref);
    map['strength'] = Variable<int>(strength);
    return map;
  }

  MemorizationsCompanion toCompanion(bool nullToAbsent) {
    return MemorizationsCompanion(
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      unit: Value(unit),
      ref: Value(ref),
      strength: Value(strength),
    );
  }

  factory MemorizationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemorizationRow(
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<int>(json['id']),
      unit: serializer.fromJson<String>(json['unit']),
      ref: serializer.fromJson<String>(json['ref']),
      strength: serializer.fromJson<int>(json['strength']),
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
      'unit': serializer.toJson<String>(unit),
      'ref': serializer.toJson<String>(ref),
      'strength': serializer.toJson<int>(strength),
    };
  }

  MemorizationRow copyWith({
    String? uuid,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? id,
    String? unit,
    String? ref,
    int? strength,
  }) => MemorizationRow(
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    unit: unit ?? this.unit,
    ref: ref ?? this.ref,
    strength: strength ?? this.strength,
  );
  MemorizationRow copyWithCompanion(MemorizationsCompanion data) {
    return MemorizationRow(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      unit: data.unit.present ? data.unit.value : this.unit,
      ref: data.ref.present ? data.ref.value : this.ref,
      strength: data.strength.present ? data.strength.value : this.strength,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemorizationRow(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('unit: $unit, ')
          ..write('ref: $ref, ')
          ..write('strength: $strength')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(uuid, updatedAt, deletedAt, id, unit, ref, strength);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemorizationRow &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.unit == this.unit &&
          other.ref == this.ref &&
          other.strength == this.strength);
}

class MemorizationsCompanion extends UpdateCompanion<MemorizationRow> {
  final Value<String> uuid;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> id;
  final Value<String> unit;
  final Value<String> ref;
  final Value<int> strength;
  const MemorizationsCompanion({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.unit = const Value.absent(),
    this.ref = const Value.absent(),
    this.strength = const Value.absent(),
  });
  MemorizationsCompanion.insert({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    required String unit,
    required String ref,
    required int strength,
  }) : unit = Value(unit),
       ref = Value(ref),
       strength = Value(strength);
  static Insertable<MemorizationRow> custom({
    Expression<String>? uuid,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? id,
    Expression<String>? unit,
    Expression<String>? ref,
    Expression<int>? strength,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (unit != null) 'unit': unit,
      if (ref != null) 'ref': ref,
      if (strength != null) 'strength': strength,
    });
  }

  MemorizationsCompanion copyWith({
    Value<String>? uuid,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? id,
    Value<String>? unit,
    Value<String>? ref,
    Value<int>? strength,
  }) {
    return MemorizationsCompanion(
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      unit: unit ?? this.unit,
      ref: ref ?? this.ref,
      strength: strength ?? this.strength,
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
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (ref.present) {
      map['ref'] = Variable<String>(ref.value);
    }
    if (strength.present) {
      map['strength'] = Variable<int>(strength.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemorizationsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('unit: $unit, ')
          ..write('ref: $ref, ')
          ..write('strength: $strength')
          ..write(')'))
        .toString();
  }
}

class $KhatmaPausesTable extends KhatmaPauses
    with TableInfo<$KhatmaPausesTable, KhatmaPauseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KhatmaPausesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _fromDayMeta = const VerificationMeta(
    'fromDay',
  );
  @override
  late final GeneratedColumn<String> fromDay = GeneratedColumn<String>(
    'from_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toDayMeta = const VerificationMeta('toDay');
  @override
  late final GeneratedColumn<String> toDay = GeneratedColumn<String>(
    'to_day',
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
    khatmaUuid,
    fromDay,
    toDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'khatma_pause';
  @override
  VerificationContext validateIntegrity(
    Insertable<KhatmaPauseRow> instance, {
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
    if (data.containsKey('from_day')) {
      context.handle(
        _fromDayMeta,
        fromDay.isAcceptableOrUnknown(data['from_day']!, _fromDayMeta),
      );
    } else if (isInserting) {
      context.missing(_fromDayMeta);
    }
    if (data.containsKey('to_day')) {
      context.handle(
        _toDayMeta,
        toDay.isAcceptableOrUnknown(data['to_day']!, _toDayMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KhatmaPauseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KhatmaPauseRow(
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
      fromDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_day'],
      )!,
      toDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_day'],
      ),
    );
  }

  @override
  $KhatmaPausesTable createAlias(String alias) {
    return $KhatmaPausesTable(attachedDatabase, alias);
  }
}

class KhatmaPauseRow extends DataClass implements Insertable<KhatmaPauseRow> {
  final String uuid;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int id;
  final String khatmaUuid;

  /// First paused day, and the last (null while still paused).
  final String fromDay;
  final String? toDay;
  const KhatmaPauseRow({
    required this.uuid,
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.khatmaUuid,
    required this.fromDay,
    this.toDay,
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
    map['from_day'] = Variable<String>(fromDay);
    if (!nullToAbsent || toDay != null) {
      map['to_day'] = Variable<String>(toDay);
    }
    return map;
  }

  KhatmaPausesCompanion toCompanion(bool nullToAbsent) {
    return KhatmaPausesCompanion(
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      khatmaUuid: Value(khatmaUuid),
      fromDay: Value(fromDay),
      toDay: toDay == null && nullToAbsent
          ? const Value.absent()
          : Value(toDay),
    );
  }

  factory KhatmaPauseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KhatmaPauseRow(
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<int>(json['id']),
      khatmaUuid: serializer.fromJson<String>(json['khatmaUuid']),
      fromDay: serializer.fromJson<String>(json['fromDay']),
      toDay: serializer.fromJson<String?>(json['toDay']),
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
      'fromDay': serializer.toJson<String>(fromDay),
      'toDay': serializer.toJson<String?>(toDay),
    };
  }

  KhatmaPauseRow copyWith({
    String? uuid,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? id,
    String? khatmaUuid,
    String? fromDay,
    Value<String?> toDay = const Value.absent(),
  }) => KhatmaPauseRow(
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    khatmaUuid: khatmaUuid ?? this.khatmaUuid,
    fromDay: fromDay ?? this.fromDay,
    toDay: toDay.present ? toDay.value : this.toDay,
  );
  KhatmaPauseRow copyWithCompanion(KhatmaPausesCompanion data) {
    return KhatmaPauseRow(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      khatmaUuid: data.khatmaUuid.present
          ? data.khatmaUuid.value
          : this.khatmaUuid,
      fromDay: data.fromDay.present ? data.fromDay.value : this.fromDay,
      toDay: data.toDay.present ? data.toDay.value : this.toDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KhatmaPauseRow(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('khatmaUuid: $khatmaUuid, ')
          ..write('fromDay: $fromDay, ')
          ..write('toDay: $toDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(uuid, updatedAt, deletedAt, id, khatmaUuid, fromDay, toDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KhatmaPauseRow &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.khatmaUuid == this.khatmaUuid &&
          other.fromDay == this.fromDay &&
          other.toDay == this.toDay);
}

class KhatmaPausesCompanion extends UpdateCompanion<KhatmaPauseRow> {
  final Value<String> uuid;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> id;
  final Value<String> khatmaUuid;
  final Value<String> fromDay;
  final Value<String?> toDay;
  const KhatmaPausesCompanion({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.khatmaUuid = const Value.absent(),
    this.fromDay = const Value.absent(),
    this.toDay = const Value.absent(),
  });
  KhatmaPausesCompanion.insert({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    required String khatmaUuid,
    required String fromDay,
    this.toDay = const Value.absent(),
  }) : khatmaUuid = Value(khatmaUuid),
       fromDay = Value(fromDay);
  static Insertable<KhatmaPauseRow> custom({
    Expression<String>? uuid,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? id,
    Expression<String>? khatmaUuid,
    Expression<String>? fromDay,
    Expression<String>? toDay,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (khatmaUuid != null) 'khatma_uuid': khatmaUuid,
      if (fromDay != null) 'from_day': fromDay,
      if (toDay != null) 'to_day': toDay,
    });
  }

  KhatmaPausesCompanion copyWith({
    Value<String>? uuid,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? id,
    Value<String>? khatmaUuid,
    Value<String>? fromDay,
    Value<String?>? toDay,
  }) {
    return KhatmaPausesCompanion(
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      khatmaUuid: khatmaUuid ?? this.khatmaUuid,
      fromDay: fromDay ?? this.fromDay,
      toDay: toDay ?? this.toDay,
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
    if (fromDay.present) {
      map['from_day'] = Variable<String>(fromDay.value);
    }
    if (toDay.present) {
      map['to_day'] = Variable<String>(toDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KhatmaPausesCompanion(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('khatmaUuid: $khatmaUuid, ')
          ..write('fromDay: $fromDay, ')
          ..write('toDay: $toDay')
          ..write(')'))
        .toString();
  }
}

class $SessionAttributionsTable extends SessionAttributions
    with TableInfo<$SessionAttributionsTable, SessionAttributionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionAttributionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionUuidMeta = const VerificationMeta(
    'sessionUuid',
  );
  @override
  late final GeneratedColumn<String> sessionUuid = GeneratedColumn<String>(
    'session_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _rangesMeta = const VerificationMeta('ranges');
  @override
  late final GeneratedColumn<String> ranges = GeneratedColumn<String>(
    'ranges',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newWeightMeta = const VerificationMeta(
    'newWeight',
  );
  @override
  late final GeneratedColumn<double> newWeight = GeneratedColumn<double>(
    'new_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _decidedByMeta = const VerificationMeta(
    'decidedBy',
  );
  @override
  late final GeneratedColumn<String> decidedBy = GeneratedColumn<String>(
    'decided_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _undoneMeta = const VerificationMeta('undone');
  @override
  late final GeneratedColumn<bool> undone = GeneratedColumn<bool>(
    'undone',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("undone" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    updatedAt,
    deletedAt,
    id,
    sessionUuid,
    khatmaUuid,
    ranges,
    newWeight,
    decidedBy,
    undone,
    day,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_attribution';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionAttributionRow> instance, {
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
    if (data.containsKey('session_uuid')) {
      context.handle(
        _sessionUuidMeta,
        sessionUuid.isAcceptableOrUnknown(
          data['session_uuid']!,
          _sessionUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionUuidMeta);
    }
    if (data.containsKey('khatma_uuid')) {
      context.handle(
        _khatmaUuidMeta,
        khatmaUuid.isAcceptableOrUnknown(data['khatma_uuid']!, _khatmaUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_khatmaUuidMeta);
    }
    if (data.containsKey('ranges')) {
      context.handle(
        _rangesMeta,
        ranges.isAcceptableOrUnknown(data['ranges']!, _rangesMeta),
      );
    } else if (isInserting) {
      context.missing(_rangesMeta);
    }
    if (data.containsKey('new_weight')) {
      context.handle(
        _newWeightMeta,
        newWeight.isAcceptableOrUnknown(data['new_weight']!, _newWeightMeta),
      );
    } else if (isInserting) {
      context.missing(_newWeightMeta);
    }
    if (data.containsKey('decided_by')) {
      context.handle(
        _decidedByMeta,
        decidedBy.isAcceptableOrUnknown(data['decided_by']!, _decidedByMeta),
      );
    } else if (isInserting) {
      context.missing(_decidedByMeta);
    }
    if (data.containsKey('undone')) {
      context.handle(
        _undoneMeta,
        undone.isAcceptableOrUnknown(data['undone']!, _undoneMeta),
      );
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionAttributionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionAttributionRow(
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
      sessionUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_uuid'],
      )!,
      khatmaUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}khatma_uuid'],
      )!,
      ranges: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ranges'],
      )!,
      newWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}new_weight'],
      )!,
      decidedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decided_by'],
      )!,
      undone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}undone'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $SessionAttributionsTable createAlias(String alias) {
    return $SessionAttributionsTable(attachedDatabase, alias);
  }
}

class SessionAttributionRow extends DataClass
    implements Insertable<SessionAttributionRow> {
  final String uuid;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int id;
  final String sessionUuid;
  final String khatmaUuid;

  /// The verses counted, new to the khatma when counted (JSON runs).
  final String ranges;

  /// Their weight then.
  final double newWeight;

  /// `auto`, `userAccepted`, `manual`, or `declined` (an «ask» answered
  /// no; kept so it is not asked again).
  final String decidedBy;
  final bool undone;

  /// The logical day of the session, and when it started (for order).
  final String day;
  final DateTime at;
  const SessionAttributionRow({
    required this.uuid,
    required this.updatedAt,
    this.deletedAt,
    required this.id,
    required this.sessionUuid,
    required this.khatmaUuid,
    required this.ranges,
    required this.newWeight,
    required this.decidedBy,
    required this.undone,
    required this.day,
    required this.at,
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
    map['session_uuid'] = Variable<String>(sessionUuid);
    map['khatma_uuid'] = Variable<String>(khatmaUuid);
    map['ranges'] = Variable<String>(ranges);
    map['new_weight'] = Variable<double>(newWeight);
    map['decided_by'] = Variable<String>(decidedBy);
    map['undone'] = Variable<bool>(undone);
    map['day'] = Variable<String>(day);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  SessionAttributionsCompanion toCompanion(bool nullToAbsent) {
    return SessionAttributionsCompanion(
      uuid: Value(uuid),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      sessionUuid: Value(sessionUuid),
      khatmaUuid: Value(khatmaUuid),
      ranges: Value(ranges),
      newWeight: Value(newWeight),
      decidedBy: Value(decidedBy),
      undone: Value(undone),
      day: Value(day),
      at: Value(at),
    );
  }

  factory SessionAttributionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionAttributionRow(
      uuid: serializer.fromJson<String>(json['uuid']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<int>(json['id']),
      sessionUuid: serializer.fromJson<String>(json['sessionUuid']),
      khatmaUuid: serializer.fromJson<String>(json['khatmaUuid']),
      ranges: serializer.fromJson<String>(json['ranges']),
      newWeight: serializer.fromJson<double>(json['newWeight']),
      decidedBy: serializer.fromJson<String>(json['decidedBy']),
      undone: serializer.fromJson<bool>(json['undone']),
      day: serializer.fromJson<String>(json['day']),
      at: serializer.fromJson<DateTime>(json['at']),
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
      'sessionUuid': serializer.toJson<String>(sessionUuid),
      'khatmaUuid': serializer.toJson<String>(khatmaUuid),
      'ranges': serializer.toJson<String>(ranges),
      'newWeight': serializer.toJson<double>(newWeight),
      'decidedBy': serializer.toJson<String>(decidedBy),
      'undone': serializer.toJson<bool>(undone),
      'day': serializer.toJson<String>(day),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  SessionAttributionRow copyWith({
    String? uuid,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? id,
    String? sessionUuid,
    String? khatmaUuid,
    String? ranges,
    double? newWeight,
    String? decidedBy,
    bool? undone,
    String? day,
    DateTime? at,
  }) => SessionAttributionRow(
    uuid: uuid ?? this.uuid,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    sessionUuid: sessionUuid ?? this.sessionUuid,
    khatmaUuid: khatmaUuid ?? this.khatmaUuid,
    ranges: ranges ?? this.ranges,
    newWeight: newWeight ?? this.newWeight,
    decidedBy: decidedBy ?? this.decidedBy,
    undone: undone ?? this.undone,
    day: day ?? this.day,
    at: at ?? this.at,
  );
  SessionAttributionRow copyWithCompanion(SessionAttributionsCompanion data) {
    return SessionAttributionRow(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      sessionUuid: data.sessionUuid.present
          ? data.sessionUuid.value
          : this.sessionUuid,
      khatmaUuid: data.khatmaUuid.present
          ? data.khatmaUuid.value
          : this.khatmaUuid,
      ranges: data.ranges.present ? data.ranges.value : this.ranges,
      newWeight: data.newWeight.present ? data.newWeight.value : this.newWeight,
      decidedBy: data.decidedBy.present ? data.decidedBy.value : this.decidedBy,
      undone: data.undone.present ? data.undone.value : this.undone,
      day: data.day.present ? data.day.value : this.day,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionAttributionRow(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('sessionUuid: $sessionUuid, ')
          ..write('khatmaUuid: $khatmaUuid, ')
          ..write('ranges: $ranges, ')
          ..write('newWeight: $newWeight, ')
          ..write('decidedBy: $decidedBy, ')
          ..write('undone: $undone, ')
          ..write('day: $day, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    updatedAt,
    deletedAt,
    id,
    sessionUuid,
    khatmaUuid,
    ranges,
    newWeight,
    decidedBy,
    undone,
    day,
    at,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionAttributionRow &&
          other.uuid == this.uuid &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.sessionUuid == this.sessionUuid &&
          other.khatmaUuid == this.khatmaUuid &&
          other.ranges == this.ranges &&
          other.newWeight == this.newWeight &&
          other.decidedBy == this.decidedBy &&
          other.undone == this.undone &&
          other.day == this.day &&
          other.at == this.at);
}

class SessionAttributionsCompanion
    extends UpdateCompanion<SessionAttributionRow> {
  final Value<String> uuid;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> id;
  final Value<String> sessionUuid;
  final Value<String> khatmaUuid;
  final Value<String> ranges;
  final Value<double> newWeight;
  final Value<String> decidedBy;
  final Value<bool> undone;
  final Value<String> day;
  final Value<DateTime> at;
  const SessionAttributionsCompanion({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.sessionUuid = const Value.absent(),
    this.khatmaUuid = const Value.absent(),
    this.ranges = const Value.absent(),
    this.newWeight = const Value.absent(),
    this.decidedBy = const Value.absent(),
    this.undone = const Value.absent(),
    this.day = const Value.absent(),
    this.at = const Value.absent(),
  });
  SessionAttributionsCompanion.insert({
    this.uuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    required String sessionUuid,
    required String khatmaUuid,
    required String ranges,
    required double newWeight,
    required String decidedBy,
    this.undone = const Value.absent(),
    required String day,
    required DateTime at,
  }) : sessionUuid = Value(sessionUuid),
       khatmaUuid = Value(khatmaUuid),
       ranges = Value(ranges),
       newWeight = Value(newWeight),
       decidedBy = Value(decidedBy),
       day = Value(day),
       at = Value(at);
  static Insertable<SessionAttributionRow> custom({
    Expression<String>? uuid,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? id,
    Expression<String>? sessionUuid,
    Expression<String>? khatmaUuid,
    Expression<String>? ranges,
    Expression<double>? newWeight,
    Expression<String>? decidedBy,
    Expression<bool>? undone,
    Expression<String>? day,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (sessionUuid != null) 'session_uuid': sessionUuid,
      if (khatmaUuid != null) 'khatma_uuid': khatmaUuid,
      if (ranges != null) 'ranges': ranges,
      if (newWeight != null) 'new_weight': newWeight,
      if (decidedBy != null) 'decided_by': decidedBy,
      if (undone != null) 'undone': undone,
      if (day != null) 'day': day,
      if (at != null) 'at': at,
    });
  }

  SessionAttributionsCompanion copyWith({
    Value<String>? uuid,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? id,
    Value<String>? sessionUuid,
    Value<String>? khatmaUuid,
    Value<String>? ranges,
    Value<double>? newWeight,
    Value<String>? decidedBy,
    Value<bool>? undone,
    Value<String>? day,
    Value<DateTime>? at,
  }) {
    return SessionAttributionsCompanion(
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      sessionUuid: sessionUuid ?? this.sessionUuid,
      khatmaUuid: khatmaUuid ?? this.khatmaUuid,
      ranges: ranges ?? this.ranges,
      newWeight: newWeight ?? this.newWeight,
      decidedBy: decidedBy ?? this.decidedBy,
      undone: undone ?? this.undone,
      day: day ?? this.day,
      at: at ?? this.at,
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
    if (sessionUuid.present) {
      map['session_uuid'] = Variable<String>(sessionUuid.value);
    }
    if (khatmaUuid.present) {
      map['khatma_uuid'] = Variable<String>(khatmaUuid.value);
    }
    if (ranges.present) {
      map['ranges'] = Variable<String>(ranges.value);
    }
    if (newWeight.present) {
      map['new_weight'] = Variable<double>(newWeight.value);
    }
    if (decidedBy.present) {
      map['decided_by'] = Variable<String>(decidedBy.value);
    }
    if (undone.present) {
      map['undone'] = Variable<bool>(undone.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionAttributionsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('sessionUuid: $sessionUuid, ')
          ..write('khatmaUuid: $khatmaUuid, ')
          ..write('ranges: $ranges, ')
          ..write('newWeight: $newWeight, ')
          ..write('decidedBy: $decidedBy, ')
          ..write('undone: $undone, ')
          ..write('day: $day, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

class $KhatmaCoveragesTable extends KhatmaCoverages
    with TableInfo<$KhatmaCoveragesTable, KhatmaCoverageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KhatmaCoveragesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _rangesMeta = const VerificationMeta('ranges');
  @override
  late final GeneratedColumn<String> ranges = GeneratedColumn<String>(
    'ranges',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coveredWeightMeta = const VerificationMeta(
    'coveredWeight',
  );
  @override
  late final GeneratedColumn<double> coveredWeight = GeneratedColumn<double>(
    'covered_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frontierMeta = const VerificationMeta(
    'frontier',
  );
  @override
  late final GeneratedColumn<int> frontier = GeneratedColumn<int>(
    'frontier',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [
    khatmaUuid,
    ranges,
    coveredWeight,
    frontier,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'khatma_coverage';
  @override
  VerificationContext validateIntegrity(
    Insertable<KhatmaCoverageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('khatma_uuid')) {
      context.handle(
        _khatmaUuidMeta,
        khatmaUuid.isAcceptableOrUnknown(data['khatma_uuid']!, _khatmaUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_khatmaUuidMeta);
    }
    if (data.containsKey('ranges')) {
      context.handle(
        _rangesMeta,
        ranges.isAcceptableOrUnknown(data['ranges']!, _rangesMeta),
      );
    } else if (isInserting) {
      context.missing(_rangesMeta);
    }
    if (data.containsKey('covered_weight')) {
      context.handle(
        _coveredWeightMeta,
        coveredWeight.isAcceptableOrUnknown(
          data['covered_weight']!,
          _coveredWeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_coveredWeightMeta);
    }
    if (data.containsKey('frontier')) {
      context.handle(
        _frontierMeta,
        frontier.isAcceptableOrUnknown(data['frontier']!, _frontierMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {khatmaUuid};
  @override
  KhatmaCoverageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KhatmaCoverageRow(
      khatmaUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}khatma_uuid'],
      )!,
      ranges: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ranges'],
      )!,
      coveredWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}covered_weight'],
      )!,
      frontier: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}frontier'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $KhatmaCoveragesTable createAlias(String alias) {
    return $KhatmaCoveragesTable(attachedDatabase, alias);
  }
}

class KhatmaCoverageRow extends DataClass
    implements Insertable<KhatmaCoverageRow> {
  final String khatmaUuid;
  final String ranges;
  final double coveredWeight;
  final int? frontier;
  final DateTime updatedAt;
  const KhatmaCoverageRow({
    required this.khatmaUuid,
    required this.ranges,
    required this.coveredWeight,
    this.frontier,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['khatma_uuid'] = Variable<String>(khatmaUuid);
    map['ranges'] = Variable<String>(ranges);
    map['covered_weight'] = Variable<double>(coveredWeight);
    if (!nullToAbsent || frontier != null) {
      map['frontier'] = Variable<int>(frontier);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  KhatmaCoveragesCompanion toCompanion(bool nullToAbsent) {
    return KhatmaCoveragesCompanion(
      khatmaUuid: Value(khatmaUuid),
      ranges: Value(ranges),
      coveredWeight: Value(coveredWeight),
      frontier: frontier == null && nullToAbsent
          ? const Value.absent()
          : Value(frontier),
      updatedAt: Value(updatedAt),
    );
  }

  factory KhatmaCoverageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KhatmaCoverageRow(
      khatmaUuid: serializer.fromJson<String>(json['khatmaUuid']),
      ranges: serializer.fromJson<String>(json['ranges']),
      coveredWeight: serializer.fromJson<double>(json['coveredWeight']),
      frontier: serializer.fromJson<int?>(json['frontier']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'khatmaUuid': serializer.toJson<String>(khatmaUuid),
      'ranges': serializer.toJson<String>(ranges),
      'coveredWeight': serializer.toJson<double>(coveredWeight),
      'frontier': serializer.toJson<int?>(frontier),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  KhatmaCoverageRow copyWith({
    String? khatmaUuid,
    String? ranges,
    double? coveredWeight,
    Value<int?> frontier = const Value.absent(),
    DateTime? updatedAt,
  }) => KhatmaCoverageRow(
    khatmaUuid: khatmaUuid ?? this.khatmaUuid,
    ranges: ranges ?? this.ranges,
    coveredWeight: coveredWeight ?? this.coveredWeight,
    frontier: frontier.present ? frontier.value : this.frontier,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  KhatmaCoverageRow copyWithCompanion(KhatmaCoveragesCompanion data) {
    return KhatmaCoverageRow(
      khatmaUuid: data.khatmaUuid.present
          ? data.khatmaUuid.value
          : this.khatmaUuid,
      ranges: data.ranges.present ? data.ranges.value : this.ranges,
      coveredWeight: data.coveredWeight.present
          ? data.coveredWeight.value
          : this.coveredWeight,
      frontier: data.frontier.present ? data.frontier.value : this.frontier,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KhatmaCoverageRow(')
          ..write('khatmaUuid: $khatmaUuid, ')
          ..write('ranges: $ranges, ')
          ..write('coveredWeight: $coveredWeight, ')
          ..write('frontier: $frontier, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(khatmaUuid, ranges, coveredWeight, frontier, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KhatmaCoverageRow &&
          other.khatmaUuid == this.khatmaUuid &&
          other.ranges == this.ranges &&
          other.coveredWeight == this.coveredWeight &&
          other.frontier == this.frontier &&
          other.updatedAt == this.updatedAt);
}

class KhatmaCoveragesCompanion extends UpdateCompanion<KhatmaCoverageRow> {
  final Value<String> khatmaUuid;
  final Value<String> ranges;
  final Value<double> coveredWeight;
  final Value<int?> frontier;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const KhatmaCoveragesCompanion({
    this.khatmaUuid = const Value.absent(),
    this.ranges = const Value.absent(),
    this.coveredWeight = const Value.absent(),
    this.frontier = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KhatmaCoveragesCompanion.insert({
    required String khatmaUuid,
    required String ranges,
    required double coveredWeight,
    this.frontier = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : khatmaUuid = Value(khatmaUuid),
       ranges = Value(ranges),
       coveredWeight = Value(coveredWeight);
  static Insertable<KhatmaCoverageRow> custom({
    Expression<String>? khatmaUuid,
    Expression<String>? ranges,
    Expression<double>? coveredWeight,
    Expression<int>? frontier,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (khatmaUuid != null) 'khatma_uuid': khatmaUuid,
      if (ranges != null) 'ranges': ranges,
      if (coveredWeight != null) 'covered_weight': coveredWeight,
      if (frontier != null) 'frontier': frontier,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KhatmaCoveragesCompanion copyWith({
    Value<String>? khatmaUuid,
    Value<String>? ranges,
    Value<double>? coveredWeight,
    Value<int?>? frontier,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return KhatmaCoveragesCompanion(
      khatmaUuid: khatmaUuid ?? this.khatmaUuid,
      ranges: ranges ?? this.ranges,
      coveredWeight: coveredWeight ?? this.coveredWeight,
      frontier: frontier ?? this.frontier,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (khatmaUuid.present) {
      map['khatma_uuid'] = Variable<String>(khatmaUuid.value);
    }
    if (ranges.present) {
      map['ranges'] = Variable<String>(ranges.value);
    }
    if (coveredWeight.present) {
      map['covered_weight'] = Variable<double>(coveredWeight.value);
    }
    if (frontier.present) {
      map['frontier'] = Variable<int>(frontier.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KhatmaCoveragesCompanion(')
          ..write('khatmaUuid: $khatmaUuid, ')
          ..write('ranges: $ranges, ')
          ..write('coveredWeight: $coveredWeight, ')
          ..write('frontier: $frontier, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyStatsTable extends DailyStats
    with TableInfo<$DailyStatsTable, DailyStatRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyStatsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightReadMeta = const VerificationMeta(
    'weightRead',
  );
  @override
  late final GeneratedColumn<double> weightRead = GeneratedColumn<double>(
    'weight_read',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionsMeta = const VerificationMeta(
    'sessions',
  );
  @override
  late final GeneratedColumn<int> sessions = GeneratedColumn<int>(
    'sessions',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<double> target = GeneratedColumn<double>(
    'target',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    khatmaUuid,
    day,
    weightRead,
    sessions,
    seconds,
    target,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_stat';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyStatRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('khatma_uuid')) {
      context.handle(
        _khatmaUuidMeta,
        khatmaUuid.isAcceptableOrUnknown(data['khatma_uuid']!, _khatmaUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_khatmaUuidMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('weight_read')) {
      context.handle(
        _weightReadMeta,
        weightRead.isAcceptableOrUnknown(data['weight_read']!, _weightReadMeta),
      );
    } else if (isInserting) {
      context.missing(_weightReadMeta);
    }
    if (data.containsKey('sessions')) {
      context.handle(
        _sessionsMeta,
        sessions.isAcceptableOrUnknown(data['sessions']!, _sessionsMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionsMeta);
    }
    if (data.containsKey('seconds')) {
      context.handle(
        _secondsMeta,
        seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta),
      );
    } else if (isInserting) {
      context.missing(_secondsMeta);
    }
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {khatmaUuid, day};
  @override
  DailyStatRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyStatRow(
      khatmaUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}khatma_uuid'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      weightRead: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_read'],
      )!,
      sessions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sessions'],
      )!,
      seconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds'],
      )!,
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target'],
      ),
    );
  }

  @override
  $DailyStatsTable createAlias(String alias) {
    return $DailyStatsTable(attachedDatabase, alias);
  }
}

class DailyStatRow extends DataClass implements Insertable<DailyStatRow> {
  final String khatmaUuid;
  final String day;
  final double weightRead;
  final int sessions;
  final int seconds;
  final double? target;
  const DailyStatRow({
    required this.khatmaUuid,
    required this.day,
    required this.weightRead,
    required this.sessions,
    required this.seconds,
    this.target,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['khatma_uuid'] = Variable<String>(khatmaUuid);
    map['day'] = Variable<String>(day);
    map['weight_read'] = Variable<double>(weightRead);
    map['sessions'] = Variable<int>(sessions);
    map['seconds'] = Variable<int>(seconds);
    if (!nullToAbsent || target != null) {
      map['target'] = Variable<double>(target);
    }
    return map;
  }

  DailyStatsCompanion toCompanion(bool nullToAbsent) {
    return DailyStatsCompanion(
      khatmaUuid: Value(khatmaUuid),
      day: Value(day),
      weightRead: Value(weightRead),
      sessions: Value(sessions),
      seconds: Value(seconds),
      target: target == null && nullToAbsent
          ? const Value.absent()
          : Value(target),
    );
  }

  factory DailyStatRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyStatRow(
      khatmaUuid: serializer.fromJson<String>(json['khatmaUuid']),
      day: serializer.fromJson<String>(json['day']),
      weightRead: serializer.fromJson<double>(json['weightRead']),
      sessions: serializer.fromJson<int>(json['sessions']),
      seconds: serializer.fromJson<int>(json['seconds']),
      target: serializer.fromJson<double?>(json['target']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'khatmaUuid': serializer.toJson<String>(khatmaUuid),
      'day': serializer.toJson<String>(day),
      'weightRead': serializer.toJson<double>(weightRead),
      'sessions': serializer.toJson<int>(sessions),
      'seconds': serializer.toJson<int>(seconds),
      'target': serializer.toJson<double?>(target),
    };
  }

  DailyStatRow copyWith({
    String? khatmaUuid,
    String? day,
    double? weightRead,
    int? sessions,
    int? seconds,
    Value<double?> target = const Value.absent(),
  }) => DailyStatRow(
    khatmaUuid: khatmaUuid ?? this.khatmaUuid,
    day: day ?? this.day,
    weightRead: weightRead ?? this.weightRead,
    sessions: sessions ?? this.sessions,
    seconds: seconds ?? this.seconds,
    target: target.present ? target.value : this.target,
  );
  DailyStatRow copyWithCompanion(DailyStatsCompanion data) {
    return DailyStatRow(
      khatmaUuid: data.khatmaUuid.present
          ? data.khatmaUuid.value
          : this.khatmaUuid,
      day: data.day.present ? data.day.value : this.day,
      weightRead: data.weightRead.present
          ? data.weightRead.value
          : this.weightRead,
      sessions: data.sessions.present ? data.sessions.value : this.sessions,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
      target: data.target.present ? data.target.value : this.target,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyStatRow(')
          ..write('khatmaUuid: $khatmaUuid, ')
          ..write('day: $day, ')
          ..write('weightRead: $weightRead, ')
          ..write('sessions: $sessions, ')
          ..write('seconds: $seconds, ')
          ..write('target: $target')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(khatmaUuid, day, weightRead, sessions, seconds, target);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyStatRow &&
          other.khatmaUuid == this.khatmaUuid &&
          other.day == this.day &&
          other.weightRead == this.weightRead &&
          other.sessions == this.sessions &&
          other.seconds == this.seconds &&
          other.target == this.target);
}

class DailyStatsCompanion extends UpdateCompanion<DailyStatRow> {
  final Value<String> khatmaUuid;
  final Value<String> day;
  final Value<double> weightRead;
  final Value<int> sessions;
  final Value<int> seconds;
  final Value<double?> target;
  final Value<int> rowid;
  const DailyStatsCompanion({
    this.khatmaUuid = const Value.absent(),
    this.day = const Value.absent(),
    this.weightRead = const Value.absent(),
    this.sessions = const Value.absent(),
    this.seconds = const Value.absent(),
    this.target = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyStatsCompanion.insert({
    required String khatmaUuid,
    required String day,
    required double weightRead,
    required int sessions,
    required int seconds,
    this.target = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : khatmaUuid = Value(khatmaUuid),
       day = Value(day),
       weightRead = Value(weightRead),
       sessions = Value(sessions),
       seconds = Value(seconds);
  static Insertable<DailyStatRow> custom({
    Expression<String>? khatmaUuid,
    Expression<String>? day,
    Expression<double>? weightRead,
    Expression<int>? sessions,
    Expression<int>? seconds,
    Expression<double>? target,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (khatmaUuid != null) 'khatma_uuid': khatmaUuid,
      if (day != null) 'day': day,
      if (weightRead != null) 'weight_read': weightRead,
      if (sessions != null) 'sessions': sessions,
      if (seconds != null) 'seconds': seconds,
      if (target != null) 'target': target,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyStatsCompanion copyWith({
    Value<String>? khatmaUuid,
    Value<String>? day,
    Value<double>? weightRead,
    Value<int>? sessions,
    Value<int>? seconds,
    Value<double?>? target,
    Value<int>? rowid,
  }) {
    return DailyStatsCompanion(
      khatmaUuid: khatmaUuid ?? this.khatmaUuid,
      day: day ?? this.day,
      weightRead: weightRead ?? this.weightRead,
      sessions: sessions ?? this.sessions,
      seconds: seconds ?? this.seconds,
      target: target ?? this.target,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (khatmaUuid.present) {
      map['khatma_uuid'] = Variable<String>(khatmaUuid.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (weightRead.present) {
      map['weight_read'] = Variable<double>(weightRead.value);
    }
    if (sessions.present) {
      map['sessions'] = Variable<int>(sessions.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    if (target.present) {
      map['target'] = Variable<double>(target.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyStatsCompanion(')
          ..write('khatmaUuid: $khatmaUuid, ')
          ..write('day: $day, ')
          ..write('weightRead: $weightRead, ')
          ..write('sessions: $sessions, ')
          ..write('seconds: $seconds, ')
          ..write('target: $target, ')
          ..write('rowid: $rowid')
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
  late final $SrsItemsTable srsItems = $SrsItemsTable(this);
  late final $MemorizationsTable memorizations = $MemorizationsTable(this);
  late final $KhatmaPausesTable khatmaPauses = $KhatmaPausesTable(this);
  late final $SessionAttributionsTable sessionAttributions =
      $SessionAttributionsTable(this);
  late final $KhatmaCoveragesTable khatmaCoverages = $KhatmaCoveragesTable(
    this,
  );
  late final $DailyStatsTable dailyStats = $DailyStatsTable(this);
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
    srsItems,
    memorizations,
    khatmaPauses,
    sessionAttributions,
    khatmaCoverages,
    dailyStats,
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
  Value<String> kind,
  Value<int?> rangeStart,
  Value<int?> rangeEnd,
  Value<int?> startAt,
  Value<String> pacingMode,
  Value<String> scheduleMode,
  Value<double?> dailyWeight,
  Value<String> restWeekdays,
  Value<String> countingMode,
  Value<bool> isPrimary,
  Value<String> status,
  Value<bool> autoRestart,
  Value<String?> presetId,
  Value<String?> aheadChoice,
  Value<String> reminderKinds,
  Value<String?> recovery,
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
  Value<String> kind,
  Value<int?> rangeStart,
  Value<int?> rangeEnd,
  Value<int?> startAt,
  Value<String> pacingMode,
  Value<String> scheduleMode,
  Value<double?> dailyWeight,
  Value<String> restWeekdays,
  Value<String> countingMode,
  Value<bool> isPrimary,
  Value<String> status,
  Value<bool> autoRestart,
  Value<String?> presetId,
  Value<String?> aheadChoice,
  Value<String> reminderKinds,
  Value<String?> recovery,
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rangeStart => $composableBuilder(
    column: $table.rangeStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rangeEnd => $composableBuilder(
    column: $table.rangeEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pacingMode => $composableBuilder(
    column: $table.pacingMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduleMode => $composableBuilder(
    column: $table.scheduleMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dailyWeight => $composableBuilder(
    column: $table.dailyWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get restWeekdays => $composableBuilder(
    column: $table.restWeekdays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countingMode => $composableBuilder(
    column: $table.countingMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoRestart => $composableBuilder(
    column: $table.autoRestart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presetId => $composableBuilder(
    column: $table.presetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aheadChoice => $composableBuilder(
    column: $table.aheadChoice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderKinds => $composableBuilder(
    column: $table.reminderKinds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recovery => $composableBuilder(
    column: $table.recovery,
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rangeStart => $composableBuilder(
    column: $table.rangeStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rangeEnd => $composableBuilder(
    column: $table.rangeEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pacingMode => $composableBuilder(
    column: $table.pacingMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduleMode => $composableBuilder(
    column: $table.scheduleMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dailyWeight => $composableBuilder(
    column: $table.dailyWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get restWeekdays => $composableBuilder(
    column: $table.restWeekdays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countingMode => $composableBuilder(
    column: $table.countingMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoRestart => $composableBuilder(
    column: $table.autoRestart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presetId => $composableBuilder(
    column: $table.presetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aheadChoice => $composableBuilder(
    column: $table.aheadChoice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderKinds => $composableBuilder(
    column: $table.reminderKinds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recovery => $composableBuilder(
    column: $table.recovery,
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

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get rangeStart => $composableBuilder(
    column: $table.rangeStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rangeEnd =>
      $composableBuilder(column: $table.rangeEnd, builder: (column) => column);

  GeneratedColumn<int> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<String> get pacingMode => $composableBuilder(
    column: $table.pacingMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scheduleMode => $composableBuilder(
    column: $table.scheduleMode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dailyWeight => $composableBuilder(
    column: $table.dailyWeight,
    builder: (column) => column,
  );

  GeneratedColumn<String> get restWeekdays => $composableBuilder(
    column: $table.restWeekdays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get countingMode => $composableBuilder(
    column: $table.countingMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get autoRestart => $composableBuilder(
    column: $table.autoRestart,
    builder: (column) => column,
  );

  GeneratedColumn<String> get presetId =>
      $composableBuilder(column: $table.presetId, builder: (column) => column);

  GeneratedColumn<String> get aheadChoice => $composableBuilder(
    column: $table.aheadChoice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderKinds => $composableBuilder(
    column: $table.reminderKinds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recovery =>
      $composableBuilder(column: $table.recovery, builder: (column) => column);
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
                Value<String> kind = const Value.absent(),
                Value<int?> rangeStart = const Value.absent(),
                Value<int?> rangeEnd = const Value.absent(),
                Value<int?> startAt = const Value.absent(),
                Value<String> pacingMode = const Value.absent(),
                Value<String> scheduleMode = const Value.absent(),
                Value<double?> dailyWeight = const Value.absent(),
                Value<String> restWeekdays = const Value.absent(),
                Value<String> countingMode = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> autoRestart = const Value.absent(),
                Value<String?> presetId = const Value.absent(),
                Value<String?> aheadChoice = const Value.absent(),
                Value<String> reminderKinds = const Value.absent(),
                Value<String?> recovery = const Value.absent(),
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
                kind: kind,
                rangeStart: rangeStart,
                rangeEnd: rangeEnd,
                startAt: startAt,
                pacingMode: pacingMode,
                scheduleMode: scheduleMode,
                dailyWeight: dailyWeight,
                restWeekdays: restWeekdays,
                countingMode: countingMode,
                isPrimary: isPrimary,
                status: status,
                autoRestart: autoRestart,
                presetId: presetId,
                aheadChoice: aheadChoice,
                reminderKinds: reminderKinds,
                recovery: recovery,
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
                Value<String> kind = const Value.absent(),
                Value<int?> rangeStart = const Value.absent(),
                Value<int?> rangeEnd = const Value.absent(),
                Value<int?> startAt = const Value.absent(),
                Value<String> pacingMode = const Value.absent(),
                Value<String> scheduleMode = const Value.absent(),
                Value<double?> dailyWeight = const Value.absent(),
                Value<String> restWeekdays = const Value.absent(),
                Value<String> countingMode = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> autoRestart = const Value.absent(),
                Value<String?> presetId = const Value.absent(),
                Value<String?> aheadChoice = const Value.absent(),
                Value<String> reminderKinds = const Value.absent(),
                Value<String?> recovery = const Value.absent(),
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
                kind: kind,
                rangeStart: rangeStart,
                rangeEnd: rangeEnd,
                startAt: startAt,
                pacingMode: pacingMode,
                scheduleMode: scheduleMode,
                dailyWeight: dailyWeight,
                restWeekdays: restWeekdays,
                countingMode: countingMode,
                isPrimary: isPrimary,
                status: status,
                autoRestart: autoRestart,
                presetId: presetId,
                aheadChoice: aheadChoice,
                reminderKinds: reminderKinds,
                recovery: recovery,
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
      Value<String> source,
      Value<String> entryPoint,
      Value<int?> activeSeconds,
      Value<String> ranges,
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
      Value<String> source,
      Value<String> entryPoint,
      Value<int?> activeSeconds,
      Value<String> ranges,
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

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryPoint => $composableBuilder(
    column: $table.entryPoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeSeconds => $composableBuilder(
    column: $table.activeSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ranges => $composableBuilder(
    column: $table.ranges,
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

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryPoint => $composableBuilder(
    column: $table.entryPoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeSeconds => $composableBuilder(
    column: $table.activeSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ranges => $composableBuilder(
    column: $table.ranges,
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

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get entryPoint => $composableBuilder(
    column: $table.entryPoint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get activeSeconds => $composableBuilder(
    column: $table.activeSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ranges =>
      $composableBuilder(column: $table.ranges, builder: (column) => column);
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
                Value<String> source = const Value.absent(),
                Value<String> entryPoint = const Value.absent(),
                Value<int?> activeSeconds = const Value.absent(),
                Value<String> ranges = const Value.absent(),
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
                source: source,
                entryPoint: entryPoint,
                activeSeconds: activeSeconds,
                ranges: ranges,
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
                Value<String> source = const Value.absent(),
                Value<String> entryPoint = const Value.absent(),
                Value<int?> activeSeconds = const Value.absent(),
                Value<String> ranges = const Value.absent(),
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
                source: source,
                entryPoint: entryPoint,
                activeSeconds: activeSeconds,
                ranges: ranges,
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
typedef $$SrsItemsTableCreateCompanionBuilder = SrsItemsCompanion Function({
  Value<String> uuid,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> id,
  required String unit,
  required String fromRef,
  required String toRef,
  required double stability,
  required double difficulty,
  required DateTime dueAt,
  Value<int> reps,
  Value<int> lapses,
  Value<DateTime?> lastReviewAt,
});
typedef $$SrsItemsTableUpdateCompanionBuilder = SrsItemsCompanion Function({
  Value<String> uuid,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> id,
  Value<String> unit,
  Value<String> fromRef,
  Value<String> toRef,
  Value<double> stability,
  Value<double> difficulty,
  Value<DateTime> dueAt,
  Value<int> reps,
  Value<int> lapses,
  Value<DateTime?> lastReviewAt,
});

class $$SrsItemsTableFilterComposer
    extends Composer<_$UserDatabase, $SrsItemsTable> {
  $$SrsItemsTableFilterComposer({
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

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromRef => $composableBuilder(
    column: $table.fromRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toRef => $composableBuilder(
    column: $table.toRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewAt => $composableBuilder(
    column: $table.lastReviewAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SrsItemsTableOrderingComposer
    extends Composer<_$UserDatabase, $SrsItemsTable> {
  $$SrsItemsTableOrderingComposer({
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

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromRef => $composableBuilder(
    column: $table.fromRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toRef => $composableBuilder(
    column: $table.toRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewAt => $composableBuilder(
    column: $table.lastReviewAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SrsItemsTableAnnotationComposer
    extends Composer<_$UserDatabase, $SrsItemsTable> {
  $$SrsItemsTableAnnotationComposer({
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

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get fromRef =>
      $composableBuilder(column: $table.fromRef, builder: (column) => column);

  GeneratedColumn<String> get toRef =>
      $composableBuilder(column: $table.toRef, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewAt => $composableBuilder(
    column: $table.lastReviewAt,
    builder: (column) => column,
  );
}

class $$SrsItemsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $SrsItemsTable,
          SrsItemRow,
          $$SrsItemsTableFilterComposer,
          $$SrsItemsTableOrderingComposer,
          $$SrsItemsTableAnnotationComposer,
          $$SrsItemsTableCreateCompanionBuilder,
          $$SrsItemsTableUpdateCompanionBuilder,
          (
            SrsItemRow,
            BaseReferences<_$UserDatabase, $SrsItemsTable, SrsItemRow>,
          ),
          SrsItemRow,
          PrefetchHooks Function()
        > {
  $$SrsItemsTableTableManager(_$UserDatabase db, $SrsItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SrsItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SrsItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SrsItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> fromRef = const Value.absent(),
                Value<String> toRef = const Value.absent(),
                Value<double> stability = const Value.absent(),
                Value<double> difficulty = const Value.absent(),
                Value<DateTime> dueAt = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<DateTime?> lastReviewAt = const Value.absent(),
              }) => SrsItemsCompanion(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                unit: unit,
                fromRef: fromRef,
                toRef: toRef,
                stability: stability,
                difficulty: difficulty,
                dueAt: dueAt,
                reps: reps,
                lapses: lapses,
                lastReviewAt: lastReviewAt,
              ),
          createCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                required String unit,
                required String fromRef,
                required String toRef,
                required double stability,
                required double difficulty,
                required DateTime dueAt,
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<DateTime?> lastReviewAt = const Value.absent(),
              }) => SrsItemsCompanion.insert(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                unit: unit,
                fromRef: fromRef,
                toRef: toRef,
                stability: stability,
                difficulty: difficulty,
                dueAt: dueAt,
                reps: reps,
                lapses: lapses,
                lastReviewAt: lastReviewAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SrsItemsTable, SrsItemRow>(table),
                  BaseReferences<_$UserDatabase, $SrsItemsTable, SrsItemRow>(
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

typedef $$SrsItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $SrsItemsTable,
      SrsItemRow,
      $$SrsItemsTableFilterComposer,
      $$SrsItemsTableOrderingComposer,
      $$SrsItemsTableAnnotationComposer,
      $$SrsItemsTableCreateCompanionBuilder,
      $$SrsItemsTableUpdateCompanionBuilder,
      (SrsItemRow, BaseReferences<_$UserDatabase, $SrsItemsTable, SrsItemRow>),
      SrsItemRow,
      PrefetchHooks Function()
    >;
typedef $$MemorizationsTableCreateCompanionBuilder =
    MemorizationsCompanion Function({
      Value<String> uuid,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> id,
      required String unit,
      required String ref,
      required int strength,
    });
typedef $$MemorizationsTableUpdateCompanionBuilder =
    MemorizationsCompanion Function({
      Value<String> uuid,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> id,
      Value<String> unit,
      Value<String> ref,
      Value<int> strength,
    });

class $$MemorizationsTableFilterComposer
    extends Composer<_$UserDatabase, $MemorizationsTable> {
  $$MemorizationsTableFilterComposer({
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

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ref => $composableBuilder(
    column: $table.ref,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemorizationsTableOrderingComposer
    extends Composer<_$UserDatabase, $MemorizationsTable> {
  $$MemorizationsTableOrderingComposer({
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

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ref => $composableBuilder(
    column: $table.ref,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemorizationsTableAnnotationComposer
    extends Composer<_$UserDatabase, $MemorizationsTable> {
  $$MemorizationsTableAnnotationComposer({
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

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get ref =>
      $composableBuilder(column: $table.ref, builder: (column) => column);

  GeneratedColumn<int> get strength =>
      $composableBuilder(column: $table.strength, builder: (column) => column);
}

class $$MemorizationsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $MemorizationsTable,
          MemorizationRow,
          $$MemorizationsTableFilterComposer,
          $$MemorizationsTableOrderingComposer,
          $$MemorizationsTableAnnotationComposer,
          $$MemorizationsTableCreateCompanionBuilder,
          $$MemorizationsTableUpdateCompanionBuilder,
          (
            MemorizationRow,
            BaseReferences<
              _$UserDatabase,
              $MemorizationsTable,
              MemorizationRow
            >,
          ),
          MemorizationRow,
          PrefetchHooks Function()
        > {
  $$MemorizationsTableTableManager(_$UserDatabase db, $MemorizationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemorizationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemorizationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemorizationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> ref = const Value.absent(),
                Value<int> strength = const Value.absent(),
              }) => MemorizationsCompanion(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                unit: unit,
                ref: ref,
                strength: strength,
              ),
          createCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                required String unit,
                required String ref,
                required int strength,
              }) => MemorizationsCompanion.insert(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                unit: unit,
                ref: ref,
                strength: strength,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MemorizationsTable, MemorizationRow>(table),
                  BaseReferences<
                    _$UserDatabase,
                    $MemorizationsTable,
                    MemorizationRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemorizationsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $MemorizationsTable,
      MemorizationRow,
      $$MemorizationsTableFilterComposer,
      $$MemorizationsTableOrderingComposer,
      $$MemorizationsTableAnnotationComposer,
      $$MemorizationsTableCreateCompanionBuilder,
      $$MemorizationsTableUpdateCompanionBuilder,
      (
        MemorizationRow,
        BaseReferences<_$UserDatabase, $MemorizationsTable, MemorizationRow>,
      ),
      MemorizationRow,
      PrefetchHooks Function()
    >;
typedef $$KhatmaPausesTableCreateCompanionBuilder =
    KhatmaPausesCompanion Function({
      Value<String> uuid,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> id,
      required String khatmaUuid,
      required String fromDay,
      Value<String?> toDay,
    });
typedef $$KhatmaPausesTableUpdateCompanionBuilder =
    KhatmaPausesCompanion Function({
      Value<String> uuid,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> id,
      Value<String> khatmaUuid,
      Value<String> fromDay,
      Value<String?> toDay,
    });

class $$KhatmaPausesTableFilterComposer
    extends Composer<_$UserDatabase, $KhatmaPausesTable> {
  $$KhatmaPausesTableFilterComposer({
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

  ColumnFilters<String> get fromDay => $composableBuilder(
    column: $table.fromDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toDay => $composableBuilder(
    column: $table.toDay,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KhatmaPausesTableOrderingComposer
    extends Composer<_$UserDatabase, $KhatmaPausesTable> {
  $$KhatmaPausesTableOrderingComposer({
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

  ColumnOrderings<String> get fromDay => $composableBuilder(
    column: $table.fromDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toDay => $composableBuilder(
    column: $table.toDay,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KhatmaPausesTableAnnotationComposer
    extends Composer<_$UserDatabase, $KhatmaPausesTable> {
  $$KhatmaPausesTableAnnotationComposer({
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

  GeneratedColumn<String> get fromDay =>
      $composableBuilder(column: $table.fromDay, builder: (column) => column);

  GeneratedColumn<String> get toDay =>
      $composableBuilder(column: $table.toDay, builder: (column) => column);
}

class $$KhatmaPausesTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $KhatmaPausesTable,
          KhatmaPauseRow,
          $$KhatmaPausesTableFilterComposer,
          $$KhatmaPausesTableOrderingComposer,
          $$KhatmaPausesTableAnnotationComposer,
          $$KhatmaPausesTableCreateCompanionBuilder,
          $$KhatmaPausesTableUpdateCompanionBuilder,
          (
            KhatmaPauseRow,
            BaseReferences<_$UserDatabase, $KhatmaPausesTable, KhatmaPauseRow>,
          ),
          KhatmaPauseRow,
          PrefetchHooks Function()
        > {
  $$KhatmaPausesTableTableManager(_$UserDatabase db, $KhatmaPausesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KhatmaPausesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KhatmaPausesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KhatmaPausesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<String> khatmaUuid = const Value.absent(),
                Value<String> fromDay = const Value.absent(),
                Value<String?> toDay = const Value.absent(),
              }) => KhatmaPausesCompanion(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                khatmaUuid: khatmaUuid,
                fromDay: fromDay,
                toDay: toDay,
              ),
          createCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                required String khatmaUuid,
                required String fromDay,
                Value<String?> toDay = const Value.absent(),
              }) => KhatmaPausesCompanion.insert(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                khatmaUuid: khatmaUuid,
                fromDay: fromDay,
                toDay: toDay,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KhatmaPausesTable, KhatmaPauseRow>(table),
                  BaseReferences<
                    _$UserDatabase,
                    $KhatmaPausesTable,
                    KhatmaPauseRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KhatmaPausesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $KhatmaPausesTable,
      KhatmaPauseRow,
      $$KhatmaPausesTableFilterComposer,
      $$KhatmaPausesTableOrderingComposer,
      $$KhatmaPausesTableAnnotationComposer,
      $$KhatmaPausesTableCreateCompanionBuilder,
      $$KhatmaPausesTableUpdateCompanionBuilder,
      (
        KhatmaPauseRow,
        BaseReferences<_$UserDatabase, $KhatmaPausesTable, KhatmaPauseRow>,
      ),
      KhatmaPauseRow,
      PrefetchHooks Function()
    >;
typedef $$SessionAttributionsTableCreateCompanionBuilder =
    SessionAttributionsCompanion Function({
      Value<String> uuid,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> id,
      required String sessionUuid,
      required String khatmaUuid,
      required String ranges,
      required double newWeight,
      required String decidedBy,
      Value<bool> undone,
      required String day,
      required DateTime at,
    });
typedef $$SessionAttributionsTableUpdateCompanionBuilder =
    SessionAttributionsCompanion Function({
      Value<String> uuid,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> id,
      Value<String> sessionUuid,
      Value<String> khatmaUuid,
      Value<String> ranges,
      Value<double> newWeight,
      Value<String> decidedBy,
      Value<bool> undone,
      Value<String> day,
      Value<DateTime> at,
    });

class $$SessionAttributionsTableFilterComposer
    extends Composer<_$UserDatabase, $SessionAttributionsTable> {
  $$SessionAttributionsTableFilterComposer({
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

  ColumnFilters<String> get sessionUuid => $composableBuilder(
    column: $table.sessionUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get khatmaUuid => $composableBuilder(
    column: $table.khatmaUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ranges => $composableBuilder(
    column: $table.ranges,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get newWeight => $composableBuilder(
    column: $table.newWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decidedBy => $composableBuilder(
    column: $table.decidedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get undone => $composableBuilder(
    column: $table.undone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionAttributionsTableOrderingComposer
    extends Composer<_$UserDatabase, $SessionAttributionsTable> {
  $$SessionAttributionsTableOrderingComposer({
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

  ColumnOrderings<String> get sessionUuid => $composableBuilder(
    column: $table.sessionUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get khatmaUuid => $composableBuilder(
    column: $table.khatmaUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ranges => $composableBuilder(
    column: $table.ranges,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get newWeight => $composableBuilder(
    column: $table.newWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decidedBy => $composableBuilder(
    column: $table.decidedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get undone => $composableBuilder(
    column: $table.undone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionAttributionsTableAnnotationComposer
    extends Composer<_$UserDatabase, $SessionAttributionsTable> {
  $$SessionAttributionsTableAnnotationComposer({
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

  GeneratedColumn<String> get sessionUuid => $composableBuilder(
    column: $table.sessionUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get khatmaUuid => $composableBuilder(
    column: $table.khatmaUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ranges =>
      $composableBuilder(column: $table.ranges, builder: (column) => column);

  GeneratedColumn<double> get newWeight =>
      $composableBuilder(column: $table.newWeight, builder: (column) => column);

  GeneratedColumn<String> get decidedBy =>
      $composableBuilder(column: $table.decidedBy, builder: (column) => column);

  GeneratedColumn<bool> get undone =>
      $composableBuilder(column: $table.undone, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$SessionAttributionsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $SessionAttributionsTable,
          SessionAttributionRow,
          $$SessionAttributionsTableFilterComposer,
          $$SessionAttributionsTableOrderingComposer,
          $$SessionAttributionsTableAnnotationComposer,
          $$SessionAttributionsTableCreateCompanionBuilder,
          $$SessionAttributionsTableUpdateCompanionBuilder,
          (
            SessionAttributionRow,
            BaseReferences<
              _$UserDatabase,
              $SessionAttributionsTable,
              SessionAttributionRow
            >,
          ),
          SessionAttributionRow,
          PrefetchHooks Function()
        > {
  $$SessionAttributionsTableTableManager(
    _$UserDatabase db,
    $SessionAttributionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionAttributionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionAttributionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SessionAttributionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<String> sessionUuid = const Value.absent(),
                Value<String> khatmaUuid = const Value.absent(),
                Value<String> ranges = const Value.absent(),
                Value<double> newWeight = const Value.absent(),
                Value<String> decidedBy = const Value.absent(),
                Value<bool> undone = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
              }) => SessionAttributionsCompanion(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                sessionUuid: sessionUuid,
                khatmaUuid: khatmaUuid,
                ranges: ranges,
                newWeight: newWeight,
                decidedBy: decidedBy,
                undone: undone,
                day: day,
                at: at,
              ),
          createCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                required String sessionUuid,
                required String khatmaUuid,
                required String ranges,
                required double newWeight,
                required String decidedBy,
                Value<bool> undone = const Value.absent(),
                required String day,
                required DateTime at,
              }) => SessionAttributionsCompanion.insert(
                uuid: uuid,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                id: id,
                sessionUuid: sessionUuid,
                khatmaUuid: khatmaUuid,
                ranges: ranges,
                newWeight: newWeight,
                decidedBy: decidedBy,
                undone: undone,
                day: day,
                at: at,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionAttributionsTable, SessionAttributionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$UserDatabase,
                    $SessionAttributionsTable,
                    SessionAttributionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionAttributionsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $SessionAttributionsTable,
      SessionAttributionRow,
      $$SessionAttributionsTableFilterComposer,
      $$SessionAttributionsTableOrderingComposer,
      $$SessionAttributionsTableAnnotationComposer,
      $$SessionAttributionsTableCreateCompanionBuilder,
      $$SessionAttributionsTableUpdateCompanionBuilder,
      (
        SessionAttributionRow,
        BaseReferences<
          _$UserDatabase,
          $SessionAttributionsTable,
          SessionAttributionRow
        >,
      ),
      SessionAttributionRow,
      PrefetchHooks Function()
    >;
typedef $$KhatmaCoveragesTableCreateCompanionBuilder =
    KhatmaCoveragesCompanion Function({
      required String khatmaUuid,
      required String ranges,
      required double coveredWeight,
      Value<int?> frontier,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$KhatmaCoveragesTableUpdateCompanionBuilder =
    KhatmaCoveragesCompanion Function({
      Value<String> khatmaUuid,
      Value<String> ranges,
      Value<double> coveredWeight,
      Value<int?> frontier,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$KhatmaCoveragesTableFilterComposer
    extends Composer<_$UserDatabase, $KhatmaCoveragesTable> {
  $$KhatmaCoveragesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get khatmaUuid => $composableBuilder(
    column: $table.khatmaUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ranges => $composableBuilder(
    column: $table.ranges,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get coveredWeight => $composableBuilder(
    column: $table.coveredWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get frontier => $composableBuilder(
    column: $table.frontier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KhatmaCoveragesTableOrderingComposer
    extends Composer<_$UserDatabase, $KhatmaCoveragesTable> {
  $$KhatmaCoveragesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get khatmaUuid => $composableBuilder(
    column: $table.khatmaUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ranges => $composableBuilder(
    column: $table.ranges,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get coveredWeight => $composableBuilder(
    column: $table.coveredWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get frontier => $composableBuilder(
    column: $table.frontier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KhatmaCoveragesTableAnnotationComposer
    extends Composer<_$UserDatabase, $KhatmaCoveragesTable> {
  $$KhatmaCoveragesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get khatmaUuid => $composableBuilder(
    column: $table.khatmaUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ranges =>
      $composableBuilder(column: $table.ranges, builder: (column) => column);

  GeneratedColumn<double> get coveredWeight => $composableBuilder(
    column: $table.coveredWeight,
    builder: (column) => column,
  );

  GeneratedColumn<int> get frontier =>
      $composableBuilder(column: $table.frontier, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$KhatmaCoveragesTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $KhatmaCoveragesTable,
          KhatmaCoverageRow,
          $$KhatmaCoveragesTableFilterComposer,
          $$KhatmaCoveragesTableOrderingComposer,
          $$KhatmaCoveragesTableAnnotationComposer,
          $$KhatmaCoveragesTableCreateCompanionBuilder,
          $$KhatmaCoveragesTableUpdateCompanionBuilder,
          (
            KhatmaCoverageRow,
            BaseReferences<
              _$UserDatabase,
              $KhatmaCoveragesTable,
              KhatmaCoverageRow
            >,
          ),
          KhatmaCoverageRow,
          PrefetchHooks Function()
        > {
  $$KhatmaCoveragesTableTableManager(
    _$UserDatabase db,
    $KhatmaCoveragesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KhatmaCoveragesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KhatmaCoveragesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KhatmaCoveragesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> khatmaUuid = const Value.absent(),
                Value<String> ranges = const Value.absent(),
                Value<double> coveredWeight = const Value.absent(),
                Value<int?> frontier = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KhatmaCoveragesCompanion(
                khatmaUuid: khatmaUuid,
                ranges: ranges,
                coveredWeight: coveredWeight,
                frontier: frontier,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String khatmaUuid,
                required String ranges,
                required double coveredWeight,
                Value<int?> frontier = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KhatmaCoveragesCompanion.insert(
                khatmaUuid: khatmaUuid,
                ranges: ranges,
                coveredWeight: coveredWeight,
                frontier: frontier,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KhatmaCoveragesTable, KhatmaCoverageRow>(table),
                  BaseReferences<
                    _$UserDatabase,
                    $KhatmaCoveragesTable,
                    KhatmaCoverageRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KhatmaCoveragesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $KhatmaCoveragesTable,
      KhatmaCoverageRow,
      $$KhatmaCoveragesTableFilterComposer,
      $$KhatmaCoveragesTableOrderingComposer,
      $$KhatmaCoveragesTableAnnotationComposer,
      $$KhatmaCoveragesTableCreateCompanionBuilder,
      $$KhatmaCoveragesTableUpdateCompanionBuilder,
      (
        KhatmaCoverageRow,
        BaseReferences<
          _$UserDatabase,
          $KhatmaCoveragesTable,
          KhatmaCoverageRow
        >,
      ),
      KhatmaCoverageRow,
      PrefetchHooks Function()
    >;
typedef $$DailyStatsTableCreateCompanionBuilder = DailyStatsCompanion Function({
  required String khatmaUuid,
  required String day,
  required double weightRead,
  required int sessions,
  required int seconds,
  Value<double?> target,
  Value<int> rowid,
});
typedef $$DailyStatsTableUpdateCompanionBuilder = DailyStatsCompanion Function({
  Value<String> khatmaUuid,
  Value<String> day,
  Value<double> weightRead,
  Value<int> sessions,
  Value<int> seconds,
  Value<double?> target,
  Value<int> rowid,
});

class $$DailyStatsTableFilterComposer
    extends Composer<_$UserDatabase, $DailyStatsTable> {
  $$DailyStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get khatmaUuid => $composableBuilder(
    column: $table.khatmaUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightRead => $composableBuilder(
    column: $table.weightRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessions => $composableBuilder(
    column: $table.sessions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyStatsTableOrderingComposer
    extends Composer<_$UserDatabase, $DailyStatsTable> {
  $$DailyStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get khatmaUuid => $composableBuilder(
    column: $table.khatmaUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightRead => $composableBuilder(
    column: $table.weightRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessions => $composableBuilder(
    column: $table.sessions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyStatsTableAnnotationComposer
    extends Composer<_$UserDatabase, $DailyStatsTable> {
  $$DailyStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get khatmaUuid => $composableBuilder(
    column: $table.khatmaUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<double> get weightRead => $composableBuilder(
    column: $table.weightRead,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sessions =>
      $composableBuilder(column: $table.sessions, builder: (column) => column);

  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);

  GeneratedColumn<double> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);
}

class $$DailyStatsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $DailyStatsTable,
          DailyStatRow,
          $$DailyStatsTableFilterComposer,
          $$DailyStatsTableOrderingComposer,
          $$DailyStatsTableAnnotationComposer,
          $$DailyStatsTableCreateCompanionBuilder,
          $$DailyStatsTableUpdateCompanionBuilder,
          (
            DailyStatRow,
            BaseReferences<_$UserDatabase, $DailyStatsTable, DailyStatRow>,
          ),
          DailyStatRow,
          PrefetchHooks Function()
        > {
  $$DailyStatsTableTableManager(_$UserDatabase db, $DailyStatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> khatmaUuid = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<double> weightRead = const Value.absent(),
                Value<int> sessions = const Value.absent(),
                Value<int> seconds = const Value.absent(),
                Value<double?> target = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyStatsCompanion(
                khatmaUuid: khatmaUuid,
                day: day,
                weightRead: weightRead,
                sessions: sessions,
                seconds: seconds,
                target: target,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String khatmaUuid,
                required String day,
                required double weightRead,
                required int sessions,
                required int seconds,
                Value<double?> target = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyStatsCompanion.insert(
                khatmaUuid: khatmaUuid,
                day: day,
                weightRead: weightRead,
                sessions: sessions,
                seconds: seconds,
                target: target,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyStatsTable, DailyStatRow>(table),
                  BaseReferences<
                    _$UserDatabase,
                    $DailyStatsTable,
                    DailyStatRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $DailyStatsTable,
      DailyStatRow,
      $$DailyStatsTableFilterComposer,
      $$DailyStatsTableOrderingComposer,
      $$DailyStatsTableAnnotationComposer,
      $$DailyStatsTableCreateCompanionBuilder,
      $$DailyStatsTableUpdateCompanionBuilder,
      (
        DailyStatRow,
        BaseReferences<_$UserDatabase, $DailyStatsTable, DailyStatRow>,
      ),
      DailyStatRow,
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
  $$SrsItemsTableTableManager get srsItems =>
      $$SrsItemsTableTableManager(_db, _db.srsItems);
  $$MemorizationsTableTableManager get memorizations =>
      $$MemorizationsTableTableManager(_db, _db.memorizations);
  $$KhatmaPausesTableTableManager get khatmaPauses =>
      $$KhatmaPausesTableTableManager(_db, _db.khatmaPauses);
  $$SessionAttributionsTableTableManager get sessionAttributions =>
      $$SessionAttributionsTableTableManager(_db, _db.sessionAttributions);
  $$KhatmaCoveragesTableTableManager get khatmaCoverages =>
      $$KhatmaCoveragesTableTableManager(_db, _db.khatmaCoverages);
  $$DailyStatsTableTableManager get dailyStats =>
      $$DailyStatsTableTableManager(_db, _db.dailyStats);
}
