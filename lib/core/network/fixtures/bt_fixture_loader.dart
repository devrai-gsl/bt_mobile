import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads mock API fixtures from [lib/core/network/fixtures/mock/].
/// JSON files use the same `{ status, data, message }` envelope as the backend.
class BtFixtureLoader {
  BtFixtureLoader({String? root})
      : _root = root ?? 'lib/core/network/fixtures/mock';

  final String _root;

  Future<Map<String, dynamic>> loadEnvelope(String fileName) async {
    final raw = await rootBundle.loadString('$_root/$fileName');
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Fixture $_root/$fileName must be a JSON object');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> loadData(String fileName) async {
    final envelope = await loadEnvelope(fileName);
    final status = envelope['status'] as int? ?? 200;
    if (status != 200) {
      final message = envelope['message'] as String? ?? 'Fixture error';
      throw StateError(message);
    }
    final data = envelope['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is List) return {'items': data};
    return {};
  }
}
