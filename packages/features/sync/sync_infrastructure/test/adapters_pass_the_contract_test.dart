@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:drift/native.dart';
import 'package:http_dio/http_dio.dart';
import 'package:storage_drift/storage_drift.dart' as db;
import 'package:sync_api/sync_api.dart';
import 'package:sync_infrastructure/sync_infrastructure.dart';
import 'package:sync_testing/sync_testing.dart';
import 'package:test/test.dart';

/// Keeps the databases alive for as long as the suite that opened them.
///
/// The contract kit calls its factory once per test and never gets a chance to
/// close anything, so the closing happens here. An in-memory database that is
/// never closed is a native handle leaked per test, and a suite of thirty is
/// where that starts to matter.
final _databases = <db.PeykDatabase>[];

DriftOutboxStore _createStore() {
  final database = db.PeykDatabase(NativeDatabase.memory());
  _databases.add(database);
  return DriftOutboxStore(
    entries: db.OutboxDao(database),
    values: db.KeyValueDao(database),
    clock: FakeClock(),
  );
}

/// A server that honours the `Idempotency-Key` it is sent.
///
/// `FakeHttpTransport` is not used here, and the reason is worth stating: it is
/// a *queue* of scripted answers, which is the right shape for testing a
/// mapping and the wrong shape for testing idempotency. The assertion the
/// transport contract exists for — the same envelope twice is one piece of
/// work — needs a stand-in that actually remembers, and the smallest honest
/// one is nine lines.
final class _IdempotentServer implements HttpTransport {
  final Map<String, String> _accepted = {};
  int _issued = 0;

  /// How many distinct pieces of work the server ended up holding.
  int get accepted => _accepted.length;

  @override
  Future<Result<HttpResponse, TransportFailure>> send(
    HttpRequest request,
  ) async {
    final id = request.headers['Idempotency-Key']!;
    final cursor = _accepted[id] ??= 'c-${++_issued}';
    return Success(
      HttpResponse(statusCode: 200, body: <String, dynamic>{'cursor': cursor}),
    );
  }
}

final _servers = <CommandTransportPort, _IdempotentServer>{};

CommandTransportPort _createTransport() {
  final server = _IdempotentServer();
  final transport = HttpCommandTransport(transport: server);
  _servers[transport] = server;
  return transport;
}

void main() {
  tearDownAll(() async {
    for (final database in _databases) {
      await database.close();
    }
  });

  // One suite, two implementations. The in-memory store in `sync_testing` runs
  // it too, and `app_dispatcher` ships that one as a product adapter — so
  // "what the fake does" and "what the real one does" being the same sentence
  // is not a nicety here. It is the difference between two applications
  // behaving alike.
  runOutboxStoreContract(_createStore);

  runCommandTransportContract(
    _createTransport,
    acceptedCount: (transport) => _servers[transport]!.accepted,
  );
}
