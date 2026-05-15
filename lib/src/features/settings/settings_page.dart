import 'package:dockge_app/src/app/locale_controller.dart';
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
    final session = ref.watch(dockgeSessionProvider);
    final language = localeOverride?.languageCode ?? 'system';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(title: l10n.profile),
          const SizedBox(height: 8),
          DockgeCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.dns_rounded),
                  title: Text(l10n.server),
                  subtitle: Text(
                    session.connected
                        ? session.profile?.baseUrl ?? ''
                        : l10n.notConnected,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/login'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(title: l10n.appearance),
          const SizedBox(height: 8),
          DockgeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: language,
                  decoration: InputDecoration(labelText: l10n.language),
                  items: [
                    DropdownMenuItem(
                      value: 'system',
                      child: Text(l10n.systemLanguage),
                    ),
                    DropdownMenuItem(value: 'en', child: Text(l10n.english)),
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
                const SizedBox(height: 8),
                Text(
                  l10n.languageHookPlaceholder,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (session.connected)
            DockgeCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded),
                title: Text(l10n.disconnect),
                subtitle: Text(session.profile?.name ?? 'Dockge'),
                onTap: () {
                  ref.read(dockgeSessionProvider.notifier).disconnect();
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.disconnected)));
                    context.go('/login');
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
