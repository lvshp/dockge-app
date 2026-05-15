import 'package:dockge_app/src/app/locale_controller.dart';
import 'package:dockge_app/src/app/router.dart';
import 'package:dockge_app/src/app/theme.dart';
import 'package:dockge_app/src/app/theme_controller.dart';
import 'package:dockge_app/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DockgeMobileApp extends ConsumerWidget {
  const DockgeMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeOverrideProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Dockge Mobile',
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildDockgeTheme(Brightness.light),
      darkTheme: buildDockgeTheme(Brightness.dark),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}