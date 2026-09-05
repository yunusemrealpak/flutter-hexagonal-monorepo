// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'geo_fence_verdict.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GeoFenceVerdict {

/// Whether [metresAway] is within [allowedMetres].
 bool get isInside;/// How far from the address, in metres.
 double get metresAway;/// How far the operation is prepared to accept.
 double get allowedMetres;
/// Create a copy of GeoFenceVerdict
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeoFenceVerdictCopyWith<GeoFenceVerdict> get copyWith => _$GeoFenceVerdictCopyWithImpl<GeoFenceVerdict>(this as GeoFenceVerdict, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeoFenceVerdict&&(identical(other.isInside, isInside) || other.isInside == isInside)&&(identical(other.metresAway, metresAway) || other.metresAway == metresAway)&&(identical(other.allowedMetres, allowedMetres) || other.allowedMetres == allowedMetres));
}


@override
int get hashCode => Object.hash(runtimeType,isInside,metresAway,allowedMetres);

@override
String toString() {
  return 'GeoFenceVerdict(isInside: $isInside, metresAway: $metresAway, allowedMetres: $allowedMetres)';
}


}

/// @nodoc
abstract mixin class $GeoFenceVerdictCopyWith<$Res>  {
  factory $GeoFenceVerdictCopyWith(GeoFenceVerdict value, $Res Function(GeoFenceVerdict) _then) = _$GeoFenceVerdictCopyWithImpl;
@useResult
$Res call({
 bool isInside, double metresAway, double allowedMetres
});




}
/// @nodoc
class _$GeoFenceVerdictCopyWithImpl<$Res>
    implements $GeoFenceVerdictCopyWith<$Res> {
  _$GeoFenceVerdictCopyWithImpl(this._self, this._then);

  final GeoFenceVerdict _self;
  final $Res Function(GeoFenceVerdict) _then;

/// Create a copy of GeoFenceVerdict
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isInside = null,Object? metresAway = null,Object? allowedMetres = null,}) {
  return _then(GeoFenceVerdict(
isInside: null == isInside ? _self.isInside : isInside // ignore: cast_nullable_to_non_nullable
as bool,metresAway: null == metresAway ? _self.metresAway : metresAway // ignore: cast_nullable_to_non_nullable
as double,allowedMetres: null == allowedMetres ? _self.allowedMetres : allowedMetres // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [GeoFenceVerdict].
extension GeoFenceVerdictPatterns on GeoFenceVerdict {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GeoFenceVerdict value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GeoFenceVerdict() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GeoFenceVerdict value)  $default,){
final _that = this;
switch (_that) {
case _GeoFenceVerdict():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GeoFenceVerdict value)?  $default,){
final _that = this;
switch (_that) {
case _GeoFenceVerdict() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isInside,  double metresAway,  double allowedMetres)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GeoFenceVerdict() when $default != null:
return $default(_that.isInside,_that.metresAway,_that.allowedMetres);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isInside,  double metresAway,  double allowedMetres)  $default,) {final _that = this;
switch (_that) {
case _GeoFenceVerdict():
return $default(_that.isInside,_that.metresAway,_that.allowedMetres);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isInside,  double metresAway,  double allowedMetres)?  $default,) {final _that = this;
switch (_that) {
case _GeoFenceVerdict() when $default != null:
return $default(_that.isInside,_that.metresAway,_that.allowedMetres);case _:
  return null;

}
}

}

/// @nodoc


class _GeoFenceVerdict implements GeoFenceVerdict {
  const _GeoFenceVerdict({required this.isInside, required this.metresAway, required this.allowedMetres});
  

/// Whether [metresAway] is within [allowedMetres].
@override final  bool isInside;
/// How far from the address, in metres.
@override final  double metresAway;
/// How far the operation is prepared to accept.
@override final  double allowedMetres;

/// Create a copy of GeoFenceVerdict
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GeoFenceVerdictCopyWith<_GeoFenceVerdict> get copyWith => __$GeoFenceVerdictCopyWithImpl<_GeoFenceVerdict>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GeoFenceVerdict&&(identical(other.isInside, isInside) || other.isInside == isInside)&&(identical(other.metresAway, metresAway) || other.metresAway == metresAway)&&(identical(other.allowedMetres, allowedMetres) || other.allowedMetres == allowedMetres));
}


@override
int get hashCode => Object.hash(runtimeType,isInside,metresAway,allowedMetres);

@override
String toString() {
  return 'GeoFenceVerdict(isInside: $isInside, metresAway: $metresAway, allowedMetres: $allowedMetres)';
}


}

/// @nodoc
abstract mixin class _$GeoFenceVerdictCopyWith<$Res> implements $GeoFenceVerdictCopyWith<$Res> {
  factory _$GeoFenceVerdictCopyWith(_GeoFenceVerdict value, $Res Function(_GeoFenceVerdict) _then) = __$GeoFenceVerdictCopyWithImpl;
@override @useResult
$Res call({
 bool isInside, double metresAway, double allowedMetres
});




}
/// @nodoc
class __$GeoFenceVerdictCopyWithImpl<$Res>
    implements _$GeoFenceVerdictCopyWith<$Res> {
  __$GeoFenceVerdictCopyWithImpl(this._self, this._then);

  final _GeoFenceVerdict _self;
  final $Res Function(_GeoFenceVerdict) _then;

/// Create a copy of GeoFenceVerdict
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isInside = null,Object? metresAway = null,Object? allowedMetres = null,}) {
  return _then(_GeoFenceVerdict(
isInside: null == isInside ? _self.isInside : isInside // ignore: cast_nullable_to_non_nullable
as bool,metresAway: null == metresAway ? _self.metresAway : metresAway // ignore: cast_nullable_to_non_nullable
as double,allowedMetres: null == allowedMetres ? _self.allowedMetres : allowedMetres // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
