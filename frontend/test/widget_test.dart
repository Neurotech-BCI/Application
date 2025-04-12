import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('MainApplication smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MainApplication());
    expect(find.text('NeuroTechUSC BCI Application'), findsOneWidget);
  });
}
