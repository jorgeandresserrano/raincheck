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
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('location-suggestion-0')));
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

    expect(find.text('32%'), findsNothing);
    await tester.tap(find.byKey(const Key('details-button')));
    await tester.pumpAndSettle();

    expect(find.text('32%'), findsWidgets);
    expect(find.text('1 week outlook'), findsOneWidget);
    expect(find.text('No rain expected'), findsWidgets);
  });

  testWidgets('location sheet can change the city from home', (tester) async {
    await _openHome(tester);

    await tester.tap(find.text('Toronto, ON'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('home-city-field')), 'Austin');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('location-suggestion-0')));
    await tester.pumpAndSettle();

    expect(find.text('Austin, TX'), findsOneWidget);
    expect(find.text('Manual location'), findsOneWidget);
  });

  testWidgets('manual location requires selecting a search suggestion', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('manual-entry-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('manual-city-field')), 'zzzz');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(
      find.text('No matching places found. Try a city and state.'),
      findsOneWidget,
    );
    expect(find.text('Safe to wash'), findsNothing);
    expect(find.byKey(const Key('save-manual-city-button')), findsNothing);
  });

  testWidgets('location search clear button resets the query and suggestions', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('manual-entry-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('manual-city-field')),
      'Austin',
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('location-suggestion-0')), findsOneWidget);

    await tester.tap(find.byKey(const Key('location-clear-button')));
    await tester.pumpAndSettle();

    expect(find.text('Austin, TX'), findsNothing);
    expect(find.byKey(const Key('location-suggestion-0')), findsNothing);
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
  Future<List<LocationSuggestion>> searchLocations(String query) async {
    if (query.toLowerCase().contains('austin')) {
      return const [
        LocationSuggestion(
          label: 'Austin, TX',
          latitude: 30.2672,
          longitude: -97.7431,
        ),
      ];
    }
    if (query.toLowerCase().contains('san francisco')) {
      return const [
        LocationSuggestion(
          label: 'San Francisco, CA',
          latitude: 37.7749,
          longitude: -122.4194,
        ),
      ];
    }
    if (query.toLowerCase().contains('toronto')) {
      return const [
        LocationSuggestion(
          label: 'Toronto, ON',
          latitude: 43.6532,
          longitude: -79.3832,
        ),
      ];
    }
    return const [];
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
      detailReason:
          'Rain chances and forecast rain stay within ${tolerance.label} tolerance for ${location.label}.',
      validUntil: 'Checked for ${horizon.copy}',
      nextRainLabel: 'No rain in window',
      confidenceLabel: 'High',
      disclaimer:
          'Recommendation based on the current forecast for ${location.label}. Forecasts can change.',
      detailTitle:
          horizon == HorizonOption.oneDay
              ? 'Next 24 hours'
              : '${horizon.label} outlook',
      detailItems: const [
        ForecastEvidenceItem(
          title: 'Today',
          description: 'No rain expected',
          rainChanceLabel: '8%',
          rainAmountLabel: '0.0 mm',
        ),
        ForecastEvidenceItem(
          title: 'Tomorrow',
          description: 'No rain expected',
          rainChanceLabel: '12%',
          rainAmountLabel: '0.0 mm',
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
