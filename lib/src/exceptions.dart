class FirebaseIdTokenException implements Exception {
  const FirebaseIdTokenException(this.message);

  final String message;

  @override
  String toString() => 'FirebaseIdTokenException: $message';
}

class FirebaseIdTokenInvalidException extends FirebaseIdTokenException {
  const FirebaseIdTokenInvalidException() : super('Invalid token');
}

class FirebaseIdTokenExpiredException extends FirebaseIdTokenException {
  const FirebaseIdTokenExpiredException() : super('Token expired');
}
