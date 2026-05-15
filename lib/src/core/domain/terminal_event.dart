import 'json_helpers.dart';

enum TerminalEventType { output, joined, left, ready, closed, error, unknown }

class TerminalEvent {
  const TerminalEvent({
    required this.type,
    this.stackName,
    this.serviceName,
    this.terminalName,
    this.data = '',
    this.rows,
    this.cols,
    this.timestamp,
    this.raw = const <String, dynamic>{},
  });

  final TerminalEventType type;
  final String? stackName;
  final String? serviceName;
  final String? terminalName;
  final String data;
  final int? rows;
  final int? cols;
  final DateTime? timestamp;
  final Map<String, dynamic> raw;

  factory TerminalEvent.fromJson(Map<String, dynamic> json) {
    return TerminalEvent(
      type: terminalEventTypeFromDockge(json['type'] ?? json['event']),
      stackName: nullableString(json['stackName']),
      serviceName: nullableString(json['serviceName']),
      terminalName: nullableString(json['terminalName'] ?? json['name']),
      data: stringValue(json['data'] ?? json['message']),
      rows: json['rows'] == null ? null : intValue(json['rows']),
      cols: json['cols'] == null ? null : intValue(json['cols']),
      timestamp: dateTimeValue(json['timestamp']) ?? DateTime.now(),
      raw: json,
    );
  }
}

TerminalEventType terminalEventTypeFromDockge(Object? value) {
  final normalized = stringValue(value).toLowerCase();
  if (normalized.contains('output') || normalized.contains('data')) {
    return TerminalEventType.output;
  }
  if (normalized.contains('join')) {
    return TerminalEventType.joined;
  }
  if (normalized.contains('leave')) {
    return TerminalEventType.left;
  }
  if (normalized.contains('ready')) {
    return TerminalEventType.ready;
  }
  if (normalized.contains('close') || normalized.contains('exit')) {
    return TerminalEventType.closed;
  }
  if (normalized.contains('error') || normalized.contains('fail')) {
    return TerminalEventType.error;
  }
  return TerminalEventType.unknown;
}
