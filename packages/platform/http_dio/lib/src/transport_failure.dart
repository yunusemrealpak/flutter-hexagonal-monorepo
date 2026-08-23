import 'package:core_kernel/core_kernel.dart';
import 'http_response.dart';

/// Why a request did not produce a usable response.
///
/// The cases are the ones a caller behaves differently about, and no more.
/// A courier app queues work when it is [TransportOffline], retries after
/// [TransportTimeout], gives up on [TransportRejected] with a 4xx and
/// escalates a 5xx — four distinct reactions, so four distinct cases. Dio's
/// own error enumeration has more members than this, and collapsing the ones
/// that lead to the same reaction is the adapter's job rather than the
/// caller's.
sealed class TransportFailure extends Failure {
  /// Const so that a failure can be built in a const context.
  const TransportFailure();
}

/// The request never reached the network.
///
/// No route to the host, DNS did not resolve, the socket was refused. This is
/// the failure `sync` treats as "try again when connectivity returns" rather
/// than "this request is wrong".
final class TransportOffline extends TransportFailure {
  /// Records that the request could not leave the device.
  const TransportOffline({this.detail});

  /// Adapter-supplied context for the log. Never rendered to a user.
  final String? detail;

  @override
  String toString() => 'TransportOffline(${detail ?? 'no detail'})';
}

/// The request left but nothing came back in time.
///
/// Distinct from [TransportOffline] because the server may well have processed
/// it. Anything retried after this failure has to be idempotent, which is why
/// `payments` binds an idempotency key to an intention rather than to an
/// attempt.
final class TransportTimeout extends TransportFailure {
  /// Records that [phase] ran out of time.
  const TransportTimeout(this.phase);

  /// Which part of the exchange timed out.
  final TransportTimeoutPhase phase;

  @override
  String toString() => 'TransportTimeout(${phase.name})';
}

/// Where a [TransportTimeout] happened.
enum TransportTimeoutPhase {
  /// The connection was never established.
  connect,

  /// The request body was not fully sent.
  send,

  /// The response was not fully received.
  receive,
}

/// The server answered, and the answer was not a success status.
///
/// Carries the whole [response] because the body of a 4xx is where an API puts
/// the reason, and the adapter that made the call is the only code that knows
/// how to read it.
final class TransportRejected extends TransportFailure {
  /// Records a non-2xx [response].
  const TransportRejected(this.response);

  /// Everything the server sent back.
  final HttpResponse response;

  /// The status, hoisted because callers branch on it constantly.
  int get statusCode => response.statusCode;

  @override
  String toString() => 'TransportRejected($statusCode)';
}

/// The caller cancelled the request before it completed.
///
/// A normal outcome — a screen was left, a search box was typed in again — and
/// not something to report or retry.
final class TransportCancelled extends TransportFailure {
  /// Records that the request was cancelled.
  const TransportCancelled();

  @override
  String toString() => 'TransportCancelled()';
}

/// The server's certificate was not accepted.
///
/// Its own case rather than a general error because it is the one failure here
/// that may mean someone is intercepting traffic. It must never be retried
/// past, and a build that pins certificates needs to be able to tell it apart.
final class TransportCertificateRejected extends TransportFailure {
  /// Records that the TLS handshake was refused.
  const TransportCertificateRejected();

  @override
  String toString() => 'TransportCertificateRejected()';
}

/// Something went wrong that none of the other cases describes.
///
/// The catch-all exists so that no exception escapes the adapter — invariant
/// 1.2.9 — not so that mapping can be skipped. A [detail] that keeps showing
/// up in logs is a case this hierarchy is missing.
final class TransportUnexpected extends TransportFailure {
  /// Records an unclassified failure, with [detail] for the log.
  const TransportUnexpected({required this.detail});

  /// What the adapter saw. Never rendered to a user.
  final String detail;

  @override
  String toString() => 'TransportUnexpected($detail)';
}
