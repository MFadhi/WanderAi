import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wander_ai/main.dart';

void main() {
  testWidgets('WanderApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WanderApp(),
      ),
    );
    expect(find.byType(WanderApp), findsOneWidget);
  });
}
