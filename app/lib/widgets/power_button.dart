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
  late final AnimationController _ring1;
  late final AnimationController _ring2;
  late final AnimationController _ring3;
  late final AnimationController _rotateController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    _ring1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _ring2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..forward(from: 0.33)
      ..addStatusListener((s) { if (s == AnimationStatus.completed) _ring2.repeat(); });
    _ring3 = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..forward(from: 0.66)
      ..addStatusListener((s) { if (s == AnimationStatus.completed) _ring3.repeat(); });

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ring1.dispose();
    _ring2.dispose();
    _ring3.dispose();
    _rotateController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (widget.status) {
      case ConnectionStateStatus.connected:
        return AppConstants.successNeon;
      case ConnectionStateStatus.connecting:
      case ConnectionStateStatus.disconnecting:
        return AppConstants.warningNeon;
      case ConnectionStateStatus.error:
        return AppConstants.errorNeon;
      case ConnectionStateStatus.disconnected:
        return AppConstants.primaryNeon;
    }
  }

  IconData _getIcon() {
    switch (widget.status) {
      case ConnectionStateStatus.connected:
        return Icons.shield_rounded;
      case ConnectionStateStatus.error:
        return Icons.error_outline_rounded;
      default:
        return Icons.power_settings_new_rounded;
    }
  }

  String _getLabel() {
    switch (widget.status) {
      case ConnectionStateStatus.connected:
        return 'CONNECTED';
      case ConnectionStateStatus.connecting:
        return 'ESTABLISHING TUNNEL...';
      case ConnectionStateStatus.disconnecting:
        return 'TERMINATING...';
      case ConnectionStateStatus.error:
        return 'CONNECTION FAILED';
      case ConnectionStateStatus.disconnected:
        return 'TAP TO CONNECT';
    }
  }

  Widget _buildPulseRing(AnimationController ctrl, Color color, double baseSize) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, _) {
        final t = ctrl.value;
        final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.55;
        final scale = 1.0 + t * 0.55;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: baseSize,
            height: baseSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: opacity),
                width: 1.8,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRotatingArc(Color color) {
    return AnimatedBuilder(
      animation: _rotateController,
      builder: (_, _) {
        return Transform.rotate(
          angle: _rotateController.value * 2 * math.pi,
          child: CustomPaint(
            size: const Size(58, 58),
            painter: _ArcPainter(color),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final isConnected = widget.status == ConnectionStateStatus.connected;
    final isActive = isConnected || widget.status == ConnectionStateStatus.connecting;
    final isConnecting = widget.status == ConnectionStateStatus.connecting ||
        widget.status == ConnectionStateStatus.disconnecting;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Button area ─────────────────────────────────────────────────────
        SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // HUD corner brackets
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _HudBrackets(
                    color: color,
                    size: 22,
                    glowController: _glowController,
                  ),
                ),
              ),

              // Pulse rings (connected / connecting only)
              if (isActive) ...[
                _buildPulseRing(_ring3, color, 200),
                _buildPulseRing(_ring2, color, 200),
                _buildPulseRing(_ring1, color, 200),
              ],

              // Ambient glow halo
              AnimatedBuilder(
                animation: _glowController,
                builder: (_, _) {
                  final glow = _glowController.value;
                  return Container(
                    width: 155,
                    height: 155,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(
                            alpha: isConnected ? 0.28 + glow * 0.12 : 0.06,
                          ),
                          blurRadius: isConnected ? 50 : 18,
                          spreadRadius: isConnected ? 16 : 2,
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Outer bezel ring
              Container(
                width: 155,
                height: 155,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1A2540),
                      const Color(0xFF0B1120),
                      const Color(0xFF060C18),
                    ],
                    stops: const [0.3, 0.75, 1.0],
                  ),
                  border: Border.all(
                    color: color.withValues(alpha: isConnected ? 0.9 : 0.35),
                    width: isConnected ? 2.5 : 1.5,
                  ),
                ),
              ),

              // Tap target – inner plate
              GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isConnected
                          ? [
                              color.withValues(alpha: 0.22),
                              color.withValues(alpha: 0.06),
                            ]
                          : [
                              const Color(0xFF1A2540),
                              const Color(0xFF0F1829),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 12,
                        offset: const Offset(2, 4),
                      ),
                      BoxShadow(
                        color: color.withValues(alpha: isConnected ? 0.25 : 0.04),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: isConnecting
                        ? _buildRotatingArc(color)
                        : Icon(
                            _getIcon(),
                            size: 54,
                            color: color,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Status badge ────────────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PulseDot(color: color, animate: isActive),
              const SizedBox(width: 8),
              Text(
                _getLabel(),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── HUD corner brackets ─────────────────────────────────────────────────────

class _HudBrackets extends StatelessWidget {
  final Color color;
  final double size;
  final AnimationController glowController;

  const _HudBrackets({
    required this.color,
    required this.size,
    required this.glowController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowController,
      builder: (_, _) {
        final c = color.withValues(alpha: 0.45 + glowController.value * 0.25);
        return Stack(
          children: [
            Positioned(top: 0, left: 0,  child: _Bracket(color: c, size: size, isTop: true,  isLeft: true)),
            Positioned(top: 0, right: 0, child: _Bracket(color: c, size: size, isTop: true,  isLeft: false)),
            Positioned(bottom: 0, left: 0,  child: _Bracket(color: c, size: size, isTop: false, isLeft: true)),
            Positioned(bottom: 0, right: 0, child: _Bracket(color: c, size: size, isTop: false, isLeft: false)),
          ],
        );
      },
    );
  }
}

class _Bracket extends StatelessWidget {
  final Color color;
  final double size;
  final bool isTop;
  final bool isLeft;

  const _Bracket({
    required this.color,
    required this.size,
    required this.isTop,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Horizontal bar
          Positioned(
            top: isTop ? 0 : null,
            bottom: isTop ? null : 0,
            left: isLeft ? 0 : null,
            right: isLeft ? null : 0,
            child: Container(width: size, height: 2, color: color),
          ),
          // Vertical bar
          Positioned(
            top: isTop ? 0 : null,
            bottom: isTop ? null : 0,
            left: isLeft ? 0 : null,
            right: isLeft ? null : 0,
            child: Container(width: 2, height: size, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Pulsing dot ─────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;
  final bool animate;
  const _PulseDot({required this.color, required this.animate});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      );
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.3 + _ctrl.value * 0.55),
              blurRadius: 6 + _ctrl.value * 6,
              spreadRadius: 1 + _ctrl.value * 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Rotating arc painter ────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final Color color;
  _ArcPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 4;

    // Background track
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke,
    );

    // Arc
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 1.4,
      false,
      Paint()
        ..color = color
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}
