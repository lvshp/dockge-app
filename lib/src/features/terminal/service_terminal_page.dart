import 'package:dockge_app/src/core/session/session.dart';
import 'package:dockge_app/src/features/common/feature_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServiceTerminalPage extends ConsumerStatefulWidget {
  const ServiceTerminalPage({
    required this.stackName,
    required this.serviceName,
    super.key,
  });

  final String stackName;
  final String serviceName;

  @override
  ConsumerState<ServiceTerminalPage> createState() => _ServiceTerminalPageState();
}

class _ServiceTerminalPageState extends ConsumerState<ServiceTerminalPage> {
  final _commandController = TextEditingController();
  final _lines = <String>[];
  bool _follow = true;
  String _activeTerminalName = '';

  /// 容器交互终端名称: container-exec-{endpoint}-{stackName}-{serviceName}-0
  void _resolveTerminalName() {
    final session = ref.read(dockgeSessionProvider);
    final matchedStacks = session.stacks.where(
      (stack) => stack.name == widget.stackName,
    );
    final endpoint = matchedStacks.isEmpty ? '' : matchedStacks.first.endpoint ?? '';
    _activeTerminalName = 'container-exec-$endpoint-${widget.stackName}-${widget.serviceName}-0';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _joinTerminal());
  }

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FeatureLocalizations.of(context);
    final session = ref.watch(dockgeSessionProvider);
    final scheme = Theme.of(context).colorScheme;
    ref.listen(terminalEventsProvider, (_, next) {
      final event = next.whenOrNull(data: (event) => event);
      if (event == null || event.data.isEmpty) return;
      // 只接受当前交互终端的事件
      if (_activeTerminalName.isNotEmpty &&
          event.terminalName != null &&
          event.terminalName != _activeTerminalName) {
        return;
      }
      if (mounted) setState(() => _lines.add(event.data));
    });

    final terminalBg = scheme.brightness == Brightness.dark
        ? const Color(0xFF1A1B1E)
        : const Color(0xFF2B2D31);
    final terminalFg = scheme.brightness == Brightness.dark
        ? const Color(0xFFA9D4A0)
        : const Color(0xFF4EC9B0);

    return Scaffold(
      appBar: AppBar(
        title: Text('>_${widget.serviceName}'),
        actions: [
          IconButton(
            tooltip: l10n.reconnect,
            onPressed: session.connected ? _joinTerminal : null,
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: scheme.surfaceContainerLow,
            child: Row(
              children: [
                Icon(Icons.terminal_rounded, size: 16, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.connected
                        ? '${widget.stackName} / ${widget.serviceName}'
                        : l10n.connectToServerFirst,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilterChip(
                  selected: _follow,
                  label: Text(l10n.follow),
                  avatar: const Icon(Icons.vertical_align_bottom_rounded, size: 16),
                  onSelected: (value) => setState(() => _follow = value),
                ),
              ],
            ),
          ),
          // 终端输出区
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: terminalBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _lines.isEmpty
                  ? Center(
                      child: Text(
                        session.connected
                            ? l10n.waitingForTerminalOutput
                            : l10n.connectToServerFirst,
                        style: TextStyle(
                          color: Colors.white54,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.builder(
                      reverse: _follow,
                      itemCount: _lines.length,
                      itemBuilder: (context, index) {
                        final line = _follow
                            ? _lines[_lines.length - index - 1]
                            : _lines[index];
                        return SelectableText(
                          line,
                          style: TextStyle(
                            color: terminalFg,
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.5,
                          ),
                        );
                      },
                    ),
            ),
          ),
          // 命令输入区
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commandController,
                      decoration: InputDecoration(
                        labelText: l10n.commandInput,
                        prefixIcon: const Icon(Icons.chevron_right_rounded),
                      ),
                      style: const TextStyle(fontFamily: 'monospace'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: l10n.send,
                    onPressed: session.connected ? _send : null,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinTerminal() async {
    _lines.clear();
    _resolveTerminalName();
    final result = await ref
        .read(dockgeSessionProvider.notifier)
        .joinServiceTerminal(widget.stackName, widget.serviceName);
    if (!mounted || result.ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Terminal error')),
    );
  }

  Future<void> _send() async {
    final command = _commandController.text;
    if (command.isEmpty) return;
    _commandController.clear();
    await ref
        .read(dockgeSessionProvider.notifier)
        .serviceTerminalInput(
          widget.stackName,
          widget.serviceName,
          command,
        );
  }
}