import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class GooglePlacesException implements Exception {
  const GooglePlacesException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GooglePlaceResult {
  const GooglePlaceResult({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.types = const [],
  });

  factory GooglePlaceResult.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? const {};
    final displayName =
        json['displayName'] as Map<String, dynamic>? ?? const {};

    return GooglePlaceResult(
      id: json['id'] as String? ?? json['name'] as String? ?? '',
      name: displayName['text'] as String? ??
          json['formattedAddress'] as String? ??
          '未命名地點',
      address: json['formattedAddress'] as String?,
      latitude: (location['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (location['longitude'] as num?)?.toDouble() ?? 0,
      types: (json['types'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }

  final String id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final List<String> types;

  LatLng get latLng => LatLng(latitude, longitude);
}

class GooglePlacesService {
  const GooglePlacesService({
    required this.apiKey,
    http.Client? client,
  }) : _client = client;

  static final _defaultClient = http.Client();
  static const _baseUrl = 'https://places.googleapis.com/v1';
  static const _languageCode = 'zh-TW';
  static const _regionCode = 'TW';
  static const _fieldMask =
      'places.id,places.displayName,places.formattedAddress,places.location,places.types';

  final String apiKey;
  final http.Client? _client;

  bool get isConfigured => apiKey.trim().isNotEmpty;

  Future<List<GooglePlaceResult>> searchNearbyLandmarks(
    LatLng location,
  ) async {
    if (!isConfigured) {
      return const [];
    }

    final response = await client.post(
      Uri.parse('$_baseUrl/places:searchNearby'),
      headers: _headers,
      body: jsonEncode({
        'languageCode': _languageCode,
        'regionCode': _regionCode,
        'maxResultCount': 8,
        'rankPreference': 'POPULARITY',
        'locationRestriction': {
          'circle': {
            'center': {
              'latitude': location.latitude,
              'longitude': location.longitude,
            },
            'radius': 250.0,
          },
        },
      }),
    );

    return _parsePlacesResponse(response);
  }

  Future<List<GooglePlaceResult>> searchText({
    required String query,
    LatLng? locationBias,
  }) async {
    if (!isConfigured || query.trim().isEmpty) {
      return const [];
    }

    final body = <String, dynamic>{
      'textQuery': query.trim(),
      'languageCode': _languageCode,
      'regionCode': _regionCode,
      'maxResultCount': 8,
    };

    if (locationBias != null) {
      body['locationBias'] = {
        'circle': {
          'center': {
            'latitude': locationBias.latitude,
            'longitude': locationBias.longitude,
          },
          'radius': 20000.0,
        },
      };
    }

    final response = await client.post(
      Uri.parse('$_baseUrl/places:searchText'),
      headers: _headers,
      body: jsonEncode(body),
    );

    return _parsePlacesResponse(response);
  }

  http.Client get client => _client ?? _defaultClient;

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask': _fieldMask,
    };
  }

  List<GooglePlaceResult> _parsePlacesResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GooglePlacesException(_parseErrorMessage(response));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final places = json['places'] as List<dynamic>? ?? const [];

    return places
        .map((place) => GooglePlaceResult.fromJson(
              Map<String, dynamic>.from(place as Map),
            ))
        .where((place) => place.latitude != 0 || place.longitude != 0)
        .toList();
  }

  String _parseErrorMessage(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String?;
      final status = error?['status'] as String?;

      if (message != null && message.isNotEmpty) {
        return status == null
            ? 'Places API 查詢失敗：$message'
            : 'Places API 查詢失敗：$status - $message';
      }
    } catch (_) {
      // Fall through to a compact status message below.
    }

    return 'Places API 查詢失敗：HTTP ${response.statusCode}';
  }
}
