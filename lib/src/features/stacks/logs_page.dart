import 'package:dockge_app/src/core/session/session.dart';
import 'package:dockge_app/src/features/common/feature_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({required this.stackName, super.key});

  final String stackName;

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> {
  final _commandController = TextEditingController();
  final _lines = <String>[];
  bool _follow = true;

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
    ref.listen(terminalEventsProvider, (_, next) {
      final event = next.whenOrNull(data: (event) => event);
      if (event == null || event.data.isEmpty) {
        return;
      }
      if (mounted) {
        setState(() => _lines.add(event.data));
      }
    });

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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    session.connected
                        ? l10n.terminalFor(widget.stackName)
                        : l10n.connectToServerFirst,
                  ),
                ),
                FilterChip(
                  selected: _follow,
                  label: Text(l10n.follow),
                  avatar: const Icon(Icons.vertical_align_bottom_rounded),
                  onSelected: (value) => setState(() => _follow = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _lines.isEmpty
                  ? Center(
                      child: Text(
                        session.connected
                            ? l10n.waitingForTerminalOutput
                            : l10n.connectToServerFirst,
                        style: const TextStyle(color: Colors.white70),
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
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commandController,
                      decoration: InputDecoration(labelText: l10n.commandInput),
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
    final stack = _stack();
    if (stack == null) return;
    final result = await ref
        .read(dockgeSessionProvider.notifier)
        .joinCombinedTerminal(stack);
    if (!mounted || result.ok) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message ?? 'Terminal error')));
  }

  Future<void> _send() async {
    final command = _commandController.text;
    if (command.isEmpty) return;
    _commandController.clear();
    final stack = _stack();
    if (stack == null) return;
    await ref
        .read(dockgeSessionProvider.notifier)
        .terminalInput(stack, command);
  }

  dynamic _stack() {
    final session = ref.read(dockgeSessionProvider);
    final matches = session.stacks.where(
      (stack) => stack.name == widget.stackName,
    );
    return matches.isEmpty ? null : matches.first;
  }
}
