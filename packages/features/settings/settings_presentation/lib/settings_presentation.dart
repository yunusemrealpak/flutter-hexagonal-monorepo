/// The settings UI.
///
/// One screen, one controller and one route module. What is worth reading here
/// is what the package does *not* contain:
///
/// **No use case and no adapter.** `SettingsController` holds `SettingsFacade`
/// and nothing else. Which implementation answers it is decided by whichever
/// app composed the screen, and this package could not name `settings_core` if
/// it wanted to — section 2 does not give this row that edge.
///
/// **No clock, and no `PermissionRequester`.** A presentation package gets
/// `core_kernel`, `core_navigation`, contracts and Flutter, not `core_ports`.
/// The alerts section needs the operating system's settings page opened and
/// cannot open it, so the app supplies that action the way it supplies
/// `onSignOut` — §2.4's shape applied to a capability rather than to a
/// destination.
///
/// **No sentences.** Every label on screen is a key — `theme.dark` — because
/// the strings belong to the app's localisation, which arrives in phase 7.
/// `SettingsScreen.describe` is the one exception, and it exists so that the
/// exhaustive `switch` over `SettingsFailure` is somewhere the compiler can
/// check it.
library;

export 'src/alerts_controller.dart';
export 'src/alerts_state.dart';
export 'src/settings_controller.dart';
export 'src/settings_routes.dart';
export 'src/settings_screen.dart';
export 'src/settings_state.dart';
export 'src/settings_strings.dart';
