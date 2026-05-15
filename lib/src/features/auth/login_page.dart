import 'package:dockge_app/src/core/domain/domain.dart' as domain;
import 'package:dockge_app/src/core/session/session.dart';
import 'package:dockge_app/src/core/storage/storage.dart';
import 'package:dockge_app/src/features/common/feature_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tokenController = TextEditingController();
  domain.AuthType _authType = domain.AuthType.password;
  domain.TlsMode _tlsMode = domain.TlsMode.system;
  bool _setupMode = false;
  bool _hydratedSavedProfile = false;

  @override
  void initState() {
    super.initState();
    _loadSavedProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FeatureLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final session = ref.watch(dockgeSessionProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Icon(Icons.dns_rounded, size: 48, color: colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  _setupMode ? l10n.setupTitle : l10n.loginTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_setupMode) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: l10n.serverName,
                          ),
                          validator: (value) => _required(context, value),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _urlController,
                        decoration: InputDecoration(labelText: l10n.serverUrl),
                        keyboardType: TextInputType.url,
                        validator: (value) => _required(context, value),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<domain.AuthType>(
                        segments: [
                          ButtonSegment(
                            value: domain.AuthType.password,
                            label: Text(l10n.passwordAuth),
                            icon: const Icon(Icons.lock_outline),
                          ),
                          ButtonSegment(
                            value: domain.AuthType.token,
                            label: Text(l10n.tokenAuth),
                            icon: const Icon(Icons.key_rounded),
                          ),
                        ],
                        selected: {_authType},
                        onSelectionChanged: (value) =>
                            setState(() => _authType = value.first),
                      ),
                      const SizedBox(height: 12),
                      if (_authType == domain.AuthType.password) ...[
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(labelText: l10n.username),
                          validator: (value) => _required(context, value),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(labelText: l10n.password),
                          obscureText: true,
                          validator: (value) => _required(context, value),
                        ),
                      ] else
                        TextFormField(
                          controller: _tokenController,
                          decoration: InputDecoration(
                            labelText: l10n.accessToken,
                          ),
                          obscureText: true,
                          validator: (value) => _required(context, value),
                        ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.allowSelfSigned),
                        value: _tlsMode == domain.TlsMode.allowSelfSigned,
                        onChanged: (value) => setState(() {
                          _tlsMode = value
                              ? domain.TlsMode.allowSelfSigned
                              : domain.TlsMode.system;
                        }),
                      ),
                      const SizedBox(height: 16),
                      if (session.error != null) ...[
                        Text(
                          session.error!,
                          style: TextStyle(color: colorScheme.error),
                        ),
                        const SizedBox(height: 12),
                      ],
                      FilledButton.icon(
                        onPressed: session.connecting || session.restoring
                            ? null
                            : () => _connect(context),
                        icon: session.connecting || session.restoring
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login_rounded),
                        label: Text(
                          _setupMode ? l10n.saveServer : l10n.connect,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _setupMode = !_setupMode),
                        child: Text(
                          _setupMode ? l10n.connect : l10n.setupTitle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return FeatureLocalizations.of(context).requiredField;
    }
    return null;
  }

  Future<void> _connect(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final controller = ref.read(dockgeSessionProvider.notifier);
    final ok = _authType == domain.AuthType.token
        ? await controller.connectWithToken(
            name: _nameController.text.trim(),
            baseUrl: _urlController.text.trim(),
            token: _tokenController.text.trim(),
            tlsMode: _tlsMode,
          )
        : await controller.connectWithPassword(
            name: _nameController.text.trim(),
            baseUrl: _urlController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            tlsMode: _tlsMode,
          );
    if (!context.mounted) {
      return;
    }
    if (ok) {
      context.go('/');
    }
  }

  Future<void> _loadSavedProfile() async {
    try {
      final storage = DockgeProfileStorage(DockgeSecureStorage());
      final profile = await storage.readActiveProfile();
      if (!mounted || profile == null || _hydratedSavedProfile) {
        return;
      }
      final token = await storage.readToken(profile.id);
      setState(() {
        _hydratedSavedProfile = true;
        _nameController.text = profile.name;
        _urlController.text = profile.baseUrl;
        _usernameController.text = profile.username ?? '';
        _authType = profile.authType;
        _tlsMode = profile.tlsMode;
        _tokenController.text = token ?? '';
      });
    } catch (_) {
      // Ignore storage errors and fall back to manual entry.
    }
  }
}
