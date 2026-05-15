// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Dockge Mobile';

  @override
  String get dashboardTab => '总览';

  @override
  String get stacksTab => '应用栈';

  @override
  String get auditTab => '审计';

  @override
  String get settingsTab => '设置';

  @override
  String get dashboardTitle => '总览';

  @override
  String get stacksTitle => '应用栈';

  @override
  String get auditTitle => '审计';

  @override
  String get settingsTitle => '设置';

  @override
  String get loginTitle => '连接';

  @override
  String get stackDetailTitle => '应用栈详情';

  @override
  String get dashboardEmptyTitle => '暂无服务器概览';

  @override
  String get dashboardEmptyMessage =>
      '连接 Dockge 服务器后，可以在这里查看应用栈健康状态、资源状态和近期活动。';

  @override
  String get stacksEmptyTitle => '暂无应用栈';

  @override
  String get stacksEmptyMessage => '服务器连接就绪后，Compose 应用栈会显示在这里。';

  @override
  String get auditEmptyTitle => '暂无审计事件';

  @override
  String get auditEmptyMessage => '服务器操作和重要变更会显示在这里。';

  @override
  String get loginEmptyTitle => '连接设置';

  @override
  String get loginEmptyMessage => '认证功能接入后，连接表单会放在这个页面。';

  @override
  String get stackDetailEmptyTitle => '应用栈详情待接入';

  @override
  String get stackDetailEmptyMessage => '容器、操作和 Compose 元数据会显示在这里。';

  @override
  String get composeEmptyTitle => 'Compose 编辑器待接入';

  @override
  String get composeEmptyMessage => '应用栈编辑接入后，Compose 编辑器会在这里加载。';

  @override
  String get logsEmptyTitle => '日志待接入';

  @override
  String get logsEmptyMessage => '日志流接入后，实时服务日志会显示在这里。';

  @override
  String get statusConnected => '已连接';

  @override
  String get statusDegraded => '降级';

  @override
  String get languageTitle => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '简体中文';

  @override
  String get saveAction => '保存';

  @override
  String get okAction => '确定';

  @override
  String get cancelAction => '取消';

  @override
  String get confirmAction => '确认';

  @override
  String get previewDialogAction => '预览弹窗';

  @override
  String get settingsSavedToast => '设置已保存';

  @override
  String get settingsDialogTitle => 'Dockge Mobile';

  @override
  String get settingsDialogMessage => '通用弹窗和提示已经可以给功能页面复用。';

  @override
  String composeTitle(String stackName) {
    return 'Compose：$stackName';
  }

  @override
  String logsTitle(String stackName) {
    return '日志：$stackName';
  }
}
