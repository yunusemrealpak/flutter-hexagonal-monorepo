// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_envelope.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SyncEnvelope {

/// The entry this attempt belongs to, and the handle the server
/// de-duplicates on.
 OutboxEntryId get id;/// The routing key the feature declared.
 String get type;/// The command body, still opaque.
 String get payload;/// What the feature wants done if the server has moved on.
 ConflictPolicy get policy;/// When the work happened, in the server's frame of reference.
 DateTime get queuedAt;/// Which attempt this is, counting from 1.
///
/// Sent so that the server can tell a retry from a fresh write in its own
/// logs. Nothing about the request changes because of it — a retry that
/// behaved differently from the first attempt would defeat the idempotency
/// the identifier buys.
 int get attempt;/// Where this device believes the server is.
 SyncCursor get cursor;
/// Create a copy of SyncEnvelope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncEnvelopeCopyWith<SyncEnvelope> get copyWith => _$SyncEnvelopeCopyWithImpl<SyncEnvelope>(this as SyncEnvelope, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncEnvelope&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.policy, policy) || other.policy == policy)&&(identical(other.queuedAt, queuedAt) || other.queuedAt == queuedAt)&&(identical(other.attempt, attempt) || other.attempt == attempt)&&(identical(other.cursor, cursor) || other.cursor == cursor));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,payload,policy,queuedAt,attempt,cursor);

@override
String toString() {
  return 'SyncEnvelope(id: $id, type: $type, payload: $payload, policy: $policy, queuedAt: $queuedAt, attempt: $attempt, cursor: $cursor)';
}


}

/// @nodoc
abstract mixin class $SyncEnvelopeCopyWith<$Res>  {
  factory $SyncEnvelopeCopyWith(SyncEnvelope value, $Res Function(SyncEnvelope) _then) = _$SyncEnvelopeCopyWithImpl;
@useResult
$Res call({
 OutboxEntryId id, String type, String payload, ConflictPolicy policy, DateTime queuedAt, int attempt, SyncCursor cursor
});


$ConflictPolicyCopyWith<$Res> get policy;

}
/// @nodoc
class _$SyncEnvelopeCopyWithImpl<$Res>
    implements $SyncEnvelopeCopyWith<$Res> {
  _$SyncEnvelopeCopyWithImpl(this._self, this._then);

  final SyncEnvelope _self;
  final $Res Function(SyncEnvelope) _then;

/// Create a copy of SyncEnvelope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? payload = null,Object? policy = null,Object? queuedAt = null,Object? attempt = null,Object? cursor = null,}) {
  return _then(SyncEnvelope(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as OutboxEntryId,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as ConflictPolicy,queuedAt: null == queuedAt ? _self.queuedAt : queuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,cursor: null == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as SyncCursor,
  ));
}
/// Create a copy of SyncEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConflictPolicyCopyWith<$Res> get policy {
  
  return $ConflictPolicyCopyWith<$Res>(_self.policy, (value) {
    return _then(_self.copyWith(policy: value));
  });
}
}


/// Adds pattern-matching-related methods to [SyncEnvelope].
extension SyncEnvelopePatterns on SyncEnvelope {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncEnvelope value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncEnvelope() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncEnvelope value)  $default,){
final _that = this;
switch (_that) {
case _SyncEnvelope():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncEnvelope value)?  $default,){
final _that = this;
switch (_that) {
case _SyncEnvelope() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OutboxEntryId id,  String type,  String payload,  ConflictPolicy policy,  DateTime queuedAt,  int attempt,  SyncCursor cursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncEnvelope() when $default != null:
return $default(_that.id,_that.type,_that.payload,_that.policy,_that.queuedAt,_that.attempt,_that.cursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OutboxEntryId id,  String type,  String payload,  ConflictPolicy policy,  DateTime queuedAt,  int attempt,  SyncCursor cursor)  $default,) {final _that = this;
switch (_that) {
case _SyncEnvelope():
return $default(_that.id,_that.type,_that.payload,_that.policy,_that.queuedAt,_that.attempt,_that.cursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OutboxEntryId id,  String type,  String payload,  ConflictPolicy policy,  DateTime queuedAt,  int attempt,  SyncCursor cursor)?  $default,) {final _that = this;
switch (_that) {
case _SyncEnvelope() when $default != null:
return $default(_that.id,_that.type,_that.payload,_that.policy,_that.queuedAt,_that.attempt,_that.cursor);case _:
  return null;

}
}

}

/// @nodoc


class _SyncEnvelope implements SyncEnvelope {
  const _SyncEnvelope({required this.id, required this.type, required this.payload, required this.policy, required this.queuedAt, required this.attempt, required this.cursor});
  

/// The entry this attempt belongs to, and the handle the server
/// de-duplicates on.
@override final  OutboxEntryId id;
/// The routing key the feature declared.
@override final  String type;
/// The command body, still opaque.
@override final  String payload;
/// What the feature wants done if the server has moved on.
@override final  ConflictPolicy policy;
/// When the work happened, in the server's frame of reference.
@override final  DateTime queuedAt;
/// Which attempt this is, counting from 1.
///
/// Sent so that the server can tell a retry from a fresh write in its own
/// logs. Nothing about the request changes because of it — a retry that
/// behaved differently from the first attempt would defeat the idempotency
/// the identifier buys.
@override final  int attempt;
/// Where this device believes the server is.
@override final  SyncCursor cursor;

/// Create a copy of SyncEnvelope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncEnvelopeCopyWith<_SyncEnvelope> get copyWith => __$SyncEnvelopeCopyWithImpl<_SyncEnvelope>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncEnvelope&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.policy, policy) || other.policy == policy)&&(identical(other.queuedAt, queuedAt) || other.queuedAt == queuedAt)&&(identical(other.attempt, attempt) || other.attempt == attempt)&&(identical(other.cursor, cursor) || other.cursor == cursor));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,payload,policy,queuedAt,attempt,cursor);

@override
String toString() {
  return 'SyncEnvelope(id: $id, type: $type, payload: $payload, policy: $policy, queuedAt: $queuedAt, attempt: $attempt, cursor: $cursor)';
}


}

/// @nodoc
abstract mixin class _$SyncEnvelopeCopyWith<$Res> implements $SyncEnvelopeCopyWith<$Res> {
  factory _$SyncEnvelopeCopyWith(_SyncEnvelope value, $Res Function(_SyncEnvelope) _then) = __$SyncEnvelopeCopyWithImpl;
@override @useResult
$Res call({
 OutboxEntryId id, String type, String payload, ConflictPolicy policy, DateTime queuedAt, int attempt, SyncCursor cursor
});


@override $ConflictPolicyCopyWith<$Res> get policy;

}
/// @nodoc
class __$SyncEnvelopeCopyWithImpl<$Res>
    implements _$SyncEnvelopeCopyWith<$Res> {
  __$SyncEnvelopeCopyWithImpl(this._self, this._then);

  final _SyncEnvelope _self;
  final $Res Function(_SyncEnvelope) _then;

/// Create a copy of SyncEnvelope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? payload = null,Object? policy = null,Object? queuedAt = null,Object? attempt = null,Object? cursor = null,}) {
  return _then(_SyncEnvelope(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as OutboxEntryId,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as ConflictPolicy,queuedAt: null == queuedAt ? _self.queuedAt : queuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,cursor: null == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as SyncCursor,
  ));
}

/// Create a copy of SyncEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConflictPolicyCopyWith<$Res> get policy {
  
  return $ConflictPolicyCopyWith<$Res>(_self.policy, (value) {
    return _then(_self.copyWith(policy: value));
  });
}
}

// dart format on
