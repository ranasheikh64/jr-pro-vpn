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
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['wgQuickConfig'] != null) {
          return VpnConfigResponse(
            success: true,
            wgQuickConfig: data['wgQuickConfig'],
            serverEndpoint: data['server']['endpoint'] ?? '${AppConstants.fallbackServerHost}:${AppConstants.fallbackServerPort}',
            clientIp: data['clientIp'],
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Warning fetching config from API: $e. Using pre-configured fallback.');
    }

    // Seamless fallback to pre-configured Google Cloud VPS
    // Uses slot 1 test configuration
    const fallbackConfig = '''[Interface]
PrivateKey = MJWDTuMoMvHneO4D7zJAe8NeuzVSyC0mYcg26UhJsFI=
Address = 10.66.66.2/32
DNS = ${AppConstants.fallbackDns}

[Peer]
PublicKey = ${AppConstants.fallbackServerPublicKey}
Endpoint = ${AppConstants.fallbackServerHost}:${AppConstants.fallbackServerPort}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
''';

    return const VpnConfigResponse(
      success: true,
      wgQuickConfig: fallbackConfig,
      serverEndpoint: '${AppConstants.fallbackServerHost}:${AppConstants.fallbackServerPort}',
      clientIp: '10.66.66.2',
    );
  }
}
