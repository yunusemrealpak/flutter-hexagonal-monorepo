import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core_ports/core_ports.dart';
import 'package:observability_bloc/observability_bloc.dart';
import 'package:test/test.dart';

/// One record the observer wrote.
final class _Record {
  _Record(this.level, this.message, this.context, this.error);

  final LogLevel level;
  final String message;
  final Map<String, Object?> context;
  final Object? error;

  /// Everything this record would put in front of a person, as one string.
  ///
  /// What the leak test asserts on. A record that carried a state's contents
  /// in any field — the message, a context value, the error — would show up
  /// here, which is the point: the assertion is about the record rather than
  /// about the one field the implementation happens to use today.
  @override
  String toString() => '$level $message $context $error';
}

/// A `Logger` that keeps what it was handed.
///
/// Written here rather than taken from `core_testing`, which section 2 does
/// not give a platform package. Six lines is the right price for the rule
/// holding.
final class _Logger implements Logger {
  final List<_Record> records = [];

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) => records.add(_Record(level, message, context, error));
}

sealed class _Event {
  const _Event();
}

final class _Asked extends _Event {
  const _Asked();
}

final class _Refused extends _Event {
  const _Refused();
}

/// A state holding something a person owns, which is the whole hazard.
final class _Signed {
  const _Signed(this.recipient);

  final String recipient;

  @override
  String toString() => '_Signed($recipient)';
}

final class _Probe extends Bloc<_Event, _Signed> {
  _Probe() : super(const _Signed('nobody')) {
    on<_Asked>((event, emit) => emit(const _Signed('Ayse Yilmaz')));
    on<_Refused>((event, emit) => throw StateError('the handler gave up'));
  }
}

/// Puts the global back where the next test file expects it.
final class _Silent extends BlocObserver {}

void main() {
  late _Logger logger;

  setUp(() {
    logger = _Logger();
    Bloc.observer = PeykBlocObserver(logger: logger);
  });

  tearDown(() => Bloc.observer = _Silent());

  test('a transition is four type names and nothing else', () async {
    final bloc = _Probe()..add(const _Asked());
    await pumpEventQueue();
    await bloc.close();

    final transition = logger.records.singleWhere(
      (record) => record.message == 'bloc transition',
    );
    expect(transition.level, LogLevel.debug);
    expect(transition.context, {
      'bloc': '_Probe',
      'event': '_Asked',
      'from': '_Signed',
      'to': '_Signed',
    });
  });

  test('nothing a state holds reaches the record', () async {
    // The reason every field is a type name. `Transition.toString()` prints
    // both states in full, and in this product that is a session with
    // somebody's name, a consignee's address, a captured signature — in a log
    // aggregator, which is the easiest place for other people's data to leave
    // a courier platform.
    final bloc = _Probe()..add(const _Asked());
    await pumpEventQueue();
    await bloc.close();

    expect(logger.records, isNotEmpty);
    for (final record in logger.records) {
      expect(record.toString(), isNot(contains('Ayse Yilmaz')));
    }
  });

  test('one record per emission, not two', () async {
    // Every bloc emission produces a change *and* a transition. Overriding
    // both would double every line, and the shorter of the two carries less:
    // a change does not name the event that caused it.
    final bloc = _Probe()..add(const _Asked());
    await pumpEventQueue();
    await bloc.close();

    expect(
      logger.records.where((record) => record.message == 'bloc transition'),
      hasLength(1),
    );
  });

  test('a handler that throws leaves a record', () async {
    // Why an observer is installed at all. Bloc catches it: the state does not
    // change, and without this the failure has no witness anywhere in the
    // process — a screen just stops responding.
    // Built inside the zone on purpose: a bloc runs its handlers in the zone
    // it was created in, so an error from one raised outside this call would
    // escape the guard and fail the test rather than being caught by it.
    late final _Probe bloc;
    await runZonedGuarded(() async {
      bloc = _Probe()..add(const _Refused());
      await pumpEventQueue();
    }, (error, stackTrace) {});
    await bloc.close();

    final failure = logger.records.singleWhere(
      (record) => record.message == 'bloc failed',
    );
    expect(failure.level, LogLevel.error);
    expect(failure.error, isA<StateError>());
    expect(failure.context, {'bloc': '_Probe'});
  });

  test('a bloc that is opened and never closed is visible', () async {
    // The pair is what makes it useful: a create with no close, repeated, is
    // a provider handing out blocs somebody forgot to dispose.
    final bloc = _Probe();
    await bloc.close();

    expect(
      logger.records.map((record) => record.message),
      containsAllInOrder(['bloc created', 'bloc closed']),
    );
  });
}
