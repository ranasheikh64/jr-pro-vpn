import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/vpn_server.dart';
import 'device_service.dart';

class VpnConfigResponse {
  final bool success;
  final String wgQuickConfig;
  final String serverEndpoint;
  final String? clientIp;
  final String? errorMessage;

  const VpnConfigResponse({
    required this.success,
    required this.wgQuickConfig,
    required this.serverEndpoint,
    this.clientIp,
    this.errorMessage,
  });
}

class VpnApiService {
  final String baseUrl;

  VpnApiService({String? apiUrl})
      : baseUrl = apiUrl ?? AppConstants.defaultApiUrl;

  /// Fetch available servers list from Node.js backend
  Future<List<VpnServer>> getServers() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/servers'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['servers'] is List) {
          final servers = (data['servers'] as List)
              .map((s) => VpnServer.fromJson(s as Map<String, dynamic>))
              .toList();
          if (servers.isNotEmpty) return servers;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Warning fetching servers from $baseUrl: $e. Using local defaults.');
    }

    // Reliable fallback
    return VpnServer.defaultServers;
  }

  /// Request WireGuard configuration for the selected server
  Future<VpnConfigResponse> getVpnConfig(String serverId) async {
    final deviceId = await DeviceService.getOrCreateDeviceId();
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📡 [VPN-API] Connecting to Cloud Backend: $baseUrl/api/vpn/config');
    debugPrint('📱 [VPN-API] Device ID: $deviceId | Selected Server: $serverId');

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/vpn/config'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'deviceId': deviceId,
              'serverId': serverId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📥 [VPN-API] Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['wgQuickConfig'] != null) {
          final endpoint = data['server']?['endpoint'] ??
              '${AppConstants.fallbackServerHost}:${AppConstants.fallbackServerPort}';
          final clientIp = data['clientIp'] ?? '10.66.0.2';

          debugPrint('✅ [VPN-API] Configuration received from VPS!');
          debugPrint('🌐 [VPN-API] Remote Server Endpoint: $endpoint');
          debugPrint('📍 [VPN-API] Allocated Virtual Tunnel IP: $clientIp');
          debugPrint('🔑 [VPN-API] WireGuard Config Payload:\n${data['wgQuickConfig']}');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          return VpnConfigResponse(
            success: true,
            wgQuickConfig: data['wgQuickConfig'],
            serverEndpoint: endpoint,
            clientIp: clientIp,
          );
        } else {
          return VpnConfigResponse(
            success: false,
            wgQuickConfig: '',
            serverEndpoint: '',
            errorMessage: data['message'] ?? 'Failed to generate configuration',
          );
        }
      } else {
        return VpnConfigResponse(
          success: false,
          wgQuickConfig: '',
          serverEndpoint: '',
          errorMessage: 'Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ [VPN-API] Error fetching config from $baseUrl: $e');
      return VpnConfigResponse(
        success: false,
        wgQuickConfig: '',
        serverEndpoint: '',
        errorMessage: 'Connection to backend API failed: $e',
      );
    }
  }

  /// Live verify external public IP address
  static Future<String?> checkPublicIp() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ip = data['ip'] as String?;
        debugPrint('🌐 [PUBLIC-IP-CHECK] Current External Public IP: $ip');
        return ip;
      }
    } catch (e) {
      debugPrint('⚠️ [PUBLIC-IP-CHECK] Note: External IP query error ($e)');
    }
    return null;
  }
}
