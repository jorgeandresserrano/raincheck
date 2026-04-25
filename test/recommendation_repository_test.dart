import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:raincheck/src/data/recommendation_repository.dart';
import 'package:raincheck/src/domain/raincheck_models.dart';

void main() {
  test(
    'explains accumulated rain trigger when flexible probability is moderate',
    () async {
      final now = DateTime.now().add(const Duration(hours: 1));
      final times = <String>[];
      final probabilities = <int>[];
      final precipitation = <double>[];

      for (var index = 0; index < HorizonOption.oneWeek.hours; index++) {
        times.add(now.add(Duration(hours: index)).toIso8601String());
        probabilities.add(23 + (index % 18));
        precipitation.add(index < 87 ? 0.1 : 0);
      }

      final repository = OpenMeteoRecommendationRepository(
        client: MockClient((request) async {
          expect(request.url.queryParameters['forecast_days'], '8');
          return http.Response(
            jsonEncode({
              'hourly': {
                'time': times,
                'precipitation_probability': probabilities,
                'precipitation': precipitation,
              },
            }),
            200,
          );
        }),
      );

      final recommendation = await repository.getRecommendation(
        location: const ManualLocation(
          cityName: 'Toronto, ON',
          latitude: 43.6532,
          longitude: -79.3832,
        ),
        horizon: HorizonOption.oneWeek,
        tolerance: RainTolerancePreset.flexible,
      );

      expect(recommendation.status, RecommendationStatus.notRecommended);
      expect(recommendation.rainChanceLabel, '40%');
      expect(recommendation.rainAmountLabel, '8.7 mm');
      expect(recommendation.detailReason, contains('below Flexible tolerance'));
      expect(recommendation.detailReason, contains('adds up to 8.7 mm'));
      expect(
        recommendation.detailReason,
        contains('above the 1.5 mm Flexible amount limit'),
      );
    },
  );
}
