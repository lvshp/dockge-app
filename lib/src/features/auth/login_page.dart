import 'package:dockge_app/src/core/domain/domain.dart' as domain;
import 'package:dockge_app/src/core/session/session.dart';
import 'package:dockge_app/src/core/storage/storage.dart';
import 'package:dockge_app/src/features/common/feature_localizations.dart';
import 'package:dockge_app/src/features/common/feature_widgets.dart';
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
                // Logo 区域
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primaryContainer,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.dns_rounded,
                      size: 40,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _setupMode ? l10n.setupTitle : l10n.loginTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _t(l10n, 'Manage your Docker stacks', '管理你的 Docker 堆栈'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                // 表单卡片
                DockgeCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_setupMode) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: l10n.serverName,
                              prefixIcon: const Icon(Icons.label_rounded),
                            ),
                            validator: (value) => _required(context, value),
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            labelText: l10n.serverUrl,
                            prefixIcon: const Icon(Icons.link_rounded),
                          ),
                          keyboardType: TextInputType.url,
                          validator: (value) => _required(context, value),
                        ),
                        const SizedBox(height: 14),
                        // 认证方式选择器
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: colorScheme.surfaceContainerLowest,
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _AuthTypeButton(
                                  icon: Icons.lock_outline,
                                  label: l10n.passwordAuth,
                                  selected: _authType == domain.AuthType.password,
                                  onTap: () => setState(
                                    () => _authType = domain.AuthType.password,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _AuthTypeButton(
                                  icon: Icons.key_rounded,
                                  label: l10n.tokenAuth,
                                  selected: _authType == domain.AuthType.token,
                                  onTap: () => setState(
                                    () => _authType = domain.AuthType.token,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_authType == domain.AuthType.password) ...[
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: l10n.username,
                              prefixIcon: const Icon(Icons.person_rounded),
                            ),
                            validator: (value) => _required(context, value),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: l10n.password,
                              prefixIcon: const Icon(Icons.lock_rounded),
                            ),
                            obscureText: true,
                            validator: (value) => _required(context, value),
                          ),
                        ] else
                          TextFormField(
                            controller: _tokenController,
                            decoration: InputDecoration(
                              labelText: l10n.accessToken,
                              prefixIcon: const Icon(Icons.vpn_key_rounded),
                            ),
                            obscureText: true,
                            validator: (value) => _required(context, value),
                          ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.security_rounded),
                          title: Text(l10n.allowSelfSigned),
                          value: _tlsMode == domain.TlsMode.allowSelfSigned,
                          onChanged: (value) => setState(() {
                            _tlsMode = value
                                ? domain.TlsMode.allowSelfSigned
                                : domain.TlsMode.system;
                          }),
                        ),
                        const SizedBox(height: 18),
                        if (session.error != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: colorScheme.onErrorContainer,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    session.error!,
                                    style: TextStyle(
                                      color: colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: session.connecting || session.restoring
                                ? null
                                : () => _connect(context),
                            icon: session.connecting || session.restoring
                                ? SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.login_rounded),
                            label: Text(
                              _setupMode ? l10n.saveServer : l10n.connect,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _setupMode = !_setupMode),
                  child: Text(_setupMode ? l10n.connect : l10n.setupTitle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _t(FeatureLocalizations l10n, String en, String zh) {
    return l10n.active == 'Active' ? en : zh;
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

class _AuthTypeButton extends StatelessWidget {
  const _AuthTypeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}