This package verifies that a Firebase token ID is valid and gives you the UID
of the user.

## Features

- verify Firebase token ID
- extract user's UID from token

## Getting started

All you need to known is the firebase project id that your users are logging
into.

## Usage

```dart
final firebaseTokenVerifier = FirebaseVerifyTokenId('firebase_project_id');
final uid = await firebaseTokenVerifier.getUidFromToken('JWT_token');
print('Hello user $uid');
```

## Additional information

The method of verifying the token is based on the method described in the
Firebase documentation [here](https://firebase.google.com/docs/auth/admin/verify-id-tokens).
