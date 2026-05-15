import 'package:flutter/material.dart';

/// 语义状态颜色扩展，为 StackStatus 提供主题色
class DockgeStatusColors extends ThemeExtension<DockgeStatusColors> {
  const DockgeStatusColors({
    required this.running,
    required this.stopped,
    required this.inactive,
    required this.partial,
    required this.error,
    required this.updating,
    required this.unknown,
  });

  final Color running;
  final Color stopped;
  final Color inactive;
  final Color partial;
  final Color error;
  final Color updating;
  final Color unknown;

  @override
  DockgeStatusColors copyWith({
    Color? running,
    Color? stopped,
    Color? inactive,
    Color? partial,
    Color? error,
    Color? updating,
    Color? unknown,
  }) {
    return DockgeStatusColors(
      running: running ?? this.running,
      stopped: stopped ?? this.stopped,
      inactive: inactive ?? this.inactive,
      partial: partial ?? this.partial,
      error: error ?? this.error,
      updating: updating ?? this.updating,
      unknown: unknown ?? this.unknown,
    );
  }

  @override
  DockgeStatusColors lerp(DockgeStatusColors? other, double t) {
    if (other is! DockgeStatusColors) return this;
    return DockgeStatusColors(
      running: Color.lerp(running, other.running, t)!,
      stopped: Color.lerp(stopped, other.stopped, t)!,
      inactive: Color.lerp(inactive, other.inactive, t)!,
      partial: Color.lerp(partial, other.partial, t)!,
      error: Color.lerp(error, other.error, t)!,
      updating: Color.lerp(updating, other.updating, t)!,
      unknown: Color.lerp(unknown, other.unknown, t)!,
    );
  }
}

ThemeData buildDockgeTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0EA5A3),
    brightness: brightness,
  );

  const radius = 16.0;

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    extensions: <ThemeExtension<dynamic>>[
      DockgeStatusColors(
        running: colorScheme.primary,
        stopped: colorScheme.error,
        inactive: colorScheme.outline,
        partial: colorScheme.tertiary,
        error: colorScheme.error,
        updating: colorScheme.tertiary,
        unknown: colorScheme.outline,
      ),
    ],
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: colorScheme.surfaceContainerLow,
      foregroundColor: colorScheme.onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      side: BorderSide(color: colorScheme.outlineVariant),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: colorScheme.surfaceContainer,
      indicatorColor: colorScheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    ),
  );
}