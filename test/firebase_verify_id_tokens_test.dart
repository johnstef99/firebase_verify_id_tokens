import 'package:firebase_verify_id_tokens/src/google_keys.dart';
import 'package:test/test.dart';

void main() {
  test('Default google keys url works', () async {
    try {
      final keys = await GooglePublicKeys.getPublicKeys();
      expect(keys.keys.length, greaterThan(0));
    } catch (e) {
      fail('Could not get Google\'s public keys');
    }
  });
}
