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
  });

  factory VpnServer.fromJson(Map<String, dynamic> json) {
    return VpnServer(
      id: json['id'] as String? ?? 'us-central',
      country: json['country'] as String? ?? 'United States',
      city: json['city'] as String? ?? 'Iowa',
      countryCode: json['countryCode'] as String? ?? 'US',
      flag: json['flag'] as String? ?? '🇺🇸',
      ping: json['ping'] as String? ?? '45 ms',
      status: json['status'] as String? ?? 'optimal',
      load: json['load'] as String? ?? '30%',
      isDefault: json['isDefault'] as bool? ?? false,
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
    };
  }

  static List<VpnServer> get defaultServers => const [
    VpnServer(
      id: 'us-central',
      country: 'United States',
      city: 'Iowa / Central',
      countryCode: 'US',
      flag: '🇺🇸',
      ping: '45 ms',
      status: 'optimal',
      load: '25%',
      isDefault: true,
    ),
    VpnServer(
      id: 'sg-singapore',
      country: 'Singapore',
      city: 'Jurong',
      countryCode: 'SG',
      flag: '🇸🇬',
      ping: '38 ms',
      status: 'optimal',
      load: '32%',
    ),
    VpnServer(
      id: 'de-frankfurt',
      country: 'Germany',
      city: 'Frankfurt',
      countryCode: 'DE',
      flag: '🇩🇪',
      ping: '110 ms',
      status: 'online',
      load: '40%',
    ),
    VpnServer(
      id: 'uk-london',
      country: 'United Kingdom',
      city: 'London',
      countryCode: 'GB',
      flag: '🇬🇧',
      ping: '125 ms',
      status: 'online',
      load: '48%',
    ),
    VpnServer(
      id: 'jp-tokyo',
      country: 'Japan',
      city: 'Tokyo',
      countryCode: 'JP',
      flag: '🇯🇵',
      ping: '95 ms',
      status: 'online',
      load: '55%',
    ),
  ];
}
