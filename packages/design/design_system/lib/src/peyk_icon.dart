import 'package:flutter/material.dart';

/// The pictures this component library can draw, named for what they depict.
///
/// The same inversion `PeykIntent` performs, applied to iconography. A caller
/// asks for a picture of a list; it does not pass an `IconData`, because an
/// `IconData` is a Material value and the point of this package is that no
/// caller of it names one.
///
/// **Named for the picture, not for the product.** `list` rather than `stops`,
/// `map` rather than `route`: what a courier's second tab means is
/// `app_courier`'s answer, and a design system that spelled it would be a
/// design system that has to change when the tab is renamed. The same reason
/// `PeykIntent` is not called `delivered`.
///
/// The set is small on purpose. An enum with one value per Material icon would
/// be a worse spelling of `Icons`; each entry here is a picture some screen in
/// this product actually asks for.
enum PeykIcon {
  /// A stack of lines. Something enumerable.
  list,

  /// A folded map. Somewhere geographic.
  map,

  /// A tray. Something that arrives and is read.
  inbox,

  /// Three dots. Whatever did not fit.
  more,
}

/// Turns a [PeykIcon] into the glyph that draws it.
extension PeykIconGlyph on PeykIcon {
  /// The Material icon for this picture.
  ///
  /// A `switch` over the enum rather than a map, so that adding a value stops
  /// this file compiling instead of returning null at the bottom of a bar.
  IconData get glyph => switch (this) {
    PeykIcon.list => Icons.list_alt_outlined,
    PeykIcon.map => Icons.map_outlined,
    PeykIcon.inbox => Icons.inbox_outlined,
    PeykIcon.more => Icons.more_horiz,
  };
}
