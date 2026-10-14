import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const String _deviceIdKey = 'jronix_device_uuid';
  static const String _selectedServerKey = 'jronix_selected_server_id';

  /// Get or create persistent anonymous device ID
  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  /// Save user's selected server
  static Future<void> saveSelectedServerId(String serverId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedServerKey, serverId);
  }

  /// Get saved selected server ID
  static Future<String?> getSavedSelectedServerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedServerKey);
  }
}
