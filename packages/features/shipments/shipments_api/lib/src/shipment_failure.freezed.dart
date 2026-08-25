// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shipment_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShipmentFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShipmentFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShipmentFailure()';
}


}

/// @nodoc
class $ShipmentFailureCopyWith<$Res>  {
$ShipmentFailureCopyWith(ShipmentFailure _, $Res Function(ShipmentFailure) __);
}


/// Adds pattern-matching-related methods to [ShipmentFailure].
extension ShipmentFailurePatterns on ShipmentFailure {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InvalidTransition value)?  invalidTransition,TResult Function( NotTheAssignedCourier value)?  notTheAssignedCourier,TResult Function( ShipmentNotFound value)?  shipmentNotFound,TResult Function( MalformedShipmentId value)?  malformedShipmentId,TResult Function( MalformedBarcode value)?  malformedBarcode,TResult Function( BarcodeNotRecognised value)?  barcodeNotRecognised,TResult Function( MalformedValue value)?  malformedValue,TResult Function( ShipmentsUnavailable value)?  shipmentsUnavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InvalidTransition() when invalidTransition != null:
return invalidTransition(_that);case NotTheAssignedCourier() when notTheAssignedCourier != null:
return notTheAssignedCourier(_that);case ShipmentNotFound() when shipmentNotFound != null:
return shipmentNotFound(_that);case MalformedShipmentId() when malformedShipmentId != null:
return malformedShipmentId(_that);case MalformedBarcode() when malformedBarcode != null:
return malformedBarcode(_that);case BarcodeNotRecognised() when barcodeNotRecognised != null:
return barcodeNotRecognised(_that);case MalformedValue() when malformedValue != null:
return malformedValue(_that);case ShipmentsUnavailable() when shipmentsUnavailable != null:
return shipmentsUnavailable(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InvalidTransition value)  invalidTransition,required TResult Function( NotTheAssignedCourier value)  notTheAssignedCourier,required TResult Function( ShipmentNotFound value)  shipmentNotFound,required TResult Function( MalformedShipmentId value)  malformedShipmentId,required TResult Function( MalformedBarcode value)  malformedBarcode,required TResult Function( BarcodeNotRecognised value)  barcodeNotRecognised,required TResult Function( MalformedValue value)  malformedValue,required TResult Function( ShipmentsUnavailable value)  shipmentsUnavailable,}){
final _that = this;
switch (_that) {
case InvalidTransition():
return invalidTransition(_that);case NotTheAssignedCourier():
return notTheAssignedCourier(_that);case ShipmentNotFound():
return shipmentNotFound(_that);case MalformedShipmentId():
return malformedShipmentId(_that);case MalformedBarcode():
return malformedBarcode(_that);case BarcodeNotRecognised():
return barcodeNotRecognised(_that);case MalformedValue():
return malformedValue(_that);case ShipmentsUnavailable():
return shipmentsUnavailable(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InvalidTransition value)?  invalidTransition,TResult? Function( NotTheAssignedCourier value)?  notTheAssignedCourier,TResult? Function( ShipmentNotFound value)?  shipmentNotFound,TResult? Function( MalformedShipmentId value)?  malformedShipmentId,TResult? Function( MalformedBarcode value)?  malformedBarcode,TResult? Function( BarcodeNotRecognised value)?  barcodeNotRecognised,TResult? Function( MalformedValue value)?  malformedValue,TResult? Function( ShipmentsUnavailable value)?  shipmentsUnavailable,}){
final _that = this;
switch (_that) {
case InvalidTransition() when invalidTransition != null:
return invalidTransition(_that);case NotTheAssignedCourier() when notTheAssignedCourier != null:
return notTheAssignedCourier(_that);case ShipmentNotFound() when shipmentNotFound != null:
return shipmentNotFound(_that);case MalformedShipmentId() when malformedShipmentId != null:
return malformedShipmentId(_that);case MalformedBarcode() when malformedBarcode != null:
return malformedBarcode(_that);case BarcodeNotRecognised() when barcodeNotRecognised != null:
return barcodeNotRecognised(_that);case MalformedValue() when malformedValue != null:
return malformedValue(_that);case ShipmentsUnavailable() when shipmentsUnavailable != null:
return shipmentsUnavailable(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String from,  String to)?  invalidTransition,TResult Function( ActorId assigned,  ActorId attempted)?  notTheAssignedCourier,TResult Function( ShipmentId id)?  shipmentNotFound,TResult Function( String raw)?  malformedShipmentId,TResult Function( String raw,  String reason)?  malformedBarcode,TResult Function( String barcode)?  barcodeNotRecognised,TResult Function( String field,  String reason)?  malformedValue,TResult Function( String? detail)?  shipmentsUnavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InvalidTransition() when invalidTransition != null:
return invalidTransition(_that.from,_that.to);case NotTheAssignedCourier() when notTheAssignedCourier != null:
return notTheAssignedCourier(_that.assigned,_that.attempted);case ShipmentNotFound() when shipmentNotFound != null:
return shipmentNotFound(_that.id);case MalformedShipmentId() when malformedShipmentId != null:
return malformedShipmentId(_that.raw);case MalformedBarcode() when malformedBarcode != null:
return malformedBarcode(_that.raw,_that.reason);case BarcodeNotRecognised() when barcodeNotRecognised != null:
return barcodeNotRecognised(_that.barcode);case MalformedValue() when malformedValue != null:
return malformedValue(_that.field,_that.reason);case ShipmentsUnavailable() when shipmentsUnavailable != null:
return shipmentsUnavailable(_that.detail);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String from,  String to)  invalidTransition,required TResult Function( ActorId assigned,  ActorId attempted)  notTheAssignedCourier,required TResult Function( ShipmentId id)  shipmentNotFound,required TResult Function( String raw)  malformedShipmentId,required TResult Function( String raw,  String reason)  malformedBarcode,required TResult Function( String barcode)  barcodeNotRecognised,required TResult Function( String field,  String reason)  malformedValue,required TResult Function( String? detail)  shipmentsUnavailable,}) {final _that = this;
switch (_that) {
case InvalidTransition():
return invalidTransition(_that.from,_that.to);case NotTheAssignedCourier():
return notTheAssignedCourier(_that.assigned,_that.attempted);case ShipmentNotFound():
return shipmentNotFound(_that.id);case MalformedShipmentId():
return malformedShipmentId(_that.raw);case MalformedBarcode():
return malformedBarcode(_that.raw,_that.reason);case BarcodeNotRecognised():
return barcodeNotRecognised(_that.barcode);case MalformedValue():
return malformedValue(_that.field,_that.reason);case ShipmentsUnavailable():
return shipmentsUnavailable(_that.detail);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String from,  String to)?  invalidTransition,TResult? Function( ActorId assigned,  ActorId attempted)?  notTheAssignedCourier,TResult? Function( ShipmentId id)?  shipmentNotFound,TResult? Function( String raw)?  malformedShipmentId,TResult? Function( String raw,  String reason)?  malformedBarcode,TResult? Function( String barcode)?  barcodeNotRecognised,TResult? Function( String field,  String reason)?  malformedValue,TResult? Function( String? detail)?  shipmentsUnavailable,}) {final _that = this;
switch (_that) {
case InvalidTransition() when invalidTransition != null:
return invalidTransition(_that.from,_that.to);case NotTheAssignedCourier() when notTheAssignedCourier != null:
return notTheAssignedCourier(_that.assigned,_that.attempted);case ShipmentNotFound() when shipmentNotFound != null:
return shipmentNotFound(_that.id);case MalformedShipmentId() when malformedShipmentId != null:
return malformedShipmentId(_that.raw);case MalformedBarcode() when malformedBarcode != null:
return malformedBarcode(_that.raw,_that.reason);case BarcodeNotRecognised() when barcodeNotRecognised != null:
return barcodeNotRecognised(_that.barcode);case MalformedValue() when malformedValue != null:
return malformedValue(_that.field,_that.reason);case ShipmentsUnavailable() when shipmentsUnavailable != null:
return shipmentsUnavailable(_that.detail);case _:
  return null;

}
}

}

/// @nodoc


class InvalidTransition extends ShipmentFailure {
  const InvalidTransition({required this.from, required this.to}): super._();
  

 final  String from;
 final  String to;

/// Create a copy of ShipmentFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvalidTransitionCopyWith<InvalidTransition> get copyWith => _$InvalidTransitionCopyWithImpl<InvalidTransition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvalidTransition&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}


@override
int get hashCode => Object.hash(runtimeType,from,to);

@override
String toString() {
  return 'ShipmentFailure.invalidTransition(from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class $InvalidTransitionCopyWith<$Res> implements $ShipmentFailureCopyWith<$Res> {
  factory $InvalidTransitionCopyWith(InvalidTransition value, $Res Function(InvalidTransition) _then) = _$InvalidTransitionCopyWithImpl;
@useResult
$Res call({
 String from, String to
});




}
/// @nodoc
class _$InvalidTransitionCopyWithImpl<$Res>
    implements $InvalidTransitionCopyWith<$Res> {
  _$InvalidTransitionCopyWithImpl(this._self, this._then);

  final InvalidTransition _self;
  final $Res Function(InvalidTransition) _then;

/// Create a copy of ShipmentFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,}) {
  return _then(InvalidTransition(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class NotTheAssignedCourier extends ShipmentFailure {
  const NotTheAssignedCourier({required this.assigned, required this.attempted}): super._();
  

 final  ActorId assigned;
 final  ActorId attempted;

/// Create a copy of ShipmentFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotTheAssignedCourierCopyWith<NotTheAssignedCourier> get copyWith => _$NotTheAssignedCourierCopyWithImpl<NotTheAssignedCourier>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotTheAssignedCourier&&(identical(other.assigned, assigned) || other.assigned == assigned)&&(identical(other.attempted, attempted) || other.attempted == attempted));
}


@override
int get hashCode => Object.hash(runtimeType,assigned,attempted);

@override
String toString() {
  return 'ShipmentFailure.notTheAssignedCourier(assigned: $assigned, attempted: $attempted)';
}


}

/// @nodoc
abstract mixin class $NotTheAssignedCourierCopyWith<$Res> implements $ShipmentFailureCopyWith<$Res> {
  factory $NotTheAssignedCourierCopyWith(NotTheAssignedCourier value, $Res Function(NotTheAssignedCourier) _then) = _$NotTheAssignedCourierCopyWithImpl;
@useResult
$Res call({
 ActorId assigned, ActorId attempted
});




}
/// @nodoc
class _$NotTheAssignedCourierCopyWithImpl<$Res>
    implements $NotTheAssignedCourierCopyWith<$Res> {
  _$NotTheAssignedCourierCopyWithImpl(this._self, this._then);

  final NotTheAssignedCourier _self;
  final $Res Function(NotTheAssignedCourier) _then;

/// Create a copy of ShipmentFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? assigned = null,Object? attempted = null,}) {
  return _then(NotTheAssignedCourier(
assigned: null == assigned ? _self.assigned : assigned // ignore: cast_nullable_to_non_nullable
as ActorId,attempted: null == attempted ? _self.attempted : attempted // ignore: cast_nullable_to_non_nullable
as ActorId,
  ));
}


}

/// @nodoc


class ShipmentNotFound extends ShipmentFailure {
  const ShipmentNotFound(this.id): super._();
  

 final  ShipmentId id;

/// Create a copy of ShipmentFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShipmentNotFoundCopyWith<ShipmentNotFound> get copyWith => _$ShipmentNotFoundCopyWithImpl<ShipmentNotFound>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShipmentNotFound&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ShipmentFailure.shipmentNotFound(id: $id)';
}


}

/// @nodoc
abstract mixin class $ShipmentNotFoundCopyWith<$Res> implements $ShipmentFailureCopyWith<$Res> {
  factory $ShipmentNotFoundCopyWith(ShipmentNotFound value, $Res Function(ShipmentNotFound) _then) = _$ShipmentNotFoundCopyWithImpl;
@useResult
$Res call({
 ShipmentId id
});




}
/// @nodoc
class _$ShipmentNotFoundCopyWithImpl<$Res>
    implements $ShipmentNotFoundCopyWith<$Res> {
  _$ShipmentNotFoundCopyWithImpl(this._self, this._then);

  final ShipmentNotFound _self;
  final $Res Function(ShipmentNotFound) _then;

/// Create a copy of ShipmentFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(ShipmentNotFound(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ShipmentId,
  ));
}


}

/// @nodoc


class MalformedShipmentId extends ShipmentFailure {
  const MalformedShipmentId(this.raw): super._();
  

 final  String raw;

/// Create a copy of ShipmentFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MalformedShipmentIdCopyWith<MalformedShipmentId> get copyWith => _$MalformedShipmentIdCopyWithImpl<MalformedShipmentId>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MalformedShipmentId&&(identical(other.raw, raw) || other.raw == raw));
}


@override
int get hashCode => Object.hash(runtimeType,raw);

@override
String toString() {
  return 'ShipmentFailure.malformedShipmentId(raw: $raw)';
}


}

/// @nodoc
abstract mixin class $MalformedShipmentIdCopyWith<$Res> implements $ShipmentFailureCopyWith<$Res> {
  factory $MalformedShipmentIdCopyWith(MalformedShipmentId value, $Res Function(MalformedShipmentId) _then) = _$MalformedShipmentIdCopyWithImpl;
@useResult
$Res call({
 String raw
});




}
/// @nodoc
class _$MalformedShipmentIdCopyWithImpl<$Res>
    implements $MalformedShipmentIdCopyWith<$Res> {
  _$MalformedShipmentIdCopyWithImpl(this._self, this._then);

  final MalformedShipmentId _self;
  final $Res Function(MalformedShipmentId) _then;

/// Create a copy of ShipmentFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? raw = null,}) {
  return _then(MalformedShipmentId(
null == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MalformedBarcode extends ShipmentFailure {
  const MalformedBarcode({required this.raw, required this.reason}): super._();
  

 final  String raw;
 final  String reason;

/// Create a copy of ShipmentFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MalformedBarcodeCopyWith<MalformedBarcode> get copyWith => _$MalformedBarcodeCopyWithImpl<MalformedBarcode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MalformedBarcode&&(identical(other.raw, raw) || other.raw == raw)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,raw,reason);

@override
String toString() {
  return 'ShipmentFailure.malformedBarcode(raw: $raw, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $MalformedBarcodeCopyWith<$Res> implements $ShipmentFailureCopyWith<$Res> {
  factory $MalformedBarcodeCopyWith(MalformedBarcode value, $Res Function(MalformedBarcode) _then) = _$MalformedBarcodeCopyWithImpl;
@useResult
$Res call({
 String raw, String reason
});




}
/// @nodoc
class _$MalformedBarcodeCopyWithImpl<$Res>
    implements $MalformedBarcodeCopyWith<$Res> {
  _$MalformedBarcodeCopyWithImpl(this._self, this._then);

  final MalformedBarcode _self;
  final $Res Function(MalformedBarcode) _then;

/// Create a copy of ShipmentFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? raw = null,Object? reason = null,}) {
  return _then(MalformedBarcode(
raw: null == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class BarcodeNotRecognised extends ShipmentFailure {
  const BarcodeNotRecognised(this.barcode): super._();
  

 final  String barcode;

/// Create a copy of ShipmentFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BarcodeNotRecognisedCopyWith<BarcodeNotRecognised> get copyWith => _$BarcodeNotRecognisedCopyWithImpl<BarcodeNotRecognised>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BarcodeNotRecognised&&(identical(other.barcode, barcode) || other.barcode == barcode));
}


@override
int get hashCode => Object.hash(runtimeType,barcode);

@override
String toString() {
  return 'ShipmentFailure.barcodeNotRecognised(barcode: $barcode)';
}


}

/// @nodoc
abstract mixin class $BarcodeNotRecognisedCopyWith<$Res> implements $ShipmentFailureCopyWith<$Res> {
  factory $BarcodeNotRecognisedCopyWith(BarcodeNotRecognised value, $Res Function(BarcodeNotRecognised) _then) = _$BarcodeNotRecognisedCopyWithImpl;
@useResult
$Res call({
 String barcode
});




}
/// @nodoc
class _$BarcodeNotRecognisedCopyWithImpl<$Res>
    implements $BarcodeNotRecognisedCopyWith<$Res> {
  _$BarcodeNotRecognisedCopyWithImpl(this._self, this._then);

  final BarcodeNotRecognised _self;
  final $Res Function(BarcodeNotRecognised) _then;

/// Create a copy of ShipmentFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? barcode = null,}) {
  return _then(BarcodeNotRecognised(
null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MalformedValue extends ShipmentFailure {
  const MalformedValue({required this.field, required this.reason}): super._();
  

 final  String field;
 final  String reason;

/// Create a copy of ShipmentFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MalformedValueCopyWith<MalformedValue> get copyWith => _$MalformedValueCopyWithImpl<MalformedValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MalformedValue&&(identical(other.field, field) || other.field == field)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,field,reason);

@override
String toString() {
  return 'ShipmentFailure.malformedValue(field: $field, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $MalformedValueCopyWith<$Res> implements $ShipmentFailureCopyWith<$Res> {
  factory $MalformedValueCopyWith(MalformedValue value, $Res Function(MalformedValue) _then) = _$MalformedValueCopyWithImpl;
@useResult
$Res call({
 String field, String reason
});




}
/// @nodoc
class _$MalformedValueCopyWithImpl<$Res>
    implements $MalformedValueCopyWith<$Res> {
  _$MalformedValueCopyWithImpl(this._self, this._then);

  final MalformedValue _self;
  final $Res Function(MalformedValue) _then;

/// Create a copy of ShipmentFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field = null,Object? reason = null,}) {
  return _then(MalformedValue(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ShipmentsUnavailable extends ShipmentFailure {
  const ShipmentsUnavailable({this.detail}): super._();
  

 final  String? detail;

/// Create a copy of ShipmentFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShipmentsUnavailableCopyWith<ShipmentsUnavailable> get copyWith => _$ShipmentsUnavailableCopyWithImpl<ShipmentsUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShipmentsUnavailable&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'ShipmentFailure.shipmentsUnavailable(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $ShipmentsUnavailableCopyWith<$Res> implements $ShipmentFailureCopyWith<$Res> {
  factory $ShipmentsUnavailableCopyWith(ShipmentsUnavailable value, $Res Function(ShipmentsUnavailable) _then) = _$ShipmentsUnavailableCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$ShipmentsUnavailableCopyWithImpl<$Res>
    implements $ShipmentsUnavailableCopyWith<$Res> {
  _$ShipmentsUnavailableCopyWithImpl(this._self, this._then);

  final ShipmentsUnavailable _self;
  final $Res Function(ShipmentsUnavailable) _then;

/// Create a copy of ShipmentFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(ShipmentsUnavailable(
detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
