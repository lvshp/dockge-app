import 'package:dockge_app/src/app/navigation_shell.dart';
import 'package:dockge_app/src/features/audit/audit_page.dart';
import 'package:dockge_app/src/features/auth/login_page.dart';
import 'package:dockge_app/src/features/dashboard/dashboard_page.dart';
import 'package:dockge_app/src/features/settings/settings_page.dart';
import 'package:dockge_app/src/features/stacks/compose_editor_page.dart';
import 'package:dockge_app/src/features/stacks/logs_page.dart';
import 'package:dockge_app/src/features/stacks/stack_detail_page.dart';
import 'package:dockge_app/src/features/stacks/stacks_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DockgeNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: AppRoute.dashboard.name,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stacks',
                name: AppRoute.stacks.name,
                builder: (context, state) => const StacksPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/audit',
                name: AppRoute.audit.name,
                builder: (context, state) => const AuditPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: AppRoute.settings.name,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        name: AppRoute.login.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/stacks/:name',
        name: AppRoute.stackDetail.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final name = Uri.decodeComponent(state.pathParameters['name'] ?? '');
          return StackDetailPage(stackName: name);
        },
      ),
      GoRoute(
        path: '/stacks/:name/compose',
        name: AppRoute.stackCompose.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final name = Uri.decodeComponent(state.pathParameters['name'] ?? '');
          return ComposeEditorPage(stackName: name);
        },
      ),
      GoRoute(
        path: '/stacks/:name/logs',
        name: AppRoute.stackLogs.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final name = Uri.decodeComponent(state.pathParameters['name'] ?? '');
          return LogsPage(stackName: name);
        },
      ),
    ],
  );
});

enum AppRoute {
  dashboard,
  stacks,
  audit,
  settings,
  login,
  stackDetail,
  stackCompose,
  stackLogs,
}
