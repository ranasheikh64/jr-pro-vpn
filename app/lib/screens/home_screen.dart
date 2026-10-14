import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/vpn_server.dart';
import '../services/device_service.dart';
import '../services/vpn_api_service.dart';
import '../services/wireguard_service.dart';
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
    // 1. Initialize WireGuard
    await _wireguardService.initialize();

    // 2. Listen to status stream
    _statusSubscription = _wireguardService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _vpnStatus = status;
        });
      }
    });

    // 3. Fetch servers from API
    final remoteServers = await _apiService.getServers();
    if (mounted && remoteServers.isNotEmpty) {
      setState(() {
        _servers = remoteServers;
      });
    }

    // 4. Restore last selected server
    final savedServerId = await DeviceService.getSavedSelectedServerId();
    if (savedServerId != null && mounted) {
      final found = _servers.firstWhere(
        (s) => s.id == savedServerId,
        orElse: () => _servers.first,
      );
      setState(() {
        _selectedServer = found;
      });
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleVpn() async {
    if (_isLoading) return;

    if (_vpnStatus == ConnectionStateStatus.connected) {
      // Disconnect
      setState(() => _isLoading = true);
      try {
        await _wireguardService.disconnect();
      } catch (e) {
        _showError('Error disconnecting: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Connect
      setState(() => _isLoading = true);
      try {
        // Request config from Node.js API or fallback
        final configResponse = await _apiService.getVpnConfig(_selectedServer.id);

        if (!configResponse.success) {
          throw Exception(configResponse.errorMessage ?? 'Failed to get VPN config');
        }

        if (configResponse.clientIp != null) {
          _activeIp = configResponse.clientIp!;
        }

        // Start WireGuard native tunnel
        await _wireguardService.connect(
          serverAddress: configResponse.serverEndpoint,
          wgQuickConfig: configResponse.wgQuickConfig,
        );
      } catch (e) {
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
        content: Text(message),
        backgroundColor: AppConstants.errorNeon,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openServerPicker() {
    if (_vpnStatus == ConnectionStateStatus.connected ||
        _vpnStatus == ConnectionStateStatus.connecting) {
      _showError('Please disconnect before changing server location.');
      return;
    }

    ServerBottomSheet.show(
      context: context,
      servers: _servers,
      selectedServer: _selectedServer,
      onSelect: (server) {
        setState(() {
          _selectedServer = server;
        });
        DeviceService.saveSelectedServerId(server.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _vpnStatus == ConnectionStateStatus.connected;

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // 1. Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryNeon.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppConstants.primaryNeon.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: AppConstants.primaryNeon,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            AppConstants.appName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isConnected
                                      ? AppConstants.successNeon
                                      : Colors.white30,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isConnected ? 'Protected' : 'Unprotected',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isConnected
                                      ? AppConstants.successNeon
                                      : Colors.white38,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Kill switch / protocol badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppConstants.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 14, color: AppConstants.warningNeon),
                        SizedBox(width: 4),
                        Text(
                          'Fastest',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // 2. Center: Glowing Power Button
              PowerButton(
                status: _vpnStatus,
                onTap: _toggleVpn,
              ),

              const Spacer(flex: 1),

              // 3. Country / Server Selector Card
              InkWell(
                onTap: _openServerPicker,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppConstants.border,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Flag
                      Text(
                        _selectedServer.flag,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 16),

                      // Location text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SERVER LOCATION',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_selectedServer.country} (${_selectedServer.city})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Change Server Action
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryNeon.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'CHANGE',
                              style: TextStyle(
                                color: AppConstants.primaryNeon,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: AppConstants.primaryNeon,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 4. Live Stats Card
              StatsCard(
                status: _vpnStatus,
                ipAddress: _activeIp,
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
