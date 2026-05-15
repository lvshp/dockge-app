import 'json_helpers.dart';

enum AuthType { password, token }

enum TlsMode { system, allowSelfSigned }

enum LanguagePreference { system, en, zhHans, zhHant }

class ServerProfile {
  const ServerProfile({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.authType = AuthType.password,
    this.tlsMode = TlsMode.system,
    this.username,
    this.lastConnectedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String baseUrl;
  final AuthType authType;
  final TlsMode tlsMode;
  final String? username;
  final DateTime? lastConnectedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServerProfile copyWith({
    String? id,
    String? name,
    String? baseUrl,
    AuthType? authType,
    TlsMode? tlsMode,
    String? username,
    DateTime? lastConnectedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      authType: authType ?? this.authType,
      tlsMode: tlsMode ?? this.tlsMode,
      username: username ?? this.username,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ServerProfile.fromJson(Map<String, dynamic> json) {
    return ServerProfile(
      id: stringValue(json['id']),
      name: stringValue(json['name']),
      baseUrl: stringValue(json['baseUrl'] ?? json['url']),
      authType: _enumByName(
        AuthType.values,
        stringValue(json['authType'], fallback: AuthType.password.name),
      ),
      tlsMode: _enumByName(
        TlsMode.values,
        stringValue(json['tlsMode'], fallback: TlsMode.system.name),
      ),
      username: nullableString(json['username']),
      lastConnectedAt: dateTimeValue(json['lastConnectedAt']),
      createdAt: dateTimeValue(json['createdAt']),
      updatedAt: dateTimeValue(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return omitNulls({
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'authType': authType.name,
      'tlsMode': tlsMode.name,
      'username': username,
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    });
  }
}

T _enumByName<T extends Enum>(List<T> values, String name) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return values.first;
}
