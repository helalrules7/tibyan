// TEST PACKS (closed testing, 2026-10-05) — remove before a public release.
//
// The owner's decision of 2026-10-05: the app is in a closed test, every
// feature flag is on, and testers should see the flagged sections now,
// from unreviewed drafts and from sources whose permission is still
// pending, clearly marked as test data. Every pack and index here is on
// Tibyan's server under /mirror/test/, and every title says it is a test
// draft. The book packs are `tools/export_pack.py --test-drafts` exports
// (pack_index status `test-drafts`); the others are stamped by
// `tools/stamp_test_packs.py`.
//
// To drop them all: set [includeTestPacks] to false (or delete this file
// and the three spreads that use it). docs/MISSING_DATA.md («قبل النشر
// العام») lists them with the flags to turn off.

import '../../features/books/data/book_pack.dart';
import '../../features/content_extras/english_tafsir.dart';
import '../../features/content_extras/verse_audio_index.dart';

/// The one switch for every test pack below.
const includeTestPacks = true;

/// Where every test pack lives.
const testPacksBaseUrl = 'https://tibyan.ahmedhelal.dev/mirror/test/';

/// The mark every test title carries.
const testTitleMarkAr = '(مسودة للاختبار)';
const testTitleMarkEn = '(test draft)';

/// Book packs of unreviewed drafts (tafsir books, asbab al-nuzul,
/// munasabat, wujuh), spread into [BookPackSpec.all].
const testBookPacks = includeTestPacks ? _testBookPacks : <BookPackSpec>[];

/// Audio link indexes (Nuqayah tafsir audio, QuranEnc English audio),
/// spread into [AudioIndexSpec.all].
const testAudioIndexes = includeTestPacks
    ? _testAudioIndexes
    : <AudioIndexSpec>[];

/// The English tafsir pack (QuranEnc), spread into
/// [TafsirTextPackSpec.english].
const testEnglishTafsirPacks = includeTestPacks
    ? _testEnglishTafsirPacks
    : <TafsirTextPackSpec>[];

const _books = '${testPacksBaseUrl}books/';
const _audio = '${testPacksBaseUrl}audio-index/';

const _testBookPacks = <BookPackSpec>[
  BookPackSpec(
    id: 'test-asbab-wahidi',
    url: '${_books}test-asbab-wahidi.pack.db',
    sha256: 'dd97ea2fc0e243eefbdf6e01ed9ea226b90b2c3a706e840755ed3b95ac8ffa74',
    bytes: 1241088,
    kind: BookKind.asbabNuzul,
    title: 'أسباب نزول القرآن للواحدي $testTitleMarkAr',
  ),
  BookPackSpec(
    id: 'test-munasabat-biqai',
    url: '${_books}test-munasabat-biqai.pack.db',
    sha256: '2b029aa6587ebb8f1a26742c417332c41420c284220904bfed9c4fef1c4cf30f',
    bytes: 18100224,
    kind: BookKind.munasabat,
    title: 'نظم الدرر للبقاعي $testTitleMarkAr',
  ),
  BookPackSpec(
    id: 'test-wujuh-damghani',
    url: '${_books}test-wujuh-damghani.pack.db',
    sha256: 'de8bc9ffc14291b8b8bdd7ce10bc62b33a933223037030ed4cdb7f7e9759cdff',
    bytes: 1363968,
    kind: BookKind.wujuhNazair,
    title: 'الوجوه والنظائر للدامغاني $testTitleMarkAr',
  ),
  BookPackSpec(
    id: 'test-tafsir-tabari',
    url: '${_books}test-tafsir-tabari.pack.db',
    sha256: '224f30702f40b402a09164d88511a91d1963c86c282f862649bb86a904afef70',
    bytes: 28868608,
    kind: BookKind.tafsir,
    title: 'تفسير الطبري $testTitleMarkAr',
  ),
  BookPackSpec(
    id: 'test-tafsir-qurtubi',
    url: '${_books}test-tafsir-qurtubi.pack.db',
    sha256: 'cfe872a2caeb0c95777dbe41f2bbc1dffc0352bed642957f4152bbf210c5f070',
    bytes: 21159936,
    kind: BookKind.tafsir,
    title: 'تفسير القرطبي $testTitleMarkAr',
  ),
  BookPackSpec(
    id: 'test-tafsir-ibn-kathir',
    url: '${_books}test-tafsir-ibn-kathir.pack.db',
    sha256: 'fd10a3d62b37c389b1dd6ea338d222f09ed1e3ec2c253d9f76dbbe5e3251684d',
    bytes: 15282176,
    kind: BookKind.tafsir,
    title: 'تفسير ابن كثير $testTitleMarkAr',
  ),
  BookPackSpec(
    id: 'test-tafsir-baghawi',
    url: '${_books}test-tafsir-baghawi.pack.db',
    sha256: 'c0c16ee6a9c79cb5596f6778bc6a2842ec5f5b837c1ce9483a8eb0663de6ef00',
    bytes: 9334784,
    kind: BookKind.tafsir,
    title: 'تفسير البغوي $testTitleMarkAr',
  ),
  BookPackSpec(
    id: 'test-tafsir-saadi',
    url: '${_books}test-tafsir-saadi.pack.db',
    sha256: 'd2785bd61b3ebd7844ceb0f50c332ab085a1f72d12e2025c3ee6445b1bf945cb',
    bytes: 6770688,
    kind: BookKind.tafsir,
    title: 'تفسير السعدي $testTitleMarkAr',
  ),
];

const _testAudioIndexes = <AudioIndexSpec>[
  AudioIndexSpec(
    id: 'test-nuqayah-almuyassar',
    kind: VerseAudioKind.tafsir,
    url: '${_audio}test-nuqayah-almuyassar.json',
    sha256: '5398441013124fb7dbf074d2e77b66af914993f35acd4a172103e84fe51e4d29',
  ),
  AudioIndexSpec(
    id: 'test-nuqayah-saadi',
    kind: VerseAudioKind.tafsir,
    url: '${_audio}test-nuqayah-saadi.json',
    sha256: 'ed0958e282e0df14e52994d9f5948a2237032e70573ce1b44db3e5e19d19941d',
  ),
  AudioIndexSpec(
    id: 'test-quranenc-english-rwwad',
    kind: VerseAudioKind.translation,
    url: '${_audio}test-quranenc-english-rwwad.json',
    sha256: '0a3fddfa3c446fc7bd1c15605ff3e02828196f39b474d76eaa54a03a2ab71f11',
  ),
];

const _testEnglishTafsirPacks = <TafsirTextPackSpec>[
  TafsirTextPackSpec(
    id: 'test-english-mokhtasar',
    url: '${_books}test-english-mokhtasar.pack.db',
    sha256: '65607b9dcd11f25928f43a27d7cde03c9560ff9a1669c6fc44701489dc2943e8',
    bytes: 2150400,
    title:
        'Al-Mukhtasar fi Tafsir al-Quran al-Karim (English) $testTitleMarkEn',
  ),
];
