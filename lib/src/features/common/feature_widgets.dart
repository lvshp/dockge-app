import 'package:dockge_app/src/core/domain/domain.dart' show StackStatus;
import 'package:dockge_app/src/core/models.dart' show OperationType;
import 'package:dockge_app/src/features/common/feature_localizations.dart';
import 'package:flutter/material.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({required this.status, super.key});

  final StackStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = FeatureLocalizations.of(context);
    final color = statusColor(context, status);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          statusLabel(l10n, status),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

Color statusColor(BuildContext context, StackStatus status) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    StackStatus.running => Colors.green,
    StackStatus.stopped => Colors.orange,
    StackStatus.inactive => scheme.outline,
    StackStatus.partial => Colors.amber,
    StackStatus.error => scheme.error,
    StackStatus.updating => scheme.primary,
    StackStatus.unknown => scheme.outline,
  };
}

String statusLabel(FeatureLocalizations l10n, StackStatus status) {
  return switch (status) {
    StackStatus.running => l10n.running,
    StackStatus.stopped => l10n.stopped,
    StackStatus.inactive => l10n.inactive,
    StackStatus.partial => l10n.partial,
    StackStatus.error => l10n.error,
    StackStatus.updating => l10n.updating,
    StackStatus.unknown => l10n.unknown,
  };
}

String operationLabel(FeatureLocalizations l10n, OperationType type) {
  return switch (type) {
    OperationType.start => l10n.start,
    OperationType.stop => l10n.stop,
    OperationType.restart => l10n.restart,
    OperationType.update => l10n.update,
    OperationType.down => l10n.down,
    OperationType.delete => l10n.delete,
    OperationType.saveCompose => l10n.saveCompose,
  };
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class DockgeCard extends StatelessWidget {
  const DockgeCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
