import 'permission.dart';
import 'permission_set.dart';

/// A named bundle of permissions an actor is granted by their job.
///
/// The role is what an administrator assigns; the [Permission] is what code
/// checks. Keeping the two apart is what lets a role gain a permission without
/// a single call site changing, and what stops `if (role == Role.dispatcher)`
/// spreading through the presentation packages — a check that is wrong the
/// first time a supervisor needs to do a dispatcher's job.
enum Role {
  /// Drives the van and delivers.
  courier(<Permission>{
    Permission.viewAssignedShipments,
    Permission.completeDelivery,
    Permission.collectPayment,
    Permission.reportIncident,
  }),

  /// Runs the board: sees everything, assigns work.
  dispatcher(<Permission>{
    Permission.viewAllShipments,
    Permission.assignShipment,
    Permission.bulkAssignShipments,
    Permission.reportIncident,
  }),

  /// A dispatcher who can also undo money and read the numbers.
  supervisor(<Permission>{
    Permission.viewAllShipments,
    Permission.assignShipment,
    Permission.bulkAssignShipments,
    Permission.refundPayment,
    Permission.reportIncident,
    Permission.viewReports,
    Permission.manageSettings,
  }),

  /// Reads, changes nothing.
  auditor(<Permission>{
    Permission.viewAllShipments,
    Permission.viewReports,
  });

  const Role(this._permissions);

  final Set<Permission> _permissions;

  /// What holding this role grants on its own.
  PermissionSet get permissions => PermissionSet.of(_permissions);
}
