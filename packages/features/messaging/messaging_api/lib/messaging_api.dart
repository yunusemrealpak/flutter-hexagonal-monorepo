/// The messaging contract: a thread between a courier and the operation, what
/// counts as read, and the two ports that carry it.
///
/// **Three instants on a message, and each answers a different question.**
/// Written, sent, read. A message written in a tunnel has the first and not
/// the second; a thread sorted by `sentAt` would reorder itself when the
/// signal came back and put a courier's question after its answer.
///
/// **The queue is the store, not a second list.** A message is written locally
/// and sent afterwards, so what is queued is simply what is stored and not yet
/// sent. A separate outbox would be a second list to keep in step with the
/// thread on screen, and the two would disagree the first time a send failed
/// halfway.
///
/// **`ThreadId` is derived and `MessageId` is minted.** Two devices have to
/// agree on which conversation they are in without asking anybody, and the
/// same device has to be able to name a message before any server has seen it.
/// The same split as `SettlementId` and `IdempotencyKey` in payments, for the
/// same reasons.
library;

export 'src/entities/message.dart';
export 'src/failures/messaging_failure.dart';
export 'src/ports/driven/message_store.dart';
export 'src/ports/driven/message_transport.dart';
export 'src/ports/driving/messaging_facade.dart';
export 'src/values/message_id.dart';
export 'src/values/thread_id.dart';
