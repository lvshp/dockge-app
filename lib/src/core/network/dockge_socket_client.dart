import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../domain/domain.dart';

typedef JsonDecoder<T> = T Function(Object? payload);

class DockgeSocketClient {
  DockgeSocketClient({
    io.Socket? socket,
    Duration ackTimeout = const Duration(seconds: 20),
    Duration connectTimeout = const Duration(seconds: 15),
  }) : _socket = socket,
       _ackTimeout = ackTimeout,
       _connectTimeout = connectTimeout;

  io.Socket? _socket;
  final Duration _ackTimeout;
  final Duration _connectTimeout;

  bool get isConnected => _socket?.connected ?? false;

  Stream<TerminalEvent> get terminalEvents => _terminalController.stream;
  final _terminalController = StreamController<TerminalEvent>.broadcast();
  Stream<List<StackSummary>> get stackLists => _stackListController.stream;
  final _stackListController = StreamController<List<StackSummary>>.broadcast();

  Future<void> connect(
    ServerProfile profile, {
    String? token,
    Map<String, String>? headers,
    String socketPath = '/socket.io/',
  }) async {
    disconnect();

    final builder = io.OptionBuilder()
        .setTransports(const ['websocket'])
        .setPath(socketPath)
        .setAckTimeout(_ackTimeout.inMilliseconds)
        .enableForceNew()
        .disableAutoConnect();

    if (headers != null && headers.isNotEmpty) {
      builder.setExtraHeaders(headers);
    }
    if (token != null && token.isNotEmpty) {
      builder.setAuth({'token': token});
    }

    final socket = io.io(profile.baseUrl, builder.build());
    _socket = socket;
    _wireTerminalEvents(socket);

    final completer = Completer<void>();
    Timer? timer;
    socket.onConnect((_) {
      timer?.cancel();
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    socket.onConnectError((error) {
      timer?.cancel();
      if (!completer.isCompleted) {
        completer.completeError(error ?? 'Socket connection failed');
      }
    });
    timer = Timer(_connectTimeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Socket connection timed out', _connectTimeout),
        );
      }
    });

    socket.connect();
    return completer.future;
  }

  void disconnect() {
    final socket = _socket;
    if (socket != null) {
      socket.dispose();
    }
    _socket = null;
  }

  Future<ApiResult<Map<String, dynamic>>> setup({
    required String username,
    required String password,
  }) {
    return _emitAck('setup', [
      username,
      password,
    ], decode: (value) => jsonMap(value));
  }

  Future<ApiResult<Map<String, dynamic>>> login({
    required String username,
    required String password,
    String? token,
  }) {
    return _emitAck(
      'login',
      omitNulls({'username': username, 'password': password, 'token': token}),
      decode: (value) => jsonMap(value),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> loginByToken(String token) {
    return _emitAck('loginByToken', token, decode: (value) => jsonMap(value));
  }

  Future<ApiResult<DockgeSettings>> getSettings() {
    return _emitAck(
      'getSettings',
      null,
      decode: (value) {
        final map = jsonMap(value);
        return DockgeSettings.fromJson(
          jsonMap(map['data']).isEmpty ? map : jsonMap(map['data']),
        );
      },
    );
  }

  Future<ApiResult<Map<String, dynamic>>> setSettings(
    DockgeSettings settings, {
    String currentPassword = '',
  }) {
    return _emitAck('setSettings', [
      settings.toJson(),
      currentPassword,
    ], decode: (value) => jsonMap(value));
  }

  Future<ApiResult<String>> composerize(String dockerRunCommand) {
    return _emitAck(
      'composerize',
      dockerRunCommand,
      decode: (value) {
        final map = jsonMap(value);
        return stringValue(map['composeTemplate'] ?? value);
      },
    );
  }

  Future<ApiResult<DockgeAgent>> addAgent(DockgeAgent agent) {
    return _emitAck(
      'addAgent',
      agent.toJson(),
      decode: (value) => DockgeAgent.fromJson(jsonMap(value)),
    );
  }

  Future<ApiResult<void>> removeAgent(String url) {
    return _emitVoid('removeAgent', url);
  }

  Future<ApiResult<Map<String, dynamic>>> updateAgent(
    String url,
    String updatedName,
  ) {
    return _emitAck('updateAgent', [
      url,
      updatedName,
    ], decode: (value) => jsonMap(value));
  }

  Future<ApiResult<T>> emitAgent<T>(
    String endpoint,
    String event, {
    Object? payload,
    JsonDecoder<T>? decode,
  }) {
    final args = payload == null
        ? <Object?>[endpoint, event]
        : payload is List
        ? <Object?>[endpoint, event, ...payload]
        : <Object?>[endpoint, event, payload];
    return _emitAck('agent', args, decode: decode);
  }

  Future<ApiResult<List<StackSummary>>> requestStackList(String endpoint) {
    return emitAgent(
      endpoint,
      'requestStackList',
      decode: parseStackSummaryList,
    );
  }

  Future<ApiResult<StackDetail>> getStack(
    String endpoint, {
    required String stackName,
  }) {
    return emitAgent(
      endpoint,
      'getStack',
      payload: [stackName],
      decode: (value) => StackDetail.fromJson(jsonMap(value)),
    );
  }

  Future<ApiResult<void>> deployStack(
    String endpoint, {
    required String stackName,
    required String composeYaml,
    String composeEnv = '',
    bool isAdd = false,
  }) {
    return _emitAgentVoid(endpoint, 'deployStack', [
      stackName,
      composeYaml,
      composeEnv,
      isAdd,
    ]);
  }

  Future<ApiResult<void>> saveStack(
    String endpoint, {
    required String stackName,
    required String composeYaml,
    String composeEnv = '',
    bool isAdd = false,
  }) {
    return _emitAgentVoid(endpoint, 'saveStack', [
      stackName,
      composeYaml,
      composeEnv,
      isAdd,
    ]);
  }

  Future<ApiResult<void>> start(String endpoint, String stackName) {
    return _stackAction(endpoint, 'startStack', stackName);
  }

  Future<ApiResult<void>> stop(String endpoint, String stackName) {
    return _stackAction(endpoint, 'stopStack', stackName);
  }

  Future<ApiResult<void>> restart(String endpoint, String stackName) {
    return _stackAction(endpoint, 'restartStack', stackName);
  }

  Future<ApiResult<void>> update(String endpoint, String stackName) {
    return _stackAction(endpoint, 'updateStack', stackName);
  }

  Future<ApiResult<void>> down(String endpoint, String stackName) {
    return _stackAction(endpoint, 'downStack', stackName);
  }

  Future<ApiResult<void>> delete(String endpoint, String stackName) {
    return _stackAction(endpoint, 'deleteStack', stackName);
  }

  Future<ApiResult<List<ServiceStatus>>> serviceStatusList(
    String endpoint, {
    required String stackName,
  }) {
    return emitAgent(
      endpoint,
      'serviceStatusList',
      payload: [stackName],
      decode: (value) {
        final map = jsonMap(value);
        return parseServiceStatusList(map['serviceStatusList'] ?? value);
      },
    );
  }

  Future<ApiResult<List<DockerStats>>> dockerStats(String endpoint) {
    return emitAgent(
      endpoint,
      'dockerStats',
      decode: (value) {
        final map = jsonMap(value);
        return parseDockerStatsList(map['dockerStats'] ?? value);
      },
    );
  }

  Future<ApiResult<void>> startService(
    String endpoint, {
    required String stackName,
    required String serviceName,
  }) {
    return _serviceAction(endpoint, 'startService', stackName, serviceName);
  }

  Future<ApiResult<void>> stopService(
    String endpoint, {
    required String stackName,
    required String serviceName,
  }) {
    return _serviceAction(endpoint, 'stopService', stackName, serviceName);
  }

  Future<ApiResult<void>> restartService(
    String endpoint, {
    required String stackName,
    required String serviceName,
  }) {
    return _serviceAction(endpoint, 'restartService', stackName, serviceName);
  }

  Future<ApiResult<List<String>>> getDockerNetworkList(String endpoint) {
    return emitAgent(
      endpoint,
      'getDockerNetworkList',
      decode: (value) {
        final map = jsonMap(value);
        return jsonList(
          map['dockerNetworkList'] ?? value,
        ).map((network) => network.toString()).toList();
      },
    );
  }

  Future<ApiResult<void>> terminalJoin(
    String endpoint, {
    required String terminalName,
  }) {
    return _emitAgentVoid(endpoint, 'terminalJoin', [terminalName]);
  }

  Future<ApiResult<void>> leaveCombinedTerminal(
    String endpoint, {
    required String stackName,
  }) {
    return _emitAgentVoid(endpoint, 'leaveCombinedTerminal', [stackName]);
  }

  Future<ApiResult<void>> mainTerminal(
    String endpoint, {
    String terminalName = 'console',
  }) {
    return _emitAgentVoid(endpoint, 'mainTerminal', [terminalName]);
  }

  Future<ApiResult<bool>> checkMainTerminal(String endpoint) {
    return emitAgent(
      endpoint,
      'checkMainTerminal',
      decode: (value) => boolValue(jsonMap(value)['ok'] ?? value),
    );
  }

  Future<ApiResult<void>> interactiveTerminal(
    String endpoint, {
    required String stackName,
    required String serviceName,
    String shell = 'sh',
  }) {
    return _emitAgentVoid(endpoint, 'interactiveTerminal', [
      stackName,
      serviceName,
      shell,
    ]);
  }

  Future<ApiResult<void>> terminalInput(
    String endpoint, {
    required String input,
    required String terminalName,
  }) {
    return _emitAgentVoid(endpoint, 'terminalInput', [terminalName, input]);
  }

  Future<ApiResult<void>> terminalResize(
    String endpoint, {
    required String terminalName,
    required int rows,
    required int cols,
  }) {
    return _emitAgentVoid(endpoint, 'terminalResize', [
      terminalName,
      rows,
      cols,
    ]);
  }

  Future<ApiResult<void>> _stackAction(
    String endpoint,
    String event,
    String stackName,
  ) {
    return _emitAgentVoid(endpoint, event, [stackName]);
  }

  Future<ApiResult<void>> _serviceAction(
    String endpoint,
    String event,
    String stackName,
    String serviceName,
  ) {
    return _emitAgentVoid(endpoint, event, [stackName, serviceName]);
  }

  Future<ApiResult<void>> _emitVoid(String event, Object? payload) {
    return _emitAck<void>(event, payload);
  }

  Future<ApiResult<void>> _emitAgentVoid(
    String endpoint,
    String event,
    Object? payload,
  ) {
    return emitAgent<void>(endpoint, event, payload: payload);
  }

  Future<ApiResult<T>> _emitAck<T>(
    String event,
    Object? payload, {
    JsonDecoder<T>? decode,
  }) async {
    final socket = _socket;
    if (socket == null) {
      return ApiResult<T>.failure('Socket has not been configured');
    }
    if (!socket.connected) {
      return ApiResult<T>.failure('Socket is not connected');
    }

    try {
      final ack = await socket
          .emitWithAckAsync(event, payload)
          .timeout(_ackTimeout);
      return ApiResult<T>.fromAck(ack, decode: decode);
    } on TimeoutException catch (error) {
      return ApiResult<T>.failure(error.message ?? 'Request timed out');
    } catch (error) {
      return ApiResult<T>.failure(error.toString());
    }
  }

  void _wireTerminalEvents(io.Socket socket) {
    const eventNames = ['terminalWrite', 'terminalExit'];
    for (final eventName in eventNames) {
      socket.on(eventName, (payload) {
        final map = jsonMap(payload);
        _terminalController.add(
          TerminalEvent.fromJson({'type': eventName, ...map}),
        );
      });
    }
    socket.on('agent', (payload) {
      if (payload is! List || payload.isEmpty) {
        return;
      }
      final eventName = payload.first.toString();
      if (eventName == 'stackList' && payload.length > 1) {
        final map = jsonMap(payload[1]);
        _stackListController.add(
          parseStackSummaryList(map['stackList'] ?? payload[1]),
        );
        return;
      }
      if (eventName != 'terminalWrite' && eventName != 'terminalExit') {
        return;
      }
      _terminalController.add(
        TerminalEvent.fromJson({
          'type': eventName,
          'terminalName': payload.length > 1 ? payload[1] : null,
          'data': payload.length > 2 ? payload[2] : null,
        }),
      );
    });
  }
}
