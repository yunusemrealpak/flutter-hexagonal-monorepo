@Tags(['unit'])
library;

import 'package:delivery_presentation/delivery_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeliveryScreen', () {
    testWidgets('builds', (tester) async {
      await tester.pumpWidget(const DeliveryScreen());

      expect(find.byType(DeliveryScreen), findsOneWidget);
    });
  });
}
