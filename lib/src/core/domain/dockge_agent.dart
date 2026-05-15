import 'json_helpers.dart';

class DockgeAgent {
  const DockgeAgent({
    required this.id,
    required this.url,
    this.name,
    this.username,
    this.endpoint,
    this.online = false,
    this.lastConnectedAt,
    this.raw = const <String, dynamic>{},
  });

  final String id;
  final String? name;
  final String url;
  final String? username;
  final String? endpoint;
  final bool online;
  final DateTime? lastConnectedAt;
  final Map<String, dynamic> raw;

  factory DockgeAgent.fromJson(Map<String, dynamic> json) {
    final id = stringValue(json['id'] ?? json['endpoint'] ?? json['url']);
    return DockgeAgent(
      id: id,
      name: nullableString(json['name']),
      url: stringValue(json['url'] ?? json['baseUrl'] ?? json['endpoint']),
      username: nullableString(json['username']),
      endpoint: nullableString(json['endpoint']),
      online: boolValue(json['online'] ?? json['connected']),
      lastConnectedAt: dateTimeValue(json['lastConnectedAt']),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() {
    return omitNulls({
      'id': id,
      'name': name,
      'url': url,
      'username': username,
      'endpoint': endpoint,
      'online': online,
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
    });
  }
}
