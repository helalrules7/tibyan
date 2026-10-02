import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan_review/src/model/content_hash.dart';
import 'package:tibyan_review/src/model/model.dart';

void main() {
  // The same vectors are asserted in tools/tests/test_review_pipeline.py:
  // the tool and export_pack.py must agree on every hash.
  test('matches the Python content hash', () {
    expect(
      contentHash(
        sourceKey: 'test_book',
        volume: 1,
        page: 2,
        pageEnd: 3,
        text: 'نص أول\nسطر ثان',
        links: const [
          Link(surah: 2, ayahFrom: 3, ayahTo: 4),
          Link(surah: 2, ayahFrom: 1, ayahTo: 1, wordFrom: 2, wordTo: 5),
        ],
      ),
      '09a74b286bb472b432c75ff4244a1e3a812f68bae87e0dc6129478c6d4c1cc7e',
    );
    expect(
      contentHash(sourceKey: 'test_book', volume: null, page: null, pageEnd: null, text: 'x', links: const []),
      'd139698903294aec7b3d2958e0d849b5e0ea9fd8444a42ad5a5673910883a9cb',
    );
  });

  test('link order and link metadata do not change the hash', () {
    String h(List<Link> l) =>
        contentHash(sourceKey: 'k', volume: 1, page: 1, pageEnd: 1, text: 't', links: l);
    const a = Link(surah: 1, ayahFrom: 1, ayahTo: 1, basis: 'marker', confidence: 0.5);
    const b = Link(surah: 2, ayahFrom: 5, ayahTo: 6);
    expect(h([a, b]), h([b, a]));
    expect(h([a]), h([const Link(surah: 1, ayahFrom: 1, ayahTo: 1, basis: 'manual')]));
    expect(h([a]), isNot(h([const Link(surah: 1, ayahFrom: 1, ayahTo: 2)])));
  });
}
