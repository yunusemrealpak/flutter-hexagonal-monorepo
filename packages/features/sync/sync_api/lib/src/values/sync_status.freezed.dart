// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SyncStatus {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncStatus()';
}


}

/// @nodoc
class $SyncStatusCopyWith<$Res>  {
$SyncStatusCopyWith(SyncStatus _, $Res Function(SyncStatus) __);
}


/// Adds pattern-matching-related methods to [SyncStatus].
extension SyncStatusPatterns on SyncStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SyncIdle value)?  idle,TResult Function( SyncDraining value)?  draining,TResult Function( SyncWaitingForNetwork value)?  waitingForNetwork,TResult Function( SyncWaitingToRetry value)?  waitingToRetry,TResult Function( SyncBlocked value)?  blocked,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SyncIdle() when idle != null:
return idle(_that);case SyncDraining() when draining != null:
return draining(_that);case SyncWaitingForNetwork() when waitingForNetwork != null:
return waitingForNetwork(_that);case SyncWaitingToRetry() when waitingToRetry != null:
return waitingToRetry(_that);case SyncBlocked() when blocked != null:
return blocked(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SyncIdle value)  idle,required TResult Function( SyncDraining value)  draining,required TResult Function( SyncWaitingForNetwork value)  waitingForNetwork,required TResult Function( SyncWaitingToRetry value)  waitingToRetry,required TResult Function( SyncBlocked value)  blocked,}){
final _that = this;
switch (_that) {
case SyncIdle():
return idle(_that);case SyncDraining():
return draining(_that);case SyncWaitingForNetwork():
return waitingForNetwork(_that);case SyncWaitingToRetry():
return waitingToRetry(_that);case SyncBlocked():
return blocked(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SyncIdle value)?  idle,TResult? Function( SyncDraining value)?  draining,TResult? Function( SyncWaitingForNetwork value)?  waitingForNetwork,TResult? Function( SyncWaitingToRetry value)?  waitingToRetry,TResult? Function( SyncBlocked value)?  blocked,}){
final _that = this;
switch (_that) {
case SyncIdle() when idle != null:
return idle(_that);case SyncDraining() when draining != null:
return draining(_that);case SyncWaitingForNetwork() when waitingForNetwork != null:
return waitingForNetwork(_that);case SyncWaitingToRetry() when waitingToRetry != null:
return waitingToRetry(_that);case SyncBlocked() when blocked != null:
return blocked(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( int pending)?  draining,TResult Function( int pending)?  waitingForNetwork,TResult Function( int pending,  DateTime nextAttemptAt)?  waitingToRetry,TResult Function( int pending,  int needingReview)?  blocked,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SyncIdle() when idle != null:
return idle();case SyncDraining() when draining != null:
return draining(_that.pending);case SyncWaitingForNetwork() when waitingForNetwork != null:
return waitingForNetwork(_that.pending);case SyncWaitingToRetry() when waitingToRetry != null:
return waitingToRetry(_that.pending,_that.nextAttemptAt);case SyncBlocked() when blocked != null:
return blocked(_that.pending,_that.needingReview);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( int pending)  draining,required TResult Function( int pending)  waitingForNetwork,required TResult Function( int pending,  DateTime nextAttemptAt)  waitingToRetry,required TResult Function( int pending,  int needingReview)  blocked,}) {final _that = this;
switch (_that) {
case SyncIdle():
return idle();case SyncDraining():
return draining(_that.pending);case SyncWaitingForNetwork():
return waitingForNetwork(_that.pending);case SyncWaitingToRetry():
return waitingToRetry(_that.pending,_that.nextAttemptAt);case SyncBlocked():
return blocked(_that.pending,_that.needingReview);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( int pending)?  draining,TResult? Function( int pending)?  waitingForNetwork,TResult? Function( int pending,  DateTime nextAttemptAt)?  waitingToRetry,TResult? Function( int pending,  int needingReview)?  blocked,}) {final _that = this;
switch (_that) {
case SyncIdle() when idle != null:
return idle();case SyncDraining() when draining != null:
return draining(_that.pending);case SyncWaitingForNetwork() when waitingForNetwork != null:
return waitingForNetwork(_that.pending);case SyncWaitingToRetry() when waitingToRetry != null:
return waitingToRetry(_that.pending,_that.nextAttemptAt);case SyncBlocked() when blocked != null:
return blocked(_that.pending,_that.needingReview);case _:
  return null;

}
}

}

/// @nodoc


class SyncIdle extends SyncStatus {
  const SyncIdle(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncStatus.idle()';
}


}




/// @nodoc


class SyncDraining extends SyncStatus {
  const SyncDraining({required this.pending}): super._();
  

 final  int pending;

/// Create a copy of SyncStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncDrainingCopyWith<SyncDraining> get copyWith => _$SyncDrainingCopyWithImpl<SyncDraining>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncDraining&&(identical(other.pending, pending) || other.pending == pending));
}


@override
int get hashCode => Object.hash(runtimeType,pending);

@override
String toString() {
  return 'SyncStatus.draining(pending: $pending)';
}


}

/// @nodoc
abstract mixin class $SyncDrainingCopyWith<$Res> implements $SyncStatusCopyWith<$Res> {
  factory $SyncDrainingCopyWith(SyncDraining value, $Res Function(SyncDraining) _then) = _$SyncDrainingCopyWithImpl;
@useResult
$Res call({
 int pending
});




}
/// @nodoc
class _$SyncDrainingCopyWithImpl<$Res>
    implements $SyncDrainingCopyWith<$Res> {
  _$SyncDrainingCopyWithImpl(this._self, this._then);

  final SyncDraining _self;
  final $Res Function(SyncDraining) _then;

/// Create a copy of SyncStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pending = null,}) {
  return _then(SyncDraining(
pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class SyncWaitingForNetwork extends SyncStatus {
  const SyncWaitingForNetwork({required this.pending}): super._();
  

 final  int pending;

/// Create a copy of SyncStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncWaitingForNetworkCopyWith<SyncWaitingForNetwork> get copyWith => _$SyncWaitingForNetworkCopyWithImpl<SyncWaitingForNetwork>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncWaitingForNetwork&&(identical(other.pending, pending) || other.pending == pending));
}


@override
int get hashCode => Object.hash(runtimeType,pending);

@override
String toString() {
  return 'SyncStatus.waitingForNetwork(pending: $pending)';
}


}

/// @nodoc
abstract mixin class $SyncWaitingForNetworkCopyWith<$Res> implements $SyncStatusCopyWith<$Res> {
  factory $SyncWaitingForNetworkCopyWith(SyncWaitingForNetwork value, $Res Function(SyncWaitingForNetwork) _then) = _$SyncWaitingForNetworkCopyWithImpl;
@useResult
$Res call({
 int pending
});




}
/// @nodoc
class _$SyncWaitingForNetworkCopyWithImpl<$Res>
    implements $SyncWaitingForNetworkCopyWith<$Res> {
  _$SyncWaitingForNetworkCopyWithImpl(this._self, this._then);

  final SyncWaitingForNetwork _self;
  final $Res Function(SyncWaitingForNetwork) _then;

/// Create a copy of SyncStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pending = null,}) {
  return _then(SyncWaitingForNetwork(
pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class SyncWaitingToRetry extends SyncStatus {
  const SyncWaitingToRetry({required this.pending, required this.nextAttemptAt}): super._();
  

 final  int pending;
 final  DateTime nextAttemptAt;

/// Create a copy of SyncStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncWaitingToRetryCopyWith<SyncWaitingToRetry> get copyWith => _$SyncWaitingToRetryCopyWithImpl<SyncWaitingToRetry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncWaitingToRetry&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.nextAttemptAt, nextAttemptAt) || other.nextAttemptAt == nextAttemptAt));
}


@override
int get hashCode => Object.hash(runtimeType,pending,nextAttemptAt);

@override
String toString() {
  return 'SyncStatus.waitingToRetry(pending: $pending, nextAttemptAt: $nextAttemptAt)';
}


}

/// @nodoc
abstract mixin class $SyncWaitingToRetryCopyWith<$Res> implements $SyncStatusCopyWith<$Res> {
  factory $SyncWaitingToRetryCopyWith(SyncWaitingToRetry value, $Res Function(SyncWaitingToRetry) _then) = _$SyncWaitingToRetryCopyWithImpl;
@useResult
$Res call({
 int pending, DateTime nextAttemptAt
});




}
/// @nodoc
class _$SyncWaitingToRetryCopyWithImpl<$Res>
    implements $SyncWaitingToRetryCopyWith<$Res> {
  _$SyncWaitingToRetryCopyWithImpl(this._self, this._then);

  final SyncWaitingToRetry _self;
  final $Res Function(SyncWaitingToRetry) _then;

/// Create a copy of SyncStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pending = null,Object? nextAttemptAt = null,}) {
  return _then(SyncWaitingToRetry(
pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as int,nextAttemptAt: null == nextAttemptAt ? _self.nextAttemptAt : nextAttemptAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class SyncBlocked extends SyncStatus {
  const SyncBlocked({required this.pending, required this.needingReview}): super._();
  

 final  int pending;
 final  int needingReview;

/// Create a copy of SyncStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncBlockedCopyWith<SyncBlocked> get copyWith => _$SyncBlockedCopyWithImpl<SyncBlocked>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncBlocked&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.needingReview, needingReview) || other.needingReview == needingReview));
}


@override
int get hashCode => Object.hash(runtimeType,pending,needingReview);

@override
String toString() {
  return 'SyncStatus.blocked(pending: $pending, needingReview: $needingReview)';
}


}

/// @nodoc
abstract mixin class $SyncBlockedCopyWith<$Res> implements $SyncStatusCopyWith<$Res> {
  factory $SyncBlockedCopyWith(SyncBlocked value, $Res Function(SyncBlocked) _then) = _$SyncBlockedCopyWithImpl;
@useResult
$Res call({
 int pending, int needingReview
});




}
/// @nodoc
class _$SyncBlockedCopyWithImpl<$Res>
    implements $SyncBlockedCopyWith<$Res> {
  _$SyncBlockedCopyWithImpl(this._self, this._then);

  final SyncBlocked _self;
  final $Res Function(SyncBlocked) _then;

/// Create a copy of SyncStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pending = null,Object? needingReview = null,}) {
  return _then(SyncBlocked(
pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as int,needingReview: null == needingReview ? _self.needingReview : needingReview // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
