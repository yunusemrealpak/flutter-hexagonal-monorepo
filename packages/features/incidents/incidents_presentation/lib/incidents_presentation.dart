/// The incidents UI: the board a dispatcher works down, and the form a courier
/// reports from.
///
/// **Scenario 6 for the fourth time.** `IncidentBoardController.canReport`
/// asks `identity_api`'s `PermissionChecker` whether the signed-in actor holds
/// `Permission.reportIncident`, and learns nothing else.
/// `IncidentsRoutes` guards the two destinations with two different
/// permissions, because recording an exception at a door and working down the
/// operation's board are not the same authority.
///
/// The permission is asked **once and read by the widget**, never inside
/// `build`. A check in a build method runs on every frame and turns a question
/// about authority into a question about rendering.
///
/// The controller checks it a second time before reporting. That is not
/// belt-and-braces: a controller is reachable from a route as well as from the
/// button the screen has already hidden.
library;

export 'src/incident_board_controller.dart';
export 'src/incident_board_screen.dart';
export 'src/incident_board_state.dart';
export 'src/incidents_routes.dart';
