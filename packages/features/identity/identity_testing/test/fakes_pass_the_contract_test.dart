@Tags(['unit'])
library;

import 'package:identity_testing/identity_testing.dart';
import 'package:test/test.dart';

void main() {
  runSessionStoreContract(InMemorySessionStore.new);
}
