// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'identity_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IdentityFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IdentityFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'IdentityFailure()';
}


}

/// @nodoc
class $IdentityFailureCopyWith<$Res>  {
$IdentityFailureCopyWith(IdentityFailure _, $Res Function(IdentityFailure) __);
}


/// Adds pattern-matching-related methods to [IdentityFailure].
extension IdentityFailurePatterns on IdentityFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MalformedActorId value)?  malformedActorId,TResult Function( MalformedAccessToken value)?  malformedAccessToken,TResult Function( InvalidCredentials value)?  invalidCredentials,TResult Function( ActorDisabled value)?  actorDisabled,TResult Function( NoSession value)?  noSession,TResult Function( SessionExpired value)?  sessionExpired,TResult Function( DeviceNotRegistered value)?  deviceNotRegistered,TResult Function( DeviceBindingBroken value)?  deviceBindingBroken,TResult Function( IdentityUnavailable value)?  identityUnavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MalformedActorId() when malformedActorId != null:
return malformedActorId(_that);case MalformedAccessToken() when malformedAccessToken != null:
return malformedAccessToken(_that);case InvalidCredentials() when invalidCredentials != null:
return invalidCredentials(_that);case ActorDisabled() when actorDisabled != null:
return actorDisabled(_that);case NoSession() when noSession != null:
return noSession(_that);case SessionExpired() when sessionExpired != null:
return sessionExpired(_that);case DeviceNotRegistered() when deviceNotRegistered != null:
return deviceNotRegistered(_that);case DeviceBindingBroken() when deviceBindingBroken != null:
return deviceBindingBroken(_that);case IdentityUnavailable() when identityUnavailable != null:
return identityUnavailable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MalformedActorId value)  malformedActorId,required TResult Function( MalformedAccessToken value)  malformedAccessToken,required TResult Function( InvalidCredentials value)  invalidCredentials,required TResult Function( ActorDisabled value)  actorDisabled,required TResult Function( NoSession value)  noSession,required TResult Function( SessionExpired value)  sessionExpired,required TResult Function( DeviceNotRegistered value)  deviceNotRegistered,required TResult Function( DeviceBindingBroken value)  deviceBindingBroken,required TResult Function( IdentityUnavailable value)  identityUnavailable,}){
final _that = this;
switch (_that) {
case MalformedActorId():
return malformedActorId(_that);case MalformedAccessToken():
return malformedAccessToken(_that);case InvalidCredentials():
return invalidCredentials(_that);case ActorDisabled():
return actorDisabled(_that);case NoSession():
return noSession(_that);case SessionExpired():
return sessionExpired(_that);case DeviceNotRegistered():
return deviceNotRegistered(_that);case DeviceBindingBroken():
return deviceBindingBroken(_that);case IdentityUnavailable():
return identityUnavailable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MalformedActorId value)?  malformedActorId,TResult? Function( MalformedAccessToken value)?  malformedAccessToken,TResult? Function( InvalidCredentials value)?  invalidCredentials,TResult? Function( ActorDisabled value)?  actorDisabled,TResult? Function( NoSession value)?  noSession,TResult? Function( SessionExpired value)?  sessionExpired,TResult? Function( DeviceNotRegistered value)?  deviceNotRegistered,TResult? Function( DeviceBindingBroken value)?  deviceBindingBroken,TResult? Function( IdentityUnavailable value)?  identityUnavailable,}){
final _that = this;
switch (_that) {
case MalformedActorId() when malformedActorId != null:
return malformedActorId(_that);case MalformedAccessToken() when malformedAccessToken != null:
return malformedAccessToken(_that);case InvalidCredentials() when invalidCredentials != null:
return invalidCredentials(_that);case ActorDisabled() when actorDisabled != null:
return actorDisabled(_that);case NoSession() when noSession != null:
return noSession(_that);case SessionExpired() when sessionExpired != null:
return sessionExpired(_that);case DeviceNotRegistered() when deviceNotRegistered != null:
return deviceNotRegistered(_that);case DeviceBindingBroken() when deviceBindingBroken != null:
return deviceBindingBroken(_that);case IdentityUnavailable() when identityUnavailable != null:
return identityUnavailable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String raw)?  malformedActorId,TResult Function( String reason)?  malformedAccessToken,TResult Function()?  invalidCredentials,TResult Function( ActorId actorId)?  actorDisabled,TResult Function()?  noSession,TResult Function()?  sessionExpired,TResult Function( String deviceId)?  deviceNotRegistered,TResult Function( String deviceId,  String expectedFingerprint,  String actualFingerprint)?  deviceBindingBroken,TResult Function( String? detail)?  identityUnavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MalformedActorId() when malformedActorId != null:
return malformedActorId(_that.raw);case MalformedAccessToken() when malformedAccessToken != null:
return malformedAccessToken(_that.reason);case InvalidCredentials() when invalidCredentials != null:
return invalidCredentials();case ActorDisabled() when actorDisabled != null:
return actorDisabled(_that.actorId);case NoSession() when noSession != null:
return noSession();case SessionExpired() when sessionExpired != null:
return sessionExpired();case DeviceNotRegistered() when deviceNotRegistered != null:
return deviceNotRegistered(_that.deviceId);case DeviceBindingBroken() when deviceBindingBroken != null:
return deviceBindingBroken(_that.deviceId,_that.expectedFingerprint,_that.actualFingerprint);case IdentityUnavailable() when identityUnavailable != null:
return identityUnavailable(_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String raw)  malformedActorId,required TResult Function( String reason)  malformedAccessToken,required TResult Function()  invalidCredentials,required TResult Function( ActorId actorId)  actorDisabled,required TResult Function()  noSession,required TResult Function()  sessionExpired,required TResult Function( String deviceId)  deviceNotRegistered,required TResult Function( String deviceId,  String expectedFingerprint,  String actualFingerprint)  deviceBindingBroken,required TResult Function( String? detail)  identityUnavailable,}) {final _that = this;
switch (_that) {
case MalformedActorId():
return malformedActorId(_that.raw);case MalformedAccessToken():
return malformedAccessToken(_that.reason);case InvalidCredentials():
return invalidCredentials();case ActorDisabled():
return actorDisabled(_that.actorId);case NoSession():
return noSession();case SessionExpired():
return sessionExpired();case DeviceNotRegistered():
return deviceNotRegistered(_that.deviceId);case DeviceBindingBroken():
return deviceBindingBroken(_that.deviceId,_that.expectedFingerprint,_that.actualFingerprint);case IdentityUnavailable():
return identityUnavailable(_that.detail);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String raw)?  malformedActorId,TResult? Function( String reason)?  malformedAccessToken,TResult? Function()?  invalidCredentials,TResult? Function( ActorId actorId)?  actorDisabled,TResult? Function()?  noSession,TResult? Function()?  sessionExpired,TResult? Function( String deviceId)?  deviceNotRegistered,TResult? Function( String deviceId,  String expectedFingerprint,  String actualFingerprint)?  deviceBindingBroken,TResult? Function( String? detail)?  identityUnavailable,}) {final _that = this;
switch (_that) {
case MalformedActorId() when malformedActorId != null:
return malformedActorId(_that.raw);case MalformedAccessToken() when malformedAccessToken != null:
return malformedAccessToken(_that.reason);case InvalidCredentials() when invalidCredentials != null:
return invalidCredentials();case ActorDisabled() when actorDisabled != null:
return actorDisabled(_that.actorId);case NoSession() when noSession != null:
return noSession();case SessionExpired() when sessionExpired != null:
return sessionExpired();case DeviceNotRegistered() when deviceNotRegistered != null:
return deviceNotRegistered(_that.deviceId);case DeviceBindingBroken() when deviceBindingBroken != null:
return deviceBindingBroken(_that.deviceId,_that.expectedFingerprint,_that.actualFingerprint);case IdentityUnavailable() when identityUnavailable != null:
return identityUnavailable(_that.detail);case _:
  return null;

}
}

}

/// @nodoc


class MalformedActorId extends IdentityFailure {
  const MalformedActorId(this.raw): super._();
  

 final  String raw;

/// Create a copy of IdentityFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MalformedActorIdCopyWith<MalformedActorId> get copyWith => _$MalformedActorIdCopyWithImpl<MalformedActorId>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MalformedActorId&&(identical(other.raw, raw) || other.raw == raw));
}


@override
int get hashCode => Object.hash(runtimeType,raw);

@override
String toString() {
  return 'IdentityFailure.malformedActorId(raw: $raw)';
}


}

/// @nodoc
abstract mixin class $MalformedActorIdCopyWith<$Res> implements $IdentityFailureCopyWith<$Res> {
  factory $MalformedActorIdCopyWith(MalformedActorId value, $Res Function(MalformedActorId) _then) = _$MalformedActorIdCopyWithImpl;
@useResult
$Res call({
 String raw
});




}
/// @nodoc
class _$MalformedActorIdCopyWithImpl<$Res>
    implements $MalformedActorIdCopyWith<$Res> {
  _$MalformedActorIdCopyWithImpl(this._self, this._then);

  final MalformedActorId _self;
  final $Res Function(MalformedActorId) _then;

/// Create a copy of IdentityFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? raw = null,}) {
  return _then(MalformedActorId(
null == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MalformedAccessToken extends IdentityFailure {
  const MalformedAccessToken(this.reason): super._();
  

 final  String reason;

/// Create a copy of IdentityFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MalformedAccessTokenCopyWith<MalformedAccessToken> get copyWith => _$MalformedAccessTokenCopyWithImpl<MalformedAccessToken>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MalformedAccessToken&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'IdentityFailure.malformedAccessToken(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $MalformedAccessTokenCopyWith<$Res> implements $IdentityFailureCopyWith<$Res> {
  factory $MalformedAccessTokenCopyWith(MalformedAccessToken value, $Res Function(MalformedAccessToken) _then) = _$MalformedAccessTokenCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$MalformedAccessTokenCopyWithImpl<$Res>
    implements $MalformedAccessTokenCopyWith<$Res> {
  _$MalformedAccessTokenCopyWithImpl(this._self, this._then);

  final MalformedAccessToken _self;
  final $Res Function(MalformedAccessToken) _then;

/// Create a copy of IdentityFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(MalformedAccessToken(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class InvalidCredentials extends IdentityFailure {
  const InvalidCredentials(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvalidCredentials);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'IdentityFailure.invalidCredentials()';
}


}




/// @nodoc


class ActorDisabled extends IdentityFailure {
  const ActorDisabled(this.actorId): super._();
  

 final  ActorId actorId;

/// Create a copy of IdentityFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActorDisabledCopyWith<ActorDisabled> get copyWith => _$ActorDisabledCopyWithImpl<ActorDisabled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActorDisabled&&(identical(other.actorId, actorId) || other.actorId == actorId));
}


@override
int get hashCode => Object.hash(runtimeType,actorId);

@override
String toString() {
  return 'IdentityFailure.actorDisabled(actorId: $actorId)';
}


}

/// @nodoc
abstract mixin class $ActorDisabledCopyWith<$Res> implements $IdentityFailureCopyWith<$Res> {
  factory $ActorDisabledCopyWith(ActorDisabled value, $Res Function(ActorDisabled) _then) = _$ActorDisabledCopyWithImpl;
@useResult
$Res call({
 ActorId actorId
});




}
/// @nodoc
class _$ActorDisabledCopyWithImpl<$Res>
    implements $ActorDisabledCopyWith<$Res> {
  _$ActorDisabledCopyWithImpl(this._self, this._then);

  final ActorDisabled _self;
  final $Res Function(ActorDisabled) _then;

/// Create a copy of IdentityFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? actorId = null,}) {
  return _then(ActorDisabled(
null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as ActorId,
  ));
}


}

/// @nodoc


class NoSession extends IdentityFailure {
  const NoSession(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoSession);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'IdentityFailure.noSession()';
}


}




/// @nodoc


class SessionExpired extends IdentityFailure {
  const SessionExpired(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionExpired);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'IdentityFailure.sessionExpired()';
}


}




/// @nodoc


class DeviceNotRegistered extends IdentityFailure {
  const DeviceNotRegistered(this.deviceId): super._();
  

 final  String deviceId;

/// Create a copy of IdentityFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceNotRegisteredCopyWith<DeviceNotRegistered> get copyWith => _$DeviceNotRegisteredCopyWithImpl<DeviceNotRegistered>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceNotRegistered&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId);

@override
String toString() {
  return 'IdentityFailure.deviceNotRegistered(deviceId: $deviceId)';
}


}

/// @nodoc
abstract mixin class $DeviceNotRegisteredCopyWith<$Res> implements $IdentityFailureCopyWith<$Res> {
  factory $DeviceNotRegisteredCopyWith(DeviceNotRegistered value, $Res Function(DeviceNotRegistered) _then) = _$DeviceNotRegisteredCopyWithImpl;
@useResult
$Res call({
 String deviceId
});




}
/// @nodoc
class _$DeviceNotRegisteredCopyWithImpl<$Res>
    implements $DeviceNotRegisteredCopyWith<$Res> {
  _$DeviceNotRegisteredCopyWithImpl(this._self, this._then);

  final DeviceNotRegistered _self;
  final $Res Function(DeviceNotRegistered) _then;

/// Create a copy of IdentityFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? deviceId = null,}) {
  return _then(DeviceNotRegistered(
null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DeviceBindingBroken extends IdentityFailure {
  const DeviceBindingBroken({required this.deviceId, required this.expectedFingerprint, required this.actualFingerprint}): super._();
  

 final  String deviceId;
 final  String expectedFingerprint;
 final  String actualFingerprint;

/// Create a copy of IdentityFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceBindingBrokenCopyWith<DeviceBindingBroken> get copyWith => _$DeviceBindingBrokenCopyWithImpl<DeviceBindingBroken>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceBindingBroken&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.expectedFingerprint, expectedFingerprint) || other.expectedFingerprint == expectedFingerprint)&&(identical(other.actualFingerprint, actualFingerprint) || other.actualFingerprint == actualFingerprint));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,expectedFingerprint,actualFingerprint);

@override
String toString() {
  return 'IdentityFailure.deviceBindingBroken(deviceId: $deviceId, expectedFingerprint: $expectedFingerprint, actualFingerprint: $actualFingerprint)';
}


}

/// @nodoc
abstract mixin class $DeviceBindingBrokenCopyWith<$Res> implements $IdentityFailureCopyWith<$Res> {
  factory $DeviceBindingBrokenCopyWith(DeviceBindingBroken value, $Res Function(DeviceBindingBroken) _then) = _$DeviceBindingBrokenCopyWithImpl;
@useResult
$Res call({
 String deviceId, String expectedFingerprint, String actualFingerprint
});




}
/// @nodoc
class _$DeviceBindingBrokenCopyWithImpl<$Res>
    implements $DeviceBindingBrokenCopyWith<$Res> {
  _$DeviceBindingBrokenCopyWithImpl(this._self, this._then);

  final DeviceBindingBroken _self;
  final $Res Function(DeviceBindingBroken) _then;

/// Create a copy of IdentityFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? expectedFingerprint = null,Object? actualFingerprint = null,}) {
  return _then(DeviceBindingBroken(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,expectedFingerprint: null == expectedFingerprint ? _self.expectedFingerprint : expectedFingerprint // ignore: cast_nullable_to_non_nullable
as String,actualFingerprint: null == actualFingerprint ? _self.actualFingerprint : actualFingerprint // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class IdentityUnavailable extends IdentityFailure {
  const IdentityUnavailable({this.detail}): super._();
  

 final  String? detail;

/// Create a copy of IdentityFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IdentityUnavailableCopyWith<IdentityUnavailable> get copyWith => _$IdentityUnavailableCopyWithImpl<IdentityUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IdentityUnavailable&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'IdentityFailure.identityUnavailable(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $IdentityUnavailableCopyWith<$Res> implements $IdentityFailureCopyWith<$Res> {
  factory $IdentityUnavailableCopyWith(IdentityUnavailable value, $Res Function(IdentityUnavailable) _then) = _$IdentityUnavailableCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$IdentityUnavailableCopyWithImpl<$Res>
    implements $IdentityUnavailableCopyWith<$Res> {
  _$IdentityUnavailableCopyWithImpl(this._self, this._then);

  final IdentityUnavailable _self;
  final $Res Function(IdentityUnavailable) _then;

/// Create a copy of IdentityFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(IdentityUnavailable(
detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
