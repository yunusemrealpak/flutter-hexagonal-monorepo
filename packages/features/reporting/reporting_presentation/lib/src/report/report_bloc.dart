import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:identity_api/identity_api.dart';
import 'package:reporting_api/reporting_api.dart';

import 'report_event.dart';
import 'report_state.dart';

/// Drives the reporting board.
///
/// It holds two ports — `ReportingFacade` and `PermissionChecker` — and no
/// implementation of either. `viewReports` is scenario 6 for the fifth time,
/// and this is the feature where it matters most: reporting is the one thing
/// in phase 6 that a courier is not meant to see at all.
///
/// **`restartable()` on the range, and there is exactly one read path.**
/// Asking for a second range while the first is still being totalled abandons
/// the first — a slow answer for last week must not land on top of a fresh one
/// for today. [ReportRetried] does not read anything itself: it re-dispatches
/// the remembered range, so the retry goes through the same handler and gets
/// the same policy. Two events with two reads would be two transformers, and
/// transformers do not span registrations, so a retry could race the range it
/// was retrying.
final class ReportBloc extends Bloc<ReportEvent, ReportState> {
  /// Creates the bloc.
  ReportBloc({required this._reporting, required this._permissions})
    : super(const ReportIdle()) {
    on<RangeRequested>(_onRequested, transformer: restartable());
    on<ReportRetried>(_onRetried);
  }

  final ReportingFacade _reporting;
  final PermissionChecker _permissions;

  (ReportingDay, ReportingDay)? _lastRange;

  /// Whether this actor may see reports.
  bool get canView => _permissions.can(Permission.viewReports);

  /// Reads the totals for a range.
  ///
  /// The permission is checked **before** the read, not after. A screen that
  /// fetched first and hid the numbers afterwards would have already put them
  /// in memory on a device whose owner may not see them — and would have told
  /// the server which days somebody was interested in.
  Future<void> _onRequested(
    RangeRequested event,
    Emitter<ReportState> emit,
  ) async {
    if (!canView) {
      emit(const ReportForbidden());
      return;
    }

    _lastRange = (event.from, event.to);
    emit(const ReportLoading());
    final read = await _reporting.range(from: event.from, to: event.to);
    emit(
      switch (read) {
        Success(:final value) => ReportReady(value),
        Failed(:final failure) => ReportFailed(failure),
      },
    );
  }

  /// Does nothing when nothing has been asked for yet.
  ///
  /// A retry before a first read is not a state this screen can reach — the
  /// failure view only exists after a read — and guessing a range would be
  /// worse than doing nothing.
  void _onRetried(ReportRetried event, Emitter<ReportState> emit) {
    if (_lastRange case (final from, final to)) {
      add(RangeRequested(from: from, to: to));
    }
  }
}
