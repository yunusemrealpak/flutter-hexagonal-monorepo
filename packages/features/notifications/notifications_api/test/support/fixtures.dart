import 'package:core_kernel/core_kernel.dart';
import 'package:notifications_api/notifications_api.dart';

/// A fixed instant, so that no test in this package needs a clock.
final DateTime arrived = DateTime.utc(2026, 3, 4, 9, 30);

/// Reads an identifier, or fails the test by throwing on an invalid fixture.
NotificationId id(String raw) =>
    (NotificationId.parse(raw) as Success<NotificationId, NotificationsFailure>)
        .value;

/// The entry every test starts from.
InboxEntry unread({String withId = 'msg-1'}) =>
    (InboxEntry.arriving(
              id: id(withId),
              kind: NotificationKind.assignment,
              subject: 'inbox.assignment',
              receivedAt: arrived,
              arguments: const {'shipment': 'SHP-42'},
            )
            as Success<InboxEntry, NotificationsFailure>)
        .value;
