// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_constraint.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RouteConstraint {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteConstraint);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RouteConstraint()';
}


}

/// @nodoc
class $RouteConstraintCopyWith<$Res>  {
$RouteConstraintCopyWith(RouteConstraint _, $Res Function(RouteConstraint) __);
}


/// Adds pattern-matching-related methods to [RouteConstraint].
extension RouteConstraintPatterns on RouteConstraint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MustStartAt value)?  mustStartAt,TResult Function( MustEndAt value)?  mustEndAt,TResult Function( MaxStops value)?  maxStops,TResult Function( MaxDuration value)?  maxDuration,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MustStartAt() when mustStartAt != null:
return mustStartAt(_that);case MustEndAt() when mustEndAt != null:
return mustEndAt(_that);case MaxStops() when maxStops != null:
return maxStops(_that);case MaxDuration() when maxDuration != null:
return maxDuration(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MustStartAt value)  mustStartAt,required TResult Function( MustEndAt value)  mustEndAt,required TResult Function( MaxStops value)  maxStops,required TResult Function( MaxDuration value)  maxDuration,}){
final _that = this;
switch (_that) {
case MustStartAt():
return mustStartAt(_that);case MustEndAt():
return mustEndAt(_that);case MaxStops():
return maxStops(_that);case MaxDuration():
return maxDuration(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MustStartAt value)?  mustStartAt,TResult? Function( MustEndAt value)?  mustEndAt,TResult? Function( MaxStops value)?  maxStops,TResult? Function( MaxDuration value)?  maxDuration,}){
final _that = this;
switch (_that) {
case MustStartAt() when mustStartAt != null:
return mustStartAt(_that);case MustEndAt() when mustEndAt != null:
return mustEndAt(_that);case MaxStops() when maxStops != null:
return maxStops(_that);case MaxDuration() when maxDuration != null:
return maxDuration(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( StopId stop)?  mustStartAt,TResult Function( StopId stop)?  mustEndAt,TResult Function( int count)?  maxStops,TResult Function( Duration limit)?  maxDuration,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MustStartAt() when mustStartAt != null:
return mustStartAt(_that.stop);case MustEndAt() when mustEndAt != null:
return mustEndAt(_that.stop);case MaxStops() when maxStops != null:
return maxStops(_that.count);case MaxDuration() when maxDuration != null:
return maxDuration(_that.limit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( StopId stop)  mustStartAt,required TResult Function( StopId stop)  mustEndAt,required TResult Function( int count)  maxStops,required TResult Function( Duration limit)  maxDuration,}) {final _that = this;
switch (_that) {
case MustStartAt():
return mustStartAt(_that.stop);case MustEndAt():
return mustEndAt(_that.stop);case MaxStops():
return maxStops(_that.count);case MaxDuration():
return maxDuration(_that.limit);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( StopId stop)?  mustStartAt,TResult? Function( StopId stop)?  mustEndAt,TResult? Function( int count)?  maxStops,TResult? Function( Duration limit)?  maxDuration,}) {final _that = this;
switch (_that) {
case MustStartAt() when mustStartAt != null:
return mustStartAt(_that.stop);case MustEndAt() when mustEndAt != null:
return mustEndAt(_that.stop);case MaxStops() when maxStops != null:
return maxStops(_that.count);case MaxDuration() when maxDuration != null:
return maxDuration(_that.limit);case _:
  return null;

}
}

}

/// @nodoc


class MustStartAt extends RouteConstraint {
  const MustStartAt(this.stop): super._();
  

 final  StopId stop;

/// Create a copy of RouteConstraint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MustStartAtCopyWith<MustStartAt> get copyWith => _$MustStartAtCopyWithImpl<MustStartAt>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MustStartAt&&(identical(other.stop, stop) || other.stop == stop));
}


@override
int get hashCode => Object.hash(runtimeType,stop);

@override
String toString() {
  return 'RouteConstraint.mustStartAt(stop: $stop)';
}


}

/// @nodoc
abstract mixin class $MustStartAtCopyWith<$Res> implements $RouteConstraintCopyWith<$Res> {
  factory $MustStartAtCopyWith(MustStartAt value, $Res Function(MustStartAt) _then) = _$MustStartAtCopyWithImpl;
@useResult
$Res call({
 StopId stop
});




}
/// @nodoc
class _$MustStartAtCopyWithImpl<$Res>
    implements $MustStartAtCopyWith<$Res> {
  _$MustStartAtCopyWithImpl(this._self, this._then);

  final MustStartAt _self;
  final $Res Function(MustStartAt) _then;

/// Create a copy of RouteConstraint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? stop = null,}) {
  return _then(MustStartAt(
null == stop ? _self.stop : stop // ignore: cast_nullable_to_non_nullable
as StopId,
  ));
}


}

/// @nodoc


class MustEndAt extends RouteConstraint {
  const MustEndAt(this.stop): super._();
  

 final  StopId stop;

/// Create a copy of RouteConstraint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MustEndAtCopyWith<MustEndAt> get copyWith => _$MustEndAtCopyWithImpl<MustEndAt>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MustEndAt&&(identical(other.stop, stop) || other.stop == stop));
}


@override
int get hashCode => Object.hash(runtimeType,stop);

@override
String toString() {
  return 'RouteConstraint.mustEndAt(stop: $stop)';
}


}

/// @nodoc
abstract mixin class $MustEndAtCopyWith<$Res> implements $RouteConstraintCopyWith<$Res> {
  factory $MustEndAtCopyWith(MustEndAt value, $Res Function(MustEndAt) _then) = _$MustEndAtCopyWithImpl;
@useResult
$Res call({
 StopId stop
});




}
/// @nodoc
class _$MustEndAtCopyWithImpl<$Res>
    implements $MustEndAtCopyWith<$Res> {
  _$MustEndAtCopyWithImpl(this._self, this._then);

  final MustEndAt _self;
  final $Res Function(MustEndAt) _then;

/// Create a copy of RouteConstraint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? stop = null,}) {
  return _then(MustEndAt(
null == stop ? _self.stop : stop // ignore: cast_nullable_to_non_nullable
as StopId,
  ));
}


}

/// @nodoc


class MaxStops extends RouteConstraint {
  const MaxStops(this.count): super._();
  

 final  int count;

/// Create a copy of RouteConstraint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaxStopsCopyWith<MaxStops> get copyWith => _$MaxStopsCopyWithImpl<MaxStops>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaxStops&&(identical(other.count, count) || other.count == count));
}


@override
int get hashCode => Object.hash(runtimeType,count);

@override
String toString() {
  return 'RouteConstraint.maxStops(count: $count)';
}


}

/// @nodoc
abstract mixin class $MaxStopsCopyWith<$Res> implements $RouteConstraintCopyWith<$Res> {
  factory $MaxStopsCopyWith(MaxStops value, $Res Function(MaxStops) _then) = _$MaxStopsCopyWithImpl;
@useResult
$Res call({
 int count
});




}
/// @nodoc
class _$MaxStopsCopyWithImpl<$Res>
    implements $MaxStopsCopyWith<$Res> {
  _$MaxStopsCopyWithImpl(this._self, this._then);

  final MaxStops _self;
  final $Res Function(MaxStops) _then;

/// Create a copy of RouteConstraint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? count = null,}) {
  return _then(MaxStops(
null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class MaxDuration extends RouteConstraint {
  const MaxDuration(this.limit): super._();
  

 final  Duration limit;

/// Create a copy of RouteConstraint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaxDurationCopyWith<MaxDuration> get copyWith => _$MaxDurationCopyWithImpl<MaxDuration>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaxDuration&&(identical(other.limit, limit) || other.limit == limit));
}


@override
int get hashCode => Object.hash(runtimeType,limit);

@override
String toString() {
  return 'RouteConstraint.maxDuration(limit: $limit)';
}


}

/// @nodoc
abstract mixin class $MaxDurationCopyWith<$Res> implements $RouteConstraintCopyWith<$Res> {
  factory $MaxDurationCopyWith(MaxDuration value, $Res Function(MaxDuration) _then) = _$MaxDurationCopyWithImpl;
@useResult
$Res call({
 Duration limit
});




}
/// @nodoc
class _$MaxDurationCopyWithImpl<$Res>
    implements $MaxDurationCopyWith<$Res> {
  _$MaxDurationCopyWithImpl(this._self, this._then);

  final MaxDuration _self;
  final $Res Function(MaxDuration) _then;

/// Create a copy of RouteConstraint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? limit = null,}) {
  return _then(MaxDuration(
null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

// dart format on
