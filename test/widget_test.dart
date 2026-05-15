import 'package:dockge_app/src/app/dockge_mobile_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Dockge Mobile renders dashboard by default', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DockgeMobileApp()));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Docker Run converter'), findsOneWidget);
    expect(find.text('Stacks'), findsOneWidget);
  });
}
