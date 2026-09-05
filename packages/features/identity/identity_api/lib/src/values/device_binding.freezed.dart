// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_binding.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeviceBinding {

/// The installation's stable identifier.
 String get deviceId;/// A digest of the device characteristics the binding was issued against.
 String get fingerprint;/// When the binding was issued, in UTC, as reported by the `Clock` port.
 DateTime get boundAt;
/// Create a copy of DeviceBinding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceBindingCopyWith<DeviceBinding> get copyWith => _$DeviceBindingCopyWithImpl<DeviceBinding>(this as DeviceBinding, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceBinding&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint)&&(identical(other.boundAt, boundAt) || other.boundAt == boundAt));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,fingerprint,boundAt);

@override
String toString() {
  return 'DeviceBinding(deviceId: $deviceId, fingerprint: $fingerprint, boundAt: $boundAt)';
}


}

/// @nodoc
abstract mixin class $DeviceBindingCopyWith<$Res>  {
  factory $DeviceBindingCopyWith(DeviceBinding value, $Res Function(DeviceBinding) _then) = _$DeviceBindingCopyWithImpl;
@useResult
$Res call({
 String deviceId, String fingerprint, DateTime boundAt
});




}
/// @nodoc
class _$DeviceBindingCopyWithImpl<$Res>
    implements $DeviceBindingCopyWith<$Res> {
  _$DeviceBindingCopyWithImpl(this._self, this._then);

  final DeviceBinding _self;
  final $Res Function(DeviceBinding) _then;

/// Create a copy of DeviceBinding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? fingerprint = null,Object? boundAt = null,}) {
  return _then(DeviceBinding(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,fingerprint: null == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String,boundAt: null == boundAt ? _self.boundAt : boundAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceBinding].
extension DeviceBindingPatterns on DeviceBinding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceBinding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceBinding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceBinding value)  $default,){
final _that = this;
switch (_that) {
case _DeviceBinding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceBinding value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceBinding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String deviceId,  String fingerprint,  DateTime boundAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceBinding() when $default != null:
return $default(_that.deviceId,_that.fingerprint,_that.boundAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String deviceId,  String fingerprint,  DateTime boundAt)  $default,) {final _that = this;
switch (_that) {
case _DeviceBinding():
return $default(_that.deviceId,_that.fingerprint,_that.boundAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String deviceId,  String fingerprint,  DateTime boundAt)?  $default,) {final _that = this;
switch (_that) {
case _DeviceBinding() when $default != null:
return $default(_that.deviceId,_that.fingerprint,_that.boundAt);case _:
  return null;

}
}

}

/// @nodoc


class _DeviceBinding extends DeviceBinding {
  const _DeviceBinding({required this.deviceId, required this.fingerprint, required this.boundAt}): super._();
  

/// The installation's stable identifier.
@override final  String deviceId;
/// A digest of the device characteristics the binding was issued against.
@override final  String fingerprint;
/// When the binding was issued, in UTC, as reported by the `Clock` port.
@override final  DateTime boundAt;

/// Create a copy of DeviceBinding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceBindingCopyWith<_DeviceBinding> get copyWith => __$DeviceBindingCopyWithImpl<_DeviceBinding>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceBinding&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint)&&(identical(other.boundAt, boundAt) || other.boundAt == boundAt));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,fingerprint,boundAt);

@override
String toString() {
  return 'DeviceBinding(deviceId: $deviceId, fingerprint: $fingerprint, boundAt: $boundAt)';
}


}

/// @nodoc
abstract mixin class _$DeviceBindingCopyWith<$Res> implements $DeviceBindingCopyWith<$Res> {
  factory _$DeviceBindingCopyWith(_DeviceBinding value, $Res Function(_DeviceBinding) _then) = __$DeviceBindingCopyWithImpl;
@override @useResult
$Res call({
 String deviceId, String fingerprint, DateTime boundAt
});




}
/// @nodoc
class __$DeviceBindingCopyWithImpl<$Res>
    implements _$DeviceBindingCopyWith<$Res> {
  __$DeviceBindingCopyWithImpl(this._self, this._then);

  final _DeviceBinding _self;
  final $Res Function(_DeviceBinding) _then;

/// Create a copy of DeviceBinding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? fingerprint = null,Object? boundAt = null,}) {
  return _then(_DeviceBinding(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,fingerprint: null == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String,boundAt: null == boundAt ? _self.boundAt : boundAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
