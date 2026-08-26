import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/foundation.dart';
import 'package:identity_api/identity_api.dart';
import 'package:reporting_api/reporting_api.dart';

import 'report_state.dart';

/// Drives the reporting board.
///
/// It holds two ports — `ReportingFacade` and `PermissionChecker` — and no
/// implementation of either. `viewReports` is scenario 6 for the fifth time,
/// and this is the feature where it matters most: reporting is the one thing
/// in phase 6 that a courier is not meant to see at all.
final class ReportController extends ChangeNotifier {
  /// Creates the controller.
  ReportController({required this._reporting, required this._permissions});

  final ReportingFacade _reporting;
  final PermissionChecker _permissions;

  ReportState _state = const ReportIdle();

  /// What the screen should be showing.
  ReportState get state => _state;

  /// Whether this actor may see reports.
  bool get canView => _permissions.can(Permission.viewReports);

  /// Reads the totals for a range.
  ///
  /// The permission is checked **before** the read, not after. A screen that
  /// fetched first and hid the numbers afterwards would have already put them
  /// in memory on a device whose owner may not see them — and would have told
  /// the server which days somebody was interested in.
  Future<void> load({
    required ReportingDay from,
    required ReportingDay to,
  }) async {
    if (!canView) {
      _emit(const ReportForbidden());
      return;
    }

    _emit(const ReportLoading());
    final read = await _reporting.range(from: from, to: to);
    _emit(
      switch (read) {
        Success(:final value) => ReportReady(value),
        Failed(:final failure) => ReportFailed(failure),
      },
    );
  }

  void _emit(ReportState next) {
    _state = next;
    notifyListeners();
  }
}
