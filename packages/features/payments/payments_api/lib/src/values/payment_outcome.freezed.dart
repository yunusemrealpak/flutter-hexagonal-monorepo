// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_outcome.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PaymentOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PaymentOutcome()';
}


}

/// @nodoc
class $PaymentOutcomeCopyWith<$Res>  {
$PaymentOutcomeCopyWith(PaymentOutcome _, $Res Function(PaymentOutcome) __);
}


/// Adds pattern-matching-related methods to [PaymentOutcome].
extension PaymentOutcomePatterns on PaymentOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PaymentPending value)?  pending,TResult Function( PaymentTaken value)?  taken,TResult Function( PaymentRefused value)?  refused,TResult Function( PaymentRefunded value)?  refunded,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PaymentPending() when pending != null:
return pending(_that);case PaymentTaken() when taken != null:
return taken(_that);case PaymentRefused() when refused != null:
return refused(_that);case PaymentRefunded() when refunded != null:
return refunded(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PaymentPending value)  pending,required TResult Function( PaymentTaken value)  taken,required TResult Function( PaymentRefused value)  refused,required TResult Function( PaymentRefunded value)  refunded,}){
final _that = this;
switch (_that) {
case PaymentPending():
return pending(_that);case PaymentTaken():
return taken(_that);case PaymentRefused():
return refused(_that);case PaymentRefunded():
return refunded(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PaymentPending value)?  pending,TResult? Function( PaymentTaken value)?  taken,TResult? Function( PaymentRefused value)?  refused,TResult? Function( PaymentRefunded value)?  refunded,}){
final _that = this;
switch (_that) {
case PaymentPending() when pending != null:
return pending(_that);case PaymentTaken() when taken != null:
return taken(_that);case PaymentRefused() when refused != null:
return refused(_that);case PaymentRefunded() when refunded != null:
return refunded(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  pending,TResult Function( DateTime at)?  taken,TResult Function( String reason)?  refused,TResult Function( DateTime takenAt,  DateTime refundedAt)?  refunded,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PaymentPending() when pending != null:
return pending();case PaymentTaken() when taken != null:
return taken(_that.at);case PaymentRefused() when refused != null:
return refused(_that.reason);case PaymentRefunded() when refunded != null:
return refunded(_that.takenAt,_that.refundedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  pending,required TResult Function( DateTime at)  taken,required TResult Function( String reason)  refused,required TResult Function( DateTime takenAt,  DateTime refundedAt)  refunded,}) {final _that = this;
switch (_that) {
case PaymentPending():
return pending();case PaymentTaken():
return taken(_that.at);case PaymentRefused():
return refused(_that.reason);case PaymentRefunded():
return refunded(_that.takenAt,_that.refundedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  pending,TResult? Function( DateTime at)?  taken,TResult? Function( String reason)?  refused,TResult? Function( DateTime takenAt,  DateTime refundedAt)?  refunded,}) {final _that = this;
switch (_that) {
case PaymentPending() when pending != null:
return pending();case PaymentTaken() when taken != null:
return taken(_that.at);case PaymentRefused() when refused != null:
return refused(_that.reason);case PaymentRefunded() when refunded != null:
return refunded(_that.takenAt,_that.refundedAt);case _:
  return null;

}
}

}

/// @nodoc


class PaymentPending extends PaymentOutcome {
  const PaymentPending(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentPending);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PaymentOutcome.pending()';
}


}




/// @nodoc


class PaymentTaken extends PaymentOutcome {
  const PaymentTaken({required this.at}): super._();
  

 final  DateTime at;

/// Create a copy of PaymentOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentTakenCopyWith<PaymentTaken> get copyWith => _$PaymentTakenCopyWithImpl<PaymentTaken>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentTaken&&(identical(other.at, at) || other.at == at));
}


@override
int get hashCode => Object.hash(runtimeType,at);

@override
String toString() {
  return 'PaymentOutcome.taken(at: $at)';
}


}

/// @nodoc
abstract mixin class $PaymentTakenCopyWith<$Res> implements $PaymentOutcomeCopyWith<$Res> {
  factory $PaymentTakenCopyWith(PaymentTaken value, $Res Function(PaymentTaken) _then) = _$PaymentTakenCopyWithImpl;
@useResult
$Res call({
 DateTime at
});




}
/// @nodoc
class _$PaymentTakenCopyWithImpl<$Res>
    implements $PaymentTakenCopyWith<$Res> {
  _$PaymentTakenCopyWithImpl(this._self, this._then);

  final PaymentTaken _self;
  final $Res Function(PaymentTaken) _then;

/// Create a copy of PaymentOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? at = null,}) {
  return _then(PaymentTaken(
at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class PaymentRefused extends PaymentOutcome {
  const PaymentRefused({required this.reason}): super._();
  

 final  String reason;

/// Create a copy of PaymentOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentRefusedCopyWith<PaymentRefused> get copyWith => _$PaymentRefusedCopyWithImpl<PaymentRefused>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentRefused&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'PaymentOutcome.refused(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $PaymentRefusedCopyWith<$Res> implements $PaymentOutcomeCopyWith<$Res> {
  factory $PaymentRefusedCopyWith(PaymentRefused value, $Res Function(PaymentRefused) _then) = _$PaymentRefusedCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$PaymentRefusedCopyWithImpl<$Res>
    implements $PaymentRefusedCopyWith<$Res> {
  _$PaymentRefusedCopyWithImpl(this._self, this._then);

  final PaymentRefused _self;
  final $Res Function(PaymentRefused) _then;

/// Create a copy of PaymentOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(PaymentRefused(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PaymentRefunded extends PaymentOutcome {
  const PaymentRefunded({required this.takenAt, required this.refundedAt}): super._();
  

 final  DateTime takenAt;
 final  DateTime refundedAt;

/// Create a copy of PaymentOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentRefundedCopyWith<PaymentRefunded> get copyWith => _$PaymentRefundedCopyWithImpl<PaymentRefunded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentRefunded&&(identical(other.takenAt, takenAt) || other.takenAt == takenAt)&&(identical(other.refundedAt, refundedAt) || other.refundedAt == refundedAt));
}


@override
int get hashCode => Object.hash(runtimeType,takenAt,refundedAt);

@override
String toString() {
  return 'PaymentOutcome.refunded(takenAt: $takenAt, refundedAt: $refundedAt)';
}


}

/// @nodoc
abstract mixin class $PaymentRefundedCopyWith<$Res> implements $PaymentOutcomeCopyWith<$Res> {
  factory $PaymentRefundedCopyWith(PaymentRefunded value, $Res Function(PaymentRefunded) _then) = _$PaymentRefundedCopyWithImpl;
@useResult
$Res call({
 DateTime takenAt, DateTime refundedAt
});




}
/// @nodoc
class _$PaymentRefundedCopyWithImpl<$Res>
    implements $PaymentRefundedCopyWith<$Res> {
  _$PaymentRefundedCopyWithImpl(this._self, this._then);

  final PaymentRefunded _self;
  final $Res Function(PaymentRefunded) _then;

/// Create a copy of PaymentOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? takenAt = null,Object? refundedAt = null,}) {
  return _then(PaymentRefunded(
takenAt: null == takenAt ? _self.takenAt : takenAt // ignore: cast_nullable_to_non_nullable
as DateTime,refundedAt: null == refundedAt ? _self.refundedAt : refundedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
