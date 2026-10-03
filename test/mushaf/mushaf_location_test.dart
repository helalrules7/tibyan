import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/features/mushaf/presentation/navigation.dart';

void main() {
  test('going to the same page twice gives two locations', () {
    final a = mushafLocation(1);
    final b = mushafLocation(1);
    expect(a, isNot(b));
    expect(Uri.parse(a).queryParameters['page'], '1');
    final c = Uri.parse(mushafLocation(50, surah: 3, ayah: 7));
    expect(c.queryParameters['s'], '3');
    expect(c.queryParameters['a'], '7');
  });
}
