import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:wireguard_flutter_plus/wireguard_flutter_plus.dart';

enum ConnectionStateStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class WireguardService {
  static final WireguardService _instance = WireguardService._internal();
  factory WireguardService() => _instance;
  WireguardService._internal();

  final dynamic _wireGuard = WireGuardFlutter.instance;
  bool _initialized = false;

  final _statusController = StreamController<ConnectionStateStatus>.broadcast();
  Stream<ConnectionStateStatus> get statusStream => _statusController.stream;

  ConnectionStateStatus _currentStatus = ConnectionStateStatus.disconnected;
  ConnectionStateStatus get currentStatus => _currentStatus;

  DateTime? _connectedAt;
  DateTime? get connectedAt => _connectedAt;

  StreamSubscription? _stageSubscription;
  StreamSubscription? _trafficSubscription;

  int _bytesIn = 0;
  int _bytesOut = 0;
  int get bytesIn => _bytesIn;
  int get bytesOut => _bytesOut;

  /// Initialize WireGuard tunnel interface
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _wireGuard.initialize(interfaceName: 'jronix_wg');
      _initialized = true;

      // Listen to native stage events
      _stageSubscription = _wireGuard.vpnStageSnapshot.listen(
        _onVpnStageChanged,
        onError: (err) {
          debugPrint('⚠️ WireGuard stage error: $err');
          _updateStatus(ConnectionStateStatus.error);
        },
      );

      // Listen to live traffic statistics
      _trafficSubscription = _wireGuard.trafficSnapshot.listen(
        (data) {
          _bytesIn = (data['totalDownload'] as num?)?.toInt() ?? 0;
          _bytesOut = (data['totalUpload'] as num?)?.toInt() ?? 0;
        },
        onError: (err) {
          debugPrint('⚠️ WireGuard traffic error: $err');
        },
      );

      debugPrint('✅ WireGuard initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Error initializing WireGuard: $e');
    }
  }

  void _onVpnStageChanged(VpnStage stage) {
    debugPrint('════════════════════════════════════════════════════════');
    debugPrint('🔄 [WIREGUARD STAGE] Status: ${stage.name.toUpperCase()}');
    switch (stage) {
      case VpnStage.connected:
        _connectedAt = DateTime.now();
        _updateStatus(ConnectionStateStatus.connected);
        debugPrint('🎉 [WIREGUARD] Tunnel is ACTIVE! Native interface UP.');
        break;
      case VpnStage.connecting:
      case VpnStage.waitingConnection:
        _updateStatus(ConnectionStateStatus.connecting);
        debugPrint('⏳ [WIREGUARD] Negotiating connection with server...');
        break;
      case VpnStage.disconnecting:
        _updateStatus(ConnectionStateStatus.disconnecting);
        debugPrint('🔌 [WIREGUARD] Disconnecting tunnel...');
        break;
      case VpnStage.disconnected:
      default:
        _connectedAt = null;
        _updateStatus(ConnectionStateStatus.disconnected);
        debugPrint('⚪ [WIREGUARD] Tunnel Disconnected.');
        break;
    }
    debugPrint('════════════════════════════════════════════════════════');
  }

  void _updateStatus(ConnectionStateStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Start VPN Tunnel
  Future<bool> connect({
    required String serverAddress,
    required String wgQuickConfig,
  }) async {
    await initialize();

    try {
      _updateStatus(ConnectionStateStatus.connecting);
      debugPrint('🚀 [WIREGUARD] Calling startVpn() for: $serverAddress');

      await _wireGuard.startVpn(
        serverAddress: serverAddress,
        wgQuickConfig: wgQuickConfig,
        providerBundleIdentifier: 'com.jronix.vpn.WGExtension',
      );

      debugPrint('✅ [WIREGUARD] startVpn() invoked without error');
      return true;
    } catch (e) {
      debugPrint('❌ [WIREGUARD] Error starting WireGuard VPN: $e');
      _updateStatus(ConnectionStateStatus.disconnected);
      rethrow;
    }
  }

  /// Stop VPN Tunnel
  Future<void> disconnect() async {
    try {
      _updateStatus(ConnectionStateStatus.disconnecting);
      debugPrint('🛑 [WIREGUARD] Calling stopVpn()');
      await _wireGuard.stopVpn();
    } catch (e) {
      debugPrint('❌ [WIREGUARD] Error stopping WireGuard VPN: $e');
    } finally {
      _connectedAt = null;
      _updateStatus(ConnectionStateStatus.disconnected);
      debugPrint('⚪ [WIREGUARD] Disconnect complete.');
    }
  }

  void dispose() {
    _stageSubscription?.cancel();
    _trafficSubscription?.cancel();
    _statusController.close();
  }
}
