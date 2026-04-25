import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:raincheck/src/domain/raincheck_models.dart';

final class LocationServiceException implements Exception {
  const LocationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class LocationService {
  Future<LocationChoice> currentLocation();

  Future<List<LocationSuggestion>> searchLocations(String query);
}

final class DeviceLocationService implements LocationService {
  const DeviceLocationService({http.Client? client}) : _client = client;

  final http.Client? _client;

  @override
  Future<LocationChoice> currentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException(
        'Location services are turned off. Enter a city or enable location services.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'Location permission was denied. Enter a city to continue.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Location permission is blocked. Enter a city or enable permission in system settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
    final label = await _labelForCoordinates(
      position.latitude,
      position.longitude,
    );

    return DeviceLocation(
      displayName: label,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  Future<List<LocationSuggestion>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      return const [];
    }

    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': trimmed,
      'count': '6',
      'language': 'en',
      'format': 'json',
    });

    final client = _client ?? http.Client();
    final response = await client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const LocationServiceException(
        'Location search is unavailable. Try again in a moment.',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['results'] as List<dynamic>?) ?? [];
    if (results.isEmpty) {
      return const [];
    }

    return results
        .whereType<Map<String, dynamic>>()
        .map(_suggestionFromOpenMeteoResult)
        .nonNulls
        .toList();
  }

  LocationSuggestion? _suggestionFromOpenMeteoResult(
    Map<String, dynamic> result,
  ) {
    final name = (result['name'] as String?)?.trim();
    final latitude = (result['latitude'] as num?)?.toDouble();
    final longitude = (result['longitude'] as num?)?.toDouble();
    if (name == null || name.isEmpty || latitude == null || longitude == null) {
      return null;
    }

    final admin1 = (result['admin1'] as String?)?.trim();
    final country = (result['country'] as String?)?.trim();
    final parts = [
      name,
      if (admin1 != null && admin1.isNotEmpty) admin1,
      if (country != null && country.isNotEmpty) country,
    ];

    return LocationSuggestion(
      label: parts.join(', '),
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<String> _labelForCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locality = place.locality?.trim();
        final admin = place.administrativeArea?.trim();
        final country = place.country?.trim();
        final parts = [
          if (locality != null && locality.isNotEmpty) locality,
          if (admin != null && admin.isNotEmpty) admin,
          if (country != null && country.isNotEmpty) country,
        ];
        if (parts.isNotEmpty) {
          return parts.take(2).join(', ');
        }
      }
    } catch (_) {
      // Coordinates still work for forecasts, even if reverse geocoding fails.
    }

    return '${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)}';
  }
}
