import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Simple, guaranteed-working water wave animation
class AnimatedWaterWave extends StatefulWidget {
  final double fillPercentage;
  final Color waterColor;
  final Widget child;

  const AnimatedWaterWave({
    super.key,
    required this.fillPercentage,
    required this.waterColor,
    required this.child,
  });

  @override
  State<AnimatedWaterWave> createState() => _AnimatedWaterWaveState();
}

class _AnimatedWaterWaveState extends State<AnimatedWaterWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _targetLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _targetLevel = widget.fillPercentage;
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void didUpdateWidget(AnimatedWaterWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fillPercentage != _targetLevel) {
      setState(() {
        _targetLevel = widget.fillPercentage;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Water layer - MUST BE BEHIND child
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _WaterPainter(
                waterLevel: _targetLevel,
                wavePhase: _controller.value,
                waterColor: widget.waterColor,
              ),
              size: Size.infinite,
            );
          },
        ),
        // Content layer - MUST BE IN FRONT
        widget.child,
      ],
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double waterLevel;
  final double wavePhase;
  final Color waterColor;

  _WaterPainter({
    required this.waterLevel,
    required this.wavePhase,
    required this.waterColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clampedLevel = waterLevel.clamp(0.0, 1.0);
    if (clampedLevel <= 0.0 || size.width == 0 || size.height == 0) return;

    final wavePaint = Paint()
      ..color = waterColor.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Water fills from bottom to top
    // At 100%, waterY should be 0 (top of container)
    final waterY = size.height * (1.0 - clampedLevel);
    
    // Wave amplitude reduces near 100% to prevent overflow
    final baseAmplitude = 8.0;
    final amplitudeMultiplier = clampedLevel < 0.95 ? 1.0 : (1.0 - clampedLevel) * 20;
    final amplitude = baseAmplitude * amplitudeMultiplier.clamp(0.2, 1.0);
    
    final path = Path();
    path.moveTo(0, size.height);

    final waveOffset = wavePhase * 2 * math.pi;
    
    for (double x = 0; x <= size.width; x += 4) {
      final xRatio = x / size.width;
      
      final wave1 = math.sin(xRatio * 4 * math.pi + waveOffset) * amplitude;
      final wave2 = math.cos(xRatio * 3 * math.pi - waveOffset * 0.6) * (amplitude * 0.5);
      
      // Ensure wave doesn't go above container top
      final y = (waterY + wave1 + wave2).clamp(0.0, size.height);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    final clipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );
    
    canvas.save();
    canvas.clipRRect(clipRect);
    canvas.drawPath(path, wavePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WaterPainter oldDelegate) {
    return waterLevel != oldDelegate.waterLevel ||
        wavePhase != oldDelegate.wavePhase;
  }
}
