@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:payments_presentation/payments_presentation.dart';

void main() {
  group('PaymentsScreen', () {
    testWidgets('builds', (tester) async {
      await tester.pumpWidget(const PaymentsScreen());

      expect(find.byType(PaymentsScreen), findsOneWidget);
    });
  });
}
