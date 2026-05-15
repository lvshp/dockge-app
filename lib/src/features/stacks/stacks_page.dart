import 'package:dockge_app/src/core/domain/domain.dart' as domain;
import 'package:dockge_app/src/core/session/session.dart';
import 'package:dockge_app/src/features/common/feature_localizations.dart';
import 'package:dockge_app/src/features/common/feature_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StacksPage extends ConsumerStatefulWidget {
  const StacksPage({super.key});

  @override
  ConsumerState<StacksPage> createState() => _StacksPageState();
}

class _StacksPageState extends ConsumerState<StacksPage> {
  final _searchController = TextEditingController();
  _StackFilter _filter = _StackFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FeatureLocalizations.of(context);
    final session = ref.watch(dockgeSessionProvider);
    final stacks = session.stacks.where((stack) {
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty || stack.name.toLowerCase().contains(query);
      final matchesFilter =
          _filter.status == null || stack.status == _filter.status;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.stacks),
        actions: [
          IconButton(
            tooltip: l10n.reconnect,
            onPressed: session.connected
                ? () => ref.read(dockgeSessionProvider.notifier).refreshStacks()
                : null,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: l10n.searchStacks,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<_StackFilter>(
              segments: [
                ButtonSegment(value: _StackFilter.all, label: Text(l10n.all)),
                ButtonSegment(
                  value: _StackFilter.running,
                  label: Text(l10n.running),
                ),
                ButtonSegment(
                  value: _StackFilter.stopped,
                  label: Text(l10n.stopped),
                ),
                ButtonSegment(
                  value: _StackFilter.partial,
                  label: Text(l10n.partial),
                ),
                ButtonSegment(
                  value: _StackFilter.inactive,
                  label: Text(l10n.inactive),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (value) =>
                  setState(() => _filter = value.first),
            ),
          ),
          const SizedBox(height: 16),
          if (!session.connected)
            EmptyState(message: l10n.connectToServerFirst)
          else if (stacks.isEmpty)
            EmptyState(message: l10n.noStacks)
          else
            ...stacks.map(
              (stack) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StackTile(stack: stack),
              ),
            ),
        ],
      ),
    );
  }
}

enum _StackFilter {
  all(null),
  running(domain.StackStatus.running),
  stopped(domain.StackStatus.stopped),
  partial(domain.StackStatus.partial),
  inactive(domain.StackStatus.inactive);

  const _StackFilter(this.status);

  final domain.StackStatus? status;
}

class _StackTile extends StatelessWidget {
  const _StackTile({required this.stack});

  final domain.StackSummary stack;

  @override
  Widget build(BuildContext context) {
    final l10n = FeatureLocalizations.of(context);
    return DockgeCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          stack.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${stack.composePath ?? stack.endpoint ?? 'Dockge'}\n'
          '${l10n.servicesCount(stack.serviceCount)}',
        ),
        isThreeLine: true,
        leading: const Icon(Icons.layers_rounded),
        trailing: StatusPill(status: stack.status),
        onTap: () => context.push('/stacks/${Uri.encodeComponent(stack.name)}'),
      ),
    );
  }
}
