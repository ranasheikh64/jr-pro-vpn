import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/vpn_server.dart';
import '../services/device_service.dart';
import '../services/vpn_api_service.dart';
import '../services/wireguard_service.dart';
import '../widgets/cyber_background.dart';
import '../widgets/power_button.dart';
import '../widgets/server_bottom_sheet.dart';
import '../widgets/stats_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VpnApiService _apiService = VpnApiService();
  final WireguardService _wireguardService = WireguardService();

  List<VpnServer> _servers = VpnServer.defaultServers;
  late VpnServer _selectedServer;
  ConnectionStateStatus _vpnStatus = ConnectionStateStatus.disconnected;
  String _activeIp = AppConstants.fallbackServerHost;

  StreamSubscription? _statusSubscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedServer = _servers.first;
    _initialize();
  }

  Future<void> _initialize() async {
    await _wireguardService.initialize();

    _statusSubscription = _wireguardService.statusStream.listen((status) {
      if (mounted) {
        setState(() => _vpnStatus = status);
        if (status == ConnectionStateStatus.connected) {
          _verifyLiveConnection();
        }
      }
    });

    final remoteServers = await _apiService.getServers();
    if (mounted && remoteServers.isNotEmpty) {
      setState(() => _servers = remoteServers);
    }

    final savedId = await DeviceService.getSavedSelectedServerId();
    if (savedId != null && mounted) {
      final found = _servers.firstWhere(
        (s) => s.id == savedId,
        orElse: () => _servers.first,
      );
      setState(() => _selectedServer = found);
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _verifyLiveConnection() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _vpnStatus != ConnectionStateStatus.connected) return;

    debugPrint('🔎 [LIVE-VERIFY] Checking public IP…');
    final liveIp = await VpnApiService.checkPublicIp();

    if (liveIp != null && mounted) {
      setState(() => _activeIp = liveIp);
      debugPrint('🎉 [LIVE-VERIFIED] Public IP: $liveIp');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.verified_rounded, color: Colors.black, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tunnel verified · $liveIp',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppConstants.successNeon,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  Future<void> _toggleVpn() async {
    if (_isLoading) return;

    if (_vpnStatus == ConnectionStateStatus.connected) {
      debugPrint('🛑 [ACTION] Disconnecting VPN…');
      setState(() => _isLoading = true);
      try {
        await _wireguardService.disconnect();
      } catch (e) {
        _showError('Disconnect error: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      debugPrint('🚀 [ACTION] Connecting to ${_selectedServer.country}…');
      setState(() => _isLoading = true);
      try {
        final cfg = await _apiService.getVpnConfig(_selectedServer.id);
        if (!cfg.success) {
          throw Exception(cfg.errorMessage ?? 'Config fetch failed');
        }
        if (cfg.clientIp != null) _activeIp = cfg.clientIp!;
        await _wireguardService.connect(
          serverAddress: cfg.serverEndpoint,
          wgQuickConfig: cfg.wgQuickConfig,
        );
      } catch (e) {
        debugPrint('❌ [ACTION] Failed: $e');
        _showError('Connection failed: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppConstants.errorNeon,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _openServerPicker() {
    if (_vpnStatus == ConnectionStateStatus.connected ||
        _vpnStatus == ConnectionStateStatus.connecting) {
      _showError('Please disconnect before changing server.');
      return;
    }
    ServerBottomSheet.show(
      context: context,
      servers: _servers,
      selectedServer: _selectedServer,
      onSelect: (server) {
        setState(() => _selectedServer = server);
        DeviceService.saveSelectedServerId(server.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _vpnStatus == ConnectionStateStatus.connected;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CyberBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 18),

                // ── Header ───────────────────────────────────────────────
                _buildHeader(isConnected),

                const Spacer(flex: 2),

                // ── Power button ─────────────────────────────────────────
                PowerButton(status: _vpnStatus, onTap: _toggleVpn),

                const Spacer(flex: 2),

                // ── Server selector ──────────────────────────────────────
                _buildServerCard(),

                const SizedBox(height: 14),

                // ── Stats ────────────────────────────────────────────────
                StatsCard(status: _vpnStatus, ipAddress: _activeIp),

                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isConnected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo block
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppConstants.primaryNeon.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppConstants.primaryNeon.withValues(alpha: 0.25),
                ),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: AppConstants.primaryNeon,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'JRonix VPN',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected
                            ? AppConstants.successNeon
                            : Colors.white30,
                        boxShadow: isConnected
                            ? [
                                BoxShadow(
                                  color: AppConstants.successNeon
                                      .withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                    ),
                    const SizedBox(width: 5),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: 11,
                        color: isConnected
                            ? AppConstants.successNeon
                            : Colors.white38,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      child: Text(isConnected ? 'Protected' : 'Unprotected'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Encryption badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1825),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_rounded, size: 13, color: AppConstants.primaryNeon),
              SizedBox(width: 5),
              Text(
                'AES-256',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Server card ────────────────────────────────────────────────────────────

  Widget _buildServerCard() {
    return GestureDetector(
      onTap: _openServerPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1422).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppConstants.border, width: 1),
        ),
        child: Row(
          children: [
            // Flag
            Text(
              _selectedServer.flag,
              style: const TextStyle(fontSize: 30),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SERVER LOCATION',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_selectedServer.country}  ·  ${_selectedServer.city}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Change button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppConstants.primaryNeon.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppConstants.primaryNeon.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Text(
                    'CHANGE',
                    style: TextStyle(
                      color: AppConstants.primaryNeon,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 9, color: AppConstants.primaryNeon),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
