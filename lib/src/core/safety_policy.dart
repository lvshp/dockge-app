import 'package:dockge_app/src/core/models.dart';

class SafetyDecision {
  const SafetyDecision({
    required this.level,
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final DangerLevel level;
  final String title;
  final String message;
  final String confirmLabel;
}

class OperationSafetyPolicy {
  const OperationSafetyPolicy();

  SafetyDecision decisionFor(OperationType type, String stackName) {
    return switch (type) {
      OperationType.delete => SafetyDecision(
        level: DangerLevel.destructive,
        title: '删除 $stackName',
        message: '这会删除 Stack 配置并执行 Dockge 的删除流程。此操作不可轻易恢复。',
        confirmLabel: '删除',
      ),
      OperationType.down => SafetyDecision(
        level: DangerLevel.destructive,
        title: 'Down $stackName',
        message: '这会停止并移除 Stack 相关容器，可能造成线上服务中断。',
        confirmLabel: '确认 Down',
      ),
      OperationType.saveCompose => SafetyDecision(
        level: DangerLevel.destructive,
        title: '覆盖 compose.yaml',
        message: '保存会覆盖当前 compose.yaml。建议先确认变更内容无误。',
        confirmLabel: '保存覆盖',
      ),
      OperationType.stop => SafetyDecision(
        level: DangerLevel.caution,
        title: '停止 $stackName',
        message: '停止 Stack 会中断该 Stack 内运行中的服务。',
        confirmLabel: '停止',
      ),
      OperationType.restart => SafetyDecision(
        level: DangerLevel.caution,
        title: '重启 $stackName',
        message: '重启期间服务可能短暂不可用。',
        confirmLabel: '重启',
      ),
      OperationType.update => SafetyDecision(
        level: DangerLevel.caution,
        title: '更新 $stackName',
        message: 'Dockge 将拉取镜像并更新 Stack，请确认当前配置已保存。',
        confirmLabel: '更新',
      ),
      OperationType.start => SafetyDecision(
        level: DangerLevel.normal,
        title: '启动 $stackName',
        message: 'Dockge 将启动这个 Stack。',
        confirmLabel: '启动',
      ),
    };
  }
}
