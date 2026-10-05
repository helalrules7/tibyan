/// Plain data classes for the review database (tools/review_schema.sql).
library;

enum ReviewState {
  draft('draft', 'مسودة'),
  inReview('in_review', 'قيد المراجعة'),
  reviewed('reviewed', 'مراجَع');

  const ReviewState(this.db, this.label);
  final String db;
  final String label;

  static ReviewState parse(String s) =>
      values.firstWhere((v) => v.db == s, orElse: () => throw FormatException('state $s'));
}

enum Role {
  editor('editor', 'محرر'),
  reviewer('reviewer', 'مراجع'),
  admin('admin', 'مشرف');

  const Role(this.db, this.label);
  final String db;
  final String label;

  static Role parse(String s) =>
      values.firstWhere((v) => v.db == s, orElse: () => throw FormatException('role $s'));
}

/// Who is acting, and in which role. Every action stores both.
class Actor {
  const Actor(this.name, this.role);
  final String name;
  final Role role;
}

class Source {
  const Source({
    required this.id,
    required this.key,
    required this.kind,
    required this.title,
    required this.author,
    this.edition,
    this.publisher,
    this.tahqiq,
    required this.licence,
    this.digitisedBy,
    required this.url,
    required this.sha256,
  });

  final int id;
  final String key;
  final String kind;
  final String title;
  final String author;
  final String? edition;
  final String? publisher;
  final String? tahqiq;
  final String licence;
  final String? digitisedBy;
  final String url;
  final String sha256;
}

/// A verse link. `wordFrom`/`wordTo` are 1-based words of `ayahFrom` in the
/// KFGQPC text, or null for the whole verse(s).
class Link {
  const Link({
    required this.surah,
    required this.ayahFrom,
    required this.ayahTo,
    this.wordFrom,
    this.wordTo,
    this.quote,
    this.basis = 'manual',
    this.confidence = 1,
    this.createdBy = '',
  });

  final int surah;
  final int ayahFrom;
  final int ayahTo;
  final int? wordFrom;
  final int? wordTo;
  final String? quote;
  final String basis;
  final double confidence;
  final String createdBy;

  /// The part of a link that a reviewer approves (and that is hashed).
  bool sameTarget(Link o) =>
      surah == o.surah &&
      ayahFrom == o.ayahFrom &&
      ayahTo == o.ayahTo &&
      wordFrom == o.wordFrom &&
      wordTo == o.wordTo;

  String get label {
    final verses = ayahFrom == ayahTo ? '$surah:$ayahFrom' : '$surah:$ayahFrom-$ayahTo';
    if (wordFrom == null) return verses;
    return '$verses (كلمة $wordFrom${wordTo != null && wordTo != wordFrom ? '-$wordTo' : ''})';
  }

  Map<String, Object?> toJson() => {
        'surah': surah,
        'ayah_from': ayahFrom,
        'ayah_to': ayahTo,
        'word_from': wordFrom,
        'word_to': wordTo,
        'basis': basis,
        'confidence': confidence,
      };
}

class Entry {
  const Entry({
    required this.id,
    required this.sourceId,
    required this.seq,
    required this.kind,
    this.section,
    this.volume,
    this.page,
    this.pageEnd,
    required this.text,
    required this.createdBy,
    required this.createdAt,
    this.scriptConfidence,
    required this.state,
    this.editor,
    this.editedAt,
    this.reviewer,
    this.reviewedAt,
    this.note,
    required this.contentHash,
    required this.updatedAt,
    this.links = const [],
  });

  final int id;
  final int sourceId;
  final int seq;
  final String kind;
  final String? section;
  final int? volume;
  final int? page;
  final int? pageEnd;
  final String text;
  final String createdBy;
  final String createdAt;
  final double? scriptConfidence;
  final ReviewState state;
  final String? editor;
  final String? editedAt;
  final String? reviewer;
  final String? reviewedAt;
  final String? note;
  final String contentHash;
  final String updatedAt;
  final List<Link> links;

  String get kindLabel => entryKindLabel(kind);
}

/// The Arabic name of an entry kind (tools/review_schema.sql, `entry.kind`).
/// Kinds written by the importers: passage, surah_intro, front_matter
/// (every book); chapter, word, wajh (books of al-wujuh wa-l-nazair).
String entryKindLabel(String kind) => switch (kind) {
      'passage' => 'مقطع',
      'surah_intro' => 'مطلع سورة',
      'front_matter' => 'مقدمة الكتاب',
      'chapter' => 'باب',
      'word' => 'كلمة ووجوهها',
      'wajh' => 'وجه',
      _ => kind,
    };

/// A short row for the entry list.
class EntrySummary {
  const EntrySummary({
    required this.id,
    required this.seq,
    required this.kind,
    this.section,
    this.page,
    required this.state,
    this.confidence,
    this.firstLink,
    required this.preview,
  });

  final int id;
  final int seq;
  final String kind;
  final String? section;
  final int? page;
  final ReviewState state;
  final double? confidence;
  final String? firstLink;
  final String preview;
}

class AuditRow {
  const AuditRow({
    required this.id,
    required this.at,
    required this.actor,
    required this.role,
    required this.action,
    this.fromState,
    this.toState,
    this.note,
    this.detail,
  });

  final int id;
  final String at;
  final String actor;
  final String role;
  final String action;
  final String? fromState;
  final String? toState;
  final String? note;
  final String? detail;
}

class Verse {
  const Verse(this.surah, this.ayah, this.displayText, this.page);
  final int surah;
  final int ayah;

  /// KFGQPC Hafs 2.0 text, verbatim; ends with a space and the verse-number
  /// glyph of the KFGQPC font.
  final String displayText;
  final int page;

  /// Words of the KFGQPC text without the verse-number glyph.
  List<String> get words {
    final parts = displayText.trim().split(RegExp(r'\s+'));
    return parts.length > 1 ? parts.sublist(0, parts.length - 1) : parts;
  }
}

class SurahInfo {
  const SurahInfo(this.id, this.nameAr, this.ayahCount);
  final int id;
  final String nameAr;
  final int ayahCount;
}

/// Filters for the entry list.
class EntryFilter {
  const EntryFilter({this.state, this.kind, this.surah, this.maxConfidence, this.search});
  final ReviewState? state;
  final String? kind;
  final int? surah;

  /// Only entries whose best script confidence is below this (or unlinked).
  final double? maxConfidence;
  final String? search;
}
