@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:test/test.dart';

void main() {
  test('every store failure is a kernel Failure', () {
    const failures = <StoreFailure>[
      StoreUnavailable(),
      StoreCorrupted('k'),
      StoreOutOfSpace(),
    ];

    expect(failures, everyElement(isA<Failure>()));
  });

  test('the sealed hierarchy forces a caller to handle every case', () {
    const StoreFailure failure = StoreCorrupted('session');

    // The compiler rejects this switch if a case is added to StoreFailure and
    // not handled here. That is the whole reason the type is sealed.
    final advice = switch (failure) {
      StoreUnavailable() => 'retry later',
      StoreCorrupted(:final key) => 'drop $key and refetch',
      StoreOutOfSpace() => 'free space',
    };

    expect(advice, 'drop session and refetch');
  });

  test('secure store failures are a separate hierarchy on purpose', () {
    const SecureStoreFailure failure = SecureStoreAuthenticationFailed();

    expect(failure, isNot(isA<StoreFailure>()));
    expect(failure, isA<Failure>());
  });
}
