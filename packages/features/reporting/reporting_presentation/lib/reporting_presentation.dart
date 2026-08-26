/// The reporting UI: the board a dispatcher watches the day on.
///
/// **The permission is checked before the read, not after.** A screen that
/// fetched the figures and hid them afterwards would have put them in memory
/// on a device whose owner may not see them, and would have told the server
/// which days somebody was interested in. `ReportForbidden` is its own state
/// rather than an empty board, because an empty board is a quiet morning and
/// this is not.
///
/// **The route is guarded even though no courier app will include it.** "We
/// will not put it in that app" is a decision somebody can reverse in a pull
/// request; the guard is what makes reversing it safe.
///
/// **No chart.** It is the first thing `design_system` will bring in phase 7,
/// and one hand-painted here would be a thing to delete rather than a thing to
/// restyle.
library;

export 'src/report_controller.dart';
export 'src/report_screen.dart';
export 'src/report_state.dart';
export 'src/reporting_routes.dart';
