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
            return EmptyState(
              message: l10n.connectToServerFirst,
              icon: Icons.cloud_off_rounded,
            );
          }
          if (snapshot.hasError) {
            return EmptyState(
              message: snapshot.error.toString(),
              icon: Icons.error_outline_rounded,
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data;
          if (result == null || !result.ok || result.data == null) {
            return EmptyState(
              message: result?.message ?? l10n.stackLoadFailed,
              icon: Icons.error_outline_rounded,
            );
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
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stack 信息卡
        DockgeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      detail.summary.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusPill(status: detail.summary.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.description_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      detail.summary.composePath ?? detail.summary.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 操作按钮
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in [
                    OperationType.start,
                    OperationType.stop,
                    OperationType.restart,
                    OperationType.update,
                  ])
                    FilledButton.tonal(
                      onPressed: () =>
                          _confirmStackOperation(
                            context,
                            ref,
                            detail.summary,
                            type,
                          ).then((changed) {
                            if (changed) onRefresh();
                          }),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_operationIcon(type), size: 16),
                          const SizedBox(width: 4),
                          Text(operationLabel(l10n, type)),
                        ],
                      ),
                    ),
                  // Down 按钮 — 警告色
                  FilledButton.tonal(
                    onPressed: () =>
                        _confirmStackOperation(
                          context,
                          ref,
                          detail.summary,
                          OperationType.down,
                        ).then((changed) {
                          if (changed) onRefresh();
                        }),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: scheme.tertiaryContainer,
                      foregroundColor: scheme.onTertiaryContainer,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_operationIcon(OperationType.down), size: 16),
                        const SizedBox(width: 4),
                        Text(operationLabel(l10n, OperationType.down)),
                      ],
                    ),
                  ),
                  // Delete 按钮 — 错误色
                  FilledButton.tonal(
                    onPressed: () =>
                        _confirmStackOperation(
                          context,
                          ref,
                          detail.summary,
                          OperationType.delete,
                        ).then((changed) {
                          if (changed) onRefresh();
                        }),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: scheme.errorContainer,
                      foregroundColor: scheme.onErrorContainer,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_operationIcon(OperationType.delete), size: 16),
                        const SizedBox(width: 4),
                        Text(operationLabel(l10n, OperationType.delete)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // 服务区
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
          EmptyState(
            message: l10n.noServicesLoaded,
            icon: Icons.widgets_outlined,
          )
        else
          ...detail.services.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
    final scheme = Theme.of(context).colorScheme;
    final statusColorVal = statusColor(context, service.status);
    final session = ref.watch(dockgeSessionProvider);

    return DockgeCard(
      padding: EdgeInsets.zero,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.view_in_ar_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            service.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // >_Bash 终端按钮
                        IconButton(
                          tooltip: '>_Bash',
                          onPressed: session.connected
                              ? () => context.push(
                                  '/stacks/${Uri.encodeComponent(stack.name)}'
                                  '/services/${Uri.encodeComponent(service.name)}'
                                  '/terminal',
                                )
                              : null,
                          icon: Text(
                            '>_',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        StatusPill(status: service.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 服务详细信息
                    _InfoRow(icon: Icons.image_rounded, text: service.image),
                    if (service.ports.isNotEmpty)
                      _InfoRow(
                        icon: Icons.lan_rounded,
                        text: service.ports.join(', '),
                      ),
                    if (service.cpuPercent != null)
                      _InfoRow(
                        icon: Icons.speed_rounded,
                        text: 'CPU: ${service.cpuPercent}',
                      ),
                    if (service.memoryUsage != null)
                      _InfoRow(
                        icon: Icons.memory_rounded,
                        text: 'Mem: ${service.memoryUsage}',
                      ),
                    if (actionsVisible)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  _serviceAction(context, ref, 'start'),
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 18,
                              ),
                              label: Text(l10n.start),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _serviceAction(context, ref, 'stop'),
                              icon: const Icon(Icons.stop_rounded, size: 18),
                              label: Text(l10n.stop),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _serviceAction(context, ref, 'restart'),
                              icon: const Icon(
                                Icons.restart_alt_rounded,
                                size: 18,
                              ),
                              label: Text(l10n.restart),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String? text;

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
