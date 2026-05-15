import 'package:dockge_app/src/app/theme.dart';
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
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              statusLabel(l10n, status),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color statusColor(BuildContext context, StackStatus status) {
  final ext = Theme.of(context).extension<DockgeStatusColors>();
  if (ext != null) {
    return switch (status) {
      StackStatus.running => ext.running,
      StackStatus.stopped => ext.stopped,
      StackStatus.inactive => ext.inactive,
      StackStatus.partial => ext.partial,
      StackStatus.error => ext.error,
      StackStatus.updating => ext.updating,
      StackStatus.unknown => ext.unknown,
    };
  }
  // Fallback
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    StackStatus.running => scheme.primary,
    StackStatus.stopped => scheme.error,
    StackStatus.inactive => scheme.outline,
    StackStatus.partial => scheme.tertiary,
    StackStatus.error => scheme.error,
    StackStatus.updating => scheme.tertiary,
    StackStatus.unknown => scheme.outline,
  };
}

IconData statusIcon(StackStatus status) {
  return switch (status) {
    StackStatus.running => Icons.check_circle_rounded,
    StackStatus.stopped => Icons.cancel_rounded,
    StackStatus.inactive => Icons.remove_circle_outline_rounded,
    StackStatus.partial => Icons.warning_amber_rounded,
    StackStatus.error => Icons.error_rounded,
    StackStatus.updating => Icons.sync_rounded,
    StackStatus.unknown => Icons.help_outline_rounded,
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
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) ?trailing,
      ],
    );
  }
}

class DockgeCard extends StatelessWidget {
  const DockgeCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(padding: padding, child: child),
    );
    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.title,
    super.key,
  });

  final String message;
  final IconData icon;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.primary),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 状态色竖条装饰，用于卡片左侧
class StatusStripe extends StatelessWidget {
  const StatusStripe({required this.status, super.key});

  final StackStatus status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(context, status);
    return Container(
      width: 4,
      height: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}