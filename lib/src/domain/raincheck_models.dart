enum HorizonOption { h6, h12, h24, h48 }

extension HorizonOptionText on HorizonOption {
  String get label => switch (this) {
    HorizonOption.h6 => '6h',
    HorizonOption.h12 => '12h',
    HorizonOption.h24 => '24h',
    HorizonOption.h48 => '48h',
  };

  String get copy => switch (this) {
    HorizonOption.h6 => 'next 6 hours',
    HorizonOption.h12 => 'next 12 hours',
    HorizonOption.h24 => 'next 24 hours',
    HorizonOption.h48 => 'next 48 hours',
  };
}

enum RecommendationStatus { safeToWash, notRecommended }

enum RainTolerancePreset { conservative, standard, flexible }

extension RainTolerancePresetText on RainTolerancePreset {
  String get label => switch (this) {
    RainTolerancePreset.conservative => 'Conservative',
    RainTolerancePreset.standard => 'Standard',
    RainTolerancePreset.flexible => 'Flexible',
  };

  String get description => switch (this) {
    RainTolerancePreset.conservative =>
      'Avoid washing if a moderate rain signal appears.',
    RainTolerancePreset.standard => 'Balanced guidance for typical use.',
    RainTolerancePreset.flexible =>
      'Allow light risk when the day is mostly dry.',
  };
}

sealed class LocationChoice {
  const LocationChoice();

  String get label;
  double get latitude;
  double get longitude;
  String get sourceLabel;
}

final class DeviceLocation extends LocationChoice {
  const DeviceLocation({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  final String displayName;

  @override
  final double latitude;

  @override
  final double longitude;

  @override
  String get label => displayName;

  @override
  String get sourceLabel => 'Using device location';
}

final class ManualLocation extends LocationChoice {
  const ManualLocation({
    required this.cityName,
    required this.latitude,
    required this.longitude,
  });

  final String cityName;

  @override
  final double latitude;

  @override
  final double longitude;

  @override
  String get label => cityName;

  @override
  String get sourceLabel => 'Manual location';
}

final class HourlyForecastItem {
  const HourlyForecastItem({
    required this.timeLabel,
    required this.condition,
    required this.rainChanceLabel,
  });

  final String timeLabel;
  final String condition;
  final String rainChanceLabel;
}

final class RecommendationViewData {
  const RecommendationViewData({
    required this.status,
    required this.headline,
    required this.reason,
    required this.validUntil,
    required this.nextRainLabel,
    required this.confidenceLabel,
    required this.disclaimer,
    required this.hourlyItems,
    required this.rainChanceLabel,
    required this.rainAmountLabel,
    required this.locationLabel,
    required this.generatedAtLabel,
  });

  final RecommendationStatus status;
  final String headline;
  final String reason;
  final String validUntil;
  final String nextRainLabel;
  final String confidenceLabel;
  final String disclaimer;
  final List<HourlyForecastItem> hourlyItems;
  final String rainChanceLabel;
  final String rainAmountLabel;
  final String locationLabel;
  final String generatedAtLabel;
}

final class UserPreferences {
  const UserPreferences({
    required this.defaultHorizon,
    required this.tolerancePreset,
    required this.locationChoice,
  });

  final HorizonOption defaultHorizon;
  final RainTolerancePreset tolerancePreset;
  final LocationChoice locationChoice;

  UserPreferences copyWith({
    HorizonOption? defaultHorizon,
    RainTolerancePreset? tolerancePreset,
    LocationChoice? locationChoice,
  }) {
    return UserPreferences(
      defaultHorizon: defaultHorizon ?? this.defaultHorizon,
      tolerancePreset: tolerancePreset ?? this.tolerancePreset,
      locationChoice: locationChoice ?? this.locationChoice,
    );
  }
}
