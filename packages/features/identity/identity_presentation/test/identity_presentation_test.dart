@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:identity_presentation/identity_presentation.dart';

void main() {
  group('IdentityScreen', () {
    testWidgets('builds', (tester) async {
      await tester.pumpWidget(const IdentityScreen());

      expect(find.byType(IdentityScreen), findsOneWidget);
    });
  });
}
