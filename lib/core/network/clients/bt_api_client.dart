import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:bt_mobile/config/app_config.dart';
import 'package:bt_mobile/core/exceptions/api_exception.dart';

class BtApiClient {
  BtApiClient({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 15);

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    String? mobileToken,
  }) async {
    final uri = Uri.parse('${AppConfig.mobileAuthBase}/$path.json');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (mobileToken != null && mobileToken.isNotEmpty) {
      headers['X-Mobile-Token'] = mobileToken;
    }

    final response = await _client.post(
      uri,
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    );

    return _decodeEnvelope(response);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    String? mobileToken,
  }) async {
    final uri = Uri.parse('${AppConfig.mobileAuthBase}/$path.json');
    final headers = <String, String>{'Accept': 'application/json'};
    if (mobileToken != null && mobileToken.isNotEmpty) {
      headers['X-Mobile-Token'] = mobileToken;
    }

    final response = await _client.get(uri, headers: headers).timeout(_timeout);
    return _decodeEnvelope(response);
  }

  Map<String, dynamic> _decodeEnvelope(http.Response response) {
    Map<String, dynamic> envelope = {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        envelope = decoded;
      }
    }

    final status = envelope['status'] as int? ?? response.statusCode;
    if (status == 200 && response.statusCode >= 200 && response.statusCode < 300) {
      final data = envelope['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'result': data};
    }

    final message = envelope['message'] as String? ??
        (envelope['data'] is Map
            ? (envelope['data'] as Map)['error'] as String?
            : null) ??
        'Request failed';
    final expired = envelope['data'] is Map &&
        (envelope['data'] as Map)['expired'] == true;

    throw ApiException(
      message,
      statusCode: status,
      expired: expired == true,
    );
  }
}
