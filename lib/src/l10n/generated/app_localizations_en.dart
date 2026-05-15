// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dockge Mobile';

  @override
  String get dashboardTab => 'Dashboard';

  @override
  String get stacksTab => 'Stacks';

  @override
  String get auditTab => 'Audit';

  @override
  String get settingsTab => 'Settings';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get stacksTitle => 'Stacks';

  @override
  String get auditTitle => 'Audit';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get loginTitle => 'Connect';

  @override
  String get stackDetailTitle => 'Stack detail';

  @override
  String get dashboardEmptyTitle => 'No server summary yet';

  @override
  String get dashboardEmptyMessage =>
      'Connect to a Dockge server to see stack health, resource status, and recent activity.';

  @override
  String get stacksEmptyTitle => 'No stacks loaded';

  @override
  String get stacksEmptyMessage =>
      'Your compose stacks will appear here after the server connection is ready.';

  @override
  String get auditEmptyTitle => 'No audit events';

  @override
  String get auditEmptyMessage =>
      'Server actions and important changes will appear here.';

  @override
  String get loginEmptyTitle => 'Connection setup';

  @override
  String get loginEmptyMessage =>
      'The connection form will plug into this screen when the auth feature lands.';

  @override
  String get stackDetailEmptyTitle => 'Stack details pending';

  @override
  String get stackDetailEmptyMessage =>
      'Containers, actions, and compose metadata will appear here.';

  @override
  String get composeEmptyTitle => 'Compose editor pending';

  @override
  String get composeEmptyMessage =>
      'The compose editor will load here when stack editing is connected.';

  @override
  String get logsEmptyTitle => 'Logs pending';

  @override
  String get logsEmptyMessage =>
      'Live service logs will appear here when log streaming is connected.';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusDegraded => 'Degraded';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '简体中文';

  @override
  String get saveAction => 'Save';

  @override
  String get okAction => 'OK';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get confirmAction => 'Confirm';

  @override
  String get previewDialogAction => 'Preview dialog';

  @override
  String get settingsSavedToast => 'Settings saved';

  @override
  String get settingsDialogTitle => 'Dockge Mobile';

  @override
  String get settingsDialogMessage =>
      'Shared dialogs and toasts are ready for feature pages.';

  @override
  String composeTitle(String stackName) {
    return 'Compose: $stackName';
  }

  @override
  String logsTitle(String stackName) {
    return 'Logs: $stackName';
  }
}
