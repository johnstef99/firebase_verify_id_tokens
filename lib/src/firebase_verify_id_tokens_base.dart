import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'exceptions.dart';
import 'google_keys.dart';

export 'exceptions.dart';

/// Verify the validity of a Firebase ID token.
///
/// This class is used to verify the validity of a Firebase ID token. It
/// requires the Firebase project ID, which can be found in the Firebase
/// console.
///
/// The method of verifying the token is based on the method described in the
/// Firebase documentation [here](https://firebase.google.com/docs/auth/admin/verify-id-tokens).
class FirebaseVerifyTokenId {
  /// The Firebase project ID. This is the same as the project ID in the
  /// Firebase console.
  final String firebaseProjectId;

  /// The default url is [this](https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com)
  /// and it was taken from [here](https://firebase.google.com/docs/auth/admin/verify-id-tokens)
  final String? googlePublicKeysUrl;

  const FirebaseVerifyTokenId(
    this.firebaseProjectId, {
    this.googlePublicKeysUrl,
  });

  /// Initialize the Google Public Keys cache.
  ///
  /// This method is optional, as the cache will be initialized on the first
  /// call to [getUidFromToken].
  Future<void> initGooglePublicKeysCache() async {
    await GooglePublicKeys.getPublicKeys();
  }

  /// Verify the validity of a Firebase ID token.
  ///
  /// Throws a [FirebaseIdTokenInvalidException] if the token is invalid.
  /// Throws a [FirebaseIdTokenException] if the token could not be verified.
  Future<String> getUidFromToken(String token) async {
    try {
      final jwt = JWT.decode(token);

      final kid = jwt.header?['kid'];
      if (kid == null) {
        throw FirebaseIdTokenInvalidException();
      }

      final publicKeys = await GooglePublicKeys.getPublicKeys(
        googlePublicKeysUrl: googlePublicKeysUrl,
      );
      final publicKey = publicKeys[kid];
      if (publicKey == null) {
        throw FirebaseIdTokenInvalidException();
      }

      final uid = jwt.payload['sub'];
      if (uid == null) {
        throw FirebaseIdTokenInvalidException();
      }

      JWT.verify(
        token,
        RSAPublicKey.cert(publicKey),
        audience: Audience([firebaseProjectId]),
        issuer: 'https://securetoken.google.com/$firebaseProjectId',
      );

      return uid;
    } on JWTExpiredException {
      throw FirebaseIdTokenExpiredException();
    } on JWTException {
      throw FirebaseIdTokenInvalidException();
    } on FirebaseIdTokenException {
      rethrow;
    } catch (e) {
      throw FirebaseIdTokenException('Could not verify token');
    }
  }
}
