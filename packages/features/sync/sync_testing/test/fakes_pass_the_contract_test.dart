@Tags(['unit'])
library;

import 'package:sync_testing/sync_testing.dart';
import 'package:test/test.dart';

void main() {
  // The fakes run their own contract kits. That is not circular: the kit
  // describes the port, and running it here proves the fake satisfies the
  // description before anything trusts it. `sync_infrastructure` runs the same
  // two suites against the drift-backed store and the HTTP transport, and it
  // is having *one* description that stops the two sides drifting apart.
  runOutboxStoreContract(InMemoryOutboxStore.new);

  runCommandTransportContract(
    FakeCommandTransport.new,
    acceptedCount: (transport) => (transport as FakeCommandTransport).accepted,
  );
}
