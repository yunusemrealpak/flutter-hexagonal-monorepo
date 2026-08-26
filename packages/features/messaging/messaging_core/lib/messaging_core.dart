/// The messaging use cases, the thread store that doubles as the offline
/// queue, and the transport that drains it.
///
/// **Messaging keeps its own queue instead of using `sync`'s outbox, and the
/// difference is worth knowing.** `sync` carries opaque payloads that a
/// feature wants delivered once and then forgotten — a completed delivery, a
/// collection. A queued message is none of those things: it is *content a
/// person sees*, it has to appear in the thread in the order it was written,
/// and somebody may well delete it before it ever goes. Putting it in a
/// generic outbox would mean two lists to keep in step — the thread on screen
/// and the payload in the queue — and they would disagree the first time a
/// send failed halfway.
///
/// The test, for the next feature that has to choose: if a person can see the
/// queued thing, it belongs beside the thing they can see. If it is a write
/// nobody looks at again, it belongs in `sync`.
///
/// **A refusal and a deferral are different failures**, and every layer of
/// this package turns on it. `HttpMessageTransport` sorts a 4xx from a 5xx;
/// `DeliverMessage` logs the refusal and leaves the message queued;
/// `DrainQueue` stops on a deferral and steps over a refusal. Collapse the two
/// and you get either an outbox that gives up in a tunnel or one that retries
/// a closed thread for ever.
///
/// The halves:
///
/// - `SendMessage`, `ReadThread`, `MarkThreadRead`, `DrainQueue`,
///   `DeliverMessage` and `MessagingCoordinator` are the application half.
/// - `KeyValueMessageStore`, `HttpMessageTransport` and `MessageDto` are the
///   infrastructure half. They import no use case, and no use case imports
///   them.
library;

export 'src/deliver_message.dart';
export 'src/drain_queue.dart';
export 'src/http_message_transport.dart';
export 'src/key_value_message_store.dart';
export 'src/mark_thread_read.dart';
export 'src/message_dto.dart';
export 'src/messaging_coordinator.dart';
export 'src/read_thread.dart';
export 'src/send_message.dart';
