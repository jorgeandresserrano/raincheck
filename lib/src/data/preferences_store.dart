import 'package:raincheck/src/domain/raincheck_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PreferencesStore {
  Future<PersistedRainCheckPreferences?> load();

  Future<void> save(PersistedRainCheckPreferences preferences);
}

final class NoopPreferencesStore implements PreferencesStore {
  const NoopPreferencesStore();

  @override
  Future<PersistedRainCheckPreferences?> load() async => null;

  @override
  Future<void> save(PersistedRainCheckPreferences preferences) async {}
}

final class SharedPreferencesStore implements PreferencesStore {
  const SharedPreferencesStore();

  static const _hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const _defaultHorizonKey = 'default_horizon';
  static const _selectedHorizonKey = 'selected_horizon';
  static const _toleranceKey = 'tolerance';
  static const _locationSourceKey = 'location_source';
  static const _locationLabelKey = 'location_label';
  static const _latitudeKey = 'latitude';
  static const _longitudeKey = 'longitude';

  static const _deviceLocationSource = 'device';
  static const _manualLocationSource = 'manual';

  @override
  Future<PersistedRainCheckPreferences?> load() async {
    final storage = await SharedPreferences.getInstance();
    final latitude = storage.getDouble(_latitudeKey);
    final longitude = storage.getDouble(_longitudeKey);
    final label = storage.getString(_locationLabelKey);

    if (latitude == null ||
        longitude == null ||
        label == null ||
        label.trim().isEmpty) {
      return null;
    }

    final selectedHorizon =
        _horizonFromName(storage.getString(_selectedHorizonKey)) ??
        _horizonFromName(storage.getString(_defaultHorizonKey)) ??
        HorizonOption.h24;
    final defaultHorizon =
        _horizonFromName(storage.getString(_defaultHorizonKey)) ??
        selectedHorizon;
    final tolerance =
        _toleranceFromName(storage.getString(_toleranceKey)) ??
        RainTolerancePreset.standard;
    final source = storage.getString(_locationSourceKey);
    final location =
        source == _deviceLocationSource
            ? DeviceLocation(
              displayName: label,
              latitude: latitude,
              longitude: longitude,
            )
            : ManualLocation(
              cityName: label,
              latitude: latitude,
              longitude: longitude,
            );

    return PersistedRainCheckPreferences(
      preferences: UserPreferences(
        defaultHorizon: defaultHorizon,
        tolerancePreset: tolerance,
        locationChoice: location,
      ),
      selectedHorizon: selectedHorizon,
      hasCompletedOnboarding:
          storage.getBool(_hasCompletedOnboardingKey) ?? false,
    );
  }

  @override
  Future<void> save(PersistedRainCheckPreferences preferences) async {
    final storage = await SharedPreferences.getInstance();
    final location = preferences.preferences.locationChoice;
    final locationSource = switch (location) {
      DeviceLocation() => _deviceLocationSource,
      ManualLocation() => _manualLocationSource,
    };

    await Future.wait([
      storage.setBool(
        _hasCompletedOnboardingKey,
        preferences.hasCompletedOnboarding,
      ),
      storage.setString(
        _defaultHorizonKey,
        preferences.preferences.defaultHorizon.name,
      ),
      storage.setString(_selectedHorizonKey, preferences.selectedHorizon.name),
      storage.setString(
        _toleranceKey,
        preferences.preferences.tolerancePreset.name,
      ),
      storage.setString(_locationSourceKey, locationSource),
      storage.setString(_locationLabelKey, location.label),
      storage.setDouble(_latitudeKey, location.latitude),
      storage.setDouble(_longitudeKey, location.longitude),
    ]);
  }

  HorizonOption? _horizonFromName(String? name) {
    for (final value in HorizonOption.values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }

  RainTolerancePreset? _toleranceFromName(String? name) {
    for (final value in RainTolerancePreset.values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }
}

final class PersistedRainCheckPreferences {
  const PersistedRainCheckPreferences({
    required this.preferences,
    required this.selectedHorizon,
    required this.hasCompletedOnboarding,
  });

  final UserPreferences preferences;
  final HorizonOption selectedHorizon;
  final bool hasCompletedOnboarding;
}
