/// The bloc observer, and the one decision in it.
///
/// `Bloc.observer` is a single global hook every bloc in a process reports to.
/// What reaches it is a `Transition` carrying the event and both states — and
/// in this product those states hold a session with somebody's name, a
/// consignee's address, a signature and a delivery proof. So this observer
/// records **types and never values**: which bloc, which event, which state it
/// moved from and to. A log aggregator is the easiest place for other people's
/// data to leave a courier platform, and `Transition.toString()` is the
/// shortest path there.
///
/// The reason to install one at all is `onError`. A handler that throws is
/// caught by bloc and turned into nothing: the state does not change, no
/// exception reaches the zone, and a screen simply stops responding. Without
/// an observer that failure has no witness anywhere in the process.
library;

export 'src/peyk_bloc_observer.dart';
