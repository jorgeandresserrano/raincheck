import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:raincheck/src/domain/raincheck_models.dart';

abstract interface class RecommendationRepository {
  Future<RecommendationViewData> getRecommendation({
    required LocationChoice location,
    required HorizonOption horizon,
    required RainTolerancePreset tolerance,
  });
}

final class OpenMeteoRecommendationRepository
    implements RecommendationRepository {
  const OpenMeteoRecommendationRepository({http.Client? client})
    : _client = client;

  final http.Client? _client;

  @override
  Future<RecommendationViewData> getRecommendation({
    required LocationChoice location,
    required HorizonOption horizon,
    required RainTolerancePreset tolerance,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': location.latitude.toString(),
      'longitude': location.longitude.toString(),
      'hourly': 'precipitation_probability,precipitation',
      'forecast_days': horizon.forecastDays.toString(),
      'timezone': 'auto',
    });

    final client = _client ?? http.Client();
    final response = await client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Forecast service returned ${response.statusCode}.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return _recommendationFromForecast(
      body: body,
      location: location,
      horizon: horizon,
      tolerance: tolerance,
    );
  }

  RecommendationViewData _recommendationFromForecast({
    required Map<String, dynamic> body,
    required LocationChoice location,
    required HorizonOption horizon,
    required RainTolerancePreset tolerance,
  }) {
    final hourly = body['hourly'] as Map<String, dynamic>?;
    final times = (hourly?['time'] as List<dynamic>?)?.cast<String>() ?? [];
    final probability =
        (hourly?['precipitation_probability'] as List<dynamic>?) ?? [];
    final precipitation = (hourly?['precipitation'] as List<dynamic>?) ?? [];

    if (times.isEmpty || probability.isEmpty || precipitation.isEmpty) {
      throw Exception('Forecast response did not include hourly rain data.');
    }

    final hours = horizon.hours;
    final now = DateTime.now();
    final startIndex = max(
      0,
      times.indexWhere((value) {
        final parsed = DateTime.tryParse(value);
        return parsed != null && !parsed.isBefore(now);
      }),
    );
    final endIndex = min(times.length, startIndex + hours);

    final window = <_ForecastHour>[];
    for (var index = startIndex; index < endIndex; index++) {
      window.add(
        _ForecastHour(
          time: DateTime.parse(times[index]),
          precipitationProbability:
              (probability[index] as num?)?.round().clamp(0, 100) ?? 0,
          precipitationMm: ((precipitation[index] as num?)?.toDouble() ?? 0)
              .clamp(0, 100),
        ),
      );
    }

    if (window.isEmpty) {
      throw Exception('Forecast response did not include the selected window.');
    }

    final maxProbability = window
        .map((hour) => hour.precipitationProbability)
        .reduce(max);
    final totalPrecipitation = window.fold<double>(
      0,
      (sum, hour) => sum + hour.precipitationMm,
    );
    final thresholds = _thresholds(tolerance);
    final notRecommended =
        maxProbability >= thresholds.probability ||
        totalPrecipitation >= thresholds.precipitationMm;
    final firstRain =
        window.where((hour) => hour.precipitationMm > 0).firstOrNull;

    return RecommendationViewData(
      status:
          notRecommended
              ? RecommendationStatus.notRecommended
              : RecommendationStatus.safeToWash,
      headline: notRecommended ? 'Not recommended' : 'Safe to wash',
      reason:
          notRecommended
              ? _unsafeReason(maxProbability, totalPrecipitation, horizon)
              : _safeReason(maxProbability, totalPrecipitation, horizon),
      validUntil: 'Checked for ${horizon.copy}',
      nextRainLabel:
          firstRain == null
              ? 'No rain in window'
              : 'Rain around ${_formatHour(firstRain.time)}',
      confidenceLabel: _confidenceLabel(maxProbability),
      disclaimer:
          'Recommendation based on the current forecast for ${location.label}. Forecasts can change.',
      rainChanceLabel: '$maxProbability%',
      rainAmountLabel: '${totalPrecipitation.toStringAsFixed(1)} mm',
      locationLabel: location.label,
      generatedAtLabel: 'Updated ${_formatHour(DateTime.now())}',
      hourlyItems:
          window.take(6).map((hour) {
            return HourlyForecastItem(
              timeLabel: _formatHour(hour.time),
              condition:
                  hour.precipitationMm > 0
                      ? 'Rain possible'
                      : 'No rain expected',
              rainChanceLabel: '${hour.precipitationProbability}%',
            );
          }).toList(),
    );
  }

  _RiskThresholds _thresholds(RainTolerancePreset tolerance) =>
      switch (tolerance) {
        RainTolerancePreset.conservative => const _RiskThresholds(25, 0.3),
        RainTolerancePreset.standard => const _RiskThresholds(45, 0.8),
        RainTolerancePreset.flexible => const _RiskThresholds(65, 1.5),
      };

  String _safeReason(
    int probability,
    double precipitation,
    HorizonOption horizon,
  ) {
    if (precipitation == 0) {
      return 'No measurable rain is forecast in the ${horizon.copy}.';
    }
    return 'Only ${precipitation.toStringAsFixed(1)} mm of rain is forecast in the ${horizon.copy}.';
  }

  String _unsafeReason(
    int probability,
    double precipitation,
    HorizonOption horizon,
  ) {
    if (precipitation >= 1) {
      return '${precipitation.toStringAsFixed(1)} mm of rain is forecast in the ${horizon.copy}.';
    }
    return 'Rain risk reaches $probability% in the ${horizon.copy}.';
  }

  String _confidenceLabel(int probability) {
    if (probability <= 20 || probability >= 70) {
      return 'High';
    }
    return 'Medium';
  }

  String _formatHour(DateTime time) {
    final hour = time.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour ${period.toLowerCase()}';
  }
}

final class _ForecastHour {
  const _ForecastHour({
    required this.time,
    required this.precipitationProbability,
    required this.precipitationMm,
  });

  final DateTime time;
  final int precipitationProbability;
  final double precipitationMm;
}

final class _RiskThresholds {
  const _RiskThresholds(this.probability, this.precipitationMm);

  final int probability;
  final double precipitationMm;
}
