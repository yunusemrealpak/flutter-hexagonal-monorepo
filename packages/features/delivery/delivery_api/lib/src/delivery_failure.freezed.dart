// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeliveryFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeliveryFailure()';
}


}

/// @nodoc
class $DeliveryFailureCopyWith<$Res>  {
$DeliveryFailureCopyWith(DeliveryFailure _, $Res Function(DeliveryFailure) __);
}


/// Adds pattern-matching-related methods to [DeliveryFailure].
extension DeliveryFailurePatterns on DeliveryFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MalformedDeliveryValue value)?  malformedValue,TResult Function( ProofInsufficient value)?  proofInsufficient,TResult Function( AttemptAlreadySettled value)?  attemptAlreadySettled,TResult Function( OutsideDeliveryArea value)?  outsideDeliveryArea,TResult Function( DeliveryPositionUnavailable value)?  positionUnavailable,TResult Function( ProofStoreUnavailable value)?  proofStoreUnavailable,TResult Function( ProofNotFound value)?  proofNotFound,TResult Function( MediaTooLarge value)?  mediaTooLarge,TResult Function( DeliveryUnavailable value)?  deliveryUnavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MalformedDeliveryValue() when malformedValue != null:
return malformedValue(_that);case ProofInsufficient() when proofInsufficient != null:
return proofInsufficient(_that);case AttemptAlreadySettled() when attemptAlreadySettled != null:
return attemptAlreadySettled(_that);case OutsideDeliveryArea() when outsideDeliveryArea != null:
return outsideDeliveryArea(_that);case DeliveryPositionUnavailable() when positionUnavailable != null:
return positionUnavailable(_that);case ProofStoreUnavailable() when proofStoreUnavailable != null:
return proofStoreUnavailable(_that);case ProofNotFound() when proofNotFound != null:
return proofNotFound(_that);case MediaTooLarge() when mediaTooLarge != null:
return mediaTooLarge(_that);case DeliveryUnavailable() when deliveryUnavailable != null:
return deliveryUnavailable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MalformedDeliveryValue value)  malformedValue,required TResult Function( ProofInsufficient value)  proofInsufficient,required TResult Function( AttemptAlreadySettled value)  attemptAlreadySettled,required TResult Function( OutsideDeliveryArea value)  outsideDeliveryArea,required TResult Function( DeliveryPositionUnavailable value)  positionUnavailable,required TResult Function( ProofStoreUnavailable value)  proofStoreUnavailable,required TResult Function( ProofNotFound value)  proofNotFound,required TResult Function( MediaTooLarge value)  mediaTooLarge,required TResult Function( DeliveryUnavailable value)  deliveryUnavailable,}){
final _that = this;
switch (_that) {
case MalformedDeliveryValue():
return malformedValue(_that);case ProofInsufficient():
return proofInsufficient(_that);case AttemptAlreadySettled():
return attemptAlreadySettled(_that);case OutsideDeliveryArea():
return outsideDeliveryArea(_that);case DeliveryPositionUnavailable():
return positionUnavailable(_that);case ProofStoreUnavailable():
return proofStoreUnavailable(_that);case ProofNotFound():
return proofNotFound(_that);case MediaTooLarge():
return mediaTooLarge(_that);case DeliveryUnavailable():
return deliveryUnavailable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MalformedDeliveryValue value)?  malformedValue,TResult? Function( ProofInsufficient value)?  proofInsufficient,TResult? Function( AttemptAlreadySettled value)?  attemptAlreadySettled,TResult? Function( OutsideDeliveryArea value)?  outsideDeliveryArea,TResult? Function( DeliveryPositionUnavailable value)?  positionUnavailable,TResult? Function( ProofStoreUnavailable value)?  proofStoreUnavailable,TResult? Function( ProofNotFound value)?  proofNotFound,TResult? Function( MediaTooLarge value)?  mediaTooLarge,TResult? Function( DeliveryUnavailable value)?  deliveryUnavailable,}){
final _that = this;
switch (_that) {
case MalformedDeliveryValue() when malformedValue != null:
return malformedValue(_that);case ProofInsufficient() when proofInsufficient != null:
return proofInsufficient(_that);case AttemptAlreadySettled() when attemptAlreadySettled != null:
return attemptAlreadySettled(_that);case OutsideDeliveryArea() when outsideDeliveryArea != null:
return outsideDeliveryArea(_that);case DeliveryPositionUnavailable() when positionUnavailable != null:
return positionUnavailable(_that);case ProofStoreUnavailable() when proofStoreUnavailable != null:
return proofStoreUnavailable(_that);case ProofNotFound() when proofNotFound != null:
return proofNotFound(_that);case MediaTooLarge() when mediaTooLarge != null:
return mediaTooLarge(_that);case DeliveryUnavailable() when deliveryUnavailable != null:
return deliveryUnavailable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String field,  String reason)?  malformedValue,TResult Function( String grade,  List<String> missing)?  proofInsufficient,TResult Function( String attempt)?  attemptAlreadySettled,TResult Function( double metresAway,  double allowedMetres)?  outsideDeliveryArea,TResult Function( String? detail)?  positionUnavailable,TResult Function( String? detail)?  proofStoreUnavailable,TResult Function( String reference)?  proofNotFound,TResult Function( int bytes,  int limit)?  mediaTooLarge,TResult Function( String? detail)?  deliveryUnavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MalformedDeliveryValue() when malformedValue != null:
return malformedValue(_that.field,_that.reason);case ProofInsufficient() when proofInsufficient != null:
return proofInsufficient(_that.grade,_that.missing);case AttemptAlreadySettled() when attemptAlreadySettled != null:
return attemptAlreadySettled(_that.attempt);case OutsideDeliveryArea() when outsideDeliveryArea != null:
return outsideDeliveryArea(_that.metresAway,_that.allowedMetres);case DeliveryPositionUnavailable() when positionUnavailable != null:
return positionUnavailable(_that.detail);case ProofStoreUnavailable() when proofStoreUnavailable != null:
return proofStoreUnavailable(_that.detail);case ProofNotFound() when proofNotFound != null:
return proofNotFound(_that.reference);case MediaTooLarge() when mediaTooLarge != null:
return mediaTooLarge(_that.bytes,_that.limit);case DeliveryUnavailable() when deliveryUnavailable != null:
return deliveryUnavailable(_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String field,  String reason)  malformedValue,required TResult Function( String grade,  List<String> missing)  proofInsufficient,required TResult Function( String attempt)  attemptAlreadySettled,required TResult Function( double metresAway,  double allowedMetres)  outsideDeliveryArea,required TResult Function( String? detail)  positionUnavailable,required TResult Function( String? detail)  proofStoreUnavailable,required TResult Function( String reference)  proofNotFound,required TResult Function( int bytes,  int limit)  mediaTooLarge,required TResult Function( String? detail)  deliveryUnavailable,}) {final _that = this;
switch (_that) {
case MalformedDeliveryValue():
return malformedValue(_that.field,_that.reason);case ProofInsufficient():
return proofInsufficient(_that.grade,_that.missing);case AttemptAlreadySettled():
return attemptAlreadySettled(_that.attempt);case OutsideDeliveryArea():
return outsideDeliveryArea(_that.metresAway,_that.allowedMetres);case DeliveryPositionUnavailable():
return positionUnavailable(_that.detail);case ProofStoreUnavailable():
return proofStoreUnavailable(_that.detail);case ProofNotFound():
return proofNotFound(_that.reference);case MediaTooLarge():
return mediaTooLarge(_that.bytes,_that.limit);case DeliveryUnavailable():
return deliveryUnavailable(_that.detail);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String field,  String reason)?  malformedValue,TResult? Function( String grade,  List<String> missing)?  proofInsufficient,TResult? Function( String attempt)?  attemptAlreadySettled,TResult? Function( double metresAway,  double allowedMetres)?  outsideDeliveryArea,TResult? Function( String? detail)?  positionUnavailable,TResult? Function( String? detail)?  proofStoreUnavailable,TResult? Function( String reference)?  proofNotFound,TResult? Function( int bytes,  int limit)?  mediaTooLarge,TResult? Function( String? detail)?  deliveryUnavailable,}) {final _that = this;
switch (_that) {
case MalformedDeliveryValue() when malformedValue != null:
return malformedValue(_that.field,_that.reason);case ProofInsufficient() when proofInsufficient != null:
return proofInsufficient(_that.grade,_that.missing);case AttemptAlreadySettled() when attemptAlreadySettled != null:
return attemptAlreadySettled(_that.attempt);case OutsideDeliveryArea() when outsideDeliveryArea != null:
return outsideDeliveryArea(_that.metresAway,_that.allowedMetres);case DeliveryPositionUnavailable() when positionUnavailable != null:
return positionUnavailable(_that.detail);case ProofStoreUnavailable() when proofStoreUnavailable != null:
return proofStoreUnavailable(_that.detail);case ProofNotFound() when proofNotFound != null:
return proofNotFound(_that.reference);case MediaTooLarge() when mediaTooLarge != null:
return mediaTooLarge(_that.bytes,_that.limit);case DeliveryUnavailable() when deliveryUnavailable != null:
return deliveryUnavailable(_that.detail);case _:
  return null;

}
}

}

/// @nodoc


class MalformedDeliveryValue extends DeliveryFailure {
  const MalformedDeliveryValue({required this.field, required this.reason}): super._();
  

 final  String field;
 final  String reason;

/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MalformedDeliveryValueCopyWith<MalformedDeliveryValue> get copyWith => _$MalformedDeliveryValueCopyWithImpl<MalformedDeliveryValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MalformedDeliveryValue&&(identical(other.field, field) || other.field == field)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,field,reason);

@override
String toString() {
  return 'DeliveryFailure.malformedValue(field: $field, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $MalformedDeliveryValueCopyWith<$Res> implements $DeliveryFailureCopyWith<$Res> {
  factory $MalformedDeliveryValueCopyWith(MalformedDeliveryValue value, $Res Function(MalformedDeliveryValue) _then) = _$MalformedDeliveryValueCopyWithImpl;
@useResult
$Res call({
 String field, String reason
});




}
/// @nodoc
class _$MalformedDeliveryValueCopyWithImpl<$Res>
    implements $MalformedDeliveryValueCopyWith<$Res> {
  _$MalformedDeliveryValueCopyWithImpl(this._self, this._then);

  final MalformedDeliveryValue _self;
  final $Res Function(MalformedDeliveryValue) _then;

/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field = null,Object? reason = null,}) {
  return _then(MalformedDeliveryValue(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ProofInsufficient extends DeliveryFailure {
  const ProofInsufficient({required this.grade, required  List<String> missing}): _missing = missing,super._();
  

 final  String grade;
 final  List<String> _missing;
 List<String> get missing {
  if (_missing is EqualUnmodifiableListView) return _missing;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_missing);
}


/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProofInsufficientCopyWith<ProofInsufficient> get copyWith => _$ProofInsufficientCopyWithImpl<ProofInsufficient>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProofInsufficient&&(identical(other.grade, grade) || other.grade == grade)&&const DeepCollectionEquality().equals(other._missing, _missing));
}


@override
int get hashCode => Object.hash(runtimeType,grade,const DeepCollectionEquality().hash(_missing));

@override
String toString() {
  return 'DeliveryFailure.proofInsufficient(grade: $grade, missing: $missing)';
}


}

/// @nodoc
abstract mixin class $ProofInsufficientCopyWith<$Res> implements $DeliveryFailureCopyWith<$Res> {
  factory $ProofInsufficientCopyWith(ProofInsufficient value, $Res Function(ProofInsufficient) _then) = _$ProofInsufficientCopyWithImpl;
@useResult
$Res call({
 String grade, List<String> missing
});




}
/// @nodoc
class _$ProofInsufficientCopyWithImpl<$Res>
    implements $ProofInsufficientCopyWith<$Res> {
  _$ProofInsufficientCopyWithImpl(this._self, this._then);

  final ProofInsufficient _self;
  final $Res Function(ProofInsufficient) _then;

/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? grade = null,Object? missing = null,}) {
  return _then(ProofInsufficient(
grade: null == grade ? _self.grade : grade // ignore: cast_nullable_to_non_nullable
as String,missing: null == missing ? _self._missing : missing // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class AttemptAlreadySettled extends DeliveryFailure {
  const AttemptAlreadySettled(this.attempt): super._();
  

 final  String attempt;

/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttemptAlreadySettledCopyWith<AttemptAlreadySettled> get copyWith => _$AttemptAlreadySettledCopyWithImpl<AttemptAlreadySettled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttemptAlreadySettled&&(identical(other.attempt, attempt) || other.attempt == attempt));
}


@override
int get hashCode => Object.hash(runtimeType,attempt);

@override
String toString() {
  return 'DeliveryFailure.attemptAlreadySettled(attempt: $attempt)';
}


}

/// @nodoc
abstract mixin class $AttemptAlreadySettledCopyWith<$Res> implements $DeliveryFailureCopyWith<$Res> {
  factory $AttemptAlreadySettledCopyWith(AttemptAlreadySettled value, $Res Function(AttemptAlreadySettled) _then) = _$AttemptAlreadySettledCopyWithImpl;
@useResult
$Res call({
 String attempt
});




}
/// @nodoc
class _$AttemptAlreadySettledCopyWithImpl<$Res>
    implements $AttemptAlreadySettledCopyWith<$Res> {
  _$AttemptAlreadySettledCopyWithImpl(this._self, this._then);

  final AttemptAlreadySettled _self;
  final $Res Function(AttemptAlreadySettled) _then;

/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? attempt = null,}) {
  return _then(AttemptAlreadySettled(
null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class OutsideDeliveryArea extends DeliveryFailure {
  const OutsideDeliveryArea({required this.metresAway, required this.allowedMetres}): super._();
  

 final  double metresAway;
 final  double allowedMetres;

/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutsideDeliveryAreaCopyWith<OutsideDeliveryArea> get copyWith => _$OutsideDeliveryAreaCopyWithImpl<OutsideDeliveryArea>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutsideDeliveryArea&&(identical(other.metresAway, metresAway) || other.metresAway == metresAway)&&(identical(other.allowedMetres, allowedMetres) || other.allowedMetres == allowedMetres));
}


@override
int get hashCode => Object.hash(runtimeType,metresAway,allowedMetres);

@override
String toString() {
  return 'DeliveryFailure.outsideDeliveryArea(metresAway: $metresAway, allowedMetres: $allowedMetres)';
}


}

/// @nodoc
abstract mixin class $OutsideDeliveryAreaCopyWith<$Res> implements $DeliveryFailureCopyWith<$Res> {
  factory $OutsideDeliveryAreaCopyWith(OutsideDeliveryArea value, $Res Function(OutsideDeliveryArea) _then) = _$OutsideDeliveryAreaCopyWithImpl;
@useResult
$Res call({
 double metresAway, double allowedMetres
});




}
/// @nodoc
class _$OutsideDeliveryAreaCopyWithImpl<$Res>
    implements $OutsideDeliveryAreaCopyWith<$Res> {
  _$OutsideDeliveryAreaCopyWithImpl(this._self, this._then);

  final OutsideDeliveryArea _self;
  final $Res Function(OutsideDeliveryArea) _then;

/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? metresAway = null,Object? allowedMetres = null,}) {
  return _then(OutsideDeliveryArea(
metresAway: null == metresAway ? _self.metresAway : metresAway // ignore: cast_nullable_to_non_nullable
as double,allowedMetres: null == allowedMetres ? _self.allowedMetres : allowedMetres // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class DeliveryPositionUnavailable extends DeliveryFailure {
  const DeliveryPositionUnavailable({this.detail}): super._();
  

 final  String? detail;

/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryPositionUnavailableCopyWith<DeliveryPositionUnavailable> get copyWith => _$DeliveryPositionUnavailableCopyWithImpl<DeliveryPositionUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryPositionUnavailable&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'DeliveryFailure.positionUnavailable(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $DeliveryPositionUnavailableCopyWith<$Res> implements $DeliveryFailureCopyWith<$Res> {
  factory $DeliveryPositionUnavailableCopyWith(DeliveryPositionUnavailable value, $Res Function(DeliveryPositionUnavailable) _then) = _$DeliveryPositionUnavailableCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$DeliveryPositionUnavailableCopyWithImpl<$Res>
    implements $DeliveryPositionUnavailableCopyWith<$Res> {
  _$DeliveryPositionUnavailableCopyWithImpl(this._self, this._then);

  final DeliveryPositionUnavailable _self;
  final $Res Function(DeliveryPositionUnavailable) _then;

/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(DeliveryPositionUnavailable(
detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ProofStoreUnavailable extends DeliveryFailure {
  const ProofStoreUnavailable({this.detail}): super._();
  

 final  String? detail;

/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProofStoreUnavailableCopyWith<ProofStoreUnavailable> get copyWith => _$ProofStoreUnavailableCopyWithImpl<ProofStoreUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProofStoreUnavailable&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'DeliveryFailure.proofStoreUnavailable(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $ProofStoreUnavailableCopyWith<$Res> implements $DeliveryFailureCopyWith<$Res> {
  factory $ProofStoreUnavailableCopyWith(ProofStoreUnavailable value, $Res Function(ProofStoreUnavailable) _then) = _$ProofStoreUnavailableCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$ProofStoreUnavailableCopyWithImpl<$Res>
    implements $ProofStoreUnavailableCopyWith<$Res> {
  _$ProofStoreUnavailableCopyWithImpl(this._self, this._then);

  final ProofStoreUnavailable _self;
  final $Res Function(ProofStoreUnavailable) _then;

/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(ProofStoreUnavailable(
detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ProofNotFound extends DeliveryFailure {
  const ProofNotFound(this.reference): super._();
  

 final  String reference;

/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProofNotFoundCopyWith<ProofNotFound> get copyWith => _$ProofNotFoundCopyWithImpl<ProofNotFound>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProofNotFound&&(identical(other.reference, reference) || other.reference == reference));
}


@override
int get hashCode => Object.hash(runtimeType,reference);

@override
String toString() {
  return 'DeliveryFailure.proofNotFound(reference: $reference)';
}


}

/// @nodoc
abstract mixin class $ProofNotFoundCopyWith<$Res> implements $DeliveryFailureCopyWith<$Res> {
  factory $ProofNotFoundCopyWith(ProofNotFound value, $Res Function(ProofNotFound) _then) = _$ProofNotFoundCopyWithImpl;
@useResult
$Res call({
 String reference
});




}
/// @nodoc
class _$ProofNotFoundCopyWithImpl<$Res>
    implements $ProofNotFoundCopyWith<$Res> {
  _$ProofNotFoundCopyWithImpl(this._self, this._then);

  final ProofNotFound _self;
  final $Res Function(ProofNotFound) _then;

/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reference = null,}) {
  return _then(ProofNotFound(
null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MediaTooLarge extends DeliveryFailure {
  const MediaTooLarge({required this.bytes, required this.limit}): super._();
  

 final  int bytes;
 final  int limit;

/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaTooLargeCopyWith<MediaTooLarge> get copyWith => _$MediaTooLargeCopyWithImpl<MediaTooLarge>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaTooLarge&&(identical(other.bytes, bytes) || other.bytes == bytes)&&(identical(other.limit, limit) || other.limit == limit));
}


@override
int get hashCode => Object.hash(runtimeType,bytes,limit);

@override
String toString() {
  return 'DeliveryFailure.mediaTooLarge(bytes: $bytes, limit: $limit)';
}


}

/// @nodoc
abstract mixin class $MediaTooLargeCopyWith<$Res> implements $DeliveryFailureCopyWith<$Res> {
  factory $MediaTooLargeCopyWith(MediaTooLarge value, $Res Function(MediaTooLarge) _then) = _$MediaTooLargeCopyWithImpl;
@useResult
$Res call({
 int bytes, int limit
});




}
/// @nodoc
class _$MediaTooLargeCopyWithImpl<$Res>
    implements $MediaTooLargeCopyWith<$Res> {
  _$MediaTooLargeCopyWithImpl(this._self, this._then);

  final MediaTooLarge _self;
  final $Res Function(MediaTooLarge) _then;

/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? bytes = null,Object? limit = null,}) {
  return _then(MediaTooLarge(
bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class DeliveryUnavailable extends DeliveryFailure {
  const DeliveryUnavailable({this.detail}): super._();
  

 final  String? detail;

/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryUnavailableCopyWith<DeliveryUnavailable> get copyWith => _$DeliveryUnavailableCopyWithImpl<DeliveryUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryUnavailable&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'DeliveryFailure.deliveryUnavailable(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $DeliveryUnavailableCopyWith<$Res> implements $DeliveryFailureCopyWith<$Res> {
  factory $DeliveryUnavailableCopyWith(DeliveryUnavailable value, $Res Function(DeliveryUnavailable) _then) = _$DeliveryUnavailableCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$DeliveryUnavailableCopyWithImpl<$Res>
    implements $DeliveryUnavailableCopyWith<$Res> {
  _$DeliveryUnavailableCopyWithImpl(this._self, this._then);

  final DeliveryUnavailable _self;
  final $Res Function(DeliveryUnavailable) _then;

/// Create a copy of DeliveryFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(DeliveryUnavailable(
detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
