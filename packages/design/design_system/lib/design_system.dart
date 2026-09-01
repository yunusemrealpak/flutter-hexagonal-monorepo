/// The component library every screen in the product is drawn with.
///
/// Three things leave this package: widgets, the vocabulary for asking them
/// for something — `PeykIntent`, `PeykGapSize`, `PeykTextTone` — and the
/// contract an app supplies translated strings through. A presentation package
/// that imports this never sees a `Color`, a `TextStyle` or a number.
///
/// **The vocabulary is declared here rather than re-exported from
/// `design_tokens`, and that is the constitution's doing.** Rule S4 forbids a
/// barrel from re-exporting another package's URI, and section 2 does not put
/// `design_tokens` on the presentation row — so a type a caller must be able
/// to name has to be declared here. It is the right split independently: the
/// tokens package holds five colour triples and seven spacing values, and
/// *which one a situation calls for* is a question about this package's API.
///
/// That is also why `PeykGap` takes a `PeykGapSize` rather than a number, and
/// why the sizes are named for what the distance means. Seven values and a
/// screen picking among them by eye is how two screens stop lining up.
///
/// Material is an implementation detail of this package. `Scaffold`, `InkWell`
/// and `ThemeData` appear inside `lib/src/`; no presentation package imports
/// `package:flutter/material.dart` anywhere, which is what would have to
/// change first if this product ever stopped being a Material one.
library;

export 'src/key_echo_catalogue.dart';
export 'src/l10n/peyk_system_localizations.dart';
export 'src/peyk_badge.dart';
export 'src/peyk_button.dart';
export 'src/peyk_button_tone.dart';
export 'src/peyk_chip.dart';
export 'src/peyk_empty_view.dart';
export 'src/peyk_failure_view.dart';
export 'src/peyk_gap.dart';
export 'src/peyk_gap_size.dart';
export 'src/peyk_icon.dart';
export 'src/peyk_intent.dart';
export 'src/peyk_list_row.dart';
export 'src/peyk_loading_view.dart';
export 'src/peyk_navigation_bar.dart';
export 'src/peyk_navigation_destination.dart';
export 'src/peyk_option_row.dart';
export 'src/peyk_screen.dart';
export 'src/peyk_section.dart';
export 'src/peyk_strings.dart';
export 'src/peyk_switch_row.dart';
export 'src/peyk_text.dart';
export 'src/peyk_text_field.dart';
export 'src/peyk_text_tone.dart';
export 'src/peyk_theme.dart';
export 'src/string_catalogue.dart';
