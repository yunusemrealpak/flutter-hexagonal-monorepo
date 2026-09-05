// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'non_delivery_reason.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NonDeliveryReason {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NonDeliveryReason);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NonDeliveryReason()';
}


}

/// @nodoc
class $NonDeliveryReasonCopyWith<$Res>  {
$NonDeliveryReasonCopyWith(NonDeliveryReason _, $Res Function(NonDeliveryReason) __);
}


/// Adds pattern-matching-related methods to [NonDeliveryReason].
extension NonDeliveryReasonPatterns on NonDeliveryReason {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RecipientAbsent value)?  recipientAbsent,TResult Function( AddressNotFound value)?  addressNotFound,TResult Function( RefusedByRecipient value)?  refusedByRecipient,TResult Function( DamagedInTransit value)?  damagedInTransit,TResult Function( AccessDenied value)?  accessDenied,TResult Function( Rescheduled value)?  rescheduled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RecipientAbsent() when recipientAbsent != null:
return recipientAbsent(_that);case AddressNotFound() when addressNotFound != null:
return addressNotFound(_that);case RefusedByRecipient() when refusedByRecipient != null:
return refusedByRecipient(_that);case DamagedInTransit() when damagedInTransit != null:
return damagedInTransit(_that);case AccessDenied() when accessDenied != null:
return accessDenied(_that);case Rescheduled() when rescheduled != null:
return rescheduled(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RecipientAbsent value)  recipientAbsent,required TResult Function( AddressNotFound value)  addressNotFound,required TResult Function( RefusedByRecipient value)  refusedByRecipient,required TResult Function( DamagedInTransit value)  damagedInTransit,required TResult Function( AccessDenied value)  accessDenied,required TResult Function( Rescheduled value)  rescheduled,}){
final _that = this;
switch (_that) {
case RecipientAbsent():
return recipientAbsent(_that);case AddressNotFound():
return addressNotFound(_that);case RefusedByRecipient():
return refusedByRecipient(_that);case DamagedInTransit():
return damagedInTransit(_that);case AccessDenied():
return accessDenied(_that);case Rescheduled():
return rescheduled(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RecipientAbsent value)?  recipientAbsent,TResult? Function( AddressNotFound value)?  addressNotFound,TResult? Function( RefusedByRecipient value)?  refusedByRecipient,TResult? Function( DamagedInTransit value)?  damagedInTransit,TResult? Function( AccessDenied value)?  accessDenied,TResult? Function( Rescheduled value)?  rescheduled,}){
final _that = this;
switch (_that) {
case RecipientAbsent() when recipientAbsent != null:
return recipientAbsent(_that);case AddressNotFound() when addressNotFound != null:
return addressNotFound(_that);case RefusedByRecipient() when refusedByRecipient != null:
return refusedByRecipient(_that);case DamagedInTransit() when damagedInTransit != null:
return damagedInTransit(_that);case AccessDenied() when accessDenied != null:
return accessDenied(_that);case Rescheduled() when rescheduled != null:
return rescheduled(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  recipientAbsent,TResult Function( String? found)?  addressNotFound,TResult Function( String? note)?  refusedByRecipient,TResult Function( String note)?  damagedInTransit,TResult Function( String? note)?  accessDenied,TResult Function( DateTime requestedFor)?  rescheduled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RecipientAbsent() when recipientAbsent != null:
return recipientAbsent();case AddressNotFound() when addressNotFound != null:
return addressNotFound(_that.found);case RefusedByRecipient() when refusedByRecipient != null:
return refusedByRecipient(_that.note);case DamagedInTransit() when damagedInTransit != null:
return damagedInTransit(_that.note);case AccessDenied() when accessDenied != null:
return accessDenied(_that.note);case Rescheduled() when rescheduled != null:
return rescheduled(_that.requestedFor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  recipientAbsent,required TResult Function( String? found)  addressNotFound,required TResult Function( String? note)  refusedByRecipient,required TResult Function( String note)  damagedInTransit,required TResult Function( String? note)  accessDenied,required TResult Function( DateTime requestedFor)  rescheduled,}) {final _that = this;
switch (_that) {
case RecipientAbsent():
return recipientAbsent();case AddressNotFound():
return addressNotFound(_that.found);case RefusedByRecipient():
return refusedByRecipient(_that.note);case DamagedInTransit():
return damagedInTransit(_that.note);case AccessDenied():
return accessDenied(_that.note);case Rescheduled():
return rescheduled(_that.requestedFor);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  recipientAbsent,TResult? Function( String? found)?  addressNotFound,TResult? Function( String? note)?  refusedByRecipient,TResult? Function( String note)?  damagedInTransit,TResult? Function( String? note)?  accessDenied,TResult? Function( DateTime requestedFor)?  rescheduled,}) {final _that = this;
switch (_that) {
case RecipientAbsent() when recipientAbsent != null:
return recipientAbsent();case AddressNotFound() when addressNotFound != null:
return addressNotFound(_that.found);case RefusedByRecipient() when refusedByRecipient != null:
return refusedByRecipient(_that.note);case DamagedInTransit() when damagedInTransit != null:
return damagedInTransit(_that.note);case AccessDenied() when accessDenied != null:
return accessDenied(_that.note);case Rescheduled() when rescheduled != null:
return rescheduled(_that.requestedFor);case _:
  return null;

}
}

}

/// @nodoc


class RecipientAbsent extends NonDeliveryReason {
  const RecipientAbsent(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipientAbsent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NonDeliveryReason.recipientAbsent()';
}


}




/// @nodoc


class AddressNotFound extends NonDeliveryReason {
  const AddressNotFound({this.found}): super._();
  

 final  String? found;

/// Create a copy of NonDeliveryReason
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddressNotFoundCopyWith<AddressNotFound> get copyWith => _$AddressNotFoundCopyWithImpl<AddressNotFound>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddressNotFound&&(identical(other.found, found) || other.found == found));
}


@override
int get hashCode => Object.hash(runtimeType,found);

@override
String toString() {
  return 'NonDeliveryReason.addressNotFound(found: $found)';
}


}

/// @nodoc
abstract mixin class $AddressNotFoundCopyWith<$Res> implements $NonDeliveryReasonCopyWith<$Res> {
  factory $AddressNotFoundCopyWith(AddressNotFound value, $Res Function(AddressNotFound) _then) = _$AddressNotFoundCopyWithImpl;
@useResult
$Res call({
 String? found
});




}
/// @nodoc
class _$AddressNotFoundCopyWithImpl<$Res>
    implements $AddressNotFoundCopyWith<$Res> {
  _$AddressNotFoundCopyWithImpl(this._self, this._then);

  final AddressNotFound _self;
  final $Res Function(AddressNotFound) _then;

/// Create a copy of NonDeliveryReason
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? found = freezed,}) {
  return _then(AddressNotFound(
found: freezed == found ? _self.found : found // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class RefusedByRecipient extends NonDeliveryReason {
  const RefusedByRecipient({this.note}): super._();
  

 final  String? note;

/// Create a copy of NonDeliveryReason
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RefusedByRecipientCopyWith<RefusedByRecipient> get copyWith => _$RefusedByRecipientCopyWithImpl<RefusedByRecipient>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RefusedByRecipient&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,note);

@override
String toString() {
  return 'NonDeliveryReason.refusedByRecipient(note: $note)';
}


}

/// @nodoc
abstract mixin class $RefusedByRecipientCopyWith<$Res> implements $NonDeliveryReasonCopyWith<$Res> {
  factory $RefusedByRecipientCopyWith(RefusedByRecipient value, $Res Function(RefusedByRecipient) _then) = _$RefusedByRecipientCopyWithImpl;
@useResult
$Res call({
 String? note
});




}
/// @nodoc
class _$RefusedByRecipientCopyWithImpl<$Res>
    implements $RefusedByRecipientCopyWith<$Res> {
  _$RefusedByRecipientCopyWithImpl(this._self, this._then);

  final RefusedByRecipient _self;
  final $Res Function(RefusedByRecipient) _then;

/// Create a copy of NonDeliveryReason
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? note = freezed,}) {
  return _then(RefusedByRecipient(
note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class DamagedInTransit extends NonDeliveryReason {
  const DamagedInTransit({required this.note}): super._();
  

 final  String note;

/// Create a copy of NonDeliveryReason
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DamagedInTransitCopyWith<DamagedInTransit> get copyWith => _$DamagedInTransitCopyWithImpl<DamagedInTransit>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DamagedInTransit&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,note);

@override
String toString() {
  return 'NonDeliveryReason.damagedInTransit(note: $note)';
}


}

/// @nodoc
abstract mixin class $DamagedInTransitCopyWith<$Res> implements $NonDeliveryReasonCopyWith<$Res> {
  factory $DamagedInTransitCopyWith(DamagedInTransit value, $Res Function(DamagedInTransit) _then) = _$DamagedInTransitCopyWithImpl;
@useResult
$Res call({
 String note
});




}
/// @nodoc
class _$DamagedInTransitCopyWithImpl<$Res>
    implements $DamagedInTransitCopyWith<$Res> {
  _$DamagedInTransitCopyWithImpl(this._self, this._then);

  final DamagedInTransit _self;
  final $Res Function(DamagedInTransit) _then;

/// Create a copy of NonDeliveryReason
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? note = null,}) {
  return _then(DamagedInTransit(
note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AccessDenied extends NonDeliveryReason {
  const AccessDenied({this.note}): super._();
  

 final  String? note;

/// Create a copy of NonDeliveryReason
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccessDeniedCopyWith<AccessDenied> get copyWith => _$AccessDeniedCopyWithImpl<AccessDenied>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccessDenied&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,note);

@override
String toString() {
  return 'NonDeliveryReason.accessDenied(note: $note)';
}


}

/// @nodoc
abstract mixin class $AccessDeniedCopyWith<$Res> implements $NonDeliveryReasonCopyWith<$Res> {
  factory $AccessDeniedCopyWith(AccessDenied value, $Res Function(AccessDenied) _then) = _$AccessDeniedCopyWithImpl;
@useResult
$Res call({
 String? note
});




}
/// @nodoc
class _$AccessDeniedCopyWithImpl<$Res>
    implements $AccessDeniedCopyWith<$Res> {
  _$AccessDeniedCopyWithImpl(this._self, this._then);

  final AccessDenied _self;
  final $Res Function(AccessDenied) _then;

/// Create a copy of NonDeliveryReason
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? note = freezed,}) {
  return _then(AccessDenied(
note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class Rescheduled extends NonDeliveryReason {
  const Rescheduled({required this.requestedFor}): super._();
  

 final  DateTime requestedFor;

/// Create a copy of NonDeliveryReason
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RescheduledCopyWith<Rescheduled> get copyWith => _$RescheduledCopyWithImpl<Rescheduled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Rescheduled&&(identical(other.requestedFor, requestedFor) || other.requestedFor == requestedFor));
}


@override
int get hashCode => Object.hash(runtimeType,requestedFor);

@override
String toString() {
  return 'NonDeliveryReason.rescheduled(requestedFor: $requestedFor)';
}


}

/// @nodoc
abstract mixin class $RescheduledCopyWith<$Res> implements $NonDeliveryReasonCopyWith<$Res> {
  factory $RescheduledCopyWith(Rescheduled value, $Res Function(Rescheduled) _then) = _$RescheduledCopyWithImpl;
@useResult
$Res call({
 DateTime requestedFor
});




}
/// @nodoc
class _$RescheduledCopyWithImpl<$Res>
    implements $RescheduledCopyWith<$Res> {
  _$RescheduledCopyWithImpl(this._self, this._then);

  final Rescheduled _self;
  final $Res Function(Rescheduled) _then;

/// Create a copy of NonDeliveryReason
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? requestedFor = null,}) {
  return _then(Rescheduled(
requestedFor: null == requestedFor ? _self.requestedFor : requestedFor // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
