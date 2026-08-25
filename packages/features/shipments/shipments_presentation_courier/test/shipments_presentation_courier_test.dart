@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shipments_presentation_courier/shipments_presentation_courier.dart';

void main() {
  group('ShipmentsCourierScreen', () {
    testWidgets('builds', (tester) async {
      await tester.pumpWidget(const ShipmentsCourierScreen());

      expect(find.byType(ShipmentsCourierScreen), findsOneWidget);
    });
  });
}
