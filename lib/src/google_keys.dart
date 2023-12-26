import 'dart:convert';

import 'package:http/http.dart' as http;

class GooglePublicKeysException implements Exception {
  final String message;

  GooglePublicKeysException(this.message);

  @override
  String toString() => 'GooglePublicKeysException: $message';
}

class GooglePublicKeys {
  static Map<String, String>? _cachedKeys;
  static DateTime? _cachedKeysValidUntil;

  static const _googlePublicKeysUrl =
      'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

  static Future<http.Response> _fetchPublicKeys(String? url) async =>
      await http.get(Uri.parse(url ?? _googlePublicKeysUrl));

  static int _getMaxAgeFromHeaders(Map<String, String> headers) {
    // get max-age from cache-control header
    final cacheControl = headers['cache-control'];
    if (cacheControl == null) {
      throw Exception('Missing cache-control header');
    }
    final maxAge = cacheControl.split(', ').firstWhere(
          (element) => element.startsWith('max-age='),
          orElse: () => '',
        );
    if (maxAge.isEmpty) {
      // max-age not found
      throw Exception('Missing max-age in cache-control header');
    }
    // get max-age value
    final maxAgeValue = int.tryParse(maxAge.substring(8));
    if (maxAgeValue == null) {
      // max-age is not a number
      throw Exception('Invalid max-age value');
    }
    return maxAgeValue;
  }

  static Future<Map<String, String>> getPublicKeys({
    String? googlePublicKeysUrl,
  }) async {
    if (_cachedKeys != null &&
        _cachedKeysValidUntil != null &&
        _cachedKeysValidUntil!.isAfter(DateTime.now())) {
      return _cachedKeys!;
    }
    try {
      final response = await _fetchPublicKeys(googlePublicKeysUrl);
      if (response.statusCode != 200) {
        throw GooglePublicKeysException(
            'Server responded with ${response.statusCode}. Check the url $_googlePublicKeysUrl');
      }

      final maxAge = _getMaxAgeFromHeaders(response.headers);
      _cachedKeys = (jsonDecode(response.body) as Map).cast<String, String>();
      _cachedKeysValidUntil = DateTime.now().add(Duration(seconds: maxAge));
      return _cachedKeys!;
    } on GooglePublicKeysException {
      rethrow;
    } catch (e) {
      throw GooglePublicKeysException('Failed to get Google\'s public keys');
    }
  }
}
