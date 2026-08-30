@Tags(['widget'])
library;

import 'dart:async';

import 'package:app_harness/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late StreamController<Object?> sessions;
  late SessionRefresh refresh;
  late int notifications;
  late bool disposed;

  // A ChangeNotifier refuses a second dispose, and one test disposes on
  // purpose. The latch is what lets the teardown stay unconditional.
  void disposeOnce() {
    if (disposed) return;
    refresh.dispose();
    disposed = true;
  }

  setUp(() {
    sessions = StreamController<Object?>.broadcast();
    notifications = 0;
    disposed = false;
    refresh = SessionRefresh(sessions.stream)
      ..addListener(() => notifications++);
  });

  tearDown(() async {
    disposeOnce();
    await sessions.close();
  });

  test('notifies once per change', () async {
    sessions
      ..add('signed in')
      ..add(null);
    await pumpEventQueue();

    expect(notifications, 2);
  });

  // The value is deliberately thrown away: the guard reads
  // SessionReader.current when it runs, and passing the session through here
  // would give the router a second copy of a fact identity owns.
  test('notifies on a null as loudly as on a session', () async {
    sessions.add(null);
    await pumpEventQueue();

    expect(notifications, 1);
  });

  test('stops listening once disposed', () async {
    disposeOnce();
    sessions.add('signed in');
    await pumpEventQueue();

    expect(notifications, isZero);
  });
}
