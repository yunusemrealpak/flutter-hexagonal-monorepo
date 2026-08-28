@Tags(['widget'])
library;

import 'package:app_dispatcher/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:identity_presentation/identity_presentation.dart';

import 'support/test_platform.dart';

/// The app comes up, and it comes up speaking.
///
/// `app_harness`'s equivalent asserts that a screen draws its *key*. This one
/// asserts that a sentence arrives, and that it is *this* app's sentence: the
/// same key, `identity.signIn.idle`, reads "Sign in to start your round" on a
/// phone and "Sign in to open the board" here. Two audiences, one key, and
/// `identity_presentation` unchanged for both.
void main() {
  late GetIt container;

  setUp(() async => container = await configureDispatcher(testPlatform()));
  tearDown(() => container.reset());

  testWidgets('stands up and lands on sign-in with nobody signed in', (
    tester,
  ) async {
    await tester.pumpWidget(
      DispatcherApp(router: buildDispatcherRouter(container).build()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('draws sentences, not keys', (tester) async {
    await tester.pumpWidget(
      DispatcherApp(router: buildDispatcherRouter(container).build()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Sign in to open the board.'), findsOneWidget);
    expect(find.text(IdentityStrings.signInTitle), findsNothing);
  });

  testWidgets('speaks Turkish when the device does', (tester) async {
    // Two apps, two sets of words, one set of keys — and the locale is a third
    // axis over both. Nothing in identity_presentation changed for any of them.
    tester.platformDispatcher.localesTestValue = const [Locale('tr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      DispatcherApp(router: buildDispatcherRouter(container).build()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Giriş yap'), findsOneWidget);
    expect(find.text('Panoyu açmak için giriş yap.'), findsOneWidget);
  });
}
