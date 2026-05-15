import 'dart:async';

import 'package:dockge_app/src/core/domain/domain.dart' as domain;
import 'package:dockge_app/src/core/network/network.dart';
import 'package:dockge_app/src/core/storage/storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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

    final liveSummary = matchedStacks.isEmpty ? null : matchedStacks.first;
    final detail = stackResult.data!;
    final mergedSummary = domain.StackSummary(
      name: detail.summary.name,
      agentId: liveSummary?.agentId ?? detail.summary.agentId,
      status: liveSummary?.status ?? detail.summary.status,
      serviceCount:
          serviceResult.data?.length ??
          liveSummary?.serviceCount ??
          detail.summary.serviceCount,
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
        services: serviceResult.data ?? detail.services,
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
}
