// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Session {

/// Who is signed in.
 Actor get actor;/// The bearer token requests are made with.
 AccessToken get accessToken;/// The device this session is tied to.
 DeviceBinding get deviceBinding;/// The instant, in UTC, past which the session can no longer be refreshed
/// and the actor has to sign in again.
///
/// Distinct from `accessToken.expiresAt`, and much later. The token is
/// short-lived so that a leak is short-lived; the session is long-lived so
/// that a courier is not asked for a password halfway through a shift.
 DateTime get refreshableUntil;
/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionCopyWith<Session> get copyWith => _$SessionCopyWithImpl<Session>(this as Session, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Session&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.deviceBinding, deviceBinding) || other.deviceBinding == deviceBinding)&&(identical(other.refreshableUntil, refreshableUntil) || other.refreshableUntil == refreshableUntil));
}


@override
int get hashCode => Object.hash(runtimeType,actor,accessToken,deviceBinding,refreshableUntil);

@override
String toString() {
  return 'Session(actor: $actor, accessToken: $accessToken, deviceBinding: $deviceBinding, refreshableUntil: $refreshableUntil)';
}


}

/// @nodoc
abstract mixin class $SessionCopyWith<$Res>  {
  factory $SessionCopyWith(Session value, $Res Function(Session) _then) = _$SessionCopyWithImpl;
@useResult
$Res call({
 Actor actor, AccessToken accessToken, DeviceBinding deviceBinding, DateTime refreshableUntil
});


$DeviceBindingCopyWith<$Res> get deviceBinding;

}
/// @nodoc
class _$SessionCopyWithImpl<$Res>
    implements $SessionCopyWith<$Res> {
  _$SessionCopyWithImpl(this._self, this._then);

  final Session _self;
  final $Res Function(Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? actor = null,Object? accessToken = null,Object? deviceBinding = null,Object? refreshableUntil = null,}) {
  return _then(Session(
actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as Actor,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as AccessToken,deviceBinding: null == deviceBinding ? _self.deviceBinding : deviceBinding // ignore: cast_nullable_to_non_nullable
as DeviceBinding,refreshableUntil: null == refreshableUntil ? _self.refreshableUntil : refreshableUntil // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceBindingCopyWith<$Res> get deviceBinding {
  
  return $DeviceBindingCopyWith<$Res>(_self.deviceBinding, (value) {
    return _then(_self.copyWith(deviceBinding: value));
  });
}
}


/// Adds pattern-matching-related methods to [Session].
extension SessionPatterns on Session {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Session value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Session() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Session value)  $default,){
final _that = this;
switch (_that) {
case _Session():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Session value)?  $default,){
final _that = this;
switch (_that) {
case _Session() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Actor actor,  AccessToken accessToken,  DeviceBinding deviceBinding,  DateTime refreshableUntil)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.actor,_that.accessToken,_that.deviceBinding,_that.refreshableUntil);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Actor actor,  AccessToken accessToken,  DeviceBinding deviceBinding,  DateTime refreshableUntil)  $default,) {final _that = this;
switch (_that) {
case _Session():
return $default(_that.actor,_that.accessToken,_that.deviceBinding,_that.refreshableUntil);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Actor actor,  AccessToken accessToken,  DeviceBinding deviceBinding,  DateTime refreshableUntil)?  $default,) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.actor,_that.accessToken,_that.deviceBinding,_that.refreshableUntil);case _:
  return null;

}
}

}

/// @nodoc


class _Session extends Session {
  const _Session({required this.actor, required this.accessToken, required this.deviceBinding, required this.refreshableUntil}): super._();
  

/// Who is signed in.
@override final  Actor actor;
/// The bearer token requests are made with.
@override final  AccessToken accessToken;
/// The device this session is tied to.
@override final  DeviceBinding deviceBinding;
/// The instant, in UTC, past which the session can no longer be refreshed
/// and the actor has to sign in again.
///
/// Distinct from `accessToken.expiresAt`, and much later. The token is
/// short-lived so that a leak is short-lived; the session is long-lived so
/// that a courier is not asked for a password halfway through a shift.
@override final  DateTime refreshableUntil;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionCopyWith<_Session> get copyWith => __$SessionCopyWithImpl<_Session>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Session&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.deviceBinding, deviceBinding) || other.deviceBinding == deviceBinding)&&(identical(other.refreshableUntil, refreshableUntil) || other.refreshableUntil == refreshableUntil));
}


@override
int get hashCode => Object.hash(runtimeType,actor,accessToken,deviceBinding,refreshableUntil);

@override
String toString() {
  return 'Session(actor: $actor, accessToken: $accessToken, deviceBinding: $deviceBinding, refreshableUntil: $refreshableUntil)';
}


}

/// @nodoc
abstract mixin class _$SessionCopyWith<$Res> implements $SessionCopyWith<$Res> {
  factory _$SessionCopyWith(_Session value, $Res Function(_Session) _then) = __$SessionCopyWithImpl;
@override @useResult
$Res call({
 Actor actor, AccessToken accessToken, DeviceBinding deviceBinding, DateTime refreshableUntil
});


@override $DeviceBindingCopyWith<$Res> get deviceBinding;

}
/// @nodoc
class __$SessionCopyWithImpl<$Res>
    implements _$SessionCopyWith<$Res> {
  __$SessionCopyWithImpl(this._self, this._then);

  final _Session _self;
  final $Res Function(_Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? actor = null,Object? accessToken = null,Object? deviceBinding = null,Object? refreshableUntil = null,}) {
  return _then(_Session(
actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as Actor,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as AccessToken,deviceBinding: null == deviceBinding ? _self.deviceBinding : deviceBinding // ignore: cast_nullable_to_non_nullable
as DeviceBinding,refreshableUntil: null == refreshableUntil ? _self.refreshableUntil : refreshableUntil // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceBindingCopyWith<$Res> get deviceBinding {
  
  return $DeviceBindingCopyWith<$Res>(_self.deviceBinding, (value) {
    return _then(_self.copyWith(deviceBinding: value));
  });
}
}

// dart format on
