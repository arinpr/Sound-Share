import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import '../../domain/spatial_audio_models.dart';

/// Interactive 3D Spatial Audio Sound Visualizer.
/// Allows the user to drag the virtual sound source around the listener in real-time.
class SpatialSoundVisualizer extends StatefulWidget {
  const SpatialSoundVisualizer({
    super.key,
    required this.position,
    required this.isEnabled,
    required this.onPositionChanged,
    this.headYaw = 0.0,
    this.isTesting = false,
    this.height = 290,
  });

  final SpatialAudioPosition position;
  final bool isEnabled;
  final ValueChanged<SpatialAudioPosition> onPositionChanged;
  final double headYaw;
  final bool isTesting;
  final double height;

  @override
  State<SpatialSoundVisualizer> createState() => _SpatialSoundVisualizerState();
}

class _SpatialSoundVisualizerState extends State<SpatialSoundVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handlePanUpdate(Offset localOffset, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;

    // Convert local offset relative to center
    final dx = (localOffset.dx - center.dx) / radius;
    final dy = (center.dy - localOffset.dy) / radius; // Invert Y so Up is +Y (Front)

    // Clamp inside circular acoustic field
    final distance = math.sqrt(dx * dx + dy * dy);
    double clampedX = dx;
    double clampedDy = dy;
    if (distance > 1.0) {
      clampedX = dx / distance;
      clampedDy = dy / distance;
    }

    widget.onPositionChanged(
      widget.position.copyWith(x: clampedX, y: clampedDy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: widget.position.toAccessibleLabel(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, widget.height);
          final radius = math.min(size.width, size.height) * 0.42;
          final center = Offset(size.width / 2, size.height / 2);

          // Node position on screen
          final nodeOffset = Offset(
            center.dx + widget.position.x * radius,
            center.dy - widget.position.y * radius,
          );

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              setState(() => _isDragging = true);
              AppHaptics.selection();
              _handlePanUpdate(details.localPosition, size);
            },
            onPanUpdate: (details) {
              _handlePanUpdate(details.localPosition, size);
            },
            onPanEnd: (_) {
              setState(() => _isDragging = false);
              AppHaptics.light();
            },
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                children: [
                  // Canvas background & soundstage visualizer
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return CustomPaint(
                        size: size,
                        painter: _SpatialStagePainter(
                          position: widget.position,
                          isEnabled: widget.isEnabled,
                          isDark: isDark,
                          headYaw: widget.headYaw,
                          pulseValue: _pulseController.value,
                          isDragging: _isDragging,
                          isTesting: widget.isTesting,
                        ),
                      );
                    },
                  ),

                  // Draggable Node Interactive Touch Target
                  Positioned(
                    left: nodeOffset.dx - 22,
                    top: nodeOffset.dy - 22,
                    child: _SoundNodeWidget(
                      isEnabled: widget.isEnabled,
                      isDragging: _isDragging,
                      isTesting: widget.isTesting,
                      isDark: isDark,
                    ),
                  ),

                  // Top Front / Back / Left / Right labels
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'FRONT',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark
                              ? const Color(0xFF8B8A9E)
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'BACK',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark
                              ? const Color(0xFF8B8A9E)
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        'LEFT',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark
                              ? const Color(0xFF8B8A9E)
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        'RIGHT',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark
                              ? const Color(0xFF8B8A9E)
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SoundNodeWidget extends StatelessWidget {
  const _SoundNodeWidget({
    required this.isEnabled,
    required this.isDragging,
    required this.isTesting,
    required this.isDark,
  });

  final bool isEnabled;
  final bool isDragging;
  final bool isTesting;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isDragging ? 1.25 : (isTesting ? 1.15 : 1.0),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutBack,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isEnabled
              ? const LinearGradient(
                  colors: [AppColors.purpleLight, AppColors.blue],
                )
              : LinearGradient(
                  colors: [
                    isDark ? const Color(0xFF333148) : AppColors.disabled,
                    isDark ? const Color(0xFF2B293E) : AppColors.disabledText,
                  ],
                ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ]
              : [],
          border: Border.all(color: Colors.white, width: 2.5),
        ),
        child: const Center(
          child: Icon(
            Icons.spatial_audio_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SpatialStagePainter extends CustomPainter {
  _SpatialStagePainter({
    required this.position,
    required this.isEnabled,
    required this.isDark,
    required this.headYaw,
    required this.pulseValue,
    required this.isDragging,
    required this.isTesting,
  });

  final SpatialAudioPosition position;
  final bool isEnabled;
  final bool isDark;
  final double headYaw;
  final double pulseValue;
  final bool isDragging;
  final bool isTesting;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.42;

    // 1. Concentric acoustic field rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = isDark
          ? const Color(0xFF26243A)
          : AppColors.cardBorder.withValues(alpha: 0.9);

    final ringFractions = [0.35, 0.68, 1.0];
    for (final frac in ringFractions) {
      canvas.drawCircle(center, maxRadius * frac, ringPaint);
    }

    // 2. Crosshair axis lines
    final axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = isDark
          ? const Color(0xFF1E1D2D)
          : AppColors.cardBorder.withValues(alpha: 0.6);

    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      axisPaint,
    );

    // 3. Node position
    final nodeOffset = Offset(
      center.dx + position.x * maxRadius,
      center.dy - position.y * maxRadius,
    );

    // 4. Vector Ray / Direction line from listener to sound source
    if (isEnabled) {
      final rayPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = LinearGradient(
          colors: [
            AppColors.purple.withValues(alpha: 0.2),
            AppColors.blue.withValues(alpha: 0.8),
          ],
        ).createShader(Rect.fromPoints(center, nodeOffset));

      canvas.drawLine(center, nodeOffset, rayPaint);

      // Sound wave ripples radiating from node
      for (int i = 0; i < 3; i++) {
        final rippleFrac = (pulseValue + i / 3.0) % 1.0;
        final rippleRadius = 22 + rippleFrac * 36;
        final opacity = (1.0 - rippleFrac).clamp(0.0, 1.0) * 0.4;

        final wavePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppColors.purpleLight.withValues(alpha: opacity);

        canvas.drawCircle(nodeOffset, rippleRadius, wavePaint);
      }
    }

    // 5. Center Listener ("YOU") Head + Headphones Representation
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-headYaw); // Rotate head according to orientation sensor

    // Listener glow
    final listenerGlow = Paint()
      ..color = (isEnabled ? AppColors.purple : AppColors.textMuted)
          .withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, 24, listenerGlow);

    // Listener circle
    final listenerPaint = Paint()
      ..color = isDark ? const Color(0xFF26243A) : const Color(0xFFEFEEFC)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 20, listenerPaint);

    final listenerBorder = Paint()
      ..color = isEnabled ? AppColors.purple : AppColors.disabled
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset.zero, 20, listenerBorder);

    // Left & Right Headphone Cushions
    final earPaint = Paint()
      ..color = isEnabled ? AppColors.purple : AppColors.disabled
      ..style = PaintingStyle.fill;

    // Left Ear
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-25, -7, 6, 14),
        const Radius.circular(3),
      ),
      earPaint,
    );
    // Right Ear
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(19, -7, 6, 14),
        const Radius.circular(3),
      ),
      earPaint,
    );

    // Headphone headband arch
    final archPaint = Paint()
      ..color = isEnabled ? AppColors.purple : AppColors.disabled
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawArc(
      const Rect.fromLTWH(-22, -22, 44, 44),
      math.pi,
      math.pi,
      false,
      archPaint,
    );

    // Nose direction point (indicates FRONT)
    final nosePath = Path()
      ..moveTo(0, -22)
      ..lineTo(-3, -17)
      ..lineTo(3, -17)
      ..close();
    canvas.drawPath(nosePath, earPaint);

    canvas.restore();

    // "YOU" Text in center
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'YOU',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_SpatialStagePainter old) =>
      old.position != position ||
      old.isEnabled != isEnabled ||
      old.isDark != isDark ||
      old.headYaw != headYaw ||
      old.pulseValue != pulseValue ||
      old.isDragging != isDragging ||
      old.isTesting != isTesting;
}
