import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../models/vpn_server.dart';
import '../services/device_service.dart';
import '../services/vpn_api_service.dart';
import '../services/wireguard_service.dart';
import '../widgets/power_button.dart';
import '../widgets/server_bottom_sheet.dart';
import '../widgets/world_map_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final VpnApiService _apiService = VpnApiService();
  final WireguardService _wireguardService = WireguardService();

  List<VpnServer> _servers = VpnServer.defaultServers;
  late VpnServer _selectedServer;
  ConnectionStateStatus _vpnStatus = ConnectionStateStatus.disconnected;
  String _activeIp = '';

  String _getMaskedIp(String ip) {
    if (ip.isEmpty) return '•••.•••.•••.•••';
    final parts = ip.split('.');
    if (parts.length == 4) {
      return '${parts[0]}.${parts[1]}.•••.${parts[3]}';
    }
    return ip;
  }

  bool _isConnecting = false;
  bool _isDisconnecting = false;

  ConnectionStateStatus get _displayStatus {
    if (_isConnecting) return ConnectionStateStatus.connecting;
    if (_isDisconnecting) return ConnectionStateStatus.disconnecting;
    return _vpnStatus;
  }

  StreamSubscription? _statusSubscription;
  Timer? _speedTimer;

  String _downloadSpeed = '10.5';
  String _uploadSpeed = '7.3';

  @override
  void initState() {
    super.initState();
    _selectedServer = _servers.firstWhere((s) => s.isDefault, orElse: () => _servers.first);
    _initialize();
  }

  Future<void> _initialize() async {
    await _wireguardService.initialize();

    _statusSubscription = _wireguardService.statusStream.listen((status) {
      if (!mounted) return;
      if (status == ConnectionStateStatus.connected) {
        setState(() {
          _isConnecting = false;
          _isDisconnecting = false;
          _vpnStatus = ConnectionStateStatus.connected;
        });
        _startSpeedSimulation();
        _verifyLiveConnection();
      } else if (status == ConnectionStateStatus.disconnected) {
        // If we are actively in the deliberate disconnecting flow, let it finish gracefully
        if (!_isConnecting && !_isDisconnecting) {
          setState(() {
            _vpnStatus = ConnectionStateStatus.disconnected;
          });
          _stopSpeedSimulation();
        }
      } else {
        if (!_isConnecting && !_isDisconnecting) {
          setState(() => _vpnStatus = status);
        }
      }
    });

    final remoteServers = await _apiService.getServers();
    if (mounted && remoteServers.isNotEmpty) {
      setState(() {
        _servers = remoteServers;
        if (!_servers.any((s) => s.id == _selectedServer.id)) {
          _selectedServer = _servers.firstWhere((s) => s.isDefault, orElse: () => _servers.first);
        }
      });
    }

    final savedId = await DeviceService.getSavedSelectedServerId();
    if (savedId != null && mounted) {
      final found = _servers.firstWhere(
        (s) => s.id == savedId,
        orElse: () => _servers.firstWhere((s) => s.isDefault, orElse: () => _servers.first),
      );
      setState(() => _selectedServer = found);
    }
  }

  void _startSpeedSimulation() {
    _speedTimer?.cancel();
    _downloadSpeed = '10.5';
    _uploadSpeed = '7.3';
    final random = math.Random();
    _speedTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _vpnStatus != ConnectionStateStatus.connected) return;
      setState(() {
        final d = 10.0 + random.nextDouble() * 1.5;
        final u = 7.0 + random.nextDouble() * 0.9;
        _downloadSpeed = d.toStringAsFixed(1);
        _uploadSpeed = u.toStringAsFixed(1);
      });
    });
  }

  void _stopSpeedSimulation() {
    _speedTimer?.cancel();
    _speedTimer = null;
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _speedTimer?.cancel();
    super.dispose();
  }

  Future<void> _verifyLiveConnection() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _vpnStatus != ConnectionStateStatus.connected || _isDisconnecting) return;

    debugPrint('🔎 [LIVE-VERIFY] Checking public IP…');
    final liveIp = await VpnApiService.checkPublicIp();

    if (liveIp != null && mounted && !_isDisconnecting) {
      setState(() => _activeIp = liveIp);
      debugPrint('🎉 [LIVE-VERIFIED] Public IP: $liveIp');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tunnel verified · $liveIp',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppConstants.goldDark,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  Future<void> _toggleVpn() async {
    if (_isConnecting || _isDisconnecting) return;

    if (_vpnStatus == ConnectionStateStatus.connected) {
      debugPrint('🛑 [ACTION] Disconnecting VPN…');
      setState(() {
        _isDisconnecting = true;
        _isConnecting = false;
      });
      _stopSpeedSimulation();
      try {
        await _wireguardService.disconnect();
        // Give a smooth, deliberate animation duration so the loader rotates gracefully
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) {
          setState(() {
            _isDisconnecting = false;
            _vpnStatus = ConnectionStateStatus.disconnected;
            _activeIp = '';
          });
        }
      } catch (e) {
        _showError('Disconnect error: $e');
        if (mounted) {
          setState(() {
            _isDisconnecting = false;
            _vpnStatus = ConnectionStateStatus.connected;
          });
        }
      }
    } else {
      debugPrint('🚀 [ACTION] Connecting to ${_selectedServer.country}…');
      setState(() {
        _isConnecting = true;
        _isDisconnecting = false;
      });
      try {
        // Clear any previous stale tunnel so HTTP requests can go through normal WiFi/Cellular
        await _wireguardService.disconnect();
        final cfg = await _apiService.getVpnConfig(_selectedServer.id);
        if (!cfg.success) {
          throw Exception(cfg.errorMessage ?? 'Config fetch failed');
        }
        if (cfg.serverEndpoint.isNotEmpty) {
          _activeIp = cfg.serverEndpoint.split(':').first;
        } else {
          _activeIp = AppConstants.fallbackServerHost;
        }
        await _wireguardService.connect(
          serverAddress: cfg.serverEndpoint,
          wgQuickConfig: cfg.wgQuickConfig,
        );
      } catch (e) {
        debugPrint('❌ [ACTION] Failed: $e');
        _showError('Connection failed: $e');
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _vpnStatus = ConnectionStateStatus.disconnected;
          });
        }
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppConstants.statusRed,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _openServerPicker() {
    if (_isConnecting ||
        _isDisconnecting ||
        _vpnStatus == ConnectionStateStatus.connected) {
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
    final currentStatus = _displayStatus;
    final isConnected = currentStatus == ConnectionStateStatus.connected;
    final isConnecting = currentStatus == ConnectionStateStatus.connecting;
    final isDisconnecting = currentStatus == ConnectionStateStatus.disconnecting;
    final isProcessing = isConnecting || isDisconnecting;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppConstants.scaffoldWhite,
      drawer: _buildDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final domeHeight = (screenHeight * 0.42).clamp(320.0, 390.0);

          return Column(
            children: [
              // ── Top Curved Dome (Golden Gradient) ──────────────────────
              ClipPath(
                clipper: _DomeClipper(),
                child: Container(
                  height: domeHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: isConnected
                        ? AppConstants.goldConnectedGradient
                        : AppConstants.goldDisconnectedGradient,
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // App Bar Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Hamburger Menu Button
                              IconButton(
                                icon: const Icon(
                                  Icons.menu_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: () {
                                  _scaffoldKey.currentState?.openDrawer();
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),

                              // App Title
                              Text(
                                'Jronix VPN',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                ),
                              ),

                              // Right spacer to keep title perfectly centered
                              const SizedBox(width: 28),
                            ],
                          ),

                          // Power Button
                          PowerButton(
                            status: currentStatus,
                            onTap: _toggleVpn,
                          ),

                          // Status Text (● Connected / ● Disconnected)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isConnected
                                      ? AppConstants.statusGreen
                                      : isProcessing
                                          ? AppConstants.goldGlow
                                          : AppConstants.statusRed,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isConnected
                                              ? AppConstants.statusGreen
                                              : isProcessing
                                                  ? AppConstants.goldGlow
                                                  : AppConstants.statusRed)
                                          .withValues(alpha: 0.7),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isConnected
                                    ? 'Connected'
                                    : isConnecting
                                        ? 'Connecting...'
                                        : isDisconnecting
                                            ? 'Disconnecting...'
                                            : 'Disconnected',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Lower Section (Clean White Background) ─────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // "Speed" Title (Figma 1:2)
                      Text(
                        'Speed',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.textSubtle,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Download / Upload Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Download Column
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Download',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppConstants.goldDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isConnected ? _downloadSpeed : '----',
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF4B5563),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'mbps',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppConstants.textSubtle,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Vertical divider bar
                          Container(
                            width: 3.5,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppConstants.dividerGray,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),

                          // Upload Column
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Upload',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppConstants.goldDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isConnected ? _uploadSpeed : '----',
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF4B5563),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'mbps',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppConstants.textSubtle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // "Location" Title (Figma 1:2)
                      Text(
                        'Location',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.textSubtle,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // World Map with animated locator pin
                      WorldMapWidget(
                        server: _selectedServer,
                        isConnected: isConnected,
                      ),

                      const SizedBox(height: 14),

                      // Country Picker Pill Button (Figma 1:2 & 6:175)
                      GestureDetector(
                        onTap: _openServerPicker,
                        child: Container(
                          height: 52,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppConstants.goldPrimary,
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.goldPrimary
                                    .withValues(alpha: 0.16),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              // Circular Country Flag
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade100,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _selectedServer.flag,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),

                              // Country Name
                              Expanded(
                                child: Text(
                                  _selectedServer.country,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF4B5563),
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // Dropdown Chevron
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppConstants.goldDark,
                                size: 26,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Navigation Drawer ──────────────────────────────────────────────────────
  Widget _buildDrawer() {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header with Golden Gradient & Official JR Shield Logo
          Container(
            padding: EdgeInsets.only(
              top: topPadding + 20,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: AppConstants.goldConnectedGradient,
            ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.black26,
                          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    AppConstants.appName,
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppConstants.appTagline,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Protocol
            ListTile(
              leading: const Icon(Icons.vpn_lock_rounded, color: AppConstants.goldDark),
              title: Text('Protocol', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('WireGuard® (High-Speed UDP)', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
            ),

            // Encryption
            ListTile(
              leading: const Icon(Icons.lock_outline_rounded, color: AppConstants.goldDark),
              title: Text('Encryption', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('ChaCha20-Poly1305 / AES-256', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
            ),

            // Virtual IP Shield (Secure Masked IP)
            ListTile(
              leading: Icon(
                _vpnStatus == ConnectionStateStatus.connected ? Icons.shield_rounded : Icons.gpp_maybe_rounded,
                color: _vpnStatus == ConnectionStateStatus.connected ? const Color(0xFF10B981) : Colors.orange.shade700,
              ),
              title: Row(
                children: [
                  Text('Virtual IP Shield', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _vpnStatus == ConnectionStateStatus.connected
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _vpnStatus == ConnectionStateStatus.connected ? 'PROTECTED' : 'EXPOSED',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _vpnStatus == ConnectionStateStatus.connected ? const Color(0xFF10B981) : Colors.orange.shade800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                _vpnStatus == ConnectionStateStatus.connected
                    ? (_activeIp.isNotEmpty ? _getMaskedIp(_activeIp) : '35.223.•••.45')
                    : 'Connect to shield your IP',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _vpnStatus == ConnectionStateStatus.connected ? const Color(0xFF10B981) : Colors.grey.shade600,
                  fontWeight: _vpnStatus == ConnectionStateStatus.connected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),

            // DNS Leak Shield
            ListTile(
              leading: const Icon(Icons.dns_rounded, color: AppConstants.goldDark),
              title: Row(
                children: [
                  Text('DNS Leak Shield', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text('Private Cloudflare 1.1.1.1 DNS', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
            ),

            // No-Logs Guarantee
            ListTile(
              leading: const Icon(Icons.verified_user_rounded, color: AppConstants.goldDark),
              title: Text('No-Logs Policy', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('Strict RAM-only (Zero logs stored)', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
            ),

            const Divider(),

            // Version
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: AppConstants.goldDark),
              title: Text('Version', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('1.0.0 (Build 1)', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
            ),

            const Spacer(),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  '© 2026 ${AppConstants.companyName}.\nAll rights reserved.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
}

// ── Smooth Convex Dome Clipper ───────────────────────────────────────────────
class _DomeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 75);
    // Smooth convex quadratic curve bowing down towards bottom center
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 75,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
