// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attempt_outcome.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AttemptOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttemptOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AttemptOutcome()';
}


}

/// @nodoc
class $AttemptOutcomeCopyWith<$Res>  {
$AttemptOutcomeCopyWith(AttemptOutcome _, $Res Function(AttemptOutcome) __);
}


/// Adds pattern-matching-related methods to [AttemptOutcome].
extension AttemptOutcomePatterns on AttemptOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AttemptInProgress value)?  inProgress,TResult Function( AttemptCompleted value)?  completed,TResult Function( AttemptFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AttemptInProgress() when inProgress != null:
return inProgress(_that);case AttemptCompleted() when completed != null:
return completed(_that);case AttemptFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AttemptInProgress value)  inProgress,required TResult Function( AttemptCompleted value)  completed,required TResult Function( AttemptFailed value)  failed,}){
final _that = this;
switch (_that) {
case AttemptInProgress():
return inProgress(_that);case AttemptCompleted():
return completed(_that);case AttemptFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AttemptInProgress value)?  inProgress,TResult? Function( AttemptCompleted value)?  completed,TResult? Function( AttemptFailed value)?  failed,}){
final _that = this;
switch (_that) {
case AttemptInProgress() when inProgress != null:
return inProgress(_that);case AttemptCompleted() when completed != null:
return completed(_that);case AttemptFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  inProgress,TResult Function( ProofOfDelivery proof,  ProofReference reference)?  completed,TResult Function( NonDeliveryReason reason)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AttemptInProgress() when inProgress != null:
return inProgress();case AttemptCompleted() when completed != null:
return completed(_that.proof,_that.reference);case AttemptFailed() when failed != null:
return failed(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  inProgress,required TResult Function( ProofOfDelivery proof,  ProofReference reference)  completed,required TResult Function( NonDeliveryReason reason)  failed,}) {final _that = this;
switch (_that) {
case AttemptInProgress():
return inProgress();case AttemptCompleted():
return completed(_that.proof,_that.reference);case AttemptFailed():
return failed(_that.reason);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  inProgress,TResult? Function( ProofOfDelivery proof,  ProofReference reference)?  completed,TResult? Function( NonDeliveryReason reason)?  failed,}) {final _that = this;
switch (_that) {
case AttemptInProgress() when inProgress != null:
return inProgress();case AttemptCompleted() when completed != null:
return completed(_that.proof,_that.reference);case AttemptFailed() when failed != null:
return failed(_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class AttemptInProgress extends AttemptOutcome {
  const AttemptInProgress(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttemptInProgress);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AttemptOutcome.inProgress()';
}


}




/// @nodoc


class AttemptCompleted extends AttemptOutcome {
  const AttemptCompleted({required this.proof, required this.reference}): super._();
  

 final  ProofOfDelivery proof;
 final  ProofReference reference;

/// Create a copy of AttemptOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttemptCompletedCopyWith<AttemptCompleted> get copyWith => _$AttemptCompletedCopyWithImpl<AttemptCompleted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttemptCompleted&&(identical(other.proof, proof) || other.proof == proof)&&(identical(other.reference, reference) || other.reference == reference));
}


@override
int get hashCode => Object.hash(runtimeType,proof,reference);

@override
String toString() {
  return 'AttemptOutcome.completed(proof: $proof, reference: $reference)';
}


}

/// @nodoc
abstract mixin class $AttemptCompletedCopyWith<$Res> implements $AttemptOutcomeCopyWith<$Res> {
  factory $AttemptCompletedCopyWith(AttemptCompleted value, $Res Function(AttemptCompleted) _then) = _$AttemptCompletedCopyWithImpl;
@useResult
$Res call({
 ProofOfDelivery proof, ProofReference reference
});




}
/// @nodoc
class _$AttemptCompletedCopyWithImpl<$Res>
    implements $AttemptCompletedCopyWith<$Res> {
  _$AttemptCompletedCopyWithImpl(this._self, this._then);

  final AttemptCompleted _self;
  final $Res Function(AttemptCompleted) _then;

/// Create a copy of AttemptOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? proof = null,Object? reference = null,}) {
  return _then(AttemptCompleted(
proof: null == proof ? _self.proof : proof // ignore: cast_nullable_to_non_nullable
as ProofOfDelivery,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as ProofReference,
  ));
}


}

/// @nodoc


class AttemptFailed extends AttemptOutcome {
  const AttemptFailed(this.reason): super._();
  

 final  NonDeliveryReason reason;

/// Create a copy of AttemptOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttemptFailedCopyWith<AttemptFailed> get copyWith => _$AttemptFailedCopyWithImpl<AttemptFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttemptFailed&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'AttemptOutcome.failed(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $AttemptFailedCopyWith<$Res> implements $AttemptOutcomeCopyWith<$Res> {
  factory $AttemptFailedCopyWith(AttemptFailed value, $Res Function(AttemptFailed) _then) = _$AttemptFailedCopyWithImpl;
@useResult
$Res call({
 NonDeliveryReason reason
});


$NonDeliveryReasonCopyWith<$Res> get reason;

}
/// @nodoc
class _$AttemptFailedCopyWithImpl<$Res>
    implements $AttemptFailedCopyWith<$Res> {
  _$AttemptFailedCopyWithImpl(this._self, this._then);

  final AttemptFailed _self;
  final $Res Function(AttemptFailed) _then;

/// Create a copy of AttemptOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(AttemptFailed(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as NonDeliveryReason,
  ));
}

/// Create a copy of AttemptOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NonDeliveryReasonCopyWith<$Res> get reason {
  
  return $NonDeliveryReasonCopyWith<$Res>(_self.reason, (value) {
    return _then(_self.copyWith(reason: value));
  });
}
}

// dart format on
