import 'package:dockge_app/src/shared/status_chip.dart';
import 'package:flutter/material.dart';

void showDockgeToast(
  BuildContext context, {
  required String message,
  DockgeStatus status = DockgeStatus.neutral,
  Duration duration = const Duration(seconds: 3),
}) {
  final colors = _toastColors(context, status);

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: colors.background,
        content: Row(
          children: [
            Icon(colors.icon, color: colors.foreground, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: colors.foreground)),
            ),
          ],
        ),
      ),
    );
}

_ToastColors _toastColors(BuildContext context, DockgeStatus status) {
  final scheme = Theme.of(context).colorScheme;

  return switch (status) {
    DockgeStatus.success => _ToastColors(
      background: scheme.tertiaryContainer,
      foreground: scheme.onTertiaryContainer,
      icon: Icons.check_circle,
    ),
    DockgeStatus.warning => const _ToastColors(
      background: Color(0xFFFFF1C2),
      foreground: Color(0xFF5F4100),
      icon: Icons.warning,
    ),
    DockgeStatus.error => _ToastColors(
      background: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
      icon: Icons.error,
    ),
    DockgeStatus.info => _ToastColors(
      background: scheme.secondaryContainer,
      foreground: scheme.onSecondaryContainer,
      icon: Icons.info,
    ),
    DockgeStatus.neutral => _ToastColors(
      background: scheme.inverseSurface,
      foreground: scheme.onInverseSurface,
      icon: Icons.info_outline,
    ),
  };
}

class _ToastColors {
  const _ToastColors({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
}
