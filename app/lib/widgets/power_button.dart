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
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getPrimaryColor() {
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
      case ConnectionStateStatus.connecting:
      case ConnectionStateStatus.disconnecting:
        return Icons.sync_rounded;
      case ConnectionStateStatus.error:
        return Icons.error_outline_rounded;
      case ConnectionStateStatus.disconnected:
        return Icons.power_settings_new_rounded;
    }
  }

  String _getStatusTitle() {
    switch (widget.status) {
      case ConnectionStateStatus.connected:
        return 'CONNECTED';
      case ConnectionStateStatus.connecting:
        return 'CONNECTING...';
      case ConnectionStateStatus.disconnecting:
        return 'DISCONNECTING...';
      case ConnectionStateStatus.error:
        return 'FAILED';
      case ConnectionStateStatus.disconnected:
        return 'TAP TO CONNECT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getPrimaryColor();
    final isConnected = widget.status == ConnectionStateStatus.connected;
    final isConnecting = widget.status == ConnectionStateStatus.connecting;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Outer interactive glow container
        GestureDetector(
          onTap: widget.onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse Ring Animation
              if (isConnected || isConnecting)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    final progress = _pulseController.value;
                    final opacity = (1.0 - progress).clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: activeColor.withValues(alpha: opacity * 0.7),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withValues(alpha: opacity * 0.3),
                              blurRadius: 30,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // Ambient background blur halo
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isConnected
                          ? activeColor.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.5),
                      blurRadius: isConnected ? 45 : 20,
                      spreadRadius: isConnected ? 12 : 2,
                    ),
                  ],
                ),
              ),

              // Button Outer Bezel
              Container(
                width: 155,
                height: 155,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppConstants.surfaceLight,
                      AppConstants.surface,
                      AppConstants.background,
                    ],
                    stops: const [0.3, 0.8, 1.0],
                  ),
                  border: Border.all(
                    color: isConnected
                        ? activeColor
                        : AppConstants.border.withValues(alpha: 0.8),
                    width: isConnected ? 3 : 2,
                  ),
                ),
                child: Center(
                  // Inner Plate
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isConnected
                            ? [
                                activeColor.withValues(alpha: 0.25),
                                activeColor.withValues(alpha: 0.08),
                              ]
                            : [
                                const Color(0xFF1F2436),
                                const Color(0xFF141724),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 10,
                          offset: const Offset(3, 4),
                        ),
                        BoxShadow(
                          color: activeColor.withValues(alpha: isConnected ? 0.3 : 0.05),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: isConnecting
                          ? SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.5,
                                color: activeColor,
                              ),
                            )
                          : Icon(
                              _getIcon(),
                              size: 56,
                              color: isConnected ? activeColor : Colors.white70,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Status Indicator Badge
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: activeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: activeColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor,
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _getStatusTitle(),
                style: TextStyle(
                  color: activeColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
