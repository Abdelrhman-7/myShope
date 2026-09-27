import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shope/main.dart';

void main() {
  testWidgets('App initializes without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ElectricalStoreApp(),
      ),
    );

    // Initial pump
    await tester.pump();
    expect(find.byType(ElectricalStoreApp), findsOneWidget);
  });
}
