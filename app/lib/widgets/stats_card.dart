import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/wireguard_service.dart';

class StatsCard extends StatefulWidget {
  final ConnectionStateStatus status;
  final String ipAddress;

  const StatsCard({
    super.key,
    required this.status,
    required this.ipAddress,
  });

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard> {
  Timer? _timer;
  Duration _duration = Duration.zero;
  final WireguardService _wireguardService = WireguardService();

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant StatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == ConnectionStateStatus.connected &&
        oldWidget.status != ConnectionStateStatus.connected) {
      _startTimerIfNeeded();
    } else if (widget.status != ConnectionStateStatus.connected) {
      _stopTimer();
    }
  }

  void _startTimerIfNeeded() {
    _stopTimer();
    if (widget.status == ConnectionStateStatus.connected) {
      final start = _wireguardService.connectedAt ?? DateTime.now();
      _duration = DateTime.now().difference(start);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _duration = DateTime.now().difference(start);
          });
        }
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _duration = Duration.zero;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return d.inHours > 0
        ? '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}'
        : '${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.status == ConnectionStateStatus.connected;
    final activeColor = isConnected ? AppConstants.successNeon : AppConstants.primaryNeon;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1422).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: activeColor.withValues(alpha: isConnected ? 0.35 : 0.18),
          width: 1,
        ),
        boxShadow: [
          if (isConnected)
            BoxShadow(
              color: AppConstants.successNeon.withValues(alpha: 0.07),
              blurRadius: 24,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        children: [
          // ── Top row: IP + Protocol ─────────────────────────────────────
          Row(
            children: [
              // IP block
              Expanded(
                child: _StatTile(
                  label: 'PUBLIC IP',
                  value: isConnected ? widget.ipAddress : '───.───.───.───',
                  icon: Icons.public_rounded,
                  color: activeColor,
                  isActive: isConnected,
                  mono: true,
                ),
              ),
              const SizedBox(width: 10),
              // Protocol badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryNeon.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConstants.primaryNeon.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        color: AppConstants.primaryNeon, size: 16),
                    const SizedBox(height: 4),
                    const Text(
                      'WG®',
                      style: TextStyle(
                        color: AppConstants.primaryNeon,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Divider ────────────────────────────────────────────────────
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  activeColor.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Bottom row: Download · Upload · Session ────────────────────
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'DOWNLOAD',
                  value: isConnected
                      ? _formatBytes(_wireguardService.bytesIn)
                      : '─ ─',
                  icon: Icons.arrow_downward_rounded,
                  color: AppConstants.primaryNeon,
                  isActive: isConnected,
                ),
              ),
              _VerticalDivider(color: activeColor),
              Expanded(
                child: _StatTile(
                  label: 'UPLOAD',
                  value: isConnected
                      ? _formatBytes(_wireguardService.bytesOut)
                      : '─ ─',
                  icon: Icons.arrow_upward_rounded,
                  color: AppConstants.purpleNeon,
                  isActive: isConnected,
                ),
              ),
              _VerticalDivider(color: activeColor),
              Expanded(
                child: _StatTile(
                  label: 'SESSION',
                  value: isConnected ? _formatDuration(_duration) : '──:──',
                  icon: Icons.timer_outlined,
                  color: activeColor,
                  isActive: isConnected,
                  mono: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stat tile ───────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isActive;
  final bool mono;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isActive,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: isActive ? color : Colors.white24),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white24,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: mono ? 'monospace' : null,
            letterSpacing: mono ? 0.8 : 0,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─── Vertical divider ────────────────────────────────────────────────────────

class _VerticalDivider extends StatelessWidget {
  final Color color;
  const _VerticalDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: color.withValues(alpha: 0.18),
    );
  }
}
