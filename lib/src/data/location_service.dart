import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:raincheck/src/domain/raincheck_models.dart';

final class LocationServiceException implements Exception {
  const LocationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class LocationService {
  Future<LocationChoice> currentLocation();

  Future<LocationChoice> manualLocation(String query);
}

final class DeviceLocationService implements LocationService {
  const DeviceLocationService();

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
  Future<LocationChoice> manualLocation(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      throw const LocationServiceException('Enter a city to continue.');
    }

    final matches = await locationFromAddress(trimmed);
    if (matches.isEmpty) {
      throw LocationServiceException('No location found for "$trimmed".');
    }

    final match = matches.first;
    final label = await _labelForCoordinates(match.latitude, match.longitude);

    return ManualLocation(
      cityName: label,
      latitude: match.latitude,
      longitude: match.longitude,
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
