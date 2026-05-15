import 'dart:async';

import 'package:dockge_app/src/core/domain/domain.dart' as domain;
import 'package:dockge_app/src/core/network/network.dart';
import 'package:dockge_app/src/core/storage/storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

final dockgeSessionProvider =
    NotifierProvider<DockgeSessionController, DockgeSessionState>(
      DockgeSessionController.new,
    );

final terminalEventsProvider = StreamProvider<domain.TerminalEvent>((ref) {
  ref.watch(dockgeSessionProvider.select((state) => state.connected));
  return ref.read(dockgeSessionProvider.notifier).terminalEvents;
});

class DockgeSessionState {
  const DockgeSessionState({
    this.connected = false,
    this.connecting = false,
    this.restoring = false,
    this.error,
    this.profile,
    this.stacks = const <domain.StackSummary>[],
  });

  final bool connected;
  final bool connecting;
  final bool restoring;
  final String? error;
  final domain.ServerProfile? profile;
  final List<domain.StackSummary> stacks;

  DockgeSessionState copyWith({
    bool? connected,
    bool? connecting,
    bool? restoring,
    String? error,
    domain.ServerProfile? profile,
    List<domain.StackSummary>? stacks,
    bool clearError = false,
  }) {
    return DockgeSessionState(
      connected: connected ?? this.connected,
      connecting: connecting ?? this.connecting,
      restoring: restoring ?? this.restoring,
      error: clearError ? null : error ?? this.error,
      profile: profile ?? this.profile,
      stacks: stacks ?? this.stacks,
    );
  }
}

class DockgeSessionController extends Notifier<DockgeSessionState> {
  DockgeSocketClient? _client;
  StreamSubscription<List<domain.StackSummary>>? _stackSubscription;
  bool _restored = false;

  @override
  DockgeSessionState build() {
    ref.onDispose(() {
      _stackSubscription?.cancel();
      _client?.disconnect();
    });
    if (!_restored) {
      _restored = true;
      Future<void>.microtask(_restoreSavedSession);
    }
    return const DockgeSessionState();
  }

  Future<bool> connectWithPassword({
    required String name,
    required String baseUrl,
    required String username,
    required String password,
    domain.TlsMode tlsMode = domain.TlsMode.system,
  }) {
    final now = DateTime.now();
    final profile = _buildProfile(
      name: name,
      baseUrl: baseUrl,
      authType: domain.AuthType.password,
      tlsMode: tlsMode,
      username: username,
      timestamp: now,
    );
    return _connect(
      profile: profile,
      login: (client) => client.login(username: username, password: password),
    );
  }

  Future<bool> connectWithToken({
    required String name,
    required String baseUrl,
    required String token,
    domain.TlsMode tlsMode = domain.TlsMode.system,
  }) {
    final now = DateTime.now();
    final profile = _buildProfile(
      name: name,
      baseUrl: baseUrl,
      authType: domain.AuthType.token,
      tlsMode: tlsMode,
      timestamp: now,
    );
    return _connect(
      profile: profile,
      preferredToken: token,
      login: (client) => client.loginByToken(token),
    );
  }

  void disconnect() {
    _stackSubscription?.cancel();
    _stackSubscription = null;
    _client?.disconnect();
    _client = null;
    state = state.copyWith(
      connected: false,
      connecting: false,
      restoring: false,
      stacks: const <domain.StackSummary>[],
      clearError: true,
    );
  }

  Future<void> refreshStacks({String endpoint = ''}) async {
    final client = _client;
    if (client == null || !client.isConnected) {
      return;
    }
    await client.requestStackList(endpoint);
  }

  Future<void> stackAction(domain.StackSummary stack, String action) async {
    final client = _client;
    if (client == null) {
      return;
    }
    final endpoint = stack.endpoint ?? '';
    switch (action) {
      case 'start':
        await client.start(endpoint, stack.name);
      case 'stop':
        await client.stop(endpoint, stack.name);
      case 'restart':
        await client.restart(endpoint, stack.name);
      case 'update':
        await client.update(endpoint, stack.name);
      case 'down':
        await client.down(endpoint, stack.name);
      case 'delete':
        await client.delete(endpoint, stack.name);
    }
    await refreshStacks(endpoint: endpoint);
  }

  Stream<domain.TerminalEvent> get terminalEvents {
    return _client?.terminalEvents ??
        const Stream<domain.TerminalEvent>.empty();
  }

  Future<domain.ApiResult<domain.StackDetail>> getStack(
    String stackName, {
    String? endpoint,
  }) async {
    final client = _client;
    if (client == null || !client.isConnected) {
      return domain.ApiResult.failure('Not connected to Dockge');
    }
    final matchedStacks = state.stacks.where(
      (stack) => stack.name == stackName,
    );
    final resolvedEndpoint =
        endpoint ??
        (matchedStacks.isEmpty ? null : matchedStacks.first.endpoint) ??
        '';
    final stackResult = await client.getStack(
      resolvedEndpoint,
      stackName: stackName,
    );
    if (!stackResult.ok || stackResult.data == null) {
      return stackResult;
    }

    final serviceResult = await client.serviceStatusList(
      resolvedEndpoint,
      stackName: stackName,
    );

    // 解析 compose YAML 提取 image 和 ports（先做 envsubst 替换变量）
    Map<String, Map<String, dynamic>> composeServices;
    try {
      final substituted = _envsubst(
        stackResult.data!.composeYaml,
        stackResult.data!.composeEnv,
      );
      composeServices = _parseComposeServices(substituted);
    } catch (_) {
      composeServices = {};
    }

    // 获取 docker stats（CPU、内存等），不阻塞主流程
    Map<String, domain.DockerStats> statsMap;
    try {
      final statsResult = await client.dockerStats(resolvedEndpoint).timeout(
        const Duration(seconds: 5),
      );
      statsMap = <String, domain.DockerStats>{};
      if (statsResult.ok && statsResult.data != null) {
        for (final stat in statsResult.data!) {
          final key = stat.containerName ?? stat.serviceName;
          statsMap[key] = stat;
        }
      }
    } catch (_) {
      statsMap = {};
    }

    // 合并 image/ports/dockerStats 到每个 ServiceStatus
    List<domain.ServiceStatus> mergedServices;
    try {
      mergedServices =
          (serviceResult.data ?? stackResult.data!.services).map((service) {
            final compose = composeServices[service.name];
            final containerStats = _findStatsForService(service, statsMap);
            final composeImage = compose != null
                ? (compose['image'] is String ? compose['image'] as String : null)
                : null;
            final composePorts = compose != null && compose['ports'] is List
                ? (compose['ports'] as List).map((p) => p.toString()).toList()
                : <String>[];
            return domain.ServiceStatus(
              name: service.name,
              status: service.status,
              image: service.image ?? composeImage,
              ports: service.ports.isNotEmpty ? service.ports : composePorts,
              cpuPercent: containerStats?.cpuPercentRaw,
              memoryUsage: containerStats?.memoryUsageRaw,
              memoryPercent: containerStats?.memoryPercentRaw,
              raw: service.raw,
            );
          }).toList();
    } catch (_) {
      mergedServices = serviceResult.data ?? stackResult.data!.services;
    }

    final liveSummary = matchedStacks.isEmpty ? null : matchedStacks.first;
    final detail = stackResult.data!;
    final mergedSummary = domain.StackSummary(
      name: detail.summary.name,
      agentId: liveSummary?.agentId ?? detail.summary.agentId,
      status: liveSummary?.status ?? detail.summary.status,
      serviceCount:
          mergedServices.isNotEmpty
              ? mergedServices.length
              : liveSummary?.serviceCount ?? detail.summary.serviceCount,
      composePath: detail.summary.composePath ?? liveSummary?.composePath,
      endpoint: resolvedEndpoint.isEmpty
          ? (liveSummary?.endpoint ?? detail.summary.endpoint)
          : resolvedEndpoint,
      isManagedByDockge: detail.summary.isManagedByDockge,
      updatedAt: liveSummary?.updatedAt ?? detail.summary.updatedAt,
      raw: {...detail.summary.raw, if (liveSummary != null) ...liveSummary.raw},
    );

    return domain.ApiResult.success(
      domain.StackDetail(
        summary: mergedSummary,
        composeYaml: detail.composeYaml,
        composeEnv: detail.composeEnv,
        services: mergedServices,
        envFiles: detail.envFiles,
        raw: detail.raw,
      ),
      raw: stackResult.raw,
      message: stackResult.message,
    );
  }

  Future<domain.ApiResult<void>> saveStack(
    domain.StackSummary stack, {
    required String composeYaml,
    required String composeEnv,
  }) async {
    final client = _client;
    if (client == null || !client.isConnected) {
      return domain.ApiResult.failure('Not connected to Dockge');
    }
    return client.saveStack(
      stack.endpoint ?? '',
      stackName: stack.name,
      composeYaml: composeYaml,
      composeEnv: composeEnv,
    );
  }

  Future<domain.ApiResult<void>> deployStack(
    domain.StackSummary stack, {
    required String composeYaml,
    required String composeEnv,
  }) async {
    final client = _client;
    if (client == null || !client.isConnected) {
      return domain.ApiResult.failure('Not connected to Dockge');
    }
    return client.deployStack(
      stack.endpoint ?? '',
      stackName: stack.name,
      composeYaml: composeYaml,
      composeEnv: composeEnv,
    );
  }

  Future<domain.ApiResult<void>> serviceAction(
    domain.StackSummary stack,
    String serviceName,
    String action,
  ) async {
    final client = _client;
    if (client == null || !client.isConnected) {
      return domain.ApiResult.failure('Not connected to Dockge');
    }
    final endpoint = stack.endpoint ?? '';
    return switch (action) {
      'start' => client.startService(
        endpoint,
        stackName: stack.name,
        serviceName: serviceName,
      ),
      'stop' => client.stopService(
        endpoint,
        stackName: stack.name,
        serviceName: serviceName,
      ),
      'restart' => client.restartService(
        endpoint,
        stackName: stack.name,
        serviceName: serviceName,
      ),
      _ => domain.ApiResult.failure('Unsupported service action'),
    };
  }

  Future<domain.ApiResult<void>> joinServiceTerminal(
    String stackName,
    String serviceName,
  ) async {
    final client = _client;
    if (client == null || !client.isConnected) {
      return domain.ApiResult.failure('Not connected to Dockge');
    }
    final matchedStacks = state.stacks.where(
      (stack) => stack.name == stackName,
    );
    final endpoint = matchedStacks.isEmpty ? '' : matchedStacks.first.endpoint ?? '';
    // 先请求创建交互终端
    final result = await client.interactiveTerminal(
      endpoint,
      stackName: stackName,
      serviceName: serviceName,
      shell: 'sh',
    );
    if (!result.ok) return result;
    // 加入终端获取历史 buffer
    final terminalName = _containerExecTerminalName(endpoint, stackName, serviceName);
    return client.terminalJoin(endpoint, terminalName: terminalName);
  }

  Future<domain.ApiResult<void>> serviceTerminalInput(
    String stackName,
    String serviceName,
    String input,
  ) async {
    final client = _client;
    if (client == null || !client.isConnected) {
      return domain.ApiResult.failure('Not connected to Dockge');
    }
    final matchedStacks = state.stacks.where(
      (stack) => stack.name == stackName,
    );
    final endpoint = matchedStacks.isEmpty ? '' : matchedStacks.first.endpoint ?? '';
    final terminalName = _containerExecTerminalName(endpoint, stackName, serviceName);
    return client.terminalInputDirect(
      endpoint: endpoint,
      terminalName: terminalName,
      input: input,
    );
  }

  Future<domain.ApiResult<void>> joinMainTerminal() async {
    final client = _client;
    if (client == null || !client.isConnected) {
      return domain.ApiResult.failure('Not connected to Dockge');
    }
    // 主终端通过 agent 通道
    final result = await client.mainTerminal();
    if (!result.ok) return result;
    // 加入终端获取历史 buffer
    return client.terminalJoin('', terminalName: 'console');
  }

  Future<domain.ApiResult<void>> mainTerminalInput(String input) async {
    final client = _client;
    if (client == null || !client.isConnected) {
      return domain.ApiResult.failure('Not connected to Dockge');
    }
    return client.terminalInputDirect(
      endpoint: '',
      terminalName: 'console',
      input: input,
    );
  }

  Future<domain.ApiResult<void>> joinCombinedTerminal(
    domain.StackSummary stack,
  ) async {
    final client = _client;
    if (client == null || !client.isConnected) {
      return domain.ApiResult.failure('Not connected to Dockge');
    }
    final terminalName = _combinedTerminalName(stack);
    return client.terminalJoin(
      stack.endpoint ?? '',
      terminalName: terminalName,
    );
  }

  Future<domain.ApiResult<void>> terminalInput(
    domain.StackSummary stack,
    String input,
  ) async {
    final client = _client;
    if (client == null || !client.isConnected) {
      return domain.ApiResult.failure('Not connected to Dockge');
    }
    final terminalName = _combinedTerminalName(stack);
    return client.terminalInput(
      stack.endpoint ?? '',
      terminalName: terminalName,
      input: input,
    );
  }

  Future<bool> _connect({
    required domain.ServerProfile profile,
    String? preferredToken,
    required Future<domain.ApiResult<Map<String, dynamic>>> Function(
      DockgeSocketClient client,
    )
    login,
  }) async {
    state = state.copyWith(
      connecting: true,
      connected: false,
      clearError: true,
      profile: profile,
    );
    final client = DockgeSocketClient();

    try {
      await client.connect(profile);
      final result = await login(client);
      if (!result.ok) {
        client.disconnect();
        state = state.copyWith(
          connecting: false,
          connected: false,
          error: result.message ?? 'Login failed',
        );
        return false;
      }
      final persistedToken = _resolvePersistedToken(
        explicitToken: preferredToken,
        loginData: result.data,
      );
      final persistedProfile = profile.copyWith(
        lastConnectedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _stackSubscription?.cancel();
      _client = client;
      _stackSubscription = client.stackLists.listen((stacks) {
        state = state.copyWith(stacks: stacks);
      });
      await _saveProfile(persistedProfile, token: persistedToken);
      state = state.copyWith(
        connecting: false,
        connected: true,
        profile: persistedProfile,
        clearError: true,
      );
      await refreshStacks();
      return true;
    } catch (error) {
      client.disconnect();
      state = state.copyWith(
        connecting: false,
        connected: false,
        error: error.toString(),
      );
      return false;
    }
  }

  Future<void> _restoreSavedSession() async {
    state = state.copyWith(restoring: true, clearError: true);
    try {
      final profile = await _readActiveProfile();
      if (profile == null) {
        state = state.copyWith(restoring: false);
        return;
      }

      final token = await _readToken(profile.id);
      state = state.copyWith(profile: profile);
      if (token == null || token.isEmpty) {
        state = state.copyWith(restoring: false);
        return;
      }

      final restored = await _connect(
        profile: profile,
        preferredToken: token,
        login: (client) => client.loginByToken(token),
      );
      if (!restored) {
        state = state.copyWith(restoring: false, profile: profile);
      }
    } catch (_) {
      state = state.copyWith(restoring: false);
    } finally {
      if (state.restoring) {
        state = state.copyWith(restoring: false);
      }
    }
  }

  domain.ServerProfile _buildProfile({
    required String name,
    required String baseUrl,
    required domain.AuthType authType,
    required domain.TlsMode tlsMode,
    String? username,
    required DateTime timestamp,
  }) {
    final trimmedName = name.trim();
    final trimmedUrl = baseUrl.trim();
    final existingProfile = state.profile;
    return domain.ServerProfile(
      id: existingProfile?.baseUrl == trimmedUrl
          ? existingProfile!.id
          : const Uuid().v4(),
      name: trimmedName.isEmpty ? trimmedUrl : trimmedName,
      baseUrl: trimmedUrl,
      authType: authType,
      tlsMode: tlsMode,
      username: username?.trim().isEmpty ?? true ? null : username!.trim(),
      createdAt: existingProfile?.baseUrl == trimmedUrl
          ? existingProfile?.createdAt
          : timestamp,
      updatedAt: timestamp,
    );
  }

  String? _resolvePersistedToken({
    String? explicitToken,
    Map<String, dynamic>? loginData,
  }) {
    if (explicitToken != null && explicitToken.isNotEmpty) {
      return explicitToken;
    }
    if (loginData == null) {
      return null;
    }
    return domain.nullableString(loginData['token'] ?? loginData['accessToken']);
  }

  DockgeProfileStorage _storage() {
    return DockgeProfileStorage(DockgeSecureStorage());
  }

  Future<void> _saveProfile(domain.ServerProfile profile, {String? token}) async {
    try {
      await _storage().save(profile, token: token);
    } catch (_) {
      // Ignore storage failures in unsupported environments such as widget tests.
    }
  }

  Future<domain.ServerProfile?> _readActiveProfile() async {
    try {
      return await _storage().readActiveProfile();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _readToken(String profileId) async {
    try {
      return await _storage().readToken(profileId);
    } catch (_) {
      return null;
    }
  }

  String _combinedTerminalName(domain.StackSummary stack) {
    final endpoint = stack.endpoint ?? '';
    return endpoint.isEmpty
        ? 'combined-${stack.name}'
        : 'combined-$endpoint-${stack.name}';
  }

  /// 容器交互终端名称，格式: container-exec-{endpoint}-{stackName}-{serviceName}-0
  /// 与 Dockge 服务器端 getContainerExecTerminalName() 一致
  String _containerExecTerminalName(
    String endpoint,
    String stackName,
    String serviceName, [
    int index = 0,
  ]) {
    return 'container-exec-$endpoint-$stackName-$serviceName-$index';
  }

  /// 从 compose YAML 解析 services 下的 image 和 ports
  Map<String, Map<String, dynamic>> _parseComposeServices(String yamlText) {
    try {
      if (yamlText.isEmpty) return {};
      final doc = loadYaml(yamlText);
      if (doc is! Map) return {};
      final services = doc['services'];
      if (services is! Map) return {};
      final result = <String, Map<String, dynamic>>{};
      for (final entry in services.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is! Map) {
          result[key] = {};
          continue;
        }
        result[key] = {
          'image': value['image']?.toString(),
          'ports': value['ports'] is List
              ? value['ports'].map((p) => p.toString()).toList().cast<String>()
              : <String>[],
        };
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// 解析 .env 文件内容为 key-value 映射
  Map<String, String> _parseEnvFile(String envText) {
    final vars = <String, String>{};
    for (final line in envText.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eq = trimmed.indexOf('=');
      if (eq < 1) continue;
      final key = trimmed.substring(0, eq).trim();
      var val = trimmed.substring(eq + 1).trim();
      // 去掉引号
      if ((val.startsWith('"') && val.endsWith('"')) ||
          (val.startsWith("'") && val.endsWith("'"))) {
        val = val.substring(1, val.length - 1);
      }
      vars[key] = val;
    }
    return vars;
  }

  /// 简易 envsubst：用 .env 变量替换 compose YAML 中的 ${VAR} 和 ${VAR:-default}
  String _envsubst(String yamlText, String envText) {
    if (yamlText.isEmpty) return yamlText;
    final vars = _parseEnvFile(envText);
    // 匹配 ${VAR:-default} 和 ${VAR}
    final pattern = RegExp(r'\$\{([^}]+)\}');
    return yamlText.replaceAllMapped(pattern, (match) {
      final expr = match.group(1)!;
      // ${VAR:-default} 格式
      final defaultIndex = expr.indexOf(':-');
      if (defaultIndex > 0) {
        final varName = expr.substring(0, defaultIndex).trim();
        final defaultVal = expr.substring(defaultIndex + 2);
        return vars[varName] ?? defaultVal;
      }
      // ${VAR} 格式
      return vars[expr.trim()] ?? match.group(0)!;
    });
  }

  /// 在 dockerStats map 中查找与 service 关联的容器统计
  domain.DockerStats? _findStatsForService(
    domain.ServiceStatus service,
    Map<String, domain.DockerStats> statsMap,
  ) {
    // raw 中存有容器名（来自 serviceStatusList 的 name 字段）
    final containerName = service.raw['name']?.toString();
    if (containerName != null && statsMap.containsKey(containerName)) {
      return statsMap[containerName];
    }
    // 回退：用服务名模糊匹配容器名
    for (final entry in statsMap.entries) {
      if (entry.key.contains(service.name)) {
        return entry.value;
      }
    }
    return null;
  }
}
