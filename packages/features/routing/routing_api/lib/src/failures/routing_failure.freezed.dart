// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'routing_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RoutingFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoutingFailure()';
}


}

/// @nodoc
class $RoutingFailureCopyWith<$Res>  {
$RoutingFailureCopyWith(RoutingFailure _, $Res Function(RoutingFailure) __);
}


/// Adds pattern-matching-related methods to [RoutingFailure].
extension RoutingFailurePatterns on RoutingFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MalformedRouteValue value)?  malformedValue,TResult Function( StopNotGeocoded value)?  stopNotGeocoded,TResult Function( ConstraintUnsatisfiable value)?  constraintUnsatisfiable,TResult Function( SequenceDoesNotMatch value)?  sequenceDoesNotMatch,TResult Function( NoPlan value)?  noPlan,TResult Function( PositionUnavailable value)?  positionUnavailable,TResult Function( RoutingUnavailable value)?  routingUnavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MalformedRouteValue() when malformedValue != null:
return malformedValue(_that);case StopNotGeocoded() when stopNotGeocoded != null:
return stopNotGeocoded(_that);case ConstraintUnsatisfiable() when constraintUnsatisfiable != null:
return constraintUnsatisfiable(_that);case SequenceDoesNotMatch() when sequenceDoesNotMatch != null:
return sequenceDoesNotMatch(_that);case NoPlan() when noPlan != null:
return noPlan(_that);case PositionUnavailable() when positionUnavailable != null:
return positionUnavailable(_that);case RoutingUnavailable() when routingUnavailable != null:
return routingUnavailable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MalformedRouteValue value)  malformedValue,required TResult Function( StopNotGeocoded value)  stopNotGeocoded,required TResult Function( ConstraintUnsatisfiable value)  constraintUnsatisfiable,required TResult Function( SequenceDoesNotMatch value)  sequenceDoesNotMatch,required TResult Function( NoPlan value)  noPlan,required TResult Function( PositionUnavailable value)  positionUnavailable,required TResult Function( RoutingUnavailable value)  routingUnavailable,}){
final _that = this;
switch (_that) {
case MalformedRouteValue():
return malformedValue(_that);case StopNotGeocoded():
return stopNotGeocoded(_that);case ConstraintUnsatisfiable():
return constraintUnsatisfiable(_that);case SequenceDoesNotMatch():
return sequenceDoesNotMatch(_that);case NoPlan():
return noPlan(_that);case PositionUnavailable():
return positionUnavailable(_that);case RoutingUnavailable():
return routingUnavailable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MalformedRouteValue value)?  malformedValue,TResult? Function( StopNotGeocoded value)?  stopNotGeocoded,TResult? Function( ConstraintUnsatisfiable value)?  constraintUnsatisfiable,TResult? Function( SequenceDoesNotMatch value)?  sequenceDoesNotMatch,TResult? Function( NoPlan value)?  noPlan,TResult? Function( PositionUnavailable value)?  positionUnavailable,TResult? Function( RoutingUnavailable value)?  routingUnavailable,}){
final _that = this;
switch (_that) {
case MalformedRouteValue() when malformedValue != null:
return malformedValue(_that);case StopNotGeocoded() when stopNotGeocoded != null:
return stopNotGeocoded(_that);case ConstraintUnsatisfiable() when constraintUnsatisfiable != null:
return constraintUnsatisfiable(_that);case SequenceDoesNotMatch() when sequenceDoesNotMatch != null:
return sequenceDoesNotMatch(_that);case NoPlan() when noPlan != null:
return noPlan(_that);case PositionUnavailable() when positionUnavailable != null:
return positionUnavailable(_that);case RoutingUnavailable() when routingUnavailable != null:
return routingUnavailable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String field,  String reason)?  malformedValue,TResult Function( String stopId,  String address)?  stopNotGeocoded,TResult Function( String constraint,  String reason)?  constraintUnsatisfiable,TResult Function( String reason)?  sequenceDoesNotMatch,TResult Function( String courier)?  noPlan,TResult Function( String? detail)?  positionUnavailable,TResult Function( String? detail)?  routingUnavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MalformedRouteValue() when malformedValue != null:
return malformedValue(_that.field,_that.reason);case StopNotGeocoded() when stopNotGeocoded != null:
return stopNotGeocoded(_that.stopId,_that.address);case ConstraintUnsatisfiable() when constraintUnsatisfiable != null:
return constraintUnsatisfiable(_that.constraint,_that.reason);case SequenceDoesNotMatch() when sequenceDoesNotMatch != null:
return sequenceDoesNotMatch(_that.reason);case NoPlan() when noPlan != null:
return noPlan(_that.courier);case PositionUnavailable() when positionUnavailable != null:
return positionUnavailable(_that.detail);case RoutingUnavailable() when routingUnavailable != null:
return routingUnavailable(_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String field,  String reason)  malformedValue,required TResult Function( String stopId,  String address)  stopNotGeocoded,required TResult Function( String constraint,  String reason)  constraintUnsatisfiable,required TResult Function( String reason)  sequenceDoesNotMatch,required TResult Function( String courier)  noPlan,required TResult Function( String? detail)  positionUnavailable,required TResult Function( String? detail)  routingUnavailable,}) {final _that = this;
switch (_that) {
case MalformedRouteValue():
return malformedValue(_that.field,_that.reason);case StopNotGeocoded():
return stopNotGeocoded(_that.stopId,_that.address);case ConstraintUnsatisfiable():
return constraintUnsatisfiable(_that.constraint,_that.reason);case SequenceDoesNotMatch():
return sequenceDoesNotMatch(_that.reason);case NoPlan():
return noPlan(_that.courier);case PositionUnavailable():
return positionUnavailable(_that.detail);case RoutingUnavailable():
return routingUnavailable(_that.detail);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String field,  String reason)?  malformedValue,TResult? Function( String stopId,  String address)?  stopNotGeocoded,TResult? Function( String constraint,  String reason)?  constraintUnsatisfiable,TResult? Function( String reason)?  sequenceDoesNotMatch,TResult? Function( String courier)?  noPlan,TResult? Function( String? detail)?  positionUnavailable,TResult? Function( String? detail)?  routingUnavailable,}) {final _that = this;
switch (_that) {
case MalformedRouteValue() when malformedValue != null:
return malformedValue(_that.field,_that.reason);case StopNotGeocoded() when stopNotGeocoded != null:
return stopNotGeocoded(_that.stopId,_that.address);case ConstraintUnsatisfiable() when constraintUnsatisfiable != null:
return constraintUnsatisfiable(_that.constraint,_that.reason);case SequenceDoesNotMatch() when sequenceDoesNotMatch != null:
return sequenceDoesNotMatch(_that.reason);case NoPlan() when noPlan != null:
return noPlan(_that.courier);case PositionUnavailable() when positionUnavailable != null:
return positionUnavailable(_that.detail);case RoutingUnavailable() when routingUnavailable != null:
return routingUnavailable(_that.detail);case _:
  return null;

}
}

}

/// @nodoc


class MalformedRouteValue extends RoutingFailure {
  const MalformedRouteValue({required this.field, required this.reason}): super._();
  

 final  String field;
 final  String reason;

/// Create a copy of RoutingFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MalformedRouteValueCopyWith<MalformedRouteValue> get copyWith => _$MalformedRouteValueCopyWithImpl<MalformedRouteValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MalformedRouteValue&&(identical(other.field, field) || other.field == field)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,field,reason);

@override
String toString() {
  return 'RoutingFailure.malformedValue(field: $field, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $MalformedRouteValueCopyWith<$Res> implements $RoutingFailureCopyWith<$Res> {
  factory $MalformedRouteValueCopyWith(MalformedRouteValue value, $Res Function(MalformedRouteValue) _then) = _$MalformedRouteValueCopyWithImpl;
@useResult
$Res call({
 String field, String reason
});




}
/// @nodoc
class _$MalformedRouteValueCopyWithImpl<$Res>
    implements $MalformedRouteValueCopyWith<$Res> {
  _$MalformedRouteValueCopyWithImpl(this._self, this._then);

  final MalformedRouteValue _self;
  final $Res Function(MalformedRouteValue) _then;

/// Create a copy of RoutingFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field = null,Object? reason = null,}) {
  return _then(MalformedRouteValue(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StopNotGeocoded extends RoutingFailure {
  const StopNotGeocoded({required this.stopId, required this.address}): super._();
  

 final  String stopId;
 final  String address;

/// Create a copy of RoutingFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StopNotGeocodedCopyWith<StopNotGeocoded> get copyWith => _$StopNotGeocodedCopyWithImpl<StopNotGeocoded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StopNotGeocoded&&(identical(other.stopId, stopId) || other.stopId == stopId)&&(identical(other.address, address) || other.address == address));
}


@override
int get hashCode => Object.hash(runtimeType,stopId,address);

@override
String toString() {
  return 'RoutingFailure.stopNotGeocoded(stopId: $stopId, address: $address)';
}


}

/// @nodoc
abstract mixin class $StopNotGeocodedCopyWith<$Res> implements $RoutingFailureCopyWith<$Res> {
  factory $StopNotGeocodedCopyWith(StopNotGeocoded value, $Res Function(StopNotGeocoded) _then) = _$StopNotGeocodedCopyWithImpl;
@useResult
$Res call({
 String stopId, String address
});




}
/// @nodoc
class _$StopNotGeocodedCopyWithImpl<$Res>
    implements $StopNotGeocodedCopyWith<$Res> {
  _$StopNotGeocodedCopyWithImpl(this._self, this._then);

  final StopNotGeocoded _self;
  final $Res Function(StopNotGeocoded) _then;

/// Create a copy of RoutingFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? stopId = null,Object? address = null,}) {
  return _then(StopNotGeocoded(
stopId: null == stopId ? _self.stopId : stopId // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ConstraintUnsatisfiable extends RoutingFailure {
  const ConstraintUnsatisfiable({required this.constraint, required this.reason}): super._();
  

 final  String constraint;
 final  String reason;

/// Create a copy of RoutingFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConstraintUnsatisfiableCopyWith<ConstraintUnsatisfiable> get copyWith => _$ConstraintUnsatisfiableCopyWithImpl<ConstraintUnsatisfiable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConstraintUnsatisfiable&&(identical(other.constraint, constraint) || other.constraint == constraint)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,constraint,reason);

@override
String toString() {
  return 'RoutingFailure.constraintUnsatisfiable(constraint: $constraint, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $ConstraintUnsatisfiableCopyWith<$Res> implements $RoutingFailureCopyWith<$Res> {
  factory $ConstraintUnsatisfiableCopyWith(ConstraintUnsatisfiable value, $Res Function(ConstraintUnsatisfiable) _then) = _$ConstraintUnsatisfiableCopyWithImpl;
@useResult
$Res call({
 String constraint, String reason
});




}
/// @nodoc
class _$ConstraintUnsatisfiableCopyWithImpl<$Res>
    implements $ConstraintUnsatisfiableCopyWith<$Res> {
  _$ConstraintUnsatisfiableCopyWithImpl(this._self, this._then);

  final ConstraintUnsatisfiable _self;
  final $Res Function(ConstraintUnsatisfiable) _then;

/// Create a copy of RoutingFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? constraint = null,Object? reason = null,}) {
  return _then(ConstraintUnsatisfiable(
constraint: null == constraint ? _self.constraint : constraint // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SequenceDoesNotMatch extends RoutingFailure {
  const SequenceDoesNotMatch({required this.reason}): super._();
  

 final  String reason;

/// Create a copy of RoutingFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SequenceDoesNotMatchCopyWith<SequenceDoesNotMatch> get copyWith => _$SequenceDoesNotMatchCopyWithImpl<SequenceDoesNotMatch>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SequenceDoesNotMatch&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'RoutingFailure.sequenceDoesNotMatch(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $SequenceDoesNotMatchCopyWith<$Res> implements $RoutingFailureCopyWith<$Res> {
  factory $SequenceDoesNotMatchCopyWith(SequenceDoesNotMatch value, $Res Function(SequenceDoesNotMatch) _then) = _$SequenceDoesNotMatchCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$SequenceDoesNotMatchCopyWithImpl<$Res>
    implements $SequenceDoesNotMatchCopyWith<$Res> {
  _$SequenceDoesNotMatchCopyWithImpl(this._self, this._then);

  final SequenceDoesNotMatch _self;
  final $Res Function(SequenceDoesNotMatch) _then;

/// Create a copy of RoutingFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(SequenceDoesNotMatch(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class NoPlan extends RoutingFailure {
  const NoPlan(this.courier): super._();
  

 final  String courier;

/// Create a copy of RoutingFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoPlanCopyWith<NoPlan> get copyWith => _$NoPlanCopyWithImpl<NoPlan>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoPlan&&(identical(other.courier, courier) || other.courier == courier));
}


@override
int get hashCode => Object.hash(runtimeType,courier);

@override
String toString() {
  return 'RoutingFailure.noPlan(courier: $courier)';
}


}

/// @nodoc
abstract mixin class $NoPlanCopyWith<$Res> implements $RoutingFailureCopyWith<$Res> {
  factory $NoPlanCopyWith(NoPlan value, $Res Function(NoPlan) _then) = _$NoPlanCopyWithImpl;
@useResult
$Res call({
 String courier
});




}
/// @nodoc
class _$NoPlanCopyWithImpl<$Res>
    implements $NoPlanCopyWith<$Res> {
  _$NoPlanCopyWithImpl(this._self, this._then);

  final NoPlan _self;
  final $Res Function(NoPlan) _then;

/// Create a copy of RoutingFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? courier = null,}) {
  return _then(NoPlan(
null == courier ? _self.courier : courier // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PositionUnavailable extends RoutingFailure {
  const PositionUnavailable({this.detail}): super._();
  

 final  String? detail;

/// Create a copy of RoutingFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PositionUnavailableCopyWith<PositionUnavailable> get copyWith => _$PositionUnavailableCopyWithImpl<PositionUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PositionUnavailable&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'RoutingFailure.positionUnavailable(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $PositionUnavailableCopyWith<$Res> implements $RoutingFailureCopyWith<$Res> {
  factory $PositionUnavailableCopyWith(PositionUnavailable value, $Res Function(PositionUnavailable) _then) = _$PositionUnavailableCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$PositionUnavailableCopyWithImpl<$Res>
    implements $PositionUnavailableCopyWith<$Res> {
  _$PositionUnavailableCopyWithImpl(this._self, this._then);

  final PositionUnavailable _self;
  final $Res Function(PositionUnavailable) _then;

/// Create a copy of RoutingFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(PositionUnavailable(
detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class RoutingUnavailable extends RoutingFailure {
  const RoutingUnavailable({this.detail}): super._();
  

 final  String? detail;

/// Create a copy of RoutingFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutingUnavailableCopyWith<RoutingUnavailable> get copyWith => _$RoutingUnavailableCopyWithImpl<RoutingUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingUnavailable&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'RoutingFailure.routingUnavailable(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $RoutingUnavailableCopyWith<$Res> implements $RoutingFailureCopyWith<$Res> {
  factory $RoutingUnavailableCopyWith(RoutingUnavailable value, $Res Function(RoutingUnavailable) _then) = _$RoutingUnavailableCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$RoutingUnavailableCopyWithImpl<$Res>
    implements $RoutingUnavailableCopyWith<$Res> {
  _$RoutingUnavailableCopyWithImpl(this._self, this._then);

  final RoutingUnavailable _self;
  final $Res Function(RoutingUnavailable) _then;

/// Create a copy of RoutingFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(RoutingUnavailable(
detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
