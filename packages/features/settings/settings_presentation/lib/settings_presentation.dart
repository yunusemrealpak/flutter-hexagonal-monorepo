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
/// **No clock.** A presentation package gets `core_kernel`, `core_navigation`,
/// contracts and Flutter, not `core_ports`. Nothing here needs one.
///
/// **No sentences.** Every label on screen is a key — `theme.dark` — because
/// the strings belong to the app's localisation, which arrives in phase 7.
/// `SettingsScreen.describe` is the one exception, and it exists so that the
/// exhaustive `switch` over `SettingsFailure` is somewhere the compiler can
/// check it.
library;

export 'src/settings_controller.dart';
export 'src/settings_routes.dart';
export 'src/settings_screen.dart';
export 'src/settings_state.dart';
