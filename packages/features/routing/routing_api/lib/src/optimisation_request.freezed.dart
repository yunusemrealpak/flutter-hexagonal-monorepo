// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'optimisation_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OptimisationRequest {

/// Where the courier is starting from.
 GeoPoint get origin;/// The stops to order. May be empty.
 List<Stop> get stops;/// When the courier leaves [origin], in UTC.
 DateTime get departAt;/// How fast they will be moving.
 TrafficProfile get traffic;/// The rules the ordering has to respect.
 List<RouteConstraint> get constraints;
/// Create a copy of OptimisationRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OptimisationRequestCopyWith<OptimisationRequest> get copyWith => _$OptimisationRequestCopyWithImpl<OptimisationRequest>(this as OptimisationRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OptimisationRequest&&(identical(other.origin, origin) || other.origin == origin)&&const DeepCollectionEquality().equals(other.stops, stops)&&(identical(other.departAt, departAt) || other.departAt == departAt)&&(identical(other.traffic, traffic) || other.traffic == traffic)&&const DeepCollectionEquality().equals(other.constraints, constraints));
}


@override
int get hashCode => Object.hash(runtimeType,origin,const DeepCollectionEquality().hash(stops),departAt,traffic,const DeepCollectionEquality().hash(constraints));

@override
String toString() {
  return 'OptimisationRequest(origin: $origin, stops: $stops, departAt: $departAt, traffic: $traffic, constraints: $constraints)';
}


}

/// @nodoc
abstract mixin class $OptimisationRequestCopyWith<$Res>  {
  factory $OptimisationRequestCopyWith(OptimisationRequest value, $Res Function(OptimisationRequest) _then) = _$OptimisationRequestCopyWithImpl;
@useResult
$Res call({
 GeoPoint origin, List<Stop> stops, DateTime departAt, TrafficProfile traffic, List<RouteConstraint> constraints
});




}
/// @nodoc
class _$OptimisationRequestCopyWithImpl<$Res>
    implements $OptimisationRequestCopyWith<$Res> {
  _$OptimisationRequestCopyWithImpl(this._self, this._then);

  final OptimisationRequest _self;
  final $Res Function(OptimisationRequest) _then;

/// Create a copy of OptimisationRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? origin = null,Object? stops = null,Object? departAt = null,Object? traffic = null,Object? constraints = null,}) {
  return _then(OptimisationRequest(
origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as GeoPoint,stops: null == stops ? _self.stops : stops // ignore: cast_nullable_to_non_nullable
as List<Stop>,departAt: null == departAt ? _self.departAt : departAt // ignore: cast_nullable_to_non_nullable
as DateTime,traffic: null == traffic ? _self.traffic : traffic // ignore: cast_nullable_to_non_nullable
as TrafficProfile,constraints: null == constraints ? _self.constraints : constraints // ignore: cast_nullable_to_non_nullable
as List<RouteConstraint>,
  ));
}

}


/// Adds pattern-matching-related methods to [OptimisationRequest].
extension OptimisationRequestPatterns on OptimisationRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OptimisationRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OptimisationRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OptimisationRequest value)  $default,){
final _that = this;
switch (_that) {
case _OptimisationRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OptimisationRequest value)?  $default,){
final _that = this;
switch (_that) {
case _OptimisationRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GeoPoint origin,  List<Stop> stops,  DateTime departAt,  TrafficProfile traffic,  List<RouteConstraint> constraints)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OptimisationRequest() when $default != null:
return $default(_that.origin,_that.stops,_that.departAt,_that.traffic,_that.constraints);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GeoPoint origin,  List<Stop> stops,  DateTime departAt,  TrafficProfile traffic,  List<RouteConstraint> constraints)  $default,) {final _that = this;
switch (_that) {
case _OptimisationRequest():
return $default(_that.origin,_that.stops,_that.departAt,_that.traffic,_that.constraints);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GeoPoint origin,  List<Stop> stops,  DateTime departAt,  TrafficProfile traffic,  List<RouteConstraint> constraints)?  $default,) {final _that = this;
switch (_that) {
case _OptimisationRequest() when $default != null:
return $default(_that.origin,_that.stops,_that.departAt,_that.traffic,_that.constraints);case _:
  return null;

}
}

}

/// @nodoc


class _OptimisationRequest implements OptimisationRequest {
  const _OptimisationRequest({required this.origin, required  List<Stop> stops, required this.departAt, this.traffic = TrafficProfile.assumed,  List<RouteConstraint> constraints = const <RouteConstraint>[]}): _stops = stops,_constraints = constraints;
  

/// Where the courier is starting from.
@override final  GeoPoint origin;
/// The stops to order. May be empty.
 final  List<Stop> _stops;
/// The stops to order. May be empty.
@override List<Stop> get stops {
  if (_stops is EqualUnmodifiableListView) return _stops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stops);
}

/// When the courier leaves [origin], in UTC.
@override final  DateTime departAt;
/// How fast they will be moving.
@override@JsonKey() final  TrafficProfile traffic;
/// The rules the ordering has to respect.
 final  List<RouteConstraint> _constraints;
/// The rules the ordering has to respect.
@override@JsonKey() List<RouteConstraint> get constraints {
  if (_constraints is EqualUnmodifiableListView) return _constraints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_constraints);
}


/// Create a copy of OptimisationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OptimisationRequestCopyWith<_OptimisationRequest> get copyWith => __$OptimisationRequestCopyWithImpl<_OptimisationRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OptimisationRequest&&(identical(other.origin, origin) || other.origin == origin)&&const DeepCollectionEquality().equals(other._stops, _stops)&&(identical(other.departAt, departAt) || other.departAt == departAt)&&(identical(other.traffic, traffic) || other.traffic == traffic)&&const DeepCollectionEquality().equals(other._constraints, _constraints));
}


@override
int get hashCode => Object.hash(runtimeType,origin,const DeepCollectionEquality().hash(_stops),departAt,traffic,const DeepCollectionEquality().hash(_constraints));

@override
String toString() {
  return 'OptimisationRequest(origin: $origin, stops: $stops, departAt: $departAt, traffic: $traffic, constraints: $constraints)';
}


}

/// @nodoc
abstract mixin class _$OptimisationRequestCopyWith<$Res> implements $OptimisationRequestCopyWith<$Res> {
  factory _$OptimisationRequestCopyWith(_OptimisationRequest value, $Res Function(_OptimisationRequest) _then) = __$OptimisationRequestCopyWithImpl;
@override @useResult
$Res call({
 GeoPoint origin, List<Stop> stops, DateTime departAt, TrafficProfile traffic, List<RouteConstraint> constraints
});




}
/// @nodoc
class __$OptimisationRequestCopyWithImpl<$Res>
    implements _$OptimisationRequestCopyWith<$Res> {
  __$OptimisationRequestCopyWithImpl(this._self, this._then);

  final _OptimisationRequest _self;
  final $Res Function(_OptimisationRequest) _then;

/// Create a copy of OptimisationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? origin = null,Object? stops = null,Object? departAt = null,Object? traffic = null,Object? constraints = null,}) {
  return _then(_OptimisationRequest(
origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as GeoPoint,stops: null == stops ? _self._stops : stops // ignore: cast_nullable_to_non_nullable
as List<Stop>,departAt: null == departAt ? _self.departAt : departAt // ignore: cast_nullable_to_non_nullable
as DateTime,traffic: null == traffic ? _self.traffic : traffic // ignore: cast_nullable_to_non_nullable
as TrafficProfile,constraints: null == constraints ? _self._constraints : constraints // ignore: cast_nullable_to_non_nullable
as List<RouteConstraint>,
  ));
}


}

// dart format on
