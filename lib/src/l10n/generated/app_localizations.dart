import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Dockge Mobile'**
  String get appTitle;

  /// No description provided for @dashboardTab.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTab;

  /// No description provided for @stacksTab.
  ///
  /// In en, this message translates to:
  /// **'Stacks'**
  String get stacksTab;

  /// No description provided for @auditTab.
  ///
  /// In en, this message translates to:
  /// **'Audit'**
  String get auditTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @stacksTitle.
  ///
  /// In en, this message translates to:
  /// **'Stacks'**
  String get stacksTitle;

  /// No description provided for @auditTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit'**
  String get auditTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get loginTitle;

  /// No description provided for @stackDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Stack detail'**
  String get stackDetailTitle;

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No server summary yet'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Connect to a Dockge server to see stack health, resource status, and recent activity.'**
  String get dashboardEmptyMessage;

  /// No description provided for @stacksEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No stacks loaded'**
  String get stacksEmptyTitle;

  /// No description provided for @stacksEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your compose stacks will appear here after the server connection is ready.'**
  String get stacksEmptyMessage;

  /// No description provided for @auditEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No audit events'**
  String get auditEmptyTitle;

  /// No description provided for @auditEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Server actions and important changes will appear here.'**
  String get auditEmptyMessage;

  /// No description provided for @loginEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection setup'**
  String get loginEmptyTitle;

  /// No description provided for @loginEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'The connection form will plug into this screen when the auth feature lands.'**
  String get loginEmptyMessage;

  /// No description provided for @stackDetailEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Stack details pending'**
  String get stackDetailEmptyTitle;

  /// No description provided for @stackDetailEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Containers, actions, and compose metadata will appear here.'**
  String get stackDetailEmptyMessage;

  /// No description provided for @composeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Compose editor pending'**
  String get composeEmptyTitle;

  /// No description provided for @composeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'The compose editor will load here when stack editing is connected.'**
  String get composeEmptyMessage;

  /// No description provided for @logsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Logs pending'**
  String get logsEmptyTitle;

  /// No description provided for @logsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Live service logs will appear here when log streaming is connected.'**
  String get logsEmptyMessage;

  /// No description provided for @statusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get statusConnected;

  /// No description provided for @statusDegraded.
  ///
  /// In en, this message translates to:
  /// **'Degraded'**
  String get statusDegraded;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @okAction.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okAction;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmAction;

  /// No description provided for @previewDialogAction.
  ///
  /// In en, this message translates to:
  /// **'Preview dialog'**
  String get previewDialogAction;

  /// No description provided for @settingsSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSavedToast;

  /// No description provided for @settingsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Dockge Mobile'**
  String get settingsDialogTitle;

  /// No description provided for @settingsDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Shared dialogs and toasts are ready for feature pages.'**
  String get settingsDialogMessage;

  /// No description provided for @composeTitle.
  ///
  /// In en, this message translates to:
  /// **'Compose: {stackName}'**
  String composeTitle(String stackName);

  /// No description provided for @logsTitle.
  ///
  /// In en, this message translates to:
  /// **'Logs: {stackName}'**
  String logsTitle(String stackName);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
