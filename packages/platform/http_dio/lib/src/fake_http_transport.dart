import 'dart:collection';

import 'package:core_kernel/core_kernel.dart';
import 'http_request.dart';
import 'http_response.dart';
import 'http_transport.dart';
import 'transport_failure.dart';

/// A programmable [HttpTransport] that never touches a socket.
///
/// This is why rule 7.4 of the test strategy — no test uses the real network —
/// costs nothing to obey. Every `_infrastructure` package's tests construct
/// their adapter with one of these, queue what the server would have said, and
/// assert on both the request that was built and the domain value that came
/// back.
///
/// It ships from this package rather than from `core_testing` because it
/// stands in for a contract this package declares, and a fake belongs with the
/// contract it imitates. It is exported from the barrel, so a production
/// package could import it; the barrier against that is review, not
/// visibility, and the same is true of every fake in the workspace.
///
/// Responses are a queue rather than a single value so that a test can drive a
/// retry: enqueue a timeout, then a success, and assert that the adapter
/// retried once and returned the second answer.
final class FakeHttpTransport implements HttpTransport {
  final Queue<Result<HttpResponse, TransportFailure>> _queued = Queue();
  final List<HttpRequest> _requests = [];

  /// Every request sent so far, oldest first.
  List<HttpRequest> get requests => List.unmodifiable(_requests);

  /// The most recent request, or `null` when nothing has been sent.
  HttpRequest? get lastRequest => _requests.isEmpty ? null : _requests.last;

  /// Makes the next [send] return [response] as a success.
  void enqueueResponse(HttpResponse response) => _queued.add(Success(response));

  /// Makes the next [send] return a 2xx carrying [body].
  ///
  /// The common case, spelled short so that a test about mapping does not read
  /// as a test about HTTP.
  void enqueueJson(Object? body, {int statusCode = 200}) =>
      enqueueResponse(HttpResponse(statusCode: statusCode, body: body));

  /// Makes the next [send] return [failure].
  void enqueueFailure(TransportFailure failure) => _queued.add(Failed(failure));

  /// Forgets the recorded requests and anything still queued.
  void reset() {
    _queued.clear();
    _requests.clear();
  }

  @override
  Future<Result<HttpResponse, TransportFailure>> send(
    HttpRequest request,
  ) async {
    _requests.add(request);
    if (_queued.isEmpty) {
      // Failing rather than throwing keeps the fake honest to the contract it
      // implements: this port does not throw, not even when it is misused. The
      // detail says what the test forgot, which is the only thing that makes
      // this branch useful.
      return Failed(
        TransportUnexpected(
          detail: 'FakeHttpTransport had nothing queued for $request',
        ),
      );
    }
    return _queued.removeFirst();
  }
}
