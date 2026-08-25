@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shipments_presentation_dispatcher/shipments_presentation_dispatcher.dart';

void main() {
  group('ShipmentsDispatcherScreen', () {
    testWidgets('builds', (tester) async {
      await tester.pumpWidget(const ShipmentsDispatcherScreen());

      expect(find.byType(ShipmentsDispatcherScreen), findsOneWidget);
    });
  });
}
