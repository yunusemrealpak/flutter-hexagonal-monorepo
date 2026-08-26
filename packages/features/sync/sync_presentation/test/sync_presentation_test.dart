@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sync_presentation/sync_presentation.dart';

void main() {
  group('SyncScreen', () {
    testWidgets('builds', (tester) async {
      await tester.pumpWidget(const SyncScreen());

      expect(find.byType(SyncScreen), findsOneWidget);
    });
  });
}
