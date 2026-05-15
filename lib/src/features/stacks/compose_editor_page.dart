import 'package:dockge_app/src/core/domain/domain.dart' as domain;
import 'package:dockge_app/src/core/models.dart' show OperationType;
import 'package:dockge_app/src/core/safety_policy.dart';
import 'package:dockge_app/src/core/session/session.dart';
import 'package:dockge_app/src/features/common/feature_localizations.dart';
import 'package:dockge_app/src/features/common/feature_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaml/yaml.dart';

class ComposeEditorPage extends ConsumerStatefulWidget {
  const ComposeEditorPage({required this.stackName, super.key});

  final String stackName;

  @override
  ConsumerState<ComposeEditorPage> createState() => _ComposeEditorPageState();
}

class _ComposeEditorPageState extends ConsumerState<ComposeEditorPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _composeController = TextEditingController();
  final _envController = TextEditingController();
  late Future<domain.ApiResult<domain.StackDetail>> _detailFuture;
  domain.StackSummary? _summary;
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _detailFuture = _load();
  }

  Future<domain.ApiResult<domain.StackDetail>> _load() async {
    final result = await ref
        .read(dockgeSessionProvider.notifier)
        .getStack(widget.stackName);
    final detail = result.data;
    if (detail != null) {
      _summary = detail.summary;
      _composeController.text = detail.composeYaml;
      _envController.text = detail.composeEnv;
    }
    return result;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _composeController.dispose();
    _envController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FeatureLocalizations.of(context);
    final session = ref.watch(dockgeSessionProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.composeEditor),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.code_rounded, size: 18),
              text: l10n.compose,
            ),
            Tab(
              icon: const Icon(Icons.key_rounded, size: 18),
              text: l10n.environment,
            ),
          ],
        ),
        actions: [
          // 编辑/只读模式切换
          FilterChip(
            selected: _editMode,
            label: Text(_editMode ? l10n.cancel : l10n.edit),
            avatar: Icon(
              _editMode ? Icons.visibility_rounded : Icons.edit_rounded,
              size: 18,
            ),
            onSelected: session.connected
                ? (value) => setState(() => _editMode = value)
                : null,
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: l10n.save,
            onPressed: _editMode ? () => _save(deploy: false) : null,
            icon: const Icon(Icons.save_rounded),
          ),
        ],
      ),
      body: FutureBuilder<domain.ApiResult<domain.StackDetail>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (!session.connected) {
            return EmptyState(
              message: l10n.connectToServerFirst,
              icon: Icons.cloud_off_rounded,
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data;
          if (result == null || !result.ok) {
            return EmptyState(
              message: result?.message ?? l10n.stackLoadFailed,
              icon: Icons.error_outline_rounded,
            );
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _EditorPane(controller: _composeController, readOnly: !_editMode),
              _EditorPane(controller: _envController, readOnly: !_editMode),
            ],
          );
        },
      ),
      // 底部操作栏
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border(
            top: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _editMode ? () => _save(deploy: false) : null,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: Text(l10n.saveCompose),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _editMode ? () => _save(deploy: true) : null,
                    icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                    label: Text(l10n.deployStack),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save({required bool deploy}) async {
    final l10n = FeatureLocalizations.of(context);
    final summary = _summary;
    if (summary == null) {
      return;
    }
    try {
      loadYaml(_composeController.text);
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.yamlInvalid}: $error')));
      return;
    }
    final decision = const OperationSafetyPolicy().decisionFor(
      OperationType.saveCompose,
      widget.stackName,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(decision.title),
        content: Text(decision.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(decision.confirmLabel),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) {
      return;
    }
    final controller = ref.read(dockgeSessionProvider.notifier);
    final result = deploy
        ? await controller.deployStack(
            summary,
            composeYaml: _composeController.text,
            composeEnv: _envController.text,
          )
        : await controller.saveStack(
            summary,
            composeYaml: _composeController.text,
            composeEnv: _envController.text,
          );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? l10n.operationQueued)),
    );
    if (result.ok) {
      setState(() {
        _editMode = false;
        _detailFuture = _load();
      });
    }
  }
}

class _EditorPane extends StatelessWidget {
  const _EditorPane({required this.controller, required this.readOnly});

  final TextEditingController controller;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: controller,
          expands: true,
          maxLines: null,
          minLines: null,
          readOnly: readOnly,
          textAlignVertical: TextAlignVertical.top,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: scheme.onSurface,
          ),
          decoration: InputDecoration(
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}