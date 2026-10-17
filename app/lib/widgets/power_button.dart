import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/wireguard_service.dart';

class PowerButton extends StatefulWidget {
  final ConnectionStateStatus status;
  final VoidCallback onTap;

  const PowerButton({
    super.key,
    required this.status,
    required this.onTap,
  });

  @override
  State<PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<PowerButton>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _pulseController;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isConnected => widget.status == ConnectionStateStatus.connected;
  bool get _isProcessing =>
      widget.status == ConnectionStateStatus.connecting ||
      widget.status == ConnectionStateStatus.disconnecting;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.94),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedBuilder(
          animation: Listenable.merge([_spinController, _pulseController]),
          builder: (context, _) {
            final pulseVal = _pulseController.value;

            return SizedBox(
              width: 156,
              height: 156,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── Outside Circle Loader (Spins when Connecting/Disconnecting) ──
                  if (_isProcessing)
                    Transform.rotate(
                      angle: _spinController.value * 2 * math.pi,
                      child: CustomPaint(
                        size: const Size(154, 154),
                        painter: _OutsideLoaderPainter(),
                      ),
                    ),

                  // Outer Frosted Circular Aura Disc
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.22),
                      boxShadow: [
                        BoxShadow(
                          color: _isConnected
                              ? AppConstants.goldGlow
                                  .withValues(alpha: 0.35 + (pulseVal * 0.2))
                              : _isProcessing
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : Colors.black.withValues(alpha: 0.08),
                          blurRadius: _isConnected ? 26 : 14,
                          spreadRadius: _isConnected ? 4 : 1,
                        ),
                      ],
                    ),
                  ),

                  // Middle Ring (Depth border)
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),

                  // Inner Solid White Button
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.power_settings_new_rounded,
                        size: 46,
                        color: _isConnected
                            ? AppConstants.goldDark
                            : _isProcessing
                                ? AppConstants.goldPrimary
                                : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Outside Rotating Circle Loader Painter ────────────────────────────────────
class _OutsideLoaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;

    // Background track (translucent white circle)
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius, bgPaint);

    // Glowing spinning sweep arc
    final sweepRect = Rect.fromCircle(center: center, radius: radius);
    final arcPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Colors.transparent,
          Color(0xFFFFFBEB),
          Colors.white,
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(sweepRect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    canvas.drawArc(sweepRect, 0, 1.85 * math.pi, false, arcPaint);
  }

  @override
  bool shouldRepaint(_OutsideLoaderPainter old) => false;
}
