enum HorizonOption { oneDay, threeDays, fiveDays, oneWeek }

extension HorizonOptionText on HorizonOption {
  String get label => switch (this) {
    HorizonOption.oneDay => '1 day',
    HorizonOption.threeDays => '3 days',
    HorizonOption.fiveDays => '5 days',
    HorizonOption.oneWeek => '1 week',
  };

  String get copy => switch (this) {
    HorizonOption.oneDay => 'next day',
    HorizonOption.threeDays => 'next 3 days',
    HorizonOption.fiveDays => 'next 5 days',
    HorizonOption.oneWeek => 'next week',
  };

  int get hours => switch (this) {
    HorizonOption.oneDay => 24,
    HorizonOption.threeDays => 72,
    HorizonOption.fiveDays => 120,
    HorizonOption.oneWeek => 168,
  };

  int get forecastDays => switch (this) {
    HorizonOption.oneDay => 2,
    HorizonOption.threeDays => 4,
    HorizonOption.fiveDays => 6,
    HorizonOption.oneWeek => 8,
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

final class ForecastEvidenceItem {
  const ForecastEvidenceItem({
    required this.title,
    required this.description,
    required this.rainChanceLabel,
    required this.rainAmountLabel,
  });

  final String title;
  final String description;
  final String rainChanceLabel;
  final String rainAmountLabel;
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
    required this.detailTitle,
    required this.detailItems,
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
  final String detailTitle;
  final List<ForecastEvidenceItem> detailItems;
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
