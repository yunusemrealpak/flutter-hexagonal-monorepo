@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:test/test.dart';

/// A value object built the way the conventions require: private constructor
/// plus a validating factory that returns a [Result], so an invalid instance
/// cannot be constructed at all.
final class _Barcode extends ValueObject<String> {
  const _Barcode._(super.value);

  static Result<_Barcode, String> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length != 4) {
      return const Failed('expected exactly 4 characters');
    }
    return Success(_Barcode._(trimmed));
  }
}

/// A second wrapper over the same primitive, to show that wrapping is only
/// worth the ceremony when it actually distinguishes the value.
final class _TrackingCode extends ValueObject<String> {
  const _TrackingCode(super.value);
}

void main() {
  group('equality', () {
    test('two value objects wrapping the same value are equal', () {
      expect(const _TrackingCode('ab12'), const _TrackingCode('ab12'));
      expect(
        const _TrackingCode('ab12').hashCode,
        const _TrackingCode('ab12').hashCode,
      );
    });

    test('different values are not equal', () {
      expect(const _TrackingCode('ab12'), isNot(const _TrackingCode('ab13')));
    });

    test('different types wrapping the same value are not equal', () {
      const barcode = _Barcode._('ab12');

      expect(barcode, isNot(const _TrackingCode('ab12')));
    });

    test('behaves in a Set, which is what identity-by-value is for', () {
      final raw = ['ab12', 'ab12', 'ab13'];
      final codes = raw.map(_TrackingCode.new).toSet();

      expect(codes, hasLength(2));
    });
  });

  group('validating factory', () {
    test('returns the value object when the input is valid', () {
      final parsed = _Barcode.parse('  ab12  ');

      expect(parsed, const Success<_Barcode, String>(_Barcode._('ab12')));
    });

    test('returns a failure instead of throwing when the input is invalid', () {
      final parsed = _Barcode.parse('ab');

      expect(parsed.isFailure, isTrue);
      expect(
        parsed.fold((value) => 'unreachable', (failure) => failure),
        'expected exactly 4 characters',
      );
    });
  });

  test('prints as type and value', () {
    expect(const _TrackingCode('ab12').toString(), '_TrackingCode(ab12)');
  });
}
