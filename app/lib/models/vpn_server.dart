class VpnServer {
  final String id;
  final String country;
  final String city;
  final String countryCode;
  final String flag;
  final String ping;
  final String status;
  final String load;
  final bool isDefault;
  final double mapX;
  final double mapY;

  const VpnServer({
    required this.id,
    required this.country,
    required this.city,
    required this.countryCode,
    required this.flag,
    required this.ping,
    this.status = 'optimal',
    this.load = '30%',
    this.isDefault = false,
    this.mapX = 0.5,
    this.mapY = 0.5,
  });

  static double resolveMapX(String code) {
    switch (code.toUpperCase()) {
      case 'US':
        return 0.22;
      case 'DE':
        return 0.50;
      case 'SG':
        return 0.76;
      case 'GB':
      case 'UK':
        return 0.47;
      case 'JP':
        return 0.85;
      default:
        return 0.50;
    }
  }

  static double resolveMapY(String code) {
    switch (code.toUpperCase()) {
      case 'US':
        return 0.36;
      case 'DE':
        return 0.28;
      case 'SG':
        return 0.57;
      case 'GB':
      case 'UK':
        return 0.26;
      case 'JP':
        return 0.37;
      default:
        return 0.50;
    }
  }

  factory VpnServer.fromJson(Map<String, dynamic> json) {
    final code = (json['countryCode'] as String? ?? 'US').toUpperCase();
    return VpnServer(
      id: json['id'] as String? ?? 'us-central',
      country: json['country'] as String? ?? 'United States',
      city: json['city'] as String? ?? 'Iowa / Central',
      countryCode: code,
      flag: json['flag'] as String? ?? '🇺🇸',
      ping: json['ping'] as String? ?? '45 ms',
      status: json['status'] as String? ?? 'optimal',
      load: json['load'] as String? ?? '28%',
      isDefault: json['isDefault'] as bool? ?? false,
      mapX: (json['mapX'] as num?)?.toDouble() ?? resolveMapX(code),
      mapY: (json['mapY'] as num?)?.toDouble() ?? resolveMapY(code),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'country': country,
      'city': city,
      'countryCode': countryCode,
      'flag': flag,
      'ping': ping,
      'status': status,
      'load': load,
      'isDefault': isDefault,
      'mapX': mapX,
      'mapY': mapY,
    };
  }

  // Exact 5 servers configured in /Users/ranasheikh/my/jr-pro-vpn/server/src/server.js
  static List<VpnServer> get defaultServers => const [
    VpnServer(
      id: 'us-central',
      country: 'United States',
      city: 'Iowa / Central',
      countryCode: 'US',
      flag: '🇺🇸',
      ping: '45 ms',
      status: 'optimal',
      load: '28%',
      isDefault: true,
      mapX: 0.22,
      mapY: 0.36,
    ),
    VpnServer(
      id: 'de-frankfurt',
      country: 'Germany',
      city: 'Frankfurt',
      countryCode: 'DE',
      flag: '🇩🇪',
      ping: '110 ms',
      status: 'online',
      load: '42%',
      isDefault: false,
      mapX: 0.50,
      mapY: 0.28,
    ),
    VpnServer(
      id: 'sg-singapore',
      country: 'Singapore',
      city: 'Jurong',
      countryCode: 'SG',
      flag: '🇸🇬',
      ping: '38 ms',
      status: 'optimal',
      load: '35%',
      isDefault: false,
      mapX: 0.76,
      mapY: 0.57,
    ),
    VpnServer(
      id: 'uk-london',
      country: 'United Kingdom',
      city: 'London',
      countryCode: 'GB',
      flag: '🇬🇧',
      ping: '125 ms',
      status: 'online',
      load: '50%',
      isDefault: false,
      mapX: 0.47,
      mapY: 0.26,
    ),
    VpnServer(
      id: 'jp-tokyo',
      country: 'Japan',
      city: 'Tokyo',
      countryCode: 'JP',
      flag: '🇯🇵',
      ping: '95 ms',
      status: 'online',
      load: '60%',
      isDefault: false,
      mapX: 0.85,
      mapY: 0.37,
    ),
  ];
}
