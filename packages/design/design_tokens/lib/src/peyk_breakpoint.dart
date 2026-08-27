/// How wide the window is, in the three sizes this product lays out for.
///
/// Three rather than five, because the product has three shapes: a phone in a
/// courier's hand, a tablet on a depot desk, and a dispatcher's browser. A
/// breakpoint nobody designs for is a breakpoint that ships untested.
enum PeykBreakpoint {
  /// Below 600 logical pixels. One column, edge to edge.
  handset(minWidth: 0),

  /// 600 and above. Two columns, or one column with margins.
  tablet(minWidth: 600),

  /// 1024 and above. A list beside a detail.
  desktop(minWidth: 1024);

  const PeykBreakpoint({required this.minWidth});

  /// The narrowest window this size covers, in logical pixels.
  final double minWidth;

  /// Which size a window of [width] logical pixels is.
  ///
  /// Walks the enum backwards so that adding a fourth size is a line in the
  /// declaration rather than a chain of comparisons somebody has to keep
  /// ordered.
  static PeykBreakpoint of(double width) {
    for (final size in values.reversed) {
      if (width >= size.minWidth) {
        return size;
      }
    }
    return handset;
  }
}
