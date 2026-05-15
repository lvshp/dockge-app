import 'package:flutter/widgets.dart';

class FeatureLocalizations {
  const FeatureLocalizations._(this._isZh);

  final bool _isZh;

  static FeatureLocalizations of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return FeatureLocalizations._(languageCode == 'zh');
  }

  String get appName => 'Dockge Mobile';
  String get loginTitle => _t('Connect to Dockge', '连接 Dockge');
  String get setupTitle => _t('First server setup', '首次服务器初始化');
  String get serverName => _t('Server name', '服务器名称');
  String get serverUrl => _t('Server URL', '服务器地址');
  String get username => _t('Username', '用户名');
  String get password => _t('Password', '密码');
  String get accessToken => _t('Access token', '访问令牌');
  String get passwordAuth => _t('Password', '密码');
  String get tokenAuth => _t('Token', '令牌');
  String get allowSelfSigned => _t('Allow self-signed certificate', '允许自签名证书');
  String get connect => _t('Connect', '连接');
  String get manageConnection => _t('Manage connection', '管理连接');
  String get requiredField => _t('Required', '必填');
  String get saveServer => _t('Save server', '保存服务器');
  String get dashboard => _t('Dashboard', '概览');
  String get stacks => _t('Stacks', 'Stacks');
  String get audit => _t('Audit', '审计');
  String get settings => _t('Settings', '设置');
  String get active => _t('Active', '运行中');
  String get exited => _t('Exited', '已退出');
  String get inactive => _t('Inactive', '未激活');
  String get dockerRunConverter =>
      _t('Docker Run converter', 'Docker Run 转 Compose');
  String get dockerRunInput =>
      _t('Paste docker run command', '粘贴 docker run 命令');
  String get composePreview => _t('Compose preview', 'Compose 预览');
  String get convert => _t('Convert', '转换');
  String get agents => _t('Agents', 'Agent');
  String get localAgent => _t('Local agent', '本地 Agent');
  String get remoteAgent => _t('Remote agent', '远程 Agent');
  String get online => _t('Online', '在线');
  String get offline => _t('Offline', '离线');
  String get searchStacks => _t('Search stacks', '搜索 Stack');
  String get all => _t('All', '全部');
  String get running => _t('Running', '运行中');
  String get stopped => _t('Stopped', '已停止');
  String get partial => _t('Partial', '部分运行');
  String get error => _t('Error', '错误');
  String get updating => _t('Updating', '更新中');
  String get unknown => _t('Unknown', '未知');
  String get services => _t('Services', '服务');
  String get compose => _t('Compose', 'Compose');
  String get environment => _t('Environment', '环境变量');
  String get operations => _t('Operations', '操作');
  String get logs => _t('Logs', '日志');
  String get terminal => _t('Terminal', '终端');
  String get edit => _t('Edit', '编辑');
  String get save => _t('Save', '保存');
  String get cancel => _t('Cancel', '取消');
  String get start => _t('Start', '启动');
  String get stop => _t('Stop', '停止');
  String get restart => _t('Restart', '重启');
  String get update => _t('Update', '更新');
  String get down => _t('Down', 'Down');
  String get delete => _t('Delete', '删除');
  String get pull => _t('Pull', '拉取');
  String get recreate => _t('Recreate', '重建');
  String get shell => _t('Shell', 'Shell');
  String get openLogs => _t('Open logs', '打开日志');
  String get editCompose => _t('Edit compose', '编辑 Compose');
  String get composeEditor => _t('Compose editor', 'Compose 编辑器');
  String get saveCompose => _t('Save compose', '保存 Compose');
  String get deployStack => _t('Deploy stack', '部署 Stack');
  String get stackDetail => _t('Stack detail', 'Stack 详情');
  String get stackOperations => _t('Stack operations', 'Stack 操作');
  String get serviceOperations => _t('Service operations', '服务操作');
  String get recentOperations => _t('Recent operations', '最近操作');
  String get commandInput => _t('Command input', '命令输入');
  String get send => _t('Send', '发送');
  String get reconnect => _t('Reconnect', '重新连接');
  String get clear => _t('Clear', '清空');
  String get follow => _t('Follow', '跟随');
  String get language => _t('Language', '语言');
  String get systemLanguage => _t('System', '跟随系统');
  String get english => 'English';
  String get simplifiedChinese => _t('Simplified Chinese', '简体中文');
  String get languageHookPlaceholder =>
      _t('Language takes effect immediately.', '语言设置会立即生效。');
  String get appearance => _t('Appearance', '外观');
  String get server => _t('Server', '服务器');
  String get profile => _t('Profile', '配置');
  String get version => _t('Version', '版本');
  String get disconnect => _t('Disconnect', '断开连接');
  String get disconnected => _t('Disconnected', '已断开连接');
  String get noStacks =>
      _t('No stacks match the current filter.', '没有匹配当前筛选条件的 Stack。');
  String get notConnected => _t('Not connected', '未连接');
  String get connectToServerFirst =>
      _t('Connect to your Dockge server first.', '请先连接你的 Dockge 服务器。');
  String get noStacksLoaded =>
      _t('No stacks loaded from Dockge.', '尚未从 Dockge 加载到 Stack。');
  String get stackLoadFailed =>
      _t('Failed to load stack from Dockge.', '无法从 Dockge 加载 Stack。');
  String get noServicesLoaded =>
      _t('No services returned by Dockge.', 'Dockge 未返回服务列表。');
  String get yamlInvalid => _t('Invalid YAML', 'YAML 格式无效');
  String get waitingForTerminalOutput =>
      _t('Waiting for terminal output...', '正在等待终端输出...');
  String get noLocalOperations =>
      _t('No local operations recorded in this session.', '当前会话还没有本地操作记录。');
  String get destructiveAction => _t('Destructive action', '危险操作');
  String get confirm => _t('Confirm', '确认');
  String get operationQueued => _t('Operation queued', '操作已加入队列');
  String get auditTrail => _t('Audit trail', '审计记录');
  String get createdByMobile => _t('Created from mobile UI', '来自移动端界面');
  String get pendingCoreNote =>
      _t('Waiting for live Dockge core services', '等待接入真实 Dockge 服务');

  String servicesCount(int count) => _t('$count services', '$count 个服务');
  String containersCount(int count) => _t('$count containers', '$count 个容器');
  String updatedMinutesAgo(int minutes) =>
      _t('Updated ${minutes}m ago', '$minutes 分钟前更新');
  String agentStacks(int count) => _t('$count stacks', '$count 个 Stack');
  String operationFor(String operation, String target) =>
      _t('$operation $target', '$operation $target');
  String terminalFor(String target) => _t('Terminal: $target', '终端：$target');

  String _t(String en, String zh) => _isZh ? zh : en;
}
