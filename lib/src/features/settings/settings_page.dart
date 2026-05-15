import 'package:dockge_app/src/app/locale_controller.dart';
import 'package:dockge_app/src/app/theme_controller.dart';
import 'package:dockge_app/src/core/session/session.dart';
import 'package:dockge_app/src/features/common/feature_localizations.dart';
import 'package:dockge_app/src/features/common/feature_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = FeatureLocalizations.of(context);
    final localeOverride = ref.watch(localeOverrideProvider);
    final themeMode = ref.watch(themeModeProvider);
    final session = ref.watch(dockgeSessionProvider);
    final scheme = Theme.of(context).colorScheme;
    final language = localeOverride?.languageCode ?? 'system';
    final themeValue = themeMode == ThemeMode.light
        ? 'light'
        : themeMode == ThemeMode.dark
            ? 'dark'
            : 'system';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 服务器配置
          SectionHeader(title: l10n.profile),
          const SizedBox(height: 8),
          DockgeCard(
            onTap: () => context.push('/login'),
            child: Row(
              children: [
                // 连接状态圆点
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: session.connected ? scheme.primary : scheme.outline,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.server,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.connected
                            ? session.profile?.baseUrl ?? ''
                            : l10n.notConnected,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 外观
          SectionHeader(title: l10n.appearance),
          const SizedBox(height: 8),
          DockgeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 语言选择
                DropdownButtonFormField<String>(
                  initialValue: language,
                  decoration: InputDecoration(
                    labelText: l10n.language,
                    prefixIcon: const Icon(Icons.language_rounded),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'system',
                      child: Text(l10n.systemLanguage),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Text(l10n.english),
                    ),
                    DropdownMenuItem(
                      value: 'zh',
                      child: Text(l10n.simplifiedChinese),
                    ),
                  ],
                  onChanged: (value) {
                    final controller = ref.read(
                      localeOverrideProvider.notifier,
                    );
                    if (value == 'system' || value == null) {
                      controller.followSystem();
                    } else {
                      controller.setLocale(Locale(value));
                    }
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.languageHookPlaceholder,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                // 主题选择
                DropdownButtonFormField<String>(
                  initialValue: themeValue,
                  decoration: InputDecoration(
                    labelText: l10n.theme,
                    prefixIcon: const Icon(Icons.dark_mode_rounded),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'system',
                      child: Text(l10n.themeSystem),
                    ),
                    DropdownMenuItem(
                      value: 'light',
                      child: Text(l10n.themeLight),
                    ),
                    DropdownMenuItem(
                      value: 'dark',
                      child: Text(l10n.themeDark),
                    ),
                  ],
                  onChanged: (value) {
                    final controller = ref.read(themeModeProvider.notifier);
                    switch (value) {
                      case 'light':
                        controller.setLight();
                      case 'dark':
                        controller.setDark();
                      default:
                        controller.setSystem();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 断开连接
          if (session.connected) ...[
            SectionHeader(title: l10n.disconnect),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.disconnect),
                      content: Text(
                        _t(
                          l10n,
                          'Are you sure you want to disconnect from ${session.profile?.name ?? "Dockge"}?',
                          '确定要断开与 ${session.profile?.name ?? "Dockge"} 的连接吗？',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(l10n.cancel),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.error,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(l10n.disconnect),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true || !context.mounted) return;
                  ref.read(dockgeSessionProvider.notifier).disconnect();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.disconnected)),
                    );
                    context.go('/login');
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.errorContainer,
                  foregroundColor: scheme.onErrorContainer,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.disconnect),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _t(FeatureLocalizations l10n, String en, String zh) {
    return l10n.active == 'Active' ? en : zh;
  }
}