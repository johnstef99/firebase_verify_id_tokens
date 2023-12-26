import 'dart:io';

import 'package:firebase_verify_id_tokens/firebase_verify_id_tokens.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Example dart server that uses the firebase_verify_id_tokens package to create
// a middleware that verifies the validity of a Firebase ID token and passes on
// the uid of the user to the request.

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

// firebase auth middleware
Middleware firebaseAuthMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        final authHeader = request.headers['Authorization'];
        if (authHeader == null) {
          throw AuthException('Missing Authorization header');
        }
        final uid = await firebaseTokenVerifier.getUidFromToken(authHeader);
        return innerHandler(request.change(context: {'uid': uid}));
      } on FirebaseIdTokenException catch (e) {
        return Response.forbidden(e.message);
      } on AuthException catch (e) {
        return Response.forbidden(e.message);
      } catch (e) {
        return Response.internalServerError(body: 'Internal server error');
      }
    };
  };
}

final _router = Router()..get('/', _rootHandler);

Response _rootHandler(Request request) {
  final uid = request.context['uid'] as String;
  return Response.ok('Hello, $uid');
}

late final FirebaseVerifyTokenId firebaseTokenVerifier;

void main(List<String> args) async {
  if (Platform.environment['FIREBASE_PROJECT_ID'] == null) {
    print('Missing FIREBASE_PROJECT_ID environment variable');
    exit(1);
  }

  // Initialize the Firebase token verifier.
  firebaseTokenVerifier =
      FirebaseVerifyTokenId(Platform.environment['FIREBASE_PROJECT_ID']!);
  await firebaseTokenVerifier.initGooglePublicKeysCache();

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(firebaseAuthMiddleware())
      .addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
