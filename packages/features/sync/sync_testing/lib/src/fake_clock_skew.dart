import 'package:core_kernel/core_kernel.dart';
import 'package:sync_api/sync_api.dart';

/// A `ClockSkewPort` whose answer the test chooses.
///
/// The port exists so that a queued instant can be expressed in the server's
/// frame of reference, and the whole reason it is a port is that a test has to
/// be able to say "this device is an hour slow" without changing a device
/// clock. That is what this fake is for.
final class FakeClockSkew implements ClockSkewPort {
  /// Creates a fake reporting [skew], or a failure if one is set.
  FakeClockSkew({this._skew = Duration.zero});

  Duration _skew;
  SyncFailure? _failure;

  /// Sets the difference this port reports from now on, and clears any
  /// failure that was set.
  ///
  /// Positive when the server is ahead of the device.
  void reports(Duration skew) {
    _skew = skew;
    _failure = null;
  }

  /// Makes every call fail with [failure] until [reports] is called again.
  ///
  /// A drain has to be able to proceed without knowing the skew — an offline
  /// device cannot ask — so the branch where this port fails is one every
  /// caller needs tested. It stays a method rather than becoming a setter,
  /// because a setter would read like part of the port rather than like the
  /// test arranging one.
  // ignore: use_setters_to_change_properties
  void failsWith(SyncFailure failure) => _failure = failure;

  @override
  Future<Result<Duration, SyncFailure>> skew() async {
    final failure = _failure;
    return failure != null ? Failed(failure) : Success(_skew);
  }
}
