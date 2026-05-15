import 'package:flutter/material.dart';

enum DockgeStatus { neutral, success, warning, error, info }

class DockgeStatusChip extends StatelessWidget {
  const DockgeStatusChip({
    required this.label,
    this.status = DockgeStatus.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final DockgeStatus status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(context, status);

    return Chip(
      avatar: Icon(
        icon ?? _statusIcon(status),
        size: 16,
        color: colors.foreground,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        color: colors.foreground,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: colors.background,
      side: BorderSide(color: colors.border),
      visualDensity: VisualDensity.compact,
    );
  }
}

_DockgeStatusColors _statusColors(BuildContext context, DockgeStatus status) {
  final scheme = Theme.of(context).colorScheme;

  return switch (status) {
    DockgeStatus.success => _DockgeStatusColors(
      background: scheme.tertiaryContainer,
      foreground: scheme.onTertiaryContainer,
      border: scheme.tertiary.withValues(alpha: 0.48),
    ),
    DockgeStatus.warning => _DockgeStatusColors(
      background: const Color(0xFFFFF1C2),
      foreground: const Color(0xFF5F4100),
      border: const Color(0xFFE8B931),
    ),
    DockgeStatus.error => _DockgeStatusColors(
      background: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
      border: scheme.error.withValues(alpha: 0.48),
    ),
    DockgeStatus.info => _DockgeStatusColors(
      background: scheme.secondaryContainer,
      foreground: scheme.onSecondaryContainer,
      border: scheme.secondary.withValues(alpha: 0.48),
    ),
    DockgeStatus.neutral => _DockgeStatusColors(
      background: scheme.surfaceContainerHighest,
      foreground: scheme.onSurfaceVariant,
      border: scheme.outlineVariant,
    ),
  };
}

IconData _statusIcon(DockgeStatus status) {
  return switch (status) {
    DockgeStatus.success => Icons.check_circle,
    DockgeStatus.warning => Icons.warning,
    DockgeStatus.error => Icons.error,
    DockgeStatus.info => Icons.info,
    DockgeStatus.neutral => Icons.circle,
  };
}

class _DockgeStatusColors {
  const _DockgeStatusColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
