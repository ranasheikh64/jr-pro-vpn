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

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return d.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.status == ConnectionStateStatus.connected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isConnected
              ? AppConstants.successNeon.withValues(alpha: 0.3)
              : AppConstants.border,
          width: 1,
        ),
        boxShadow: [
          if (isConnected)
            BoxShadow(
              color: AppConstants.successNeon.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Duration Timer & Protocol
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONNECTION TIME',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConnected ? _formatDuration(_duration) : '00:00',
                    style: TextStyle(
                      color: isConnected ? Colors.white : Colors.white30,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppConstants.primaryNeon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConstants.primaryNeon.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: AppConstants.primaryNeon,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'WireGuard®',
                      style: TextStyle(
                        color: AppConstants.primaryNeon,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(color: AppConstants.border, height: 24),

          // Row 2: IP Address & Traffic Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Virtual IP
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.public_rounded,
                      size: 18,
                      color: isConnected ? AppConstants.successNeon : Colors.white38,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'IP ADDRESS',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isConnected ? widget.ipAddress : '---.---.---.---',
                        style: TextStyle(
                          color: isConnected ? Colors.white : Colors.white30,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Traffic Down / Up
              Row(
                children: [
                  // Download
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_downward_rounded,
                        size: 16,
                        color: isConnected ? AppConstants.primaryNeon : Colors.white24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isConnected
                            ? _formatBytes(_wireguardService.bytesIn)
                            : '0 KB',
                        style: TextStyle(
                          color: isConnected ? Colors.white70 : Colors.white24,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Upload
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 16,
                        color: isConnected ? AppConstants.purpleNeon : Colors.white24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isConnected
                            ? _formatBytes(_wireguardService.bytesOut)
                            : '0 KB',
                        style: TextStyle(
                          color: isConnected ? Colors.white70 : Colors.white24,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
