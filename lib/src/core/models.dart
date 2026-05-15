enum AuthType { password, token }

enum TlsMode { system, allowSelfSigned }

enum StackStatus {
  running,
  stopped,
  inactive,
  partial,
  error,
  updating,
  unknown,
}

enum OperationType { start, stop, restart, update, down, delete, saveCompose }

enum OperationStatus { pending, running, succeeded, failed }

enum DangerLevel { normal, caution, destructive }

class ServerProfile {
  const ServerProfile({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.authType = AuthType.password,
    this.tlsMode = TlsMode.system,
    this.lastConnectedAt,
  });

  final String id;
  final String name;
  final String baseUrl;
  final AuthType authType;
  final TlsMode tlsMode;
  final DateTime? lastConnectedAt;

  ServerProfile copyWith({
    String? id,
    String? name,
    String? baseUrl,
    AuthType? authType,
    TlsMode? tlsMode,
    DateTime? lastConnectedAt,
  }) {
    return ServerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      authType: authType ?? this.authType,
      tlsMode: tlsMode ?? this.tlsMode,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }

  factory ServerProfile.fromJson(Map<String, dynamic> json) {
    return ServerProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      authType: AuthType.values.byName(json['authType'] as String),
      tlsMode: TlsMode.values.byName(json['tlsMode'] as String),
      lastConnectedAt: json['lastConnectedAt'] == null
          ? null
          : DateTime.parse(json['lastConnectedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    'authType': authType.name,
    'tlsMode': tlsMode.name,
    'lastConnectedAt': lastConnectedAt?.toIso8601String(),
  };
}

class LoginCredentials {
  const LoginCredentials({
    required this.username,
    required this.password,
    this.token,
  });

  final String username;
  final String password;
  final String? token;
}

class LoginResult {
  const LoginResult({
    required this.ok,
    this.token,
    this.message,
    this.tokenRequired = false,
  });

  final bool ok;
  final String? token;
  final String? message;
  final bool tokenRequired;
}

class ServerInfo {
  const ServerInfo({
    this.version,
    this.latestVersion,
    this.isContainer,
    this.primaryHostname,
  });

  final String? version;
  final String? latestVersion;
  final bool? isContainer;
  final String? primaryHostname;

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      version: json['version'] as String?,
      latestVersion: json['latestVersion'] as String?,
      isContainer: json['isContainer'] as bool?,
      primaryHostname: json['primaryHostname'] as String?,
    );
  }
}

class StackSummary {
  const StackSummary({
    required this.name,
    required this.agentId,
    required this.status,
    required this.serviceCount,
    required this.updatedAt,
    required this.composePath,
    this.endpoint,
    this.isManagedByDockge = true,
  });

  final String name;
  final String agentId;
  final StackStatus status;
  final int serviceCount;
  final DateTime updatedAt;
  final String composePath;
  final String? endpoint;
  final bool isManagedByDockge;

  factory StackSummary.fromDockge(String name, Map<String, dynamic> json) {
    final statusText = '${json['status'] ?? json['state'] ?? ''}'.toLowerCase();
    final services = json['services'];
    final serviceCount = services is Map
        ? services.length
        : int.tryParse('${json['serviceCount'] ?? 0}') ?? 0;
    final endpoint = json['endpoint'] as String?;

    return StackSummary(
      name: name,
      agentId: endpoint?.isEmpty ?? true ? 'local' : endpoint!,
      status: StackStatusMapper.fromDockge(statusText),
      serviceCount: serviceCount,
      updatedAt: DateTime.now(),
      composePath:
          '${json['path'] ?? json['composePath'] ?? name}/compose.yaml',
      endpoint: endpoint,
      isManagedByDockge: json['isManagedByDockge'] as bool? ?? true,
    );
  }

  StackSummary copyWith({
    StackStatus? status,
    int? serviceCount,
    DateTime? updatedAt,
  }) {
    return StackSummary(
      name: name,
      agentId: agentId,
      status: status ?? this.status,
      serviceCount: serviceCount ?? this.serviceCount,
      updatedAt: updatedAt ?? this.updatedAt,
      composePath: composePath,
      endpoint: endpoint,
      isManagedByDockge: isManagedByDockge,
    );
  }
}

class StackDetail {
  const StackDetail({
    required this.summary,
    required this.composeYaml,
    required this.services,
    required this.envFiles,
    this.composeEnv = '',
    this.lastOperation,
  });

  final StackSummary summary;
  final String composeYaml;
  final String composeEnv;
  final List<ServiceStatus> services;
  final List<String> envFiles;
  final DockgeOperation? lastOperation;
}

class ServiceStatus {
  const ServiceStatus({
    required this.name,
    required this.status,
    this.image,
    this.ports = const [],
  });

  final String name;
  final StackStatus status;
  final String? image;
  final List<String> ports;
}

class DockgeOperation {
  const DockgeOperation({
    required this.id,
    required this.type,
    required this.targetStack,
    required this.status,
    required this.progress,
    required this.startedAt,
    this.finishedAt,
    this.message,
  });

  final String id;
  final OperationType type;
  final String targetStack;
  final OperationStatus status;
  final double progress;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String? message;

  DockgeOperation copyWith({
    OperationStatus? status,
    double? progress,
    DateTime? finishedAt,
    String? message,
  }) {
    return DockgeOperation(
      id: id,
      type: type,
      targetStack: targetStack,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      message: message ?? this.message,
    );
  }
}

class LogLine {
  const LogLine({
    required this.stackName,
    required this.message,
    required this.timestamp,
    this.serviceName,
  });

  final String stackName;
  final String? serviceName;
  final String message;
  final DateTime timestamp;
}

class StackStatusMapper {
  const StackStatusMapper._();

  static StackStatus fromDockge(Object? value) {
    final numeric = int.tryParse('${value ?? ''}');
    if (numeric != null) {
      return switch (numeric) {
        3 => StackStatus.running,
        4 => StackStatus.stopped,
        1 || 2 => StackStatus.inactive,
        0 => StackStatus.unknown,
        _ => StackStatus.unknown,
      };
    }

    final normalized = '${value ?? ''}'.toLowerCase();
    if (normalized.contains('running') ||
        normalized.contains('up') ||
        normalized == 'healthy') {
      return StackStatus.running;
    }
    if (normalized.contains('inactive') ||
        normalized.contains('created') ||
        normalized.contains('created_file') ||
        normalized.contains('created_stack')) {
      return StackStatus.inactive;
    }
    if (normalized.contains('stop') ||
        normalized.contains('exit') ||
        normalized.contains('down')) {
      return StackStatus.stopped;
    }
    if (normalized.contains('partial')) {
      return StackStatus.partial;
    }
    if (normalized.contains('error') ||
        normalized.contains('unhealthy') ||
        normalized.contains('fail')) {
      return StackStatus.error;
    }
    if (normalized.contains('update') ||
        normalized.contains('deploy') ||
        normalized.contains('starting')) {
      return StackStatus.updating;
    }
    return StackStatus.unknown;
  }
}
