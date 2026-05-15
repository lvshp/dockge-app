import 'package:dockge_app/src/core/domain/domain.dart' as dockge;
import 'package:dockge_app/src/core/models.dart';
import 'package:dockge_app/src/core/safety_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses Dockge stackList map payload', () {
    final stacks = dockge.parseStackSummaryList({
      'dockge': {
        'status': 'running',
        'services': {'web': {}, 'agent': {}},
        'endpoint': '',
        'isManagedByDockge': true,
      },
    });

    expect(stacks, hasLength(1));
    expect(stacks.single.name, 'dockge');
    expect(stacks.single.serviceCount, 2);
    expect(stacks.single.status, dockge.StackStatus.running);
  });

  test('parses Dockge serviceStatusList map payload', () {
    final services = dockge.parseServiceStatusList({
      'web': {'status': 'exited', 'image': 'nginx:alpine'},
    });

    expect(services.single.name, 'web');
    expect(services.single.status, dockge.StackStatus.stopped);
    expect(services.single.image, 'nginx:alpine');
  });

  test('parses Dockge numeric stack statuses', () {
    final stacks = dockge.parseStackSummaryList({
      'created-file': {'status': 1},
      'created-stack': {'status': 2},
      'running-stack': {'status': 3},
      'exited-stack': {'status': 4},
    });

    expect(stacks[0].status, dockge.StackStatus.inactive);
    expect(stacks[1].status, dockge.StackStatus.inactive);
    expect(stacks[2].status, dockge.StackStatus.running);
    expect(stacks[3].status, dockge.StackStatus.stopped);
  });

  test('parses Dockge numeric service statuses', () {
    final services = dockge.parseServiceStatusList({
      'redis': {'status': 3, 'image': 'redis:7'},
      'job': {'status': 4, 'image': 'busybox'},
    });

    expect(services[0].status, dockge.StackStatus.running);
    expect(services[1].status, dockge.StackStatus.stopped);
  });

  test('marks destructive stack operations', () {
    final policy = const OperationSafetyPolicy();

    expect(
      policy.decisionFor(OperationType.delete, 'dockge').level,
      DangerLevel.destructive,
    );
    expect(
      policy.decisionFor(OperationType.stop, 'dockge').level,
      DangerLevel.caution,
    );
  });
}
