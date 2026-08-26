@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:routing_presentation/routing_presentation.dart';

void main() {
  group('RoutingScreen', () {
    testWidgets('builds', (tester) async {
      await tester.pumpWidget(const RoutingScreen());

      expect(find.byType(RoutingScreen), findsOneWidget);
    });
  });
}
