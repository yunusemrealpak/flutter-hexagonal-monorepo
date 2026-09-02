import 'dart:math' as math;

import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:http_dio/http_dio.dart';
import 'package:location_service/location_service.dart';

import 'delivery_dto.dart';
import 'delivery_mapper.dart';

/// Answers `GeoFencePort` by combining the device's position with where the
/// operation says the parcel is going.
///
/// **Two platform capabilities meet here and nowhere else.** The port asks one
/// question — *am I there yet* — and both halves of the answer are lookups: a
/// fix from `LocationSource`, a target from the operation's own service. That
/// is why the question is shaped the way it is: neither half is a domain fact,
/// and `delivery_application` may not depend on `platform/*` to fetch either.
///
/// The target comes from **delivery's endpoint, not from shipments**. This
/// package may not depend on a foreign `_api` at all, so it cannot ask
/// `shipments` where a parcel is going even in principle. The operation
/// publishes the point on delivery's own path; what `shipments` calls the same
/// place is shipments' business, and the two staying separate is what lets an
/// operation move a delivery radius without touching the shipments service.
///
/// **A vague fix is refused rather than measured.** A reading with a fifty
/// metre error radius cannot answer a question about a fifty metre fence, and
/// forwarding it anyway would let a courier record a hand-over from the far
/// side of a car park on a day the signal was poor. The difference between "I
/// do not know where you are" and "you are somewhere over there" is what
/// `positionUnavailable` exists to say.
final class HttpGeoFence implements GeoFencePort {
  /// Creates the adapter over a transport and a position source.
  const HttpGeoFence({
    required this.transport,
    required this.location,
    this.path = '/delivery/targets',
    this.timeout = const Duration(seconds: 8),
  });

  /// Where the target is asked for.
  final HttpTransport transport;

  /// What the device's position comes from.
  final LocationSource location;

  /// The path the operation publishes delivery targets on.
  final String path;

  /// How long to wait for a fix before giving up.
  ///
  /// Eight seconds, because a courier is standing at a door. A fix that takes
  /// longer than that is one they will not wait for, and the honest answer is
  /// `positionUnavailable` rather than a spinner.
  final Duration timeout;

  @override
  Future<Result<GeoFenceVerdict, DeliveryFailure>> locate(
    String shipmentId,
  ) async {
    final ({double latitude, double longitude, double allowedMetres}) target;
    switch (await _target(shipmentId)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        target = value;
    }

    final GeoFix fix;
    switch (await location.currentFix(timeout: timeout)) {
      case Failed(:final failure):
        return Failed(_translate(failure));
      case Success(:final value):
        fix = value;
    }

    if (fix.accuracyMetres > target.allowedMetres) {
      return Failed(
        DeliveryPositionUnavailable(
          detail:
              'a fix accurate to ${fix.accuracyMetres.round()}m cannot answer '
              'a ${target.allowedMetres.round()}m fence',
        ),
      );
    }

    final metresAway = _distance(
      fromLatitude: fix.latitude,
      fromLongitude: fix.longitude,
      toLatitude: target.latitude,
      toLongitude: target.longitude,
    );

    return Success(
      GeoFenceVerdict(
        isInside: metresAway <= target.allowedMetres,
        metresAway: metresAway,
        allowedMetres: target.allowedMetres,
      ),
    );
  }

  /// Turns a location failure into delivery's own words.
  ///
  /// **One of the five is kept apart and the other four are not.** A
  /// permission the operating system has stopped asking about is the only case
  /// a courier can do something about from inside this app — press a button
  /// that opens the settings page — and it is the only one where the retry
  /// every other case gets is a button that can never work. The rest differ in
  /// why the fix did not arrive and not in what happens next, so they collapse
  /// with the detail carried for the log.
  ///
  /// `LocationServicesDisabled` is on the collapsed side and is the seam worth
  /// naming: it is also only fixable in settings, but in the *device's*
  /// settings rather than this app's, which is a different platform call than
  /// `PermissionRequester.openSettings` makes. Splitting it out before that
  /// call exists would produce a second case with the same dead end.
  static DeliveryFailure _translate(LocationFailure failure) =>
      switch (failure) {
        LocationPermissionBlocked() => const DevicePositionBlocked(),
        LocationServicesDisabled() ||
        LocationPermissionDenied() ||
        LocationTimeout() ||
        LocationUnavailable() => DeliveryPositionUnavailable(
          detail: '$failure',
        ),
      };

  Future<
    Result<
      ({double latitude, double longitude, double allowedMetres}),
      DeliveryFailure
    >
  >
  _target(String shipmentId) async {
    final response = await transport.send(
      HttpRequest(method: HttpMethod.get, path: '$path/$shipmentId'),
    );

    return switch (response) {
      Failed(:final failure) => Failed(DeliveryUnavailable(detail: '$failure')),
      Success(value: final ok) => _read(ok.body),
    };
  }

  Result<
    ({double latitude, double longitude, double allowedMetres}),
    DeliveryFailure
  >
  _read(Object? body) {
    if (body is! Map<String, dynamic>) {
      return const Failed(
        MalformedDeliveryValue(
          field: 'body',
          reason: 'the target service did not answer with a JSON object',
        ),
      );
    }
    return DeliveryMapper.targetToDomain(GeoTargetDto.fromJson(body));
  }

  /// Great-circle distance in metres.
  ///
  /// The haversine, spelled out rather than pulled in, because it is eight
  /// lines and a dependency for eight lines is a dependency to keep updated
  /// for ever. `routing` has its own copy on `GeoPoint`, and the duplication
  /// is deliberate: this package may not see `routing_api`, and a shared
  /// package for one formula is exactly the `common` package the constitution
  /// forbids.
  static double _distance({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    const earthRadiusMetres = 6371000.0;

    final dLat = _radians(toLatitude - fromLatitude);
    final dLng = _radians(toLongitude - fromLongitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(fromLatitude)) *
            math.cos(_radians(toLatitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    return earthRadiusMetres * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}
