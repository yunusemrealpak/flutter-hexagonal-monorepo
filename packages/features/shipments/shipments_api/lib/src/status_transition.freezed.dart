// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'status_transition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StatusTransition {

/// The state the shipment left.
 ShipmentStatus get from;/// The state it entered.
 ShipmentStatus get to;/// When the move happened, in UTC, as reported by the `Clock` port.
 DateTime get at;/// Who caused it, where a person did.
///
/// `null` for moves the system makes on its own — a sweep that returns
/// undelivered parcels to the depot at the end of a shift has no actor,
/// and inventing one would make the audit trail lie.
 ActorId? get by;
/// Create a copy of StatusTransition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatusTransitionCopyWith<StatusTransition> get copyWith => _$StatusTransitionCopyWithImpl<StatusTransition>(this as StatusTransition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatusTransition&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.at, at) || other.at == at)&&(identical(other.by, by) || other.by == by));
}


@override
int get hashCode => Object.hash(runtimeType,from,to,at,by);

@override
String toString() {
  return 'StatusTransition(from: $from, to: $to, at: $at, by: $by)';
}


}

/// @nodoc
abstract mixin class $StatusTransitionCopyWith<$Res>  {
  factory $StatusTransitionCopyWith(StatusTransition value, $Res Function(StatusTransition) _then) = _$StatusTransitionCopyWithImpl;
@useResult
$Res call({
 ShipmentStatus from, ShipmentStatus to, DateTime at, ActorId? by
});


$ShipmentStatusCopyWith<$Res> get from;$ShipmentStatusCopyWith<$Res> get to;

}
/// @nodoc
class _$StatusTransitionCopyWithImpl<$Res>
    implements $StatusTransitionCopyWith<$Res> {
  _$StatusTransitionCopyWithImpl(this._self, this._then);

  final StatusTransition _self;
  final $Res Function(StatusTransition) _then;

/// Create a copy of StatusTransition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? to = null,Object? at = null,Object? by = freezed,}) {
  return _then(StatusTransition(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as ShipmentStatus,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as ShipmentStatus,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,by: freezed == by ? _self.by : by // ignore: cast_nullable_to_non_nullable
as ActorId?,
  ));
}
/// Create a copy of StatusTransition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShipmentStatusCopyWith<$Res> get from {
  
  return $ShipmentStatusCopyWith<$Res>(_self.from, (value) {
    return _then(_self.copyWith(from: value));
  });
}/// Create a copy of StatusTransition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShipmentStatusCopyWith<$Res> get to {
  
  return $ShipmentStatusCopyWith<$Res>(_self.to, (value) {
    return _then(_self.copyWith(to: value));
  });
}
}


/// Adds pattern-matching-related methods to [StatusTransition].
extension StatusTransitionPatterns on StatusTransition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatusTransition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatusTransition() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatusTransition value)  $default,){
final _that = this;
switch (_that) {
case _StatusTransition():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatusTransition value)?  $default,){
final _that = this;
switch (_that) {
case _StatusTransition() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ShipmentStatus from,  ShipmentStatus to,  DateTime at,  ActorId? by)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatusTransition() when $default != null:
return $default(_that.from,_that.to,_that.at,_that.by);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ShipmentStatus from,  ShipmentStatus to,  DateTime at,  ActorId? by)  $default,) {final _that = this;
switch (_that) {
case _StatusTransition():
return $default(_that.from,_that.to,_that.at,_that.by);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ShipmentStatus from,  ShipmentStatus to,  DateTime at,  ActorId? by)?  $default,) {final _that = this;
switch (_that) {
case _StatusTransition() when $default != null:
return $default(_that.from,_that.to,_that.at,_that.by);case _:
  return null;

}
}

}

/// @nodoc


class _StatusTransition extends StatusTransition {
  const _StatusTransition({required this.from, required this.to, required this.at, this.by}): super._();
  

/// The state the shipment left.
@override final  ShipmentStatus from;
/// The state it entered.
@override final  ShipmentStatus to;
/// When the move happened, in UTC, as reported by the `Clock` port.
@override final  DateTime at;
/// Who caused it, where a person did.
///
/// `null` for moves the system makes on its own — a sweep that returns
/// undelivered parcels to the depot at the end of a shift has no actor,
/// and inventing one would make the audit trail lie.
@override final  ActorId? by;

/// Create a copy of StatusTransition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatusTransitionCopyWith<_StatusTransition> get copyWith => __$StatusTransitionCopyWithImpl<_StatusTransition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatusTransition&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.at, at) || other.at == at)&&(identical(other.by, by) || other.by == by));
}


@override
int get hashCode => Object.hash(runtimeType,from,to,at,by);

@override
String toString() {
  return 'StatusTransition(from: $from, to: $to, at: $at, by: $by)';
}


}

/// @nodoc
abstract mixin class _$StatusTransitionCopyWith<$Res> implements $StatusTransitionCopyWith<$Res> {
  factory _$StatusTransitionCopyWith(_StatusTransition value, $Res Function(_StatusTransition) _then) = __$StatusTransitionCopyWithImpl;
@override @useResult
$Res call({
 ShipmentStatus from, ShipmentStatus to, DateTime at, ActorId? by
});


@override $ShipmentStatusCopyWith<$Res> get from;@override $ShipmentStatusCopyWith<$Res> get to;

}
/// @nodoc
class __$StatusTransitionCopyWithImpl<$Res>
    implements _$StatusTransitionCopyWith<$Res> {
  __$StatusTransitionCopyWithImpl(this._self, this._then);

  final _StatusTransition _self;
  final $Res Function(_StatusTransition) _then;

/// Create a copy of StatusTransition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,Object? at = null,Object? by = freezed,}) {
  return _then(_StatusTransition(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as ShipmentStatus,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as ShipmentStatus,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,by: freezed == by ? _self.by : by // ignore: cast_nullable_to_non_nullable
as ActorId?,
  ));
}

/// Create a copy of StatusTransition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShipmentStatusCopyWith<$Res> get from {
  
  return $ShipmentStatusCopyWith<$Res>(_self.from, (value) {
    return _then(_self.copyWith(from: value));
  });
}/// Create a copy of StatusTransition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShipmentStatusCopyWith<$Res> get to {
  
  return $ShipmentStatusCopyWith<$Res>(_self.to, (value) {
    return _then(_self.copyWith(to: value));
  });
}
}

// dart format on
