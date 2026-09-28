// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ayahinfo_database.dart';

// ignore_for_file: type=lint
class $GlyphsTable extends Glyphs with TableInfo<$GlyphsTable, GlyphRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GlyphsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _glyphIdMeta = const VerificationMeta(
    'glyphId',
  );
  @override
  late final GeneratedColumn<int> glyphId = GeneratedColumn<int>(
    'glyph_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineNumberMeta = const VerificationMeta(
    'lineNumber',
  );
  @override
  late final GeneratedColumn<int> lineNumber = GeneratedColumn<int>(
    'line_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _suraNumberMeta = const VerificationMeta(
    'suraNumber',
  );
  @override
  late final GeneratedColumn<int> suraNumber = GeneratedColumn<int>(
    'sura_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahNumberMeta = const VerificationMeta(
    'ayahNumber',
  );
  @override
  late final GeneratedColumn<int> ayahNumber = GeneratedColumn<int>(
    'ayah_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minXMeta = const VerificationMeta('minX');
  @override
  late final GeneratedColumn<int> minX = GeneratedColumn<int>(
    'min_x',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxXMeta = const VerificationMeta('maxX');
  @override
  late final GeneratedColumn<int> maxX = GeneratedColumn<int>(
    'max_x',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minYMeta = const VerificationMeta('minY');
  @override
  late final GeneratedColumn<int> minY = GeneratedColumn<int>(
    'min_y',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxYMeta = const VerificationMeta('maxY');
  @override
  late final GeneratedColumn<int> maxY = GeneratedColumn<int>(
    'max_y',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    glyphId,
    pageNumber,
    lineNumber,
    suraNumber,
    ayahNumber,
    position,
    minX,
    maxX,
    minY,
    maxY,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'glyphs';
  @override
  VerificationContext validateIntegrity(
    Insertable<GlyphRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('glyph_id')) {
      context.handle(
        _glyphIdMeta,
        glyphId.isAcceptableOrUnknown(data['glyph_id']!, _glyphIdMeta),
      );
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNumberMeta);
    }
    if (data.containsKey('line_number')) {
      context.handle(
        _lineNumberMeta,
        lineNumber.isAcceptableOrUnknown(data['line_number']!, _lineNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_lineNumberMeta);
    }
    if (data.containsKey('sura_number')) {
      context.handle(
        _suraNumberMeta,
        suraNumber.isAcceptableOrUnknown(data['sura_number']!, _suraNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_suraNumberMeta);
    }
    if (data.containsKey('ayah_number')) {
      context.handle(
        _ayahNumberMeta,
        ayahNumber.isAcceptableOrUnknown(data['ayah_number']!, _ayahNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahNumberMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('min_x')) {
      context.handle(
        _minXMeta,
        minX.isAcceptableOrUnknown(data['min_x']!, _minXMeta),
      );
    } else if (isInserting) {
      context.missing(_minXMeta);
    }
    if (data.containsKey('max_x')) {
      context.handle(
        _maxXMeta,
        maxX.isAcceptableOrUnknown(data['max_x']!, _maxXMeta),
      );
    } else if (isInserting) {
      context.missing(_maxXMeta);
    }
    if (data.containsKey('min_y')) {
      context.handle(
        _minYMeta,
        minY.isAcceptableOrUnknown(data['min_y']!, _minYMeta),
      );
    } else if (isInserting) {
      context.missing(_minYMeta);
    }
    if (data.containsKey('max_y')) {
      context.handle(
        _maxYMeta,
        maxY.isAcceptableOrUnknown(data['max_y']!, _maxYMeta),
      );
    } else if (isInserting) {
      context.missing(_maxYMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {glyphId};
  @override
  GlyphRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GlyphRow(
      glyphId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}glyph_id'],
      )!,
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      )!,
      lineNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_number'],
      )!,
      suraNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sura_number'],
      )!,
      ayahNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_number'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      minX: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_x'],
      )!,
      maxX: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_x'],
      )!,
      minY: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_y'],
      )!,
      maxY: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_y'],
      )!,
    );
  }

  @override
  $GlyphsTable createAlias(String alias) {
    return $GlyphsTable(attachedDatabase, alias);
  }
}

class GlyphRow extends DataClass implements Insertable<GlyphRow> {
  final int glyphId;
  final int pageNumber;
  final int lineNumber;
  final int suraNumber;
  final int ayahNumber;
  final int position;
  final int minX;
  final int maxX;
  final int minY;
  final int maxY;
  const GlyphRow({
    required this.glyphId,
    required this.pageNumber,
    required this.lineNumber,
    required this.suraNumber,
    required this.ayahNumber,
    required this.position,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['glyph_id'] = Variable<int>(glyphId);
    map['page_number'] = Variable<int>(pageNumber);
    map['line_number'] = Variable<int>(lineNumber);
    map['sura_number'] = Variable<int>(suraNumber);
    map['ayah_number'] = Variable<int>(ayahNumber);
    map['position'] = Variable<int>(position);
    map['min_x'] = Variable<int>(minX);
    map['max_x'] = Variable<int>(maxX);
    map['min_y'] = Variable<int>(minY);
    map['max_y'] = Variable<int>(maxY);
    return map;
  }

  GlyphsCompanion toCompanion(bool nullToAbsent) {
    return GlyphsCompanion(
      glyphId: Value(glyphId),
      pageNumber: Value(pageNumber),
      lineNumber: Value(lineNumber),
      suraNumber: Value(suraNumber),
      ayahNumber: Value(ayahNumber),
      position: Value(position),
      minX: Value(minX),
      maxX: Value(maxX),
      minY: Value(minY),
      maxY: Value(maxY),
    );
  }

  factory GlyphRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GlyphRow(
      glyphId: serializer.fromJson<int>(json['glyphId']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      lineNumber: serializer.fromJson<int>(json['lineNumber']),
      suraNumber: serializer.fromJson<int>(json['suraNumber']),
      ayahNumber: serializer.fromJson<int>(json['ayahNumber']),
      position: serializer.fromJson<int>(json['position']),
      minX: serializer.fromJson<int>(json['minX']),
      maxX: serializer.fromJson<int>(json['maxX']),
      minY: serializer.fromJson<int>(json['minY']),
      maxY: serializer.fromJson<int>(json['maxY']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'glyphId': serializer.toJson<int>(glyphId),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'lineNumber': serializer.toJson<int>(lineNumber),
      'suraNumber': serializer.toJson<int>(suraNumber),
      'ayahNumber': serializer.toJson<int>(ayahNumber),
      'position': serializer.toJson<int>(position),
      'minX': serializer.toJson<int>(minX),
      'maxX': serializer.toJson<int>(maxX),
      'minY': serializer.toJson<int>(minY),
      'maxY': serializer.toJson<int>(maxY),
    };
  }

  GlyphRow copyWith({
    int? glyphId,
    int? pageNumber,
    int? lineNumber,
    int? suraNumber,
    int? ayahNumber,
    int? position,
    int? minX,
    int? maxX,
    int? minY,
    int? maxY,
  }) => GlyphRow(
    glyphId: glyphId ?? this.glyphId,
    pageNumber: pageNumber ?? this.pageNumber,
    lineNumber: lineNumber ?? this.lineNumber,
    suraNumber: suraNumber ?? this.suraNumber,
    ayahNumber: ayahNumber ?? this.ayahNumber,
    position: position ?? this.position,
    minX: minX ?? this.minX,
    maxX: maxX ?? this.maxX,
    minY: minY ?? this.minY,
    maxY: maxY ?? this.maxY,
  );
  GlyphRow copyWithCompanion(GlyphsCompanion data) {
    return GlyphRow(
      glyphId: data.glyphId.present ? data.glyphId.value : this.glyphId,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      lineNumber: data.lineNumber.present
          ? data.lineNumber.value
          : this.lineNumber,
      suraNumber: data.suraNumber.present
          ? data.suraNumber.value
          : this.suraNumber,
      ayahNumber: data.ayahNumber.present
          ? data.ayahNumber.value
          : this.ayahNumber,
      position: data.position.present ? data.position.value : this.position,
      minX: data.minX.present ? data.minX.value : this.minX,
      maxX: data.maxX.present ? data.maxX.value : this.maxX,
      minY: data.minY.present ? data.minY.value : this.minY,
      maxY: data.maxY.present ? data.maxY.value : this.maxY,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GlyphRow(')
          ..write('glyphId: $glyphId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('lineNumber: $lineNumber, ')
          ..write('suraNumber: $suraNumber, ')
          ..write('ayahNumber: $ayahNumber, ')
          ..write('position: $position, ')
          ..write('minX: $minX, ')
          ..write('maxX: $maxX, ')
          ..write('minY: $minY, ')
          ..write('maxY: $maxY')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    glyphId,
    pageNumber,
    lineNumber,
    suraNumber,
    ayahNumber,
    position,
    minX,
    maxX,
    minY,
    maxY,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GlyphRow &&
          other.glyphId == this.glyphId &&
          other.pageNumber == this.pageNumber &&
          other.lineNumber == this.lineNumber &&
          other.suraNumber == this.suraNumber &&
          other.ayahNumber == this.ayahNumber &&
          other.position == this.position &&
          other.minX == this.minX &&
          other.maxX == this.maxX &&
          other.minY == this.minY &&
          other.maxY == this.maxY);
}

class GlyphsCompanion extends UpdateCompanion<GlyphRow> {
  final Value<int> glyphId;
  final Value<int> pageNumber;
  final Value<int> lineNumber;
  final Value<int> suraNumber;
  final Value<int> ayahNumber;
  final Value<int> position;
  final Value<int> minX;
  final Value<int> maxX;
  final Value<int> minY;
  final Value<int> maxY;
  const GlyphsCompanion({
    this.glyphId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.lineNumber = const Value.absent(),
    this.suraNumber = const Value.absent(),
    this.ayahNumber = const Value.absent(),
    this.position = const Value.absent(),
    this.minX = const Value.absent(),
    this.maxX = const Value.absent(),
    this.minY = const Value.absent(),
    this.maxY = const Value.absent(),
  });
  GlyphsCompanion.insert({
    this.glyphId = const Value.absent(),
    required int pageNumber,
    required int lineNumber,
    required int suraNumber,
    required int ayahNumber,
    required int position,
    required int minX,
    required int maxX,
    required int minY,
    required int maxY,
  }) : pageNumber = Value(pageNumber),
       lineNumber = Value(lineNumber),
       suraNumber = Value(suraNumber),
       ayahNumber = Value(ayahNumber),
       position = Value(position),
       minX = Value(minX),
       maxX = Value(maxX),
       minY = Value(minY),
       maxY = Value(maxY);
  static Insertable<GlyphRow> custom({
    Expression<int>? glyphId,
    Expression<int>? pageNumber,
    Expression<int>? lineNumber,
    Expression<int>? suraNumber,
    Expression<int>? ayahNumber,
    Expression<int>? position,
    Expression<int>? minX,
    Expression<int>? maxX,
    Expression<int>? minY,
    Expression<int>? maxY,
  }) {
    return RawValuesInsertable({
      if (glyphId != null) 'glyph_id': glyphId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (lineNumber != null) 'line_number': lineNumber,
      if (suraNumber != null) 'sura_number': suraNumber,
      if (ayahNumber != null) 'ayah_number': ayahNumber,
      if (position != null) 'position': position,
      if (minX != null) 'min_x': minX,
      if (maxX != null) 'max_x': maxX,
      if (minY != null) 'min_y': minY,
      if (maxY != null) 'max_y': maxY,
    });
  }

  GlyphsCompanion copyWith({
    Value<int>? glyphId,
    Value<int>? pageNumber,
    Value<int>? lineNumber,
    Value<int>? suraNumber,
    Value<int>? ayahNumber,
    Value<int>? position,
    Value<int>? minX,
    Value<int>? maxX,
    Value<int>? minY,
    Value<int>? maxY,
  }) {
    return GlyphsCompanion(
      glyphId: glyphId ?? this.glyphId,
      pageNumber: pageNumber ?? this.pageNumber,
      lineNumber: lineNumber ?? this.lineNumber,
      suraNumber: suraNumber ?? this.suraNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      position: position ?? this.position,
      minX: minX ?? this.minX,
      maxX: maxX ?? this.maxX,
      minY: minY ?? this.minY,
      maxY: maxY ?? this.maxY,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (glyphId.present) {
      map['glyph_id'] = Variable<int>(glyphId.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (lineNumber.present) {
      map['line_number'] = Variable<int>(lineNumber.value);
    }
    if (suraNumber.present) {
      map['sura_number'] = Variable<int>(suraNumber.value);
    }
    if (ayahNumber.present) {
      map['ayah_number'] = Variable<int>(ayahNumber.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (minX.present) {
      map['min_x'] = Variable<int>(minX.value);
    }
    if (maxX.present) {
      map['max_x'] = Variable<int>(maxX.value);
    }
    if (minY.present) {
      map['min_y'] = Variable<int>(minY.value);
    }
    if (maxY.present) {
      map['max_y'] = Variable<int>(maxY.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GlyphsCompanion(')
          ..write('glyphId: $glyphId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('lineNumber: $lineNumber, ')
          ..write('suraNumber: $suraNumber, ')
          ..write('ayahNumber: $ayahNumber, ')
          ..write('position: $position, ')
          ..write('minX: $minX, ')
          ..write('maxX: $maxX, ')
          ..write('minY: $minY, ')
          ..write('maxY: $maxY')
          ..write(')'))
        .toString();
  }
}

abstract class _$AyahInfoDatabase extends GeneratedDatabase {
  _$AyahInfoDatabase(QueryExecutor e) : super(e);
  $AyahInfoDatabaseManager get managers => $AyahInfoDatabaseManager(this);
  late final $GlyphsTable glyphs = $GlyphsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [glyphs];
}

typedef $$GlyphsTableCreateCompanionBuilder = GlyphsCompanion Function({
  Value<int> glyphId,
  required int pageNumber,
  required int lineNumber,
  required int suraNumber,
  required int ayahNumber,
  required int position,
  required int minX,
  required int maxX,
  required int minY,
  required int maxY,
});
typedef $$GlyphsTableUpdateCompanionBuilder = GlyphsCompanion Function({
  Value<int> glyphId,
  Value<int> pageNumber,
  Value<int> lineNumber,
  Value<int> suraNumber,
  Value<int> ayahNumber,
  Value<int> position,
  Value<int> minX,
  Value<int> maxX,
  Value<int> minY,
  Value<int> maxY,
});

class $$GlyphsTableFilterComposer
    extends Composer<_$AyahInfoDatabase, $GlyphsTable> {
  $$GlyphsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get glyphId => $composableBuilder(
    column: $table.glyphId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineNumber => $composableBuilder(
    column: $table.lineNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get suraNumber => $composableBuilder(
    column: $table.suraNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahNumber => $composableBuilder(
    column: $table.ayahNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minX => $composableBuilder(
    column: $table.minX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxX => $composableBuilder(
    column: $table.maxX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minY => $composableBuilder(
    column: $table.minY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxY => $composableBuilder(
    column: $table.maxY,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GlyphsTableOrderingComposer
    extends Composer<_$AyahInfoDatabase, $GlyphsTable> {
  $$GlyphsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get glyphId => $composableBuilder(
    column: $table.glyphId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineNumber => $composableBuilder(
    column: $table.lineNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get suraNumber => $composableBuilder(
    column: $table.suraNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahNumber => $composableBuilder(
    column: $table.ayahNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minX => $composableBuilder(
    column: $table.minX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxX => $composableBuilder(
    column: $table.maxX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minY => $composableBuilder(
    column: $table.minY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxY => $composableBuilder(
    column: $table.maxY,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GlyphsTableAnnotationComposer
    extends Composer<_$AyahInfoDatabase, $GlyphsTable> {
  $$GlyphsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get glyphId =>
      $composableBuilder(column: $table.glyphId, builder: (column) => column);

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lineNumber => $composableBuilder(
    column: $table.lineNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get suraNumber => $composableBuilder(
    column: $table.suraNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ayahNumber => $composableBuilder(
    column: $table.ayahNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get minX =>
      $composableBuilder(column: $table.minX, builder: (column) => column);

  GeneratedColumn<int> get maxX =>
      $composableBuilder(column: $table.maxX, builder: (column) => column);

  GeneratedColumn<int> get minY =>
      $composableBuilder(column: $table.minY, builder: (column) => column);

  GeneratedColumn<int> get maxY =>
      $composableBuilder(column: $table.maxY, builder: (column) => column);
}

class $$GlyphsTableTableManager
    extends
        RootTableManager<
          _$AyahInfoDatabase,
          $GlyphsTable,
          GlyphRow,
          $$GlyphsTableFilterComposer,
          $$GlyphsTableOrderingComposer,
          $$GlyphsTableAnnotationComposer,
          $$GlyphsTableCreateCompanionBuilder,
          $$GlyphsTableUpdateCompanionBuilder,
          (
            GlyphRow,
            BaseReferences<_$AyahInfoDatabase, $GlyphsTable, GlyphRow>,
          ),
          GlyphRow,
          PrefetchHooks Function()
        > {
  $$GlyphsTableTableManager(_$AyahInfoDatabase db, $GlyphsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GlyphsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GlyphsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GlyphsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> glyphId = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<int> lineNumber = const Value.absent(),
                Value<int> suraNumber = const Value.absent(),
                Value<int> ayahNumber = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> minX = const Value.absent(),
                Value<int> maxX = const Value.absent(),
                Value<int> minY = const Value.absent(),
                Value<int> maxY = const Value.absent(),
              }) => GlyphsCompanion(
                glyphId: glyphId,
                pageNumber: pageNumber,
                lineNumber: lineNumber,
                suraNumber: suraNumber,
                ayahNumber: ayahNumber,
                position: position,
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
              ),
          createCompanionCallback:
              ({
                Value<int> glyphId = const Value.absent(),
                required int pageNumber,
                required int lineNumber,
                required int suraNumber,
                required int ayahNumber,
                required int position,
                required int minX,
                required int maxX,
                required int minY,
                required int maxY,
              }) => GlyphsCompanion.insert(
                glyphId: glyphId,
                pageNumber: pageNumber,
                lineNumber: lineNumber,
                suraNumber: suraNumber,
                ayahNumber: ayahNumber,
                position: position,
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GlyphsTable, GlyphRow>(table),
                  BaseReferences<_$AyahInfoDatabase, $GlyphsTable, GlyphRow>(
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

typedef $$GlyphsTableProcessedTableManager =
    ProcessedTableManager<
      _$AyahInfoDatabase,
      $GlyphsTable,
      GlyphRow,
      $$GlyphsTableFilterComposer,
      $$GlyphsTableOrderingComposer,
      $$GlyphsTableAnnotationComposer,
      $$GlyphsTableCreateCompanionBuilder,
      $$GlyphsTableUpdateCompanionBuilder,
      (GlyphRow, BaseReferences<_$AyahInfoDatabase, $GlyphsTable, GlyphRow>),
      GlyphRow,
      PrefetchHooks Function()
    >;

class $AyahInfoDatabaseManager {
  final _$AyahInfoDatabase _db;
  $AyahInfoDatabaseManager(this._db);
  $$GlyphsTableTableManager get glyphs =>
      $$GlyphsTableTableManager(_db, _db.glyphs);
}
