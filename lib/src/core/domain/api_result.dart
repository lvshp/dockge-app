import 'json_helpers.dart';

class ApiResult<T> {
  const ApiResult({
    required this.ok,
    this.data,
    this.message,
    this.code,
    this.raw,
  });

  final bool ok;
  final T? data;
  final String? message;
  final String? code;
  final Object? raw;

  bool get isSuccess => ok;
  bool get isFailure => !ok;

  factory ApiResult.success(T data, {Object? raw, String? message}) {
    return ApiResult<T>(ok: true, data: data, raw: raw, message: message);
  }

  factory ApiResult.empty({Object? raw, String? message}) {
    return ApiResult<T>(ok: true, raw: raw, message: message);
  }

  factory ApiResult.failure(String message, {String? code, Object? raw}) {
    return ApiResult<T>(ok: false, message: message, code: code, raw: raw);
  }

  factory ApiResult.fromAck(Object? ack, {T Function(Object? value)? decode}) {
    final map = jsonMap(ack);
    final success = map.isEmpty
        ? ack != false
        : boolValue(
            map['ok'] ?? map['success'],
            fallback: !map.containsKey('error'),
          );
    if (!success) {
      return ApiResult<T>.failure(
        stringValue(
          map['msg'] ?? map['message'] ?? map['error'],
          fallback: 'Request failed',
        ),
        code: nullableString(map['code']),
        raw: ack,
      );
    }

    final payload = map.containsKey('data')
        ? map['data']
        : map.containsKey('result')
        ? map['result']
        : ack;
    final data = decode == null ? payload as T? : decode(payload);
    if (data == null) {
      return ApiResult<T>.empty(
        raw: ack,
        message: nullableString(map['msg'] ?? map['message']),
      );
    }
    return ApiResult<T>.success(
      data,
      raw: ack,
      message: nullableString(map['msg'] ?? map['message']),
    );
  }
}
