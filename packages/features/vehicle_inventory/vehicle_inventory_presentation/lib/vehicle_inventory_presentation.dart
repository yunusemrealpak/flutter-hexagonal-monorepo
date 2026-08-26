/// The vehicle inventory UI: the screen a courier counts a van on.
///
/// **No scanner.** A presentation package may not depend on `platform/*`, so a
/// barcode arrives as a `ShipmentId` from whatever the app wired to the
/// trigger — the same decision `delivery_presentation` made about the camera
/// in phase 5.
///
/// **No arithmetic.** The scanned count, what is missing and what should not
/// be in the van all come off `LoadCount`. A screen that computed them would
/// be a second implementation of the only arithmetic this feature has, and the
/// two would disagree the day one of them was fixed.
///
/// **The screen resumes before it starts.** A phone killed mid-count leaves
/// one behind, and a courier made to start again would rescan a van they had
/// already half counted.
library;

export 'src/count_controller.dart';
export 'src/count_screen.dart';
export 'src/count_state.dart';
export 'src/vehicle_inventory_routes.dart';
