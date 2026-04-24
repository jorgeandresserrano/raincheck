import 'package:flutter/material.dart';
import 'package:raincheck/src/domain/raincheck_models.dart';
import 'package:raincheck/src/theme/raincheck_theme.dart';

class RainCheckGradientScaffold extends StatelessWidget {
  const RainCheckGradientScaffold({
    super.key,
    required this.child,
    this.isWarning = false,
  });

  final Widget child;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colors =
        isWarning
            ? const [RainCheckColors.warning, RainCheckColors.warningDeep]
            : const [
              Color(0xFF67BEF4),
              RainCheckColors.sky,
              RainCheckColors.deepSky,
            ];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}

class FrostedPanel extends StatelessWidget {
  const FrostedPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(RainCheckSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        borderRadius: BorderRadius.circular(RainCheckRadii.card),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(RainCheckRadii.card),
        boxShadow: [
          BoxShadow(
            color: RainCheckColors.ink.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(RainCheckSpacing.md),
        child: child,
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color ?? Colors.white.withValues(alpha: 0.72),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }
}

class HorizonSelector extends StatelessWidget {
  const HorizonSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final HorizonOption selected;
  final ValueChanged<HorizonOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<HorizonOption>(
      key: const Key('horizon-selector'),
      segments:
          HorizonOption.values
              .map(
                (horizon) => ButtonSegment<HorizonOption>(
                  value: horizon,
                  label: Text(horizon.label),
                ),
              )
              .toList(),
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onSelected(selection.single),
    );
  }
}

class TolerancePresetSelector extends StatelessWidget {
  const TolerancePresetSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final RainTolerancePreset selected;
  final ValueChanged<RainTolerancePreset> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: RainCheckSpacing.sm,
      runSpacing: RainCheckSpacing.sm,
      children:
          RainTolerancePreset.values.map((preset) {
            final isSelected = selected == preset;
            return ChoiceChip(
              key: Key('tolerance-${preset.name}'),
              label: Text(preset.label),
              selected: isSelected,
              onSelected: (_) => onSelected(preset),
              selectedColor: RainCheckColors.deepSky.withValues(alpha: 0.16),
            );
          }).toList(),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: RainCheckColors.mutedInk),
          const SizedBox(height: RainCheckSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Eyebrow(title, color: Colors.white.withValues(alpha: 0.70)),
        ),
        if (trailing != null)
          TextButton(onPressed: onTrailingTap, child: Text(trailing!)),
      ],
    );
  }
}
