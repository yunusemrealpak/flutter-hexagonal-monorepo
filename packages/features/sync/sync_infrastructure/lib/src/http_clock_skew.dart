import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:http_dio/http_dio.dart';
import 'package:sync_api/sync_api.dart';

import 'sync_envelope_dto.dart';

/// Answers `ClockSkewPort` by asking the server what time it thinks it is.
///
/// The subtraction is `server - device`, so a positive value means the server
/// is ahead. `Clock` supplies the device's reading — rule A1 applies here as
/// much as anywhere, and more visibly: a port whose whole job is to compare
/// two clocks cannot be allowed to read one of them ambiently.
///
/// **The measurement is deliberately naive.** A correct implementation would
/// halve the round-trip time and subtract it, the way NTP does, because the
/// server's answer describes an instant that has already passed by the time it
/// arrives. It is left out because the product needs skew accurate to about a
/// second — enough to stop a device whose clock is an hour out from winning
/// every last-write-wins contest — and a hundred milliseconds of round trip
/// does not affect that. Writing the halving here without needing it would
/// suggest a precision this feature does not have.
///
/// The result is cached for [ttl]. Asking on every drain would put a request
/// in front of every batch of work, which is a strange thing to do on a device
/// whose defining problem is that requests are expensive.
final class HttpClockSkew implements ClockSkewPort {
  /// Creates the adapter over [transport].
  HttpClockSkew({
    required this.transport,
    required this.clock,
    this.path = '/time',
    this.ttl = const Duration(minutes: 15),
  });

  /// The transport the question is asked on.
  final HttpTransport transport;

  /// The device's own clock.
  final Clock clock;

  /// Where the server reports its time.
  final String path;

  /// How long an answer stays good for.
  final Duration ttl;

  Duration? _cached;
  DateTime? _measuredAt;

  @override
  Future<Result<Duration, SyncFailure>> skew() async {
    final cached = _cached;
    final measuredAt = _measuredAt;
    if (cached != null &&
        measuredAt != null &&
        clock.now().difference(measuredAt) < ttl) {
      return Success(cached);
    }

    final response = await transport.send(
      HttpRequest(method: HttpMethod.get, path: path),
    );

    return switch (response) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success(value: final ok) => _read(ok.body),
    };
  }

  Result<Duration, SyncFailure> _read(Object? body) {
    if (body is! Map<String, dynamic>) {
      return const Failed(
        MalformedEntry(field: 'body', reason: 'is not a JSON object'),
      );
    }

    final raw = ServerTimeDto.fromJson(body).now;
    if (raw == null) {
      return const Failed(MalformedEntry(field: 'now', reason: 'is missing'));
    }

    // The one place this class catches. A server that sends an unparseable
    // instant is the far side's mistake, and the alternative to catching is
    // letting a FormatException cross a port boundary — which invariant 1.2.9
    // forbids and which would reach a drain that has no way to handle it.
    final DateTime serverNow;
    try {
      serverNow = DateTime.parse(raw).toUtc();
    } on FormatException {
      return Failed(
        MalformedEntry(field: 'now', reason: 'is not an instant: $raw'),
      );
    }

    final skew = serverNow.difference(clock.now().toUtc());
    _cached = skew;
    _measuredAt = clock.now();
    return Success(skew);
  }

  /// Every transport failure means the same thing here: the device could not
  /// ask.
  ///
  /// Unlike `HttpCommandTransport`, this port has no permanent failures worth
  /// distinguishing — a caller that cannot learn the skew proceeds without a
  /// correction, whatever the reason. Inventing cases nobody branches on is
  /// how a sealed union stops being worth matching over.
  static SyncFailure _translate(TransportFailure failure) => switch (failure) {
    TransportOffline() => const SyncOffline(),
    _ => SyncTransportFailed(detail: failure.toString()),
  };
}
