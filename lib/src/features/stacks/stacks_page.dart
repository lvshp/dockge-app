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
          // 搜索框
          SearchBar(
            controller: _searchController,
            hintText: l10n.searchStacks,
            leading: const Icon(Icons.search_rounded),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          // 筛选 FilterChip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _StackFilter.values
                  .map(
                    (filter) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: _filter == filter,
                        label: Text(_filterLabel(l10n, filter)),
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (!session.connected)
            EmptyState(
              message: l10n.connectToServerFirst,
              icon: Icons.cloud_off_rounded,
            )
          else if (stacks.isEmpty)
            EmptyState(
              message: l10n.noStacks,
              icon: Icons.inbox_outlined,
            )
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

  String _filterLabel(FeatureLocalizations l10n, _StackFilter filter) {
    return switch (filter) {
      _StackFilter.all => l10n.all,
      _StackFilter.running => l10n.running,
      _StackFilter.stopped => l10n.stopped,
      _StackFilter.inactive => l10n.inactive,
    };
  }
}

enum _StackFilter {
  all(null),
  running(domain.StackStatus.running),
  stopped(domain.StackStatus.stopped),
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
    final scheme = Theme.of(context).colorScheme;
    final statusColorVal = statusColor(context, stack.status);

    return DockgeCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/stacks/${Uri.encodeComponent(stack.name)}'),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // 左侧状态色竖条
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: statusColorVal,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            // 内容区
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stack.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stack.composePath ?? stack.endpoint ?? 'Dockge',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (stack.serviceCount > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              l10n.servicesCount(stack.serviceCount),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    StatusPill(status: stack.status),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}