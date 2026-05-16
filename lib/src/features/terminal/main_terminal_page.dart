import 'package:dockge_app/src/core/session/session.dart';
import 'package:dockge_app/src/features/common/feature_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

class MainTerminalPage extends ConsumerStatefulWidget {
  const MainTerminalPage({super.key});

  @override
  ConsumerState<MainTerminalPage> createState() => _MainTerminalPageState();
}

class _MainTerminalPageState extends ConsumerState<MainTerminalPage> {
  final _commandController = TextEditingController();
  late final Terminal _terminal;
  late final TerminalController _terminalController;
  bool _follow = true;
  static const _terminalName = 'console';

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 10000);
    _terminalController = TerminalController();
    _terminal.onOutput = (data) {
      ref.read(dockgeSessionProvider.notifier).mainTerminalInput(data);
    };
    _terminal.onResize = (cols, rows, pixelWidth, pixelHeight) {
      ref
          .read(dockgeSessionProvider.notifier)
          .mainTerminalResize(rows: rows, cols: cols);
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _joinTerminal());
  }

  @override
  void dispose() {
    _commandController.dispose();
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
      // 只接受当前终端的事件
      if (event.terminalName != null && event.terminalName != _terminalName) {
        return;
      }
      _terminal.write(event.data);
    });

    final terminalBg = scheme.brightness == Brightness.dark
        ? const Color(0xFF1A1B1E)
        : const Color(0xFF2B2D31);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.terminal),
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
                Icon(Icons.computer_rounded, size: 16, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.connected
                        ? _t(l10n, 'Host Terminal', '宿主机终端')
                        : l10n.connectToServerFirst,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilterChip(
                  selected: _follow,
                  label: Text(l10n.follow),
                  avatar: const Icon(
                    Icons.vertical_align_bottom_rounded,
                    size: 16,
                  ),
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
                readOnly: !session.connected,
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
    _terminal.write('\x1b[2J\x1b[H');
    final result = await ref
        .read(dockgeSessionProvider.notifier)
        .joinMainTerminal();
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

  Future<void> _send() async {
    final command = _commandController.text;
    if (command.isEmpty) return;
    _commandController.clear();
    await ref
        .read(dockgeSessionProvider.notifier)
        .mainTerminalInput('$command\r');
  }

  String _t(FeatureLocalizations l10n, String en, String zh) {
    return l10n.active == 'Active' ? en : zh;
  }
}
