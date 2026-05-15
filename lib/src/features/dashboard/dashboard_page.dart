import 'package:dockge_app/src/app/theme.dart';
import 'package:dockge_app/src/core/domain/domain.dart' as domain;
import 'package:dockge_app/src/core/session/session.dart';
import 'package:dockge_app/src/features/common/feature_localizations.dart';
import 'package:dockge_app/src/features/common/feature_widgets.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: [
          if (session.connected)
            IconButton(
              tooltip: l10n.terminal,
              onPressed: () => context.push('/terminal'),
              icon: const Icon(Icons.terminal_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 统计卡片
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final cards = [
                _StatCard(
                  label: l10n.active,
                  value: active,
                  icon: Icons.play_circle_rounded,
                  gradientColors: _statusGradient(context, domain.StackStatus.running),
                ),
                _StatCard(
                  label: l10n.exited,
                  value: exited,
                  icon: Icons.stop_circle_rounded,
                  gradientColors: _statusGradient(context, domain.StackStatus.stopped),
                ),
                _StatCard(
                  label: l10n.inactive,
                  value: inactive,
                  icon: Icons.pause_circle_rounded,
                  gradientColors: _statusGradient(context, domain.StackStatus.inactive),
                ),
              ];
              return GridView.count(
                crossAxisCount: compact ? 1 : 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: compact ? 4.0 : 2.8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: cards,
              );
            },
          ),
          const SizedBox(height: 16),
          // Docker Run 转换器
          DockgeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: l10n.dockerRunConverter,
                  trailing: Icon(
                    Icons.transform_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _CodeBlock(text: _compose),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 连接状态
          _ConnectionCard(session: session),
          const SizedBox(height: 16),
          if (session.connected && session.stacks.isEmpty)
            EmptyState(
              message: l10n.noStacksLoaded,
              icon: Icons.cloud_off_rounded,
            ),
        ],
      ),
    );
  }

  List<Color> _statusGradient(BuildContext context, domain.StackStatus status) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<DockgeStatusColors>();
    switch (status) {
      case domain.StackStatus.running:
        final c = colors?.running ?? scheme.primary;
        return [c, c.withValues(alpha: 0.7)];
      case domain.StackStatus.stopped:
        final c = colors?.stopped ?? scheme.error;
        return [c, c.withValues(alpha: 0.8)];
      default:
        final c = colors?.inactive ?? scheme.outline;
        return [c, c.withValues(alpha: 0.6)];
    }
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
    required this.gradientColors,
  });

  final String label;
  final int value;
  final IconData icon;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 28, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$value',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

class _ConnectionCard extends ConsumerWidget {
  const _ConnectionCard({required this.session});

  final DockgeSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = FeatureLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return DockgeCard(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.connected
                      ? session.profile?.name ?? 'Dockge'
                      : l10n.notConnected,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  session.connected
                      ? session.profile?.baseUrl ?? ''
                      : l10n.connectToServerFirst,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (session.connected)
            IconButton(
              onPressed: () => ref
                  .read(dockgeSessionProvider.notifier)
                  .refreshStacks(),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l10n.reconnect,
            ),
        ],
      ),
    );
  }
}