import 'package:bloc/bloc.dart';
import 'package:core_ports/core_ports.dart';

/// Records what every bloc in the process did, through the [Logger] port.
///
/// **Types, never values.** Each record carries the bloc's type, the event's
/// type and the two state types — and nothing that came out of a state object.
/// `Transition.toString()` prints the states in full, and in this product that
/// is a session with somebody's name, a consignee's address, a captured
/// signature. The port's own documentation says a log line is not a place for
/// anything a person should not see in an aggregator; a state machine's
/// contents are exactly that.
///
/// **[onTransition] and not [onChange].** Every bloc emission produces both: a
/// change, and a transition that also names the event that caused it. Logging
/// both would double every line and the shorter of the two carries less. A
/// `Cubit` emits changes with no transition and would go unrecorded here,
/// which is a gap this workspace does not have — nothing in it is a cubit.
///
/// **[onError] is why this exists.** A handler that throws is caught by bloc:
/// the state does not change, nothing reaches the zone's error handler, and a
/// screen stops responding with no evidence anywhere. `super.onError` still
/// runs, so a `BlocObserver` composed after this one — or bloc's own
/// rethrowing in tests — behaves as it did.
///
/// **Installed once, in a composition root.** `Bloc.observer` is a static
/// setter, which is a global by any other name; §1.2.7 of the constitution
/// puts globals in the app layer and nowhere else. A package that set it
/// would be reaching past every app that composed it.
final class PeykBlocObserver extends BlocObserver {
  /// Creates the observer over the [Logger] an app composed.
  const PeykBlocObserver({required this._logger});

  final Logger _logger;

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    _logger.debug('bloc created', context: {'bloc': _nameOf(bloc)});
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    _logger.debug(
      'bloc transition',
      context: {
        'bloc': _nameOf(bloc),
        'event': _nameOf(transition.event),
        'from': _nameOf(transition.currentState),
        'to': _nameOf(transition.nextState),
      },
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _logger.error(
      'bloc failed',
      error: error,
      stackTrace: stackTrace,
      context: {'bloc': _nameOf(bloc)},
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    _logger.debug('bloc closed', context: {'bloc': _nameOf(bloc)});
  }

  /// The one thing this observer is allowed to read off an object.
  ///
  /// A function rather than four inline `runtimeType.toString()` calls, so
  /// that there is a single place where somebody adding a field would have to
  /// decide to record a value — and one place for a reviewer to look.
  static String _nameOf(Object? subject) => subject.runtimeType.toString();
}
