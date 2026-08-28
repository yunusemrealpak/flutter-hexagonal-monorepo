@Tags(['widget'])
library;

import 'package:app_courier/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:identity_presentation/identity_presentation.dart';

import 'support/test_platform.dart';

/// The app comes up, and it comes up speaking.
///
/// `app_harness`'s equivalent asserts that a screen draws its *key*. This one
/// asserts the opposite — that a sentence arrives — because that is the
/// difference between the two apps and the only way to find out that 163
/// translations are wired to the screens that ask for them.
void main() {
  late GetIt container;

  setUp(() async => container = await configureCourier(testPlatform()));
  tearDown(() => container.reset());

  testWidgets('stands up and lands on sign-in with nobody signed in', (
    tester,
  ) async {
    await tester.pumpWidget(
      CourierApp(router: buildCourierRouter(container).build()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('draws sentences, not keys', (tester) async {
    await tester.pumpWidget(
      CourierApp(router: buildCourierRouter(container).build()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Sign in to start your round.'), findsOneWidget);
    expect(find.text(IdentityStrings.signInTitle), findsNothing);
  });

  testWidgets('speaks Turkish when the device does', (tester) async {
    // Two apps, two sets of words, one set of keys — and the locale is a third
    // axis over both. Nothing in identity_presentation changed for any of them.
    tester.platformDispatcher.localesTestValue = const [Locale('tr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      CourierApp(router: buildCourierRouter(container).build()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Giriş yap'), findsOneWidget);
    expect(find.text('Turuna başlamak için giriş yap.'), findsOneWidget);
  });
}
