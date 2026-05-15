import 'package:dockge_app/src/core/domain/domain.dart' as domain;
import 'package:dockge_app/src/core/session/session.dart';
import 'package:dockge_app/src/features/common/feature_localizations.dart';
import 'package:dockge_app/src/features/common/feature_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final _dockerRunController = TextEditingController(
    text: 'docker run -d --name redis -p 6379:6379 redis:7-alpine',
  );
  String _compose = '';

  @override
  void initState() {
    super.initState();
    _compose = _convertDockerRun(_dockerRunController.text);
  }

  @override
  void dispose() {
    _dockerRunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FeatureLocalizations.of(context);
    final session = ref.watch(dockgeSessionProvider);
    final active = session.stacks
        .where((stack) => stack.status == domain.StackStatus.running)
        .length;
    final exited = session.stacks
        .where((stack) => stack.status == domain.StackStatus.stopped)
        .length;
    final inactive = session.stacks
        .where(
          (stack) =>
              stack.status == domain.StackStatus.inactive ||
              stack.status == domain.StackStatus.unknown,
        )
        .length;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboard)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final cards = [
                _StatCard(
                  label: l10n.active,
                  value: active,
                  icon: Icons.play_circle_rounded,
                ),
                _StatCard(
                  label: l10n.exited,
                  value: exited,
                  icon: Icons.stop_circle_rounded,
                ),
                _StatCard(
                  label: l10n.inactive,
                  value: inactive,
                  icon: Icons.pause_circle_rounded,
                ),
              ];
              return GridView.count(
                crossAxisCount: compact ? 1 : 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: compact ? 3.6 : 2.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: cards,
              );
            },
          ),
          const SizedBox(height: 16),
          DockgeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: l10n.dockerRunConverter),
                const SizedBox(height: 12),
                TextField(
                  controller: _dockerRunController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: l10n.dockerRunInput),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => setState(
                      () => _compose = _convertDockerRun(
                        _dockerRunController.text,
                      ),
                    ),
                    icon: const Icon(Icons.transform_rounded),
                    label: Text(l10n.convert),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.composePreview,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _CodeBlock(text: _compose),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DockgeCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                session.connected ? Icons.link_rounded : Icons.link_off_rounded,
              ),
              title: Text(
                session.connected
                    ? session.profile?.name ?? 'Dockge'
                    : l10n.notConnected,
              ),
              subtitle: Text(
                session.connected
                    ? session.profile?.baseUrl ?? ''
                    : l10n.connectToServerFirst,
              ),
              trailing: session.connected
                  ? IconButton(
                      onPressed: () => ref
                          .read(dockgeSessionProvider.notifier)
                          .refreshStacks(),
                      icon: const Icon(Icons.refresh_rounded),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          if (session.connected && session.stacks.isEmpty)
            EmptyState(message: l10n.noStacksLoaded),
        ],
      ),
    );
  }

  String _convertDockerRun(String command) {
    final tokens = command
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    final nameIndex = tokens.indexOf('--name');
    final portIndex = tokens.indexOf('-p');
    final name = nameIndex >= 0 && nameIndex + 1 < tokens.length
        ? tokens[nameIndex + 1]
        : 'app';
    final image = tokens.isNotEmpty ? tokens.last : 'image:latest';
    final port = portIndex >= 0 && portIndex + 1 < tokens.length
        ? tokens[portIndex + 1]
        : '8080:80';
    return '''
services:
  $name:
    image: $image
    restart: unless-stopped
    ports:
      - "$port"
''';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DockgeCard(
      child: Row(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }
}
