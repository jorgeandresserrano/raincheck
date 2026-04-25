import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:raincheck/src/domain/raincheck_models.dart';
import 'package:raincheck/src/theme/raincheck_theme.dart';

class RainCheckGradientScaffold extends StatefulWidget {
  const RainCheckGradientScaffold({
    super.key,
    required this.child,
    this.isWarning = false,
  });

  final Widget child;
  final bool isWarning;

  @override
  State<RainCheckGradientScaffold> createState() =>
      _RainCheckGradientScaffoldState();
}

class _RainCheckGradientScaffoldState extends State<RainCheckGradientScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _weatherAnimation;

  @override
  void initState() {
    super.initState();
    _weatherAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.isWarning) {
      _weatherAnimation.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RainCheckGradientScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWarning == oldWidget.isWarning) {
      return;
    }
    if (widget.isWarning) {
      _weatherAnimation.repeat();
    } else {
      _weatherAnimation.stop();
      _weatherAnimation.value = 0;
    }
  }

  @override
  void dispose() {
    _weatherAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: _WeatherBackdropPainter(
                isWarning: widget.isWarning,
                animation:
                    disableAnimations
                        ? const AlwaysStoppedAnimation(0)
                        : _weatherAnimation,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    widget.isWarning
                        ? [
                          Colors.black.withValues(alpha: 0.10),
                          Colors.black.withValues(alpha: 0.24),
                        ]
                        : [
                          Colors.white.withValues(alpha: 0.06),
                          Colors.black.withValues(alpha: 0.08),
                        ],
              ),
            ),
          ),
          SafeArea(child: widget.child),
        ],
      ),
    );
  }
}

class _WeatherBackdropPainter extends CustomPainter {
  _WeatherBackdropPainter({required this.isWarning, required this.animation})
    : super(repaint: animation);

  final bool isWarning;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    if (isWarning) {
      _paintStorm(canvas, size);
    } else {
      _paintClearSky(canvas, size);
    }
  }

  void _paintClearSky(Canvas canvas, Size size) {
    final skyPaint =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8BD7FF), Color(0xFF2AA9EA), Color(0xFF0877BE)],
          ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    final sunCenter = Offset(size.width * 0.78, size.height * 0.16);
    for (var index = 4; index >= 0; index--) {
      canvas.drawCircle(
        sunCenter,
        44.0 + index * 28,
        Paint()
          ..color = RainCheckColors.sun.withValues(
            alpha: 0.08 + (4 - index) * 0.025,
          ),
      );
    }
    canvas.drawCircle(sunCenter, 42, Paint()..color = RainCheckColors.sun);

    _drawSoftCloud(
      canvas,
      Offset(size.width * 0.14, size.height * 0.18),
      0.82,
      Colors.white.withValues(alpha: 0.20),
    );
    _drawSoftCloud(
      canvas,
      Offset(size.width * 0.58, size.height * 0.32),
      0.58,
      Colors.white.withValues(alpha: 0.16),
    );

    final hazePaint = Paint()..color = Colors.white.withValues(alpha: 0.08);
    for (var index = 0; index < 6; index++) {
      final y = size.height * (0.12 + index * 0.105);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, y),
          width: size.width * (1.15 - index * 0.05),
          height: 28,
        ),
        hazePaint,
      );
    }
  }

  void _paintStorm(Canvas canvas, Size size) {
    final skyPaint =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF53688E), Color(0xFF334563), Color(0xFF182336)],
          ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    _drawSoftCloud(
      canvas,
      Offset(size.width * -0.03, size.height * 0.09),
      1.22,
      const Color(0xFF263144).withValues(alpha: 0.86),
    );
    _drawSoftCloud(
      canvas,
      Offset(size.width * 0.34, size.height * 0.13),
      1.05,
      const Color(0xFF3A465A).withValues(alpha: 0.88),
    );
    _drawSoftCloud(
      canvas,
      Offset(size.width * 0.62, size.height * 0.21),
      0.86,
      const Color(0xFF202A3B).withValues(alpha: 0.78),
    );

    _drawWetGlassRain(canvas, size);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.07),
    );
  }

  void _drawWetGlassRain(Canvas canvas, Size size) {
    final progress = animation.value;
    final streamPaint =
        Paint()
          ..color = const Color(0xFFDDF3FF).withValues(alpha: 0.28)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
    final brightStreamPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.24)
          ..strokeWidth = 0.9
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    for (var index = 0; index < 18; index++) {
      final x = _noise(index, 0) * size.width;
      final speed = 0.18 + _noise(index, 1) * 0.22;
      final y =
          ((progress * speed + _noise(index, 2)) % 1.0) * (size.height + 260) -
          160;
      final length = 80 + _noise(index, 3) * 180;
      final drift = (_noise(index, 4) - 0.5) * 22;

      final path =
          Path()
            ..moveTo(x, y)
            ..cubicTo(
              x + drift,
              y + length * 0.28,
              x - drift * 0.35,
              y + length * 0.66,
              x + drift * 0.55,
              y + length,
            );
      canvas.drawPath(path, streamPaint);

      final highlight =
          Path()
            ..moveTo(x - 1.8, y + 8)
            ..cubicTo(
              x + drift - 1.8,
              y + length * 0.26,
              x - drift * 0.35 - 1.8,
              y + length * 0.52,
              x + drift * 0.40 - 1.8,
              y + length * 0.78,
            );
      canvas.drawPath(highlight, brightStreamPaint);
    }

    for (var index = 0; index < 34; index++) {
      final x = _noise(index, 7) * size.width;
      final speed = 0.10 + _noise(index, 8) * 0.16;
      final y =
          ((progress * speed + _noise(index, 9)) % 1.0) * (size.height + 100) -
          50;
      final radius = 3.8 + _noise(index, 10) * 8.5;
      final stretch = 1.15 + _noise(index, 11) * 1.65;
      _drawGlassDrop(canvas, Offset(x, y), radius, stretch);
    }
  }

  void _drawGlassDrop(
    Canvas canvas,
    Offset center,
    double radius,
    double stretch,
  ) {
    final dropPath =
        Path()
          ..moveTo(center.dx, center.dy - radius * stretch)
          ..cubicTo(
            center.dx + radius * 0.95,
            center.dy - radius * 0.45,
            center.dx + radius * 0.82,
            center.dy + radius * 0.92,
            center.dx,
            center.dy + radius,
          )
          ..cubicTo(
            center.dx - radius * 0.82,
            center.dy + radius * 0.92,
            center.dx - radius * 0.95,
            center.dy - radius * 0.45,
            center.dx,
            center.dy - radius * stretch,
          );

    final shadowPaint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.10)
          ..style = PaintingStyle.fill;
    canvas.drawPath(
      dropPath.shift(Offset(radius * 0.18, radius * 0.22)),
      shadowPaint,
    );

    final fillPaint =
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.45),
            radius: 1.0,
            colors: [
              Colors.white.withValues(alpha: 0.34),
              const Color(0xFFB9E8FF).withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.05),
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: radius * (stretch + 1.2)),
          );
    canvas.drawPath(dropPath, fillPaint);

    final rimPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..strokeWidth = math.max(0.8, radius * 0.12)
          ..style = PaintingStyle.stroke;
    canvas.drawPath(dropPath, rimPaint);

    canvas.drawCircle(
      center.translate(-radius * 0.26, -radius * 0.36),
      radius * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.48),
    );
  }

  double _noise(int index, int salt) {
    final value = math.sin(index * 12.9898 + salt * 78.233) * 43758.5453;
    return value - value.floorToDouble();
  }

  void _drawSoftCloud(Canvas canvas, Offset origin, double scale, Color color) {
    final paint = Paint()..color = color;
    canvas.drawOval(
      Rect.fromLTWH(
        origin.dx + 2 * scale,
        origin.dy + 36 * scale,
        176 * scale,
        48 * scale,
      ),
      paint,
    );
    canvas.drawCircle(
      origin + Offset(42 * scale, 42 * scale),
      36 * scale,
      paint,
    );
    canvas.drawCircle(
      origin + Offset(86 * scale, 28 * scale),
      48 * scale,
      paint,
    );
    canvas.drawCircle(
      origin + Offset(132 * scale, 44 * scale),
      34 * scale,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _WeatherBackdropPainter oldDelegate) {
    return oldDelegate.isWarning != isWarning ||
        oldDelegate.animation != animation;
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
