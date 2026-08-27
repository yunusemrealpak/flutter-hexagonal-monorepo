/// The component library every screen in the product is drawn with.
///
/// Two things leave this package and nothing else: widgets, and the contract
/// an app supplies translated strings through. A presentation package that
/// imports this never sees a `Color`, a `TextStyle` or a number — those are
/// `design_tokens`, and the whole point of the split is that a change of
/// palette is a change to one package rather than to fourteen.
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
export 'src/peyk_list_row.dart';
export 'src/peyk_loading_view.dart';
export 'src/peyk_option_row.dart';
export 'src/peyk_screen.dart';
export 'src/peyk_section.dart';
export 'src/peyk_strings.dart';
export 'src/peyk_text.dart';
export 'src/peyk_text_tone.dart';
export 'src/peyk_theme.dart';
export 'src/peyk_type_style.dart';
export 'src/string_catalogue.dart';
