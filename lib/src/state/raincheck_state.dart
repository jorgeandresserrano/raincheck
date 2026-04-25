import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raincheck/src/data/location_service.dart';
import 'package:raincheck/src/data/preferences_store.dart';
import 'package:raincheck/src/data/recommendation_repository.dart';
import 'package:raincheck/src/domain/raincheck_models.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => const DeviceLocationService(),
);

final recommendationRepositoryProvider = Provider<RecommendationRepository>(
  (ref) => const OpenMeteoRecommendationRepository(),
);

final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => const NoopPreferencesStore(),
);

final initialRainCheckPreferencesProvider =
    Provider<PersistedRainCheckPreferences?>((ref) => null);

final rainCheckControllerProvider =
    NotifierProvider<RainCheckController, RainCheckState>(
      RainCheckController.new,
    );

final recommendationProvider = FutureProvider<RecommendationViewData>((ref) {
  final repository = ref.watch(recommendationRepositoryProvider);
  final state = ref.watch(rainCheckControllerProvider);

  return repository.getRecommendation(
    location: state.preferences.locationChoice,
    horizon: state.selectedHorizon,
    tolerance: state.preferences.tolerancePreset,
  );
});

final class RainCheckState {
  const RainCheckState({
    required this.preferences,
    required this.selectedHorizon,
    required this.hasCompletedOnboarding,
    required this.isResolvingLocation,
    this.locationError,
  });

  factory RainCheckState.initial() {
    return const RainCheckState(
      preferences: UserPreferences(
        defaultHorizon: HorizonOption.oneDay,
        tolerancePreset: RainTolerancePreset.standard,
        locationChoice: ManualLocation(
          cityName: 'San Francisco, CA',
          latitude: 37.7749,
          longitude: -122.4194,
        ),
      ),
      selectedHorizon: HorizonOption.oneDay,
      hasCompletedOnboarding: false,
      isResolvingLocation: false,
    );
  }

  factory RainCheckState.fromPersisted(
    PersistedRainCheckPreferences preferences,
  ) {
    return RainCheckState(
      preferences: preferences.preferences,
      selectedHorizon: preferences.selectedHorizon,
      hasCompletedOnboarding: preferences.hasCompletedOnboarding,
      isResolvingLocation: false,
    );
  }

  final UserPreferences preferences;
  final HorizonOption selectedHorizon;
  final bool hasCompletedOnboarding;
  final bool isResolvingLocation;
  final String? locationError;

  RainCheckState copyWith({
    UserPreferences? preferences,
    HorizonOption? selectedHorizon,
    bool? hasCompletedOnboarding,
    bool? isResolvingLocation,
    String? locationError,
    bool clearLocationError = false,
  }) {
    return RainCheckState(
      preferences: preferences ?? this.preferences,
      selectedHorizon: selectedHorizon ?? this.selectedHorizon,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isResolvingLocation: isResolvingLocation ?? this.isResolvingLocation,
      locationError:
          clearLocationError ? null : locationError ?? this.locationError,
    );
  }

  PersistedRainCheckPreferences toPersistedPreferences() {
    return PersistedRainCheckPreferences(
      preferences: preferences,
      selectedHorizon: selectedHorizon,
      hasCompletedOnboarding: hasCompletedOnboarding,
    );
  }
}

final class RainCheckController extends Notifier<RainCheckState> {
  @override
  RainCheckState build() {
    final persisted = ref.watch(initialRainCheckPreferencesProvider);
    if (persisted != null) {
      return RainCheckState.fromPersisted(persisted);
    }
    return RainCheckState.initial();
  }

  Future<bool> completeOnboardingWithDeviceLocation() async {
    final success = await useDeviceLocation();
    if (success) {
      state = state.copyWith(hasCompletedOnboarding: true);
      _persist();
    }
    return success;
  }

  void completeOnboardingWithManualLocation(LocationSuggestion suggestion) {
    useManualLocation(suggestion);
    state = state.copyWith(hasCompletedOnboarding: true);
    _persist();
  }

  Future<bool> useDeviceLocation() async {
    state = state.copyWith(isResolvingLocation: true, clearLocationError: true);
    try {
      final location =
          await ref.read(locationServiceProvider).currentLocation();
      state = state.copyWith(
        isResolvingLocation: false,
        clearLocationError: true,
        preferences: state.preferences.copyWith(locationChoice: location),
      );
      _persist();
      return true;
    } on LocationServiceException catch (error) {
      state = state.copyWith(
        isResolvingLocation: false,
        locationError: error.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isResolvingLocation: false,
        locationError: 'Unable to resolve your location. Enter a city instead.',
      );
      return false;
    }
  }

  void useManualLocation(LocationSuggestion suggestion) {
    state = state.copyWith(
      clearLocationError: true,
      preferences: state.preferences.copyWith(
        locationChoice: suggestion.toManualLocation(),
      ),
    );
    _persist();
  }

  void selectHorizon(HorizonOption horizon) {
    state = state.copyWith(
      selectedHorizon: horizon,
      preferences: state.preferences.copyWith(defaultHorizon: horizon),
    );
    _persist();
  }

  void setTolerance(RainTolerancePreset preset) {
    state = state.copyWith(
      preferences: state.preferences.copyWith(tolerancePreset: preset),
    );
    _persist();
  }

  void _persist() {
    final snapshot = state.toPersistedPreferences();
    unawaited(
      ref.read(preferencesStoreProvider).save(snapshot).catchError((_) {}),
    );
  }
}
