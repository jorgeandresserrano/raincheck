import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:raincheck/src/data/location_service.dart';
import 'package:raincheck/src/data/preferences_store.dart';
import 'package:raincheck/src/data/recommendation_repository.dart';
import 'package:raincheck/src/features/home/home_screen.dart';
import 'package:raincheck/src/features/onboarding/onboarding_screen.dart';
import 'package:raincheck/src/state/raincheck_state.dart';
import 'package:raincheck/src/theme/raincheck_theme.dart';

GoRouter buildRainCheckRouter({required bool hasCompletedOnboarding}) {
  return GoRouter(
    initialLocation: hasCompletedOnboarding ? '/home' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
  );
}

class RainCheckApp extends StatelessWidget {
  const RainCheckApp({
    super.key,
    this.locationService,
    this.recommendationRepository,
    this.preferencesStore,
    this.initialPreferences,
  });

  final LocationService? locationService;
  final RecommendationRepository? recommendationRepository;
  final PreferencesStore? preferencesStore;
  final PersistedRainCheckPreferences? initialPreferences;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        if (locationService != null)
          locationServiceProvider.overrideWithValue(locationService!),
        if (recommendationRepository != null)
          recommendationRepositoryProvider.overrideWithValue(
            recommendationRepository!,
          ),
        if (preferencesStore != null)
          preferencesStoreProvider.overrideWithValue(preferencesStore!),
        if (initialPreferences != null)
          initialRainCheckPreferencesProvider.overrideWithValue(
            initialPreferences,
          ),
      ],
      child: _RainCheckMaterialApp(
        hasCompletedOnboarding:
            initialPreferences?.hasCompletedOnboarding ?? false,
      ),
    );
  }
}

class _RainCheckMaterialApp extends StatefulWidget {
  const _RainCheckMaterialApp({required this.hasCompletedOnboarding});

  final bool hasCompletedOnboarding;

  @override
  State<_RainCheckMaterialApp> createState() => _RainCheckMaterialAppState();
}

class _RainCheckMaterialAppState extends State<_RainCheckMaterialApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRainCheckRouter(
      hasCompletedOnboarding: widget.hasCompletedOnboarding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RainCheck',
      debugShowCheckedModeBanner: false,
      theme: buildRainCheckTheme(),
      routerConfig: _router,
    );
  }
}
