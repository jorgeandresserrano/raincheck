import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raincheck/src/domain/raincheck_models.dart';
import 'package:raincheck/src/state/raincheck_state.dart';
import 'package:raincheck/src/theme/raincheck_theme.dart';
import 'package:raincheck/src/ui/location_search_field.dart';
import 'package:raincheck/src/ui/raincheck_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(rainCheckControllerProvider);
    final recommendationAsync = ref.watch(recommendationProvider);
    final recommendation = recommendationAsync.valueOrNull;
    final isWarning =
        recommendation?.status == RecommendationStatus.notRecommended;

    return RainCheckGradientScaffold(
      isWarning: isWarning,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              RainCheckSpacing.lg,
              RainCheckSpacing.md,
              RainCheckSpacing.lg,
              RainCheckSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _LocationPill(
                    label: appState.preferences.locationChoice.label,
                    sourceLabel:
                        appState.preferences.locationChoice.sourceLabel,
                    onTap: () => showLocationSheet(context, ref),
                  ),
                ),
                const SizedBox(width: RainCheckSpacing.sm),
                IconButton.filledTonal(
                  key: const Key('refresh-location-button'),
                  onPressed:
                      appState.isResolvingLocation
                          ? null
                          : () async {
                            await ref
                                .read(rainCheckControllerProvider.notifier)
                                .useDeviceLocation();
                          },
                  icon:
                      appState.isResolvingLocation
                          ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.my_location),
                  tooltip: 'Refresh location',
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(recommendationProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  RainCheckSpacing.lg,
                  RainCheckSpacing.md,
                  RainCheckSpacing.lg,
                  RainCheckSpacing.lg,
                ),
                children: [
                  recommendationAsync.when(
                    loading: () => const _RecommendationLoading(),
                    error:
                        (error, stackTrace) => _RecommendationError(
                          message:
                              'Forecast unavailable for ${appState.preferences.locationChoice.label}. Pull to retry.',
                        ),
                    data:
                        (data) => Column(
                          children: [
                            _RecommendationHero(recommendation: data),
                            const SizedBox(height: RainCheckSpacing.xl),
                          ],
                        ),
                  ),
                  FrostedPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Time window',
                          trailing: appState.selectedHorizon.copy,
                        ),
                        const SizedBox(height: RainCheckSpacing.sm),
                        HorizonSelector(
                          selected: appState.selectedHorizon,
                          onSelected:
                              ref
                                  .read(rainCheckControllerProvider.notifier)
                                  .selectHorizon,
                        ),
                        const SizedBox(height: RainCheckSpacing.lg),
                        SectionHeader(
                          title: 'Tolerance',
                          trailing: appState.preferences.tolerancePreset.label,
                        ),
                        const SizedBox(height: RainCheckSpacing.sm),
                        TolerancePresetSelector(
                          selected: appState.preferences.tolerancePreset,
                          onSelected:
                              ref
                                  .read(rainCheckControllerProvider.notifier)
                                  .setTolerance,
                        ),
                      ],
                    ),
                  ),
                  if (recommendation != null) ...[
                    const SizedBox(height: RainCheckSpacing.md),
                    _RecommendationSummary(recommendation: recommendation),
                  ],
                  if (appState.locationError != null) ...[
                    const SizedBox(height: RainCheckSpacing.md),
                    _InlineWarning(message: appState.locationError!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({
    required this.label,
    required this.sourceLabel,
    required this.onTap,
  });

  final String label;
  final String sourceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(RainCheckRadii.card),
        onTap: onTap,
        child: FrostedPanel(
          padding: const EdgeInsets.symmetric(
            horizontal: RainCheckSpacing.md,
            vertical: RainCheckSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white),
              const SizedBox(width: RainCheckSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      sourceLabel,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: RainCheckSpacing.xs),
              const Icon(Icons.expand_more, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationHero extends StatelessWidget {
  const _RecommendationHero({required this.recommendation});

  final RecommendationViewData recommendation;

  @override
  Widget build(BuildContext context) {
    final isWarning =
        recommendation.status == RecommendationStatus.notRecommended;
    final icon = isWarning ? Icons.cloudy_snowing : Icons.wb_sunny_rounded;

    return Column(
      children: [
        Icon(
          icon,
          size: 112,
          color: isWarning ? Colors.white : RainCheckColors.sun,
        ),
        const SizedBox(height: RainCheckSpacing.md),
        const Eyebrow('Current recommendation'),
        const SizedBox(height: RainCheckSpacing.sm),
        Text(
          recommendation.headline,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: RainCheckSpacing.md),
        Text(
          recommendation.reason,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.86),
          ),
        ),
        const SizedBox(height: RainCheckSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: RainCheckSpacing.sm,
          runSpacing: RainCheckSpacing.sm,
          children: [
            _HeroChip(label: recommendation.validUntil),
            _HeroChip(label: recommendation.nextRainLabel),
            _HeroChip(label: recommendation.generatedAtLabel),
          ],
        ),
      ],
    );
  }
}

class _RecommendationLoading extends StatelessWidget {
  const _RecommendationLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: RainCheckSpacing.xl),
        const CircularProgressIndicator(color: Colors.white),
        const SizedBox(height: RainCheckSpacing.lg),
        Text(
          'Checking forecast',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: RainCheckSpacing.sm),
        Text(
          'Fetching the current hourly rain outlook.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.84),
          ),
        ),
        const SizedBox(height: RainCheckSpacing.xl),
      ],
    );
  }
}

class _RecommendationError extends StatelessWidget {
  const _RecommendationError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.cloud_off, size: 88, color: Colors.white),
        const SizedBox(height: RainCheckSpacing.md),
        Text(
          'Forecast unavailable',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: RainCheckSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.84),
          ),
        ),
        const SizedBox(height: RainCheckSpacing.xl),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(RainCheckRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RainCheckSpacing.md,
          vertical: RainCheckSpacing.sm,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.86),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RecommendationSummary extends StatelessWidget {
  const _RecommendationSummary({required this.recommendation});

  final RecommendationViewData recommendation;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow(
                      'Why this recommendation',
                      color: RainCheckColors.mutedInk,
                    ),
                    const SizedBox(height: RainCheckSpacing.xs),
                    Text(
                      recommendation.detailReason,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                key: const Key('details-button'),
                onPressed:
                    () => showRecommendationDetails(context, recommendation),
                icon: const Icon(Icons.expand_less),
                label: const Text('Details'),
              ),
            ],
          ),
          const SizedBox(height: RainCheckSpacing.md),
          Row(
            children: [
              MetricTile(
                icon: Icons.water_drop_outlined,
                value: recommendation.rainChanceLabel,
                label: 'Rain chance',
              ),
              MetricTile(
                icon: Icons.grain_outlined,
                value: recommendation.rainAmountLabel,
                label: 'Amount',
              ),
              MetricTile(
                icon: Icons.shield_outlined,
                value: recommendation.confidenceLabel,
                label: 'Confidence',
              ),
            ],
          ),
          const SizedBox(height: RainCheckSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: RainCheckColors.mutedInk,
                size: 18,
              ),
              const SizedBox(width: RainCheckSpacing.xs),
              Expanded(
                child: Text(
                  recommendation.disclaimer,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return FrostedPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.white),
          const SizedBox(width: RainCheckSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showLocationSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const _LocationSheetContent(),
  );
}

class _LocationSheetContent extends ConsumerStatefulWidget {
  const _LocationSheetContent();

  @override
  ConsumerState<_LocationSheetContent> createState() =>
      _LocationSheetContentState();
}

class _LocationSheetContentState extends ConsumerState<_LocationSheetContent> {
  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(rainCheckControllerProvider);
    final controller = ref.read(rainCheckControllerProvider.notifier);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          RainCheckSpacing.lg,
          0,
          RainCheckSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + RainCheckSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Location', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: RainCheckSpacing.sm),
            Text(
              'Currently using ${appState.preferences.locationChoice.label}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (appState.locationError != null) ...[
              const SizedBox(height: RainCheckSpacing.sm),
              Text(
                appState.locationError!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: RainCheckSpacing.md),
            FilledButton.icon(
              key: const Key('sheet-current-location-button'),
              onPressed:
                  appState.isResolvingLocation
                      ? null
                      : () async {
                        final success = await controller.useDeviceLocation();
                        if (context.mounted && success) {
                          Navigator.of(context).pop();
                        }
                      },
              icon: const Icon(Icons.my_location),
              label: Text(
                appState.isResolvingLocation
                    ? 'Finding location'
                    : 'Use current location',
              ),
            ),
            const SizedBox(height: RainCheckSpacing.md),
            LocationSearchField(
              textFieldKey: const Key('home-city-field'),
              initialQuery: appState.preferences.locationChoice.label,
              onSelected: (suggestion) {
                if (suggestion == null) {
                  return;
                }
                controller.useManualLocation(suggestion);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showRecommendationDetails(
  BuildContext context,
  RecommendationViewData recommendation,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        minChildSize: 0.38,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              RainCheckSpacing.lg,
              0,
              RainCheckSpacing.lg,
              RainCheckSpacing.lg,
            ),
            children: [
              Text(
                recommendation.status == RecommendationStatus.safeToWash
                    ? 'Why RainCheck says it is safe'
                    : 'Why RainCheck says to wait',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: RainCheckSpacing.md),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.reason,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: RainCheckSpacing.sm),
                    Text(
                      recommendation.disclaimer,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: RainCheckSpacing.md),
              Text(
                recommendation.detailTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: RainCheckSpacing.sm),
              ...recommendation.detailItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: RainCheckSpacing.sm),
                  child: SurfaceCard(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.description,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.rainAmountLabel,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          item.rainChanceLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
