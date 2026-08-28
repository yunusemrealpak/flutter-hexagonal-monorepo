@Tags(['widget'])
library;

import 'package:app_harness/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:identity_presentation/identity_presentation.dart';

/// The acceptance criterion in one test: the app comes up.
///
/// Everything else in this directory checks a part — the container resolves,
/// the router assembles, the keys are answered. This one puts the three
/// together and pumps the result, which is the only way to find out that a
/// screen a container can build is a screen a widget tree can hold.
void main() {
  late GetIt container;

  setUp(() => container = configureHarness());
  tearDown(() => container.reset());

  testWidgets('stands up and lands on sign-in with nobody signed in', (
    tester,
  ) async {
    await tester.pumpWidget(
      HarnessApp(router: buildHarnessRouter(container).build()),
    );
    await tester.pumpAndSettle();

    // The guard sent it here: the initial location is the courier manifest,
    // which requires a session, and no session has been created.
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('draws keys rather than sentences', (tester) async {
    await tester.pumpWidget(
      HarnessApp(router: buildHarnessRouter(container).build()),
    );
    await tester.pumpAndSettle();

    // The whole reason this app uses KeyEchoCatalogue. A label wired to the
    // wrong key is visible here and invisible in an app with real sentences.
    expect(find.text(IdentityStrings.signInTitle), findsOneWidget);
    expect(find.text(IdentityStrings.signInIdle), findsOneWidget);
  });
}
