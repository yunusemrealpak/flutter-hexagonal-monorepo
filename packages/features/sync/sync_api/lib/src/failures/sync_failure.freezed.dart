// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SyncFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncFailure()';
}


}

/// @nodoc
class $SyncFailureCopyWith<$Res>  {
$SyncFailureCopyWith(SyncFailure _, $Res Function(SyncFailure) __);
}


/// Adds pattern-matching-related methods to [SyncFailure].
extension SyncFailurePatterns on SyncFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SyncOffline value)?  offline,TResult Function( SyncTransportFailed value)?  transportFailed,TResult Function( SyncRejected value)?  rejected,TResult Function( SyncConflict value)?  conflict,TResult Function( OutboxUnavailable value)?  outboxUnavailable,TResult Function( MalformedEntry value)?  malformedEntry,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SyncOffline() when offline != null:
return offline(_that);case SyncTransportFailed() when transportFailed != null:
return transportFailed(_that);case SyncRejected() when rejected != null:
return rejected(_that);case SyncConflict() when conflict != null:
return conflict(_that);case OutboxUnavailable() when outboxUnavailable != null:
return outboxUnavailable(_that);case MalformedEntry() when malformedEntry != null:
return malformedEntry(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SyncOffline value)  offline,required TResult Function( SyncTransportFailed value)  transportFailed,required TResult Function( SyncRejected value)  rejected,required TResult Function( SyncConflict value)  conflict,required TResult Function( OutboxUnavailable value)  outboxUnavailable,required TResult Function( MalformedEntry value)  malformedEntry,}){
final _that = this;
switch (_that) {
case SyncOffline():
return offline(_that);case SyncTransportFailed():
return transportFailed(_that);case SyncRejected():
return rejected(_that);case SyncConflict():
return conflict(_that);case OutboxUnavailable():
return outboxUnavailable(_that);case MalformedEntry():
return malformedEntry(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SyncOffline value)?  offline,TResult? Function( SyncTransportFailed value)?  transportFailed,TResult? Function( SyncRejected value)?  rejected,TResult? Function( SyncConflict value)?  conflict,TResult? Function( OutboxUnavailable value)?  outboxUnavailable,TResult? Function( MalformedEntry value)?  malformedEntry,}){
final _that = this;
switch (_that) {
case SyncOffline() when offline != null:
return offline(_that);case SyncTransportFailed() when transportFailed != null:
return transportFailed(_that);case SyncRejected() when rejected != null:
return rejected(_that);case SyncConflict() when conflict != null:
return conflict(_that);case OutboxUnavailable() when outboxUnavailable != null:
return outboxUnavailable(_that);case MalformedEntry() when malformedEntry != null:
return malformedEntry(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  offline,TResult Function( String? detail)?  transportFailed,TResult Function( String reason,  int? statusCode)?  rejected,TResult Function( String cursor,  String detail)?  conflict,TResult Function( String? detail)?  outboxUnavailable,TResult Function( String field,  String reason)?  malformedEntry,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SyncOffline() when offline != null:
return offline();case SyncTransportFailed() when transportFailed != null:
return transportFailed(_that.detail);case SyncRejected() when rejected != null:
return rejected(_that.reason,_that.statusCode);case SyncConflict() when conflict != null:
return conflict(_that.cursor,_that.detail);case OutboxUnavailable() when outboxUnavailable != null:
return outboxUnavailable(_that.detail);case MalformedEntry() when malformedEntry != null:
return malformedEntry(_that.field,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  offline,required TResult Function( String? detail)  transportFailed,required TResult Function( String reason,  int? statusCode)  rejected,required TResult Function( String cursor,  String detail)  conflict,required TResult Function( String? detail)  outboxUnavailable,required TResult Function( String field,  String reason)  malformedEntry,}) {final _that = this;
switch (_that) {
case SyncOffline():
return offline();case SyncTransportFailed():
return transportFailed(_that.detail);case SyncRejected():
return rejected(_that.reason,_that.statusCode);case SyncConflict():
return conflict(_that.cursor,_that.detail);case OutboxUnavailable():
return outboxUnavailable(_that.detail);case MalformedEntry():
return malformedEntry(_that.field,_that.reason);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  offline,TResult? Function( String? detail)?  transportFailed,TResult? Function( String reason,  int? statusCode)?  rejected,TResult? Function( String cursor,  String detail)?  conflict,TResult? Function( String? detail)?  outboxUnavailable,TResult? Function( String field,  String reason)?  malformedEntry,}) {final _that = this;
switch (_that) {
case SyncOffline() when offline != null:
return offline();case SyncTransportFailed() when transportFailed != null:
return transportFailed(_that.detail);case SyncRejected() when rejected != null:
return rejected(_that.reason,_that.statusCode);case SyncConflict() when conflict != null:
return conflict(_that.cursor,_that.detail);case OutboxUnavailable() when outboxUnavailable != null:
return outboxUnavailable(_that.detail);case MalformedEntry() when malformedEntry != null:
return malformedEntry(_that.field,_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class SyncOffline extends SyncFailure {
  const SyncOffline(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncOffline);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncFailure.offline()';
}


}




/// @nodoc


class SyncTransportFailed extends SyncFailure {
  const SyncTransportFailed({this.detail}): super._();
  

 final  String? detail;

/// Create a copy of SyncFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncTransportFailedCopyWith<SyncTransportFailed> get copyWith => _$SyncTransportFailedCopyWithImpl<SyncTransportFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncTransportFailed&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'SyncFailure.transportFailed(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $SyncTransportFailedCopyWith<$Res> implements $SyncFailureCopyWith<$Res> {
  factory $SyncTransportFailedCopyWith(SyncTransportFailed value, $Res Function(SyncTransportFailed) _then) = _$SyncTransportFailedCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$SyncTransportFailedCopyWithImpl<$Res>
    implements $SyncTransportFailedCopyWith<$Res> {
  _$SyncTransportFailedCopyWithImpl(this._self, this._then);

  final SyncTransportFailed _self;
  final $Res Function(SyncTransportFailed) _then;

/// Create a copy of SyncFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(SyncTransportFailed(
detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class SyncRejected extends SyncFailure {
  const SyncRejected({required this.reason, this.statusCode}): super._();
  

 final  String reason;
 final  int? statusCode;

/// Create a copy of SyncFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncRejectedCopyWith<SyncRejected> get copyWith => _$SyncRejectedCopyWithImpl<SyncRejected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncRejected&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode));
}


@override
int get hashCode => Object.hash(runtimeType,reason,statusCode);

@override
String toString() {
  return 'SyncFailure.rejected(reason: $reason, statusCode: $statusCode)';
}


}

/// @nodoc
abstract mixin class $SyncRejectedCopyWith<$Res> implements $SyncFailureCopyWith<$Res> {
  factory $SyncRejectedCopyWith(SyncRejected value, $Res Function(SyncRejected) _then) = _$SyncRejectedCopyWithImpl;
@useResult
$Res call({
 String reason, int? statusCode
});




}
/// @nodoc
class _$SyncRejectedCopyWithImpl<$Res>
    implements $SyncRejectedCopyWith<$Res> {
  _$SyncRejectedCopyWithImpl(this._self, this._then);

  final SyncRejected _self;
  final $Res Function(SyncRejected) _then;

/// Create a copy of SyncFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? statusCode = freezed,}) {
  return _then(SyncRejected(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class SyncConflict extends SyncFailure {
  const SyncConflict({required this.cursor, required this.detail}): super._();
  

 final  String cursor;
 final  String detail;

/// Create a copy of SyncFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncConflictCopyWith<SyncConflict> get copyWith => _$SyncConflictCopyWithImpl<SyncConflict>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncConflict&&(identical(other.cursor, cursor) || other.cursor == cursor)&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,cursor,detail);

@override
String toString() {
  return 'SyncFailure.conflict(cursor: $cursor, detail: $detail)';
}


}

/// @nodoc
abstract mixin class $SyncConflictCopyWith<$Res> implements $SyncFailureCopyWith<$Res> {
  factory $SyncConflictCopyWith(SyncConflict value, $Res Function(SyncConflict) _then) = _$SyncConflictCopyWithImpl;
@useResult
$Res call({
 String cursor, String detail
});




}
/// @nodoc
class _$SyncConflictCopyWithImpl<$Res>
    implements $SyncConflictCopyWith<$Res> {
  _$SyncConflictCopyWithImpl(this._self, this._then);

  final SyncConflict _self;
  final $Res Function(SyncConflict) _then;

/// Create a copy of SyncFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cursor = null,Object? detail = null,}) {
  return _then(SyncConflict(
cursor: null == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class OutboxUnavailable extends SyncFailure {
  const OutboxUnavailable({this.detail}): super._();
  

 final  String? detail;

/// Create a copy of SyncFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutboxUnavailableCopyWith<OutboxUnavailable> get copyWith => _$OutboxUnavailableCopyWithImpl<OutboxUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutboxUnavailable&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'SyncFailure.outboxUnavailable(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $OutboxUnavailableCopyWith<$Res> implements $SyncFailureCopyWith<$Res> {
  factory $OutboxUnavailableCopyWith(OutboxUnavailable value, $Res Function(OutboxUnavailable) _then) = _$OutboxUnavailableCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$OutboxUnavailableCopyWithImpl<$Res>
    implements $OutboxUnavailableCopyWith<$Res> {
  _$OutboxUnavailableCopyWithImpl(this._self, this._then);

  final OutboxUnavailable _self;
  final $Res Function(OutboxUnavailable) _then;

/// Create a copy of SyncFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(OutboxUnavailable(
detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class MalformedEntry extends SyncFailure {
  const MalformedEntry({required this.field, required this.reason}): super._();
  

 final  String field;
 final  String reason;

/// Create a copy of SyncFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MalformedEntryCopyWith<MalformedEntry> get copyWith => _$MalformedEntryCopyWithImpl<MalformedEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MalformedEntry&&(identical(other.field, field) || other.field == field)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,field,reason);

@override
String toString() {
  return 'SyncFailure.malformedEntry(field: $field, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $MalformedEntryCopyWith<$Res> implements $SyncFailureCopyWith<$Res> {
  factory $MalformedEntryCopyWith(MalformedEntry value, $Res Function(MalformedEntry) _then) = _$MalformedEntryCopyWithImpl;
@useResult
$Res call({
 String field, String reason
});




}
/// @nodoc
class _$MalformedEntryCopyWithImpl<$Res>
    implements $MalformedEntryCopyWith<$Res> {
  _$MalformedEntryCopyWithImpl(this._self, this._then);

  final MalformedEntry _self;
  final $Res Function(MalformedEntry) _then;

/// Create a copy of SyncFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field = null,Object? reason = null,}) {
  return _then(MalformedEntry(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
