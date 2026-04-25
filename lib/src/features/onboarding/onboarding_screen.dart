import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:raincheck/src/state/raincheck_state.dart';
import 'package:raincheck/src/theme/raincheck_theme.dart';
import 'package:raincheck/src/ui/location_search_field.dart';
import 'package:raincheck/src/ui/raincheck_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _showManualEntry = false;

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(rainCheckControllerProvider);

    return RainCheckGradientScaffold(
      child: ListView(
        padding: const EdgeInsets.all(RainCheckSpacing.lg),
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop, color: Colors.white),
              const SizedBox(width: RainCheckSpacing.sm),
              Expanded(
                child: Text(
                  'RainCheck',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: RainCheckSpacing.sm),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(RainCheckRadii.pill),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    'Ready',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: RainCheckSpacing.xl),
          const Icon(Icons.cloud_queue, color: RainCheckColors.sun, size: 96),
          const SizedBox(height: RainCheckSpacing.lg),
          const Eyebrow('First launch'),
          const SizedBox(height: RainCheckSpacing.sm),
          Text(
            'Know if washing your car is worth it today.',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: RainCheckSpacing.md),
          Text(
            'RainCheck turns the forecast into a clear wash or wait recommendation.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
          const SizedBox(height: RainCheckSpacing.xl),
          const _OnboardingPoint(
            icon: Icons.schedule,
            title: 'Pick a horizon',
            copy: 'Check the next day, 3 days, 5 days, or week.',
          ),
          const SizedBox(height: RainCheckSpacing.sm),
          const _OnboardingPoint(
            icon: Icons.verified,
            title: 'Get one clear answer',
            copy:
                'See whether conditions stay dry enough to make washing worth it.',
          ),
          const SizedBox(height: RainCheckSpacing.sm),
          const _OnboardingPoint(
            icon: Icons.location_on_outlined,
            title: 'Use your place',
            copy:
                'Use GPS or enter a city so RainCheck can check the right forecast.',
          ),
          if (appState.locationError != null) ...[
            const SizedBox(height: RainCheckSpacing.md),
            FrostedPanel(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: RainCheckSpacing.sm),
                  Expanded(
                    child: Text(
                      appState.locationError!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: RainCheckSpacing.xl),
          FilledButton.icon(
            key: const Key('use-location-button'),
            onPressed:
                appState.isResolvingLocation
                    ? null
                    : () async {
                      final success =
                          await ref
                              .read(rainCheckControllerProvider.notifier)
                              .completeOnboardingWithDeviceLocation();
                      if (!context.mounted) {
                        return;
                      }
                      if (success) {
                        context.go('/home');
                      } else {
                        setState(() => _showManualEntry = true);
                      }
                    },
            icon:
                appState.isResolvingLocation
                    ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.my_location),
            label: Text(
              appState.isResolvingLocation
                  ? 'Finding your location'
                  : 'Use my location',
            ),
          ),
          const SizedBox(height: RainCheckSpacing.sm),
          OutlinedButton(
            key: const Key('manual-entry-button'),
            onPressed: () {
              setState(() => _showManualEntry = !_showManualEntry);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.38)),
            ),
            child: const Text('Enter city manually'),
          ),
          if (_showManualEntry) ...[
            const SizedBox(height: RainCheckSpacing.md),
            FrostedPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LocationSearchField(
                    textFieldKey: const Key('manual-city-field'),
                    initialQuery: 'San Francisco, CA',
                    dark: true,
                    onSelected: (suggestion) {
                      if (suggestion == null) {
                        return;
                      }
                      ref
                          .read(rainCheckControllerProvider.notifier)
                          .completeOnboardingWithManualLocation(suggestion);
                      if (!context.mounted) {
                        return;
                      }
                      context.go('/home');
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OnboardingPoint extends StatelessWidget {
  const _OnboardingPoint({
    required this.icon,
    required this.title,
    required this.copy,
  });

  final IconData icon;
  final String title;
  final String copy;

  @override
  Widget build(BuildContext context) {
    return FrostedPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: RainCheckSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: RainCheckSpacing.xs),
                Text(
                  copy,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
