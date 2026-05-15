import 'json_helpers.dart';

enum StackStatus {
  running,
  stopped,
  inactive,
  partial,
  error,
  updating,
  unknown,
}

class StackSummary {
  const StackSummary({
    required this.name,
    required this.agentId,
    required this.status,
    this.serviceCount = 0,
    this.composePath,
    this.endpoint,
    this.isManagedByDockge = true,
    this.updatedAt,
    this.raw = const <String, dynamic>{},
  });

  final String name;
  final String agentId;
  final StackStatus status;
  final int serviceCount;
  final String? composePath;
  final String? endpoint;
  final bool isManagedByDockge;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  factory StackSummary.fromJson(Map<String, dynamic> json, {String? name}) {
    final services = json['services'];
    return StackSummary(
      name: stringValue(name ?? json['name'] ?? json['stackName']),
      agentId: stringValue(
        json['agentId'] ?? json['endpoint'],
        fallback: 'local',
      ),
      status: stackStatusFromDockge(json['status'] ?? json['state']),
      serviceCount: services is Map
          ? services.length
          : intValue(json['serviceCount'] ?? json['services']),
      composePath: nullableString(
        json['composePath'] ?? json['path'] ?? json['composeFileName'],
      ),
      endpoint: nullableString(json['endpoint']),
      isManagedByDockge: boolValue(json['isManagedByDockge'], fallback: true),
      updatedAt: dateTimeValue(json['updatedAt'] ?? json['lastUpdated']),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() {
    return omitNulls({
      'name': name,
      'agentId': agentId,
      'status': status.name,
      'serviceCount': serviceCount,
      'composePath': composePath,
      'endpoint': endpoint,
      'isManagedByDockge': isManagedByDockge,
      'updatedAt': updatedAt?.toIso8601String(),
    });
  }
}

class StackDetail {
  const StackDetail({
    required this.summary,
    this.composeYaml = '',
    this.composeEnv = '',
    this.services = const <ServiceStatus>[],
    this.envFiles = const <String>[],
    this.raw = const <String, dynamic>{},
  });

  final StackSummary summary;
  final String composeYaml;
  final String composeEnv;
  final List<ServiceStatus> services;
  final List<String> envFiles;
  final Map<String, dynamic> raw;

  factory StackDetail.fromJson(Map<String, dynamic> json) {
    final stack = jsonMap(json['stack']).isEmpty
        ? json
        : jsonMap(json['stack']);
    final servicesPayload =
        json['serviceStatusList'] ??
        json['services'] ??
        stack['serviceStatusList'] ??
        stack['services'];
    return StackDetail(
      summary: StackSummary.fromJson(stack),
      composeYaml: stringValue(
        json['composeYaml'] ??
            json['composeYAML'] ??
            json['compose'] ??
            stack['composeYaml'] ??
            stack['composeYAML'],
      ),
      composeEnv: stringValue(
        json['composeEnv'] ??
            json['composeENV'] ??
            stack['composeEnv'] ??
            stack['composeENV'],
      ),
      services: _parseServices(servicesPayload),
      envFiles: jsonList(
        json['envFiles'] ?? stack['envFiles'],
      ).map((value) => value.toString()).toList(growable: false),
      raw: json,
    );
  }
}

class ServiceStatus {
  const ServiceStatus({
    required this.name,
    required this.status,
    this.image,
    this.ports = const <String>[],
    this.cpuPercent,
    this.memoryUsage,
    this.memoryPercent,
    this.raw = const <String, dynamic>{},
  });

  final String name;
  final StackStatus status;
  final String? image;
  final List<String> ports;
  final String? cpuPercent;
  final String? memoryUsage;
  final String? memoryPercent;
  final Map<String, dynamic> raw;

  factory ServiceStatus.fromJson(Map<String, dynamic> json, {String? name}) {
    return ServiceStatus(
      name: stringValue(name ?? json['name'] ?? json['serviceName']),
      status: stackStatusFromDockge(json['status'] ?? json['state']),
      image: nullableString(json['image']),
      ports: jsonList(json['ports']).map((value) => value.toString()).toList(),
      cpuPercent: nullableString(json['cpuPercent']),
      memoryUsage: nullableString(json['memoryUsage']),
      memoryPercent: nullableString(json['memoryPercent']),
      raw: json,
    );
  }
}

class DockerStats {
  const DockerStats({
    required this.serviceName,
    this.containerName,
    this.cpuPercent = 0,
    this.cpuPercentRaw,
    this.memoryUsageBytes = 0,
    this.memoryLimitBytes = 0,
    this.memoryPercent = 0,
    this.memoryPercentRaw,
    this.memoryUsageRaw,
    this.networkRxBytes = 0,
    this.networkTxBytes = 0,
    this.blockReadBytes = 0,
    this.blockWriteBytes = 0,
    this.raw = const <String, dynamic>{},
  });

  final String serviceName;
  final String? containerName;
  final double cpuPercent;
  final String? cpuPercentRaw;
  final int memoryUsageBytes;
  final int memoryLimitBytes;
  final double memoryPercent;
  final String? memoryPercentRaw;
  final String? memoryUsageRaw;
  final int networkRxBytes;
  final int networkTxBytes;
  final int blockReadBytes;
  final int blockWriteBytes;
  final Map<String, dynamic> raw;

  factory DockerStats.fromJson(Map<String, dynamic> json, {String? name}) {
    return DockerStats(
      serviceName: stringValue(name ?? json['serviceName'] ?? json['Name']),
      containerName: nullableString(
        json['containerName'] ?? json['container'] ?? json['Name'],
      ),
      cpuPercent: _parsePercent(json['CPUPerc'] ?? json['cpuPercent'] ?? json['cpu']),
      cpuPercentRaw: nullableString(json['CPUPerc'] ?? json['cpuPercentRaw']),
      memoryUsageBytes: intValue(
        json['memoryUsageBytes'] ?? json['memUsage'],
      ),
      memoryLimitBytes: intValue(
        json['memoryLimitBytes'] ?? json['memLimit'],
      ),
      memoryPercent: _parsePercent(
        json['MemPerc'] ?? json['memoryPercent'],
      ),
      memoryPercentRaw: nullableString(json['MemPerc'] ?? json['memoryPercentRaw']),
      memoryUsageRaw: nullableString(json['MemUsage'] ?? json['memoryUsageRaw']),
      networkRxBytes: intValue(json['networkRxBytes']),
      networkTxBytes: intValue(json['networkTxBytes']),
      blockReadBytes: intValue(json['blockReadBytes']),
      blockWriteBytes: intValue(json['blockWriteBytes']),
      raw: json,
    );
  }

  /// 从百分比字符串如 "0.17%" 提取数值
  static double _parsePercent(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll('%', '').trim()) ?? 0;
    }
    return 0;
  }
}

StackStatus stackStatusFromDockge(Object? value) {
  final numeric = int.tryParse(stringValue(value));
  if (numeric != null) {
    return switch (numeric) {
      3 => StackStatus.running,
      4 => StackStatus.stopped,
      1 || 2 => StackStatus.inactive,
      0 => StackStatus.unknown,
      _ => StackStatus.unknown,
    };
  }

  final normalized = stringValue(value).toLowerCase();
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

List<StackSummary> parseStackSummaryList(Object? payload) {
  if (payload is Map) {
    return payload.entries
        .map(
          (entry) => StackSummary.fromJson(
            jsonMap(entry.value),
            name: entry.key.toString(),
          ),
        )
        .toList(growable: false);
  }
  return jsonList(payload)
      .map((value) => StackSummary.fromJson(jsonMap(value)))
      .toList(growable: false);
}

List<ServiceStatus> parseServiceStatusList(Object? payload) {
  return _parseServices(payload);
}

List<DockerStats> parseDockerStatsList(Object? payload) {
  if (payload is Map) {
    return payload.entries
        .map(
          (entry) => DockerStats.fromJson(
            jsonMap(entry.value),
            name: entry.key.toString(),
          ),
        )
        .toList(growable: false);
  }
  return jsonList(payload)
      .map((value) => DockerStats.fromJson(jsonMap(value)))
      .toList(growable: false);
}

List<ServiceStatus> _parseServices(Object? payload) {
  if (payload is Map) {
    return payload.entries.map((entry) {
      final value = entry.value;
      // 服务器返回 { "serviceName": [{ status, name }, ...] } 格式
      // 每个服务对应一个容器数组，取第一个容器的状态作为服务状态
      if (value is List && value.isNotEmpty) {
        return ServiceStatus.fromJson(
          jsonMap(value.first),
          name: entry.key.toString(),
        );
      }
      return ServiceStatus.fromJson(
        jsonMap(value),
        name: entry.key.toString(),
      );
    }).toList(growable: false);
  }
  return jsonList(payload)
      .map((value) => ServiceStatus.fromJson(jsonMap(value)))
      .toList(growable: false);
}
