@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:delivery_infrastructure/delivery_infrastructure.dart';
import 'package:delivery_testing/delivery_testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_dio/http_dio.dart';

/// A stand-in for the operation's proof service.
///
/// `FakeHttpTransport` answers from a queue, which is right for a test that
/// scripts one exchange and wrong for a contract kit: the kit stores, then
/// reads back what it stored, and the second answer depends on the first. So
/// this transport keeps a map — it is a fake *server*, not a fake adapter, and
/// `RemoteProofStore` is the thing under test either way.
final class _ProofServer implements HttpTransport {
  final Map<String, Object?> _stored = {};
  var _minted = 0;

  @override
  Future<Result<HttpResponse, TransportFailure>> send(
    HttpRequest request,
  ) async {
    if (request.method == HttpMethod.post) {
      _minted++;
      // A reference in the server's own shape, deliberately unlike the local
      // store's. The kit asserts nothing about the format, which is the point.
      final reference = 'srv_${_minted.toRadixString(16)}';
      _stored[reference] = request.body;
      return Success(
        HttpResponse(statusCode: 201, body: {'reference': reference}),
      );
    }

    final reference = request.path.split('/').last;
    final body = _stored[reference];
    if (body == null) {
      return const Failed(
        TransportRejected(HttpResponse(statusCode: 404)),
      );
    }
    return Success(HttpResponse(statusCode: 200, body: body));
  }
}

void main() {
  // One description, three answers. `FakeProofStore` runs it in
  // `delivery_testing`; these two are the adapters an app actually binds, and
  // the fact that nothing in the kit had to change for either of them is what
  // makes the port swappable at the composition root.
  group('LocalEncryptedProofStore', () {
    runProofStoreContract(
      () => LocalEncryptedProofStore(store: InMemoryKeyValueStore()),
    );
  });

  group('RemoteProofStore', () {
    runProofStoreContract(() => RemoteProofStore(transport: _ProofServer()));
  });
}
