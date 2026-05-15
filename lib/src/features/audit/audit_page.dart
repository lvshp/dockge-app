import 'package:dockge_app/src/features/common/feature_localizations.dart';
import 'package:dockge_app/src/features/common/feature_widgets.dart';
import 'package:flutter/material.dart';

class AuditPage extends StatelessWidget {
  const AuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = FeatureLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.auditTrail)),
      body: EmptyState(
        message: l10n.noLocalOperations,
        icon: Icons.history_rounded,
        title: l10n.auditTrail,
      ),
    );
  }
}