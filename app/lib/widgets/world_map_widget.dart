import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/vpn_server.dart';

class WorldMapWidget extends StatefulWidget {
  final VpnServer server;
  final bool isConnected;

  const WorldMapWidget({
    super.key,
    required this.server,
    required this.isConnected,
  });

  @override
  State<WorldMapWidget> createState() => _WorldMapWidgetState();
}

class _WorldMapWidgetState extends State<WorldMapWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * (9.0 / 16.0); // 16:9 ratio matching map asset

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Clean World Map Image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/world_map.jpg',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (_, _, _) => _fallbackMap(),
                ),
              ),

              // Smooth Animated Golden Locator Pin (Glides across countries)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOutCubic,
                left: (widget.server.mapX * width) - 16,
                top: (widget.server.mapY * height) - 16,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final t = _pulseController.value;
                    return SizedBox(
                      width: 32,
                      height: 32,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (widget.isConnected) ...[
                            // Outer expanding golden pulse ring
                            Container(
                              width: 14 + (t * 18),
                              height: 14 + (t * 18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppConstants.goldPrimary
                                    .withValues(alpha: (1.0 - t) * 0.45),
                                border: Border.all(
                                  color: AppConstants.goldPrimary
                                      .withValues(alpha: (1.0 - t) * 0.8),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ],

                          // Golden Core Pin
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isConnected
                                  ? AppConstants.goldDark
                                  : const Color(0xFF9CA3AF),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (widget.isConnected
                                          ? AppConstants.goldDark
                                          : Colors.black26)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fallbackMap() {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Icon(
          Icons.public_rounded,
          size: 64,
          color: Colors.grey.shade300,
        ),
      ),
    );
  }
}
