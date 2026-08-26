// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payments_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PaymentsFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentsFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PaymentsFailure()';
}


}

/// @nodoc
class $PaymentsFailureCopyWith<$Res>  {
$PaymentsFailureCopyWith(PaymentsFailure _, $Res Function(PaymentsFailure) __);
}


/// Adds pattern-matching-related methods to [PaymentsFailure].
extension PaymentsFailurePatterns on PaymentsFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MalformedPaymentValue value)?  malformedValue,TResult Function( CurrencyMismatch value)?  currencyMismatch,TResult Function( CollectionRefused value)?  collectionRefused,TResult Function( AlreadySettled value)?  alreadySettled,TResult Function( NoCollectionFor value)?  noCollectionFor,TResult Function( RefundNotPossible value)?  refundNotPossible,TResult Function( CashDrawerUnavailable value)?  cashDrawerUnavailable,TResult Function( PaymentsUnavailable value)?  paymentsUnavailable,TResult Function( SettlementUnavailable value)?  settlementUnavailable,TResult Function( SettlementClosed value)?  settlementClosed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MalformedPaymentValue() when malformedValue != null:
return malformedValue(_that);case CurrencyMismatch() when currencyMismatch != null:
return currencyMismatch(_that);case CollectionRefused() when collectionRefused != null:
return collectionRefused(_that);case AlreadySettled() when alreadySettled != null:
return alreadySettled(_that);case NoCollectionFor() when noCollectionFor != null:
return noCollectionFor(_that);case RefundNotPossible() when refundNotPossible != null:
return refundNotPossible(_that);case CashDrawerUnavailable() when cashDrawerUnavailable != null:
return cashDrawerUnavailable(_that);case PaymentsUnavailable() when paymentsUnavailable != null:
return paymentsUnavailable(_that);case SettlementUnavailable() when settlementUnavailable != null:
return settlementUnavailable(_that);case SettlementClosed() when settlementClosed != null:
return settlementClosed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MalformedPaymentValue value)  malformedValue,required TResult Function( CurrencyMismatch value)  currencyMismatch,required TResult Function( CollectionRefused value)  collectionRefused,required TResult Function( AlreadySettled value)  alreadySettled,required TResult Function( NoCollectionFor value)  noCollectionFor,required TResult Function( RefundNotPossible value)  refundNotPossible,required TResult Function( CashDrawerUnavailable value)  cashDrawerUnavailable,required TResult Function( PaymentsUnavailable value)  paymentsUnavailable,required TResult Function( SettlementUnavailable value)  settlementUnavailable,required TResult Function( SettlementClosed value)  settlementClosed,}){
final _that = this;
switch (_that) {
case MalformedPaymentValue():
return malformedValue(_that);case CurrencyMismatch():
return currencyMismatch(_that);case CollectionRefused():
return collectionRefused(_that);case AlreadySettled():
return alreadySettled(_that);case NoCollectionFor():
return noCollectionFor(_that);case RefundNotPossible():
return refundNotPossible(_that);case CashDrawerUnavailable():
return cashDrawerUnavailable(_that);case PaymentsUnavailable():
return paymentsUnavailable(_that);case SettlementUnavailable():
return settlementUnavailable(_that);case SettlementClosed():
return settlementClosed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MalformedPaymentValue value)?  malformedValue,TResult? Function( CurrencyMismatch value)?  currencyMismatch,TResult? Function( CollectionRefused value)?  collectionRefused,TResult? Function( AlreadySettled value)?  alreadySettled,TResult? Function( NoCollectionFor value)?  noCollectionFor,TResult? Function( RefundNotPossible value)?  refundNotPossible,TResult? Function( CashDrawerUnavailable value)?  cashDrawerUnavailable,TResult? Function( PaymentsUnavailable value)?  paymentsUnavailable,TResult? Function( SettlementUnavailable value)?  settlementUnavailable,TResult? Function( SettlementClosed value)?  settlementClosed,}){
final _that = this;
switch (_that) {
case MalformedPaymentValue() when malformedValue != null:
return malformedValue(_that);case CurrencyMismatch() when currencyMismatch != null:
return currencyMismatch(_that);case CollectionRefused() when collectionRefused != null:
return collectionRefused(_that);case AlreadySettled() when alreadySettled != null:
return alreadySettled(_that);case NoCollectionFor() when noCollectionFor != null:
return noCollectionFor(_that);case RefundNotPossible() when refundNotPossible != null:
return refundNotPossible(_that);case CashDrawerUnavailable() when cashDrawerUnavailable != null:
return cashDrawerUnavailable(_that);case PaymentsUnavailable() when paymentsUnavailable != null:
return paymentsUnavailable(_that);case SettlementUnavailable() when settlementUnavailable != null:
return settlementUnavailable(_that);case SettlementClosed() when settlementClosed != null:
return settlementClosed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String field,  String reason)?  malformedValue,TResult Function( String expected,  String actual)?  currencyMismatch,TResult Function( String reason)?  collectionRefused,TResult Function( String key)?  alreadySettled,TResult Function( String shipment)?  noCollectionFor,TResult Function( String reason)?  refundNotPossible,TResult Function( String? detail)?  cashDrawerUnavailable,TResult Function( String? detail)?  paymentsUnavailable,TResult Function( String? detail)?  settlementUnavailable,TResult Function( String settlement)?  settlementClosed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MalformedPaymentValue() when malformedValue != null:
return malformedValue(_that.field,_that.reason);case CurrencyMismatch() when currencyMismatch != null:
return currencyMismatch(_that.expected,_that.actual);case CollectionRefused() when collectionRefused != null:
return collectionRefused(_that.reason);case AlreadySettled() when alreadySettled != null:
return alreadySettled(_that.key);case NoCollectionFor() when noCollectionFor != null:
return noCollectionFor(_that.shipment);case RefundNotPossible() when refundNotPossible != null:
return refundNotPossible(_that.reason);case CashDrawerUnavailable() when cashDrawerUnavailable != null:
return cashDrawerUnavailable(_that.detail);case PaymentsUnavailable() when paymentsUnavailable != null:
return paymentsUnavailable(_that.detail);case SettlementUnavailable() when settlementUnavailable != null:
return settlementUnavailable(_that.detail);case SettlementClosed() when settlementClosed != null:
return settlementClosed(_that.settlement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String field,  String reason)  malformedValue,required TResult Function( String expected,  String actual)  currencyMismatch,required TResult Function( String reason)  collectionRefused,required TResult Function( String key)  alreadySettled,required TResult Function( String shipment)  noCollectionFor,required TResult Function( String reason)  refundNotPossible,required TResult Function( String? detail)  cashDrawerUnavailable,required TResult Function( String? detail)  paymentsUnavailable,required TResult Function( String? detail)  settlementUnavailable,required TResult Function( String settlement)  settlementClosed,}) {final _that = this;
switch (_that) {
case MalformedPaymentValue():
return malformedValue(_that.field,_that.reason);case CurrencyMismatch():
return currencyMismatch(_that.expected,_that.actual);case CollectionRefused():
return collectionRefused(_that.reason);case AlreadySettled():
return alreadySettled(_that.key);case NoCollectionFor():
return noCollectionFor(_that.shipment);case RefundNotPossible():
return refundNotPossible(_that.reason);case CashDrawerUnavailable():
return cashDrawerUnavailable(_that.detail);case PaymentsUnavailable():
return paymentsUnavailable(_that.detail);case SettlementUnavailable():
return settlementUnavailable(_that.detail);case SettlementClosed():
return settlementClosed(_that.settlement);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String field,  String reason)?  malformedValue,TResult? Function( String expected,  String actual)?  currencyMismatch,TResult? Function( String reason)?  collectionRefused,TResult? Function( String key)?  alreadySettled,TResult? Function( String shipment)?  noCollectionFor,TResult? Function( String reason)?  refundNotPossible,TResult? Function( String? detail)?  cashDrawerUnavailable,TResult? Function( String? detail)?  paymentsUnavailable,TResult? Function( String? detail)?  settlementUnavailable,TResult? Function( String settlement)?  settlementClosed,}) {final _that = this;
switch (_that) {
case MalformedPaymentValue() when malformedValue != null:
return malformedValue(_that.field,_that.reason);case CurrencyMismatch() when currencyMismatch != null:
return currencyMismatch(_that.expected,_that.actual);case CollectionRefused() when collectionRefused != null:
return collectionRefused(_that.reason);case AlreadySettled() when alreadySettled != null:
return alreadySettled(_that.key);case NoCollectionFor() when noCollectionFor != null:
return noCollectionFor(_that.shipment);case RefundNotPossible() when refundNotPossible != null:
return refundNotPossible(_that.reason);case CashDrawerUnavailable() when cashDrawerUnavailable != null:
return cashDrawerUnavailable(_that.detail);case PaymentsUnavailable() when paymentsUnavailable != null:
return paymentsUnavailable(_that.detail);case SettlementUnavailable() when settlementUnavailable != null:
return settlementUnavailable(_that.detail);case SettlementClosed() when settlementClosed != null:
return settlementClosed(_that.settlement);case _:
  return null;

}
}

}

/// @nodoc


class MalformedPaymentValue extends PaymentsFailure {
  const MalformedPaymentValue({required this.field, required this.reason}): super._();
  

 final  String field;
 final  String reason;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MalformedPaymentValueCopyWith<MalformedPaymentValue> get copyWith => _$MalformedPaymentValueCopyWithImpl<MalformedPaymentValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MalformedPaymentValue&&(identical(other.field, field) || other.field == field)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,field,reason);

@override
String toString() {
  return 'PaymentsFailure.malformedValue(field: $field, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $MalformedPaymentValueCopyWith<$Res> implements $PaymentsFailureCopyWith<$Res> {
  factory $MalformedPaymentValueCopyWith(MalformedPaymentValue value, $Res Function(MalformedPaymentValue) _then) = _$MalformedPaymentValueCopyWithImpl;
@useResult
$Res call({
 String field, String reason
});




}
/// @nodoc
class _$MalformedPaymentValueCopyWithImpl<$Res>
    implements $MalformedPaymentValueCopyWith<$Res> {
  _$MalformedPaymentValueCopyWithImpl(this._self, this._then);

  final MalformedPaymentValue _self;
  final $Res Function(MalformedPaymentValue) _then;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field = null,Object? reason = null,}) {
  return _then(MalformedPaymentValue(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CurrencyMismatch extends PaymentsFailure {
  const CurrencyMismatch({required this.expected, required this.actual}): super._();
  

 final  String expected;
 final  String actual;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CurrencyMismatchCopyWith<CurrencyMismatch> get copyWith => _$CurrencyMismatchCopyWithImpl<CurrencyMismatch>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CurrencyMismatch&&(identical(other.expected, expected) || other.expected == expected)&&(identical(other.actual, actual) || other.actual == actual));
}


@override
int get hashCode => Object.hash(runtimeType,expected,actual);

@override
String toString() {
  return 'PaymentsFailure.currencyMismatch(expected: $expected, actual: $actual)';
}


}

/// @nodoc
abstract mixin class $CurrencyMismatchCopyWith<$Res> implements $PaymentsFailureCopyWith<$Res> {
  factory $CurrencyMismatchCopyWith(CurrencyMismatch value, $Res Function(CurrencyMismatch) _then) = _$CurrencyMismatchCopyWithImpl;
@useResult
$Res call({
 String expected, String actual
});




}
/// @nodoc
class _$CurrencyMismatchCopyWithImpl<$Res>
    implements $CurrencyMismatchCopyWith<$Res> {
  _$CurrencyMismatchCopyWithImpl(this._self, this._then);

  final CurrencyMismatch _self;
  final $Res Function(CurrencyMismatch) _then;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? expected = null,Object? actual = null,}) {
  return _then(CurrencyMismatch(
expected: null == expected ? _self.expected : expected // ignore: cast_nullable_to_non_nullable
as String,actual: null == actual ? _self.actual : actual // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CollectionRefused extends PaymentsFailure {
  const CollectionRefused({required this.reason}): super._();
  

 final  String reason;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionRefusedCopyWith<CollectionRefused> get copyWith => _$CollectionRefusedCopyWithImpl<CollectionRefused>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionRefused&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'PaymentsFailure.collectionRefused(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $CollectionRefusedCopyWith<$Res> implements $PaymentsFailureCopyWith<$Res> {
  factory $CollectionRefusedCopyWith(CollectionRefused value, $Res Function(CollectionRefused) _then) = _$CollectionRefusedCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$CollectionRefusedCopyWithImpl<$Res>
    implements $CollectionRefusedCopyWith<$Res> {
  _$CollectionRefusedCopyWithImpl(this._self, this._then);

  final CollectionRefused _self;
  final $Res Function(CollectionRefused) _then;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(CollectionRefused(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AlreadySettled extends PaymentsFailure {
  const AlreadySettled(this.key): super._();
  

 final  String key;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlreadySettledCopyWith<AlreadySettled> get copyWith => _$AlreadySettledCopyWithImpl<AlreadySettled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlreadySettled&&(identical(other.key, key) || other.key == key));
}


@override
int get hashCode => Object.hash(runtimeType,key);

@override
String toString() {
  return 'PaymentsFailure.alreadySettled(key: $key)';
}


}

/// @nodoc
abstract mixin class $AlreadySettledCopyWith<$Res> implements $PaymentsFailureCopyWith<$Res> {
  factory $AlreadySettledCopyWith(AlreadySettled value, $Res Function(AlreadySettled) _then) = _$AlreadySettledCopyWithImpl;
@useResult
$Res call({
 String key
});




}
/// @nodoc
class _$AlreadySettledCopyWithImpl<$Res>
    implements $AlreadySettledCopyWith<$Res> {
  _$AlreadySettledCopyWithImpl(this._self, this._then);

  final AlreadySettled _self;
  final $Res Function(AlreadySettled) _then;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? key = null,}) {
  return _then(AlreadySettled(
null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class NoCollectionFor extends PaymentsFailure {
  const NoCollectionFor(this.shipment): super._();
  

 final  String shipment;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoCollectionForCopyWith<NoCollectionFor> get copyWith => _$NoCollectionForCopyWithImpl<NoCollectionFor>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoCollectionFor&&(identical(other.shipment, shipment) || other.shipment == shipment));
}


@override
int get hashCode => Object.hash(runtimeType,shipment);

@override
String toString() {
  return 'PaymentsFailure.noCollectionFor(shipment: $shipment)';
}


}

/// @nodoc
abstract mixin class $NoCollectionForCopyWith<$Res> implements $PaymentsFailureCopyWith<$Res> {
  factory $NoCollectionForCopyWith(NoCollectionFor value, $Res Function(NoCollectionFor) _then) = _$NoCollectionForCopyWithImpl;
@useResult
$Res call({
 String shipment
});




}
/// @nodoc
class _$NoCollectionForCopyWithImpl<$Res>
    implements $NoCollectionForCopyWith<$Res> {
  _$NoCollectionForCopyWithImpl(this._self, this._then);

  final NoCollectionFor _self;
  final $Res Function(NoCollectionFor) _then;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? shipment = null,}) {
  return _then(NoCollectionFor(
null == shipment ? _self.shipment : shipment // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class RefundNotPossible extends PaymentsFailure {
  const RefundNotPossible({required this.reason}): super._();
  

 final  String reason;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RefundNotPossibleCopyWith<RefundNotPossible> get copyWith => _$RefundNotPossibleCopyWithImpl<RefundNotPossible>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RefundNotPossible&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'PaymentsFailure.refundNotPossible(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $RefundNotPossibleCopyWith<$Res> implements $PaymentsFailureCopyWith<$Res> {
  factory $RefundNotPossibleCopyWith(RefundNotPossible value, $Res Function(RefundNotPossible) _then) = _$RefundNotPossibleCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$RefundNotPossibleCopyWithImpl<$Res>
    implements $RefundNotPossibleCopyWith<$Res> {
  _$RefundNotPossibleCopyWithImpl(this._self, this._then);

  final RefundNotPossible _self;
  final $Res Function(RefundNotPossible) _then;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(RefundNotPossible(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CashDrawerUnavailable extends PaymentsFailure {
  const CashDrawerUnavailable({this.detail}): super._();
  

 final  String? detail;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CashDrawerUnavailableCopyWith<CashDrawerUnavailable> get copyWith => _$CashDrawerUnavailableCopyWithImpl<CashDrawerUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CashDrawerUnavailable&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'PaymentsFailure.cashDrawerUnavailable(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $CashDrawerUnavailableCopyWith<$Res> implements $PaymentsFailureCopyWith<$Res> {
  factory $CashDrawerUnavailableCopyWith(CashDrawerUnavailable value, $Res Function(CashDrawerUnavailable) _then) = _$CashDrawerUnavailableCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$CashDrawerUnavailableCopyWithImpl<$Res>
    implements $CashDrawerUnavailableCopyWith<$Res> {
  _$CashDrawerUnavailableCopyWithImpl(this._self, this._then);

  final CashDrawerUnavailable _self;
  final $Res Function(CashDrawerUnavailable) _then;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(CashDrawerUnavailable(
detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class PaymentsUnavailable extends PaymentsFailure {
  const PaymentsUnavailable({this.detail}): super._();
  

 final  String? detail;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentsUnavailableCopyWith<PaymentsUnavailable> get copyWith => _$PaymentsUnavailableCopyWithImpl<PaymentsUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentsUnavailable&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'PaymentsFailure.paymentsUnavailable(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $PaymentsUnavailableCopyWith<$Res> implements $PaymentsFailureCopyWith<$Res> {
  factory $PaymentsUnavailableCopyWith(PaymentsUnavailable value, $Res Function(PaymentsUnavailable) _then) = _$PaymentsUnavailableCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$PaymentsUnavailableCopyWithImpl<$Res>
    implements $PaymentsUnavailableCopyWith<$Res> {
  _$PaymentsUnavailableCopyWithImpl(this._self, this._then);

  final PaymentsUnavailable _self;
  final $Res Function(PaymentsUnavailable) _then;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(PaymentsUnavailable(
detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class SettlementUnavailable extends PaymentsFailure {
  const SettlementUnavailable({this.detail}): super._();
  

 final  String? detail;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettlementUnavailableCopyWith<SettlementUnavailable> get copyWith => _$SettlementUnavailableCopyWithImpl<SettlementUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettlementUnavailable&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'PaymentsFailure.settlementUnavailable(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $SettlementUnavailableCopyWith<$Res> implements $PaymentsFailureCopyWith<$Res> {
  factory $SettlementUnavailableCopyWith(SettlementUnavailable value, $Res Function(SettlementUnavailable) _then) = _$SettlementUnavailableCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$SettlementUnavailableCopyWithImpl<$Res>
    implements $SettlementUnavailableCopyWith<$Res> {
  _$SettlementUnavailableCopyWithImpl(this._self, this._then);

  final SettlementUnavailable _self;
  final $Res Function(SettlementUnavailable) _then;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(SettlementUnavailable(
detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class SettlementClosed extends PaymentsFailure {
  const SettlementClosed(this.settlement): super._();
  

 final  String settlement;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettlementClosedCopyWith<SettlementClosed> get copyWith => _$SettlementClosedCopyWithImpl<SettlementClosed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettlementClosed&&(identical(other.settlement, settlement) || other.settlement == settlement));
}


@override
int get hashCode => Object.hash(runtimeType,settlement);

@override
String toString() {
  return 'PaymentsFailure.settlementClosed(settlement: $settlement)';
}


}

/// @nodoc
abstract mixin class $SettlementClosedCopyWith<$Res> implements $PaymentsFailureCopyWith<$Res> {
  factory $SettlementClosedCopyWith(SettlementClosed value, $Res Function(SettlementClosed) _then) = _$SettlementClosedCopyWithImpl;
@useResult
$Res call({
 String settlement
});




}
/// @nodoc
class _$SettlementClosedCopyWithImpl<$Res>
    implements $SettlementClosedCopyWith<$Res> {
  _$SettlementClosedCopyWithImpl(this._self, this._then);

  final SettlementClosed _self;
  final $Res Function(SettlementClosed) _then;

/// Create a copy of PaymentsFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? settlement = null,}) {
  return _then(SettlementClosed(
null == settlement ? _self.settlement : settlement // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
