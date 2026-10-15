import 'package:flutter/material.dart';

class CyberBackground extends StatefulWidget {
  final Widget child;
  const CyberBackground({super.key, required this.child});

  @override
  State<CyberBackground> createState() => _CyberBackgroundState();
}

class _CyberBackgroundState extends State<CyberBackground>
    with TickerProviderStateMixin {
  late final AnimationController _scanController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Deep-space base gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF080E1C), Color(0xFF030609)],
            ),
          ),
        ),

        // Static dot-grid overlay
        CustomPaint(painter: _GridPainter()),

        // Moving scan-line
        AnimatedBuilder(
          animation: _scanController,
          builder: (_, _) => CustomPaint(
            painter: _ScanLinePainter(_scanController.value),
            size: Size.infinite,
          ),
        ),

        // Ambient corner glows
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            final t = _pulseController.value;
            return Stack(
              children: [
                // Top-centre cyan bloom
                Positioned(
                  top: -120,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 400,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF00F5FF).withValues(alpha: 0.04 + t * 0.02),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom-right purple bloom
                Positioned(
                  bottom: -100,
                  right: -80,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF7B2FFF).withValues(alpha: 0.05 + t * 0.02),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Main content
        widget.child,
      ],
    );
  }
}

// ─── Grid Painter ────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFF00F5FF).withValues(alpha: 0.028)
      ..strokeWidth = 0.6;

    for (double x = 0; x <= size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y <= size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }

    final dot = Paint()
      ..color = const Color(0xFF00F5FF).withValues(alpha: 0.06);
    for (double x = 0; x <= size.width; x += 42) {
      for (double y = 0; y <= size.height; y += 42) {
        canvas.drawCircle(Offset(x, y), 1.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// ─── Scan-Line Painter ───────────────────────────────────────────────────────

class _ScanLinePainter extends CustomPainter {
  final double progress;
  _ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final y = progress * size.height;
    final rect = Rect.fromLTWH(0, y - 60, size.width, 120);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF00F5FF).withValues(alpha: 0.025),
          const Color(0xFF00F5FF).withValues(alpha: 0.055),
          const Color(0xFF00F5FF).withValues(alpha: 0.025),
          Colors.transparent,
        ],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.progress != progress;
}
