import 'package:design_tokens/design_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PeykBreakpoint.of', () {
    test('a window at a size boundary is the wider size', () {
      expect(PeykBreakpoint.of(600), PeykBreakpoint.tablet);
      expect(PeykBreakpoint.of(1024), PeykBreakpoint.desktop);
    });

    test('a window one pixel below a boundary is the narrower size', () {
      expect(PeykBreakpoint.of(599), PeykBreakpoint.handset);
      expect(PeykBreakpoint.of(1023), PeykBreakpoint.tablet);
    });

    test('a zero-width window is a handset rather than an error', () {
      expect(PeykBreakpoint.of(0), PeykBreakpoint.handset);
    });

    // Flutter reports a window size of zero while a route is being laid out
    // for the first time, and has been observed reporting a negative one on a
    // desktop window being dragged to nothing. Neither is a size anybody
    // designs for, and neither should be a crash.
    test('a negative width is a handset rather than an error', () {
      expect(PeykBreakpoint.of(-1), PeykBreakpoint.handset);
    });

    test('every declared size is reachable from its own minimum', () {
      for (final size in PeykBreakpoint.values) {
        expect(PeykBreakpoint.of(size.minWidth), size);
      }
    });
  });
}
