import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raincheck/src/data/location_service.dart';
import 'package:raincheck/src/data/preferences_store.dart';
import 'package:raincheck/src/data/recommendation_repository.dart';
import 'package:raincheck/src/domain/raincheck_models.dart';
import 'package:raincheck/src/raincheck_app.dart';

Widget _app({
  LocationService? locationService,
  RecommendationRepository? recommendationRepository,
  PersistedRainCheckPreferences? initialPreferences,
}) {
  return RainCheckApp(
    locationService: locationService,
    recommendationRepository: recommendationRepository,
    initialPreferences: initialPreferences,
  );
}

Future<void> _pumpApp(
  WidgetTester tester, {
  LocationService? locationService,
  RecommendationRepository? recommendationRepository,
  PersistedRainCheckPreferences? initialPreferences,
}) async {
  tester.view.physicalSize = const Size(390, 1900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    _app(
      locationService: locationService ?? const _FakeLocationService(),
      recommendationRepository:
          recommendationRepository ?? const _FakeRecommendationRepository(),
      initialPreferences: initialPreferences,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openHome(WidgetTester tester) async {
  await _pumpApp(tester);
  await tester.tap(find.byKey(const Key('use-location-button')));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding resolves current location and shows the place used', (
    tester,
  ) async {
    await _openHome(tester);

    expect(find.text('Safe to wash'), findsOneWidget);
    expect(find.text('Toronto, ON'), findsOneWidget);
    expect(find.text('Using device location'), findsOneWidget);
  });

  testWidgets('manual location fallback feeds the home recommendation', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('manual-entry-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('manual-city-field')),
      'Austin, TX',
    );
    await tester.tap(find.byKey(const Key('save-manual-city-button')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Safe to wash'), findsOneWidget);
    expect(find.text('Austin, TX'), findsOneWidget);
    expect(find.text('Manual location'), findsOneWidget);
  });

  testWidgets('home switches horizons and opens live forecast details', (
    tester,
  ) async {
    await _openHome(tester);

    expect(find.text('Safe to wash'), findsOneWidget);

    await tester.tap(find.text('1 week'));
    await tester.pumpAndSettle();

    expect(find.text('32%'), findsOneWidget);
    await tester.tap(find.byKey(const Key('details-button')));
    await tester.pumpAndSettle();

    expect(find.text('Hourly outlook'), findsOneWidget);
    expect(find.text('No rain expected'), findsWidgets);
  });

  testWidgets('location sheet can change the city from home', (tester) async {
    await _openHome(tester);

    await tester.tap(find.text('Toronto, ON'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('home-city-field')), 'Austin');
    await tester.tap(find.byKey(const Key('sheet-save-location-button')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Austin, TX'), findsOneWidget);
    expect(find.text('Manual location'), findsOneWidget);
  });

  testWidgets('forecast errors render a retryable production error state', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      recommendationRepository: const _FailingRecommendationRepository(),
    );
    await tester.tap(find.byKey(const Key('use-location-button')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Forecast unavailable'), findsOneWidget);
    expect(find.textContaining('Pull to retry'), findsOneWidget);
  });

  testWidgets('configured users start on the recommendation screen', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      initialPreferences: const PersistedRainCheckPreferences(
        preferences: UserPreferences(
          defaultHorizon: HorizonOption.threeDays,
          tolerancePreset: RainTolerancePreset.flexible,
          locationChoice: ManualLocation(
            cityName: 'Austin, TX',
            latitude: 30.2672,
            longitude: -97.7431,
          ),
        ),
        selectedHorizon: HorizonOption.threeDays,
        hasCompletedOnboarding: true,
      ),
    );

    expect(find.text('Safe to wash'), findsOneWidget);
    expect(find.text('Austin, TX'), findsOneWidget);
    expect(find.text('First launch'), findsNothing);
  });
}

final class _FakeLocationService implements LocationService {
  const _FakeLocationService();

  @override
  Future<LocationChoice> currentLocation() async {
    return const DeviceLocation(
      displayName: 'Toronto, ON',
      latitude: 43.6532,
      longitude: -79.3832,
    );
  }

  @override
  Future<LocationChoice> manualLocation(String query) async {
    if (query.toLowerCase().contains('austin')) {
      return const ManualLocation(
        cityName: 'Austin, TX',
        latitude: 30.2672,
        longitude: -97.7431,
      );
    }
    return ManualLocation(
      cityName: query,
      latitude: 43.6532,
      longitude: -79.3832,
    );
  }
}

final class _FakeRecommendationRepository implements RecommendationRepository {
  const _FakeRecommendationRepository();

  @override
  Future<RecommendationViewData> getRecommendation({
    required LocationChoice location,
    required HorizonOption horizon,
    required RainTolerancePreset tolerance,
  }) async {
    final chance = horizon == HorizonOption.oneWeek ? '32%' : '12%';
    return RecommendationViewData(
      status: RecommendationStatus.safeToWash,
      headline: 'Safe to wash',
      reason: 'No measurable rain is forecast in the ${horizon.copy}.',
      validUntil: 'Checked for ${horizon.copy}',
      nextRainLabel: 'No rain in window',
      confidenceLabel: 'High',
      disclaimer:
          'Recommendation based on the current forecast for ${location.label}. Forecasts can change.',
      hourlyItems: const [
        HourlyForecastItem(
          timeLabel: '2 pm',
          condition: 'No rain expected',
          rainChanceLabel: '8%',
        ),
        HourlyForecastItem(
          timeLabel: '3 pm',
          condition: 'No rain expected',
          rainChanceLabel: '12%',
        ),
      ],
      rainChanceLabel: chance,
      rainAmountLabel: '0.0 mm',
      locationLabel: location.label,
      generatedAtLabel: 'Updated 2 pm',
    );
  }
}

final class _FailingRecommendationRepository
    implements RecommendationRepository {
  const _FailingRecommendationRepository();

  @override
  Future<RecommendationViewData> getRecommendation({
    required LocationChoice location,
    required HorizonOption horizon,
    required RainTolerancePreset tolerance,
  }) async {
    throw Exception('offline');
  }
}
