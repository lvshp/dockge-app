import 'package:dockge_app/src/core/session/session.dart';
import 'package:dockge_app/src/features/common/feature_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({required this.stackName, super.key});

  final String stackName;

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> {
  late final Terminal _terminal;
  late final TerminalController _terminalController;
  String? _activeTerminalName;

  String _combinedTerminalName(String endpoint) {
    return 'combined-$endpoint-${widget.stackName}';
  }

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 10000);
    _terminalController = TerminalController();
    _terminal.onResize = (cols, rows, pixelWidth, pixelHeight) {
      final stack = _stack();
      if (stack == null) return;
      ref
          .read(dockgeSessionProvider.notifier)
          .terminalResize(stack, rows: rows, cols: cols);
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _joinTerminal());
  }

  @override
  void dispose() {
    _terminalController.dispose();
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
      // 只接受当前组合终端的事件
      if (_activeTerminalName != null &&
          event.terminalName != null &&
          event.terminalName != _activeTerminalName) {
        return;
      }
      if (mounted) {
        _terminal.write(event.data);
      }
    });

    // 终端背景色：暗色模式深黑，亮色模式深灰
    final terminalBg = scheme.brightness == Brightness.dark
        ? const Color(0xFF1A1B1E)
        : const Color(0xFF2B2D31);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.logs),
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
                        ? widget.stackName
                        : l10n.connectToServerFirst,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
              child: TerminalView(
                _terminal,
                controller: _terminalController,
                autofocus: true,
                backgroundOpacity: 0,
                padding: const EdgeInsets.all(2),
                textStyle: const TerminalStyle(
                  fontSize: 13,
                  height: 1.25,
                  fontFamily: 'monospace',
                ),
                keyboardType: TextInputType.text,
                deleteDetection: true,
                readOnly: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinTerminal() async {
    final stack = _stack();
    if (stack == null) return;
    _terminal.write('\x1b[2J\x1b[H');
    _activeTerminalName = _combinedTerminalName(stack.endpoint ?? '');
    final result = await ref
        .read(dockgeSessionProvider.notifier)
        .joinCombinedTerminal(stack);
    if (!mounted) return;
    if (result.ok) {
      final buffer = result.data;
      if (buffer != null && buffer.isNotEmpty) {
        _terminal.write(buffer);
      }
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message ?? 'Terminal error')));
  }

  dynamic _stack() {
    final session = ref.read(dockgeSessionProvider);
    final matches = session.stacks.where(
      (stack) => stack.name == widget.stackName,
    );
    return matches.isEmpty ? null : matches.first;
  }
}
