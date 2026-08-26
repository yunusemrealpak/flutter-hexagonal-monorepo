import 'package:core_testing/core_testing.dart';
import 'package:messaging_core/messaging_core.dart';
import 'package:messaging_testing/messaging_testing.dart';

void main() {
  // The same kit that runs against `InMemoryMessageStore` in
  // `messaging_testing`. Two implementations of one port, held to one
  // behaviour — including the ordering, which is the half an adapter gets
  // wrong by returning whatever the map iterated.
  runMessageStoreContract(
    () => KeyValueMessageStore(store: InMemoryKeyValueStore()),
  );
}
