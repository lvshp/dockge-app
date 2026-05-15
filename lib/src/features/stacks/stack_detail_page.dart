import 'package:dockge_app/src/core/domain/domain.dart' as domain;
import 'package:dockge_app/src/core/models.dart'
    show DangerLevel, OperationType;
import 'package:dockge_app/src/core/safety_policy.dart';
import 'package:dockge_app/src/core/session/session.dart';
import 'package:dockge_app/src/features/common/feature_localizations.dart';
import 'package:dockge_app/src/features/common/feature_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StackDetailPage extends ConsumerStatefulWidget {
  const StackDetailPage({required this.stackName, super.key});

  final String stackName;

  @override
  ConsumerState<StackDetailPage> createState() => _StackDetailPageState();
}

class _StackDetailPageState extends ConsumerState<StackDetailPage> {
  late Future<domain.ApiResult<domain.StackDetail>> _detailFuture;
  bool _serviceActionsVisible = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<domain.ApiResult<domain.StackDetail>> _loadDetail() {
    return ref.read(dockgeSessionProvider.notifier).getStack(widget.stackName);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FeatureLocalizations.of(context);
    final session = ref.watch(dockgeSessionProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stackName),
        actions: [
          IconButton(
            tooltip: l10n.openLogs,
            onPressed: session.connected
                ? () => context.push(
                    '/stacks/${Uri.encodeComponent(widget.stackName)}/logs',
                  )
                : null,
            icon: const Icon(Icons.article_rounded),
          ),
          IconButton(
            tooltip: l10n.editCompose,
            onPressed: session.connected
                ? () => context.push(
                    '/stacks/${Uri.encodeComponent(widget.stackName)}/compose',
                  )
                : null,
            icon: const Icon(Icons.edit_note_rounded),
          ),
        ],
      ),
      body: FutureBuilder<domain.ApiResult<domain.StackDetail>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (!session.connected) {
            return EmptyState(message: l10n.connectToServerFirst);
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data;
          if (result == null || !result.ok || result.data == null) {
            return EmptyState(message: result?.message ?? l10n.stackLoadFailed);
          }
          return _DetailContent(
            detail: result.data!,
            serviceActionsVisible: _serviceActionsVisible,
            onToggleServiceActions: () => setState(() {
              _serviceActionsVisible = !_serviceActionsVisible;
            }),
            onRefresh: () => setState(() => _detailFuture = _loadDetail()),
          );
        },
      ),
      floatingActionButton: session.connected
          ? FloatingActionButton.extended(
              onPressed: () => context.push(
                '/stacks/${Uri.encodeComponent(widget.stackName)}/logs',
              ),
              icon: const Icon(Icons.terminal_rounded),
              label: Text(l10n.terminal),
            )
          : null,
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({
    required this.detail,
    required this.serviceActionsVisible,
    required this.onToggleServiceActions,
    required this.onRefresh,
  });

  final domain.StackDetail detail;
  final bool serviceActionsVisible;
  final VoidCallback onToggleServiceActions;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = FeatureLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DockgeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.stackDetail,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusPill(status: detail.summary.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(detail.summary.composePath ?? detail.summary.name),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in [
                    OperationType.start,
                    OperationType.stop,
                    OperationType.restart,
                    OperationType.update,
                    OperationType.down,
                    OperationType.delete,
                  ])
                    ActionChip(
                      avatar: Icon(_operationIcon(type), size: 18),
                      label: Text(operationLabel(l10n, type)),
                      onPressed: () =>
                          _confirmStackOperation(
                            context,
                            ref,
                            detail.summary,
                            type,
                          ).then((changed) {
                            if (changed) onRefresh();
                          }),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionHeader(
          title: l10n.services,
          trailing: TextButton.icon(
            onPressed: onToggleServiceActions,
            icon: Icon(
              serviceActionsVisible ? Icons.close_rounded : Icons.tune_rounded,
            ),
            label: Text(serviceActionsVisible ? l10n.cancel : l10n.operations),
          ),
        ),
        const SizedBox(height: 8),
        if (detail.services.isEmpty)
          EmptyState(message: l10n.noServicesLoaded)
        else
          ...detail.services.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ServiceTile(
                stack: detail.summary,
                service: service,
                actionsVisible: serviceActionsVisible,
              ),
            ),
          ),
      ],
    );
  }

  IconData _operationIcon(OperationType type) {
    return switch (type) {
      OperationType.start => Icons.play_arrow_rounded,
      OperationType.stop => Icons.stop_rounded,
      OperationType.restart => Icons.restart_alt_rounded,
      OperationType.update => Icons.system_update_alt_rounded,
      OperationType.down => Icons.keyboard_double_arrow_down_rounded,
      OperationType.delete => Icons.delete_outline_rounded,
      OperationType.saveCompose => Icons.save_rounded,
    };
  }

  Future<bool> _confirmStackOperation(
    BuildContext context,
    WidgetRef ref,
    domain.StackSummary stack,
    OperationType type,
  ) async {
    final l10n = FeatureLocalizations.of(context);
    final decision = const OperationSafetyPolicy().decisionFor(
      type,
      stack.name,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(decision.title),
        content: Text(decision.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: decision.level == DangerLevel.destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(decision.confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return false;
    }
    await ref
        .read(dockgeSessionProvider.notifier)
        .stackAction(stack, type.name);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.operationQueued)));
    }
    return true;
  }
}

class _ServiceTile extends ConsumerWidget {
  const _ServiceTile({
    required this.stack,
    required this.service,
    required this.actionsVisible,
  });

  final domain.StackSummary stack;
  final domain.ServiceStatus service;
  final bool actionsVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = FeatureLocalizations.of(context);
    return DockgeCard(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.view_in_ar_rounded),
            title: Text(service.name),
            subtitle: Text(
              [service.image, ...service.ports].whereType<String>().join('\n'),
            ),
            trailing: StatusPill(status: service.status),
          ),
          if (actionsVisible)
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _serviceAction(context, ref, 'start'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.start),
                ),
                TextButton.icon(
                  onPressed: () => _serviceAction(context, ref, 'stop'),
                  icon: const Icon(Icons.stop_rounded),
                  label: Text(l10n.stop),
                ),
                TextButton.icon(
                  onPressed: () => _serviceAction(context, ref, 'restart'),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(l10n.restart),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _serviceAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final l10n = FeatureLocalizations.of(context);
    final result = await ref
        .read(dockgeSessionProvider.notifier)
        .serviceAction(stack, service.name, action);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? l10n.operationQueued)),
    );
  }
}
