// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'eta.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Eta {

/// Which stop.
 StopId get stop;/// When the courier is expected to arrive, in UTC.
 DateTime get arrivesAt;/// When they are expected to leave, in UTC.
///
/// Arrival, plus any wait for the window to open, plus the service time.
 DateTime get departsAt;/// Whether this arrival misses the stop's window.
///
/// A plan can legitimately contain a late stop: refusing to produce one
/// would leave a courier with no route at all on a morning that started
/// badly, which is worse than a route that says which stop is at risk.
 bool get isLate;
/// Create a copy of Eta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EtaCopyWith<Eta> get copyWith => _$EtaCopyWithImpl<Eta>(this as Eta, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Eta&&(identical(other.stop, stop) || other.stop == stop)&&(identical(other.arrivesAt, arrivesAt) || other.arrivesAt == arrivesAt)&&(identical(other.departsAt, departsAt) || other.departsAt == departsAt)&&(identical(other.isLate, isLate) || other.isLate == isLate));
}


@override
int get hashCode => Object.hash(runtimeType,stop,arrivesAt,departsAt,isLate);

@override
String toString() {
  return 'Eta(stop: $stop, arrivesAt: $arrivesAt, departsAt: $departsAt, isLate: $isLate)';
}


}

/// @nodoc
abstract mixin class $EtaCopyWith<$Res>  {
  factory $EtaCopyWith(Eta value, $Res Function(Eta) _then) = _$EtaCopyWithImpl;
@useResult
$Res call({
 StopId stop, DateTime arrivesAt, DateTime departsAt, bool isLate
});




}
/// @nodoc
class _$EtaCopyWithImpl<$Res>
    implements $EtaCopyWith<$Res> {
  _$EtaCopyWithImpl(this._self, this._then);

  final Eta _self;
  final $Res Function(Eta) _then;

/// Create a copy of Eta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stop = null,Object? arrivesAt = null,Object? departsAt = null,Object? isLate = null,}) {
  return _then(Eta(
stop: null == stop ? _self.stop : stop // ignore: cast_nullable_to_non_nullable
as StopId,arrivesAt: null == arrivesAt ? _self.arrivesAt : arrivesAt // ignore: cast_nullable_to_non_nullable
as DateTime,departsAt: null == departsAt ? _self.departsAt : departsAt // ignore: cast_nullable_to_non_nullable
as DateTime,isLate: null == isLate ? _self.isLate : isLate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Eta].
extension EtaPatterns on Eta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Eta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Eta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Eta value)  $default,){
final _that = this;
switch (_that) {
case _Eta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Eta value)?  $default,){
final _that = this;
switch (_that) {
case _Eta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StopId stop,  DateTime arrivesAt,  DateTime departsAt,  bool isLate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Eta() when $default != null:
return $default(_that.stop,_that.arrivesAt,_that.departsAt,_that.isLate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StopId stop,  DateTime arrivesAt,  DateTime departsAt,  bool isLate)  $default,) {final _that = this;
switch (_that) {
case _Eta():
return $default(_that.stop,_that.arrivesAt,_that.departsAt,_that.isLate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StopId stop,  DateTime arrivesAt,  DateTime departsAt,  bool isLate)?  $default,) {final _that = this;
switch (_that) {
case _Eta() when $default != null:
return $default(_that.stop,_that.arrivesAt,_that.departsAt,_that.isLate);case _:
  return null;

}
}

}

/// @nodoc


class _Eta implements Eta {
  const _Eta({required this.stop, required this.arrivesAt, required this.departsAt, this.isLate = false});
  

/// Which stop.
@override final  StopId stop;
/// When the courier is expected to arrive, in UTC.
@override final  DateTime arrivesAt;
/// When they are expected to leave, in UTC.
///
/// Arrival, plus any wait for the window to open, plus the service time.
@override final  DateTime departsAt;
/// Whether this arrival misses the stop's window.
///
/// A plan can legitimately contain a late stop: refusing to produce one
/// would leave a courier with no route at all on a morning that started
/// badly, which is worse than a route that says which stop is at risk.
@override@JsonKey() final  bool isLate;

/// Create a copy of Eta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EtaCopyWith<_Eta> get copyWith => __$EtaCopyWithImpl<_Eta>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Eta&&(identical(other.stop, stop) || other.stop == stop)&&(identical(other.arrivesAt, arrivesAt) || other.arrivesAt == arrivesAt)&&(identical(other.departsAt, departsAt) || other.departsAt == departsAt)&&(identical(other.isLate, isLate) || other.isLate == isLate));
}


@override
int get hashCode => Object.hash(runtimeType,stop,arrivesAt,departsAt,isLate);

@override
String toString() {
  return 'Eta(stop: $stop, arrivesAt: $arrivesAt, departsAt: $departsAt, isLate: $isLate)';
}


}

/// @nodoc
abstract mixin class _$EtaCopyWith<$Res> implements $EtaCopyWith<$Res> {
  factory _$EtaCopyWith(_Eta value, $Res Function(_Eta) _then) = __$EtaCopyWithImpl;
@override @useResult
$Res call({
 StopId stop, DateTime arrivesAt, DateTime departsAt, bool isLate
});




}
/// @nodoc
class __$EtaCopyWithImpl<$Res>
    implements _$EtaCopyWith<$Res> {
  __$EtaCopyWithImpl(this._self, this._then);

  final _Eta _self;
  final $Res Function(_Eta) _then;

/// Create a copy of Eta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stop = null,Object? arrivesAt = null,Object? departsAt = null,Object? isLate = null,}) {
  return _then(_Eta(
stop: null == stop ? _self.stop : stop // ignore: cast_nullable_to_non_nullable
as StopId,arrivesAt: null == arrivesAt ? _self.arrivesAt : arrivesAt // ignore: cast_nullable_to_non_nullable
as DateTime,departsAt: null == departsAt ? _self.departsAt : departsAt // ignore: cast_nullable_to_non_nullable
as DateTime,isLate: null == isLate ? _self.isLate : isLate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
