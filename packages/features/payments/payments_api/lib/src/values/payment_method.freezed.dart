// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_method.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PaymentMethod {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentMethod);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PaymentMethod()';
}


}

/// @nodoc
class $PaymentMethodCopyWith<$Res>  {
$PaymentMethodCopyWith(PaymentMethod _, $Res Function(PaymentMethod) __);
}


/// Adds pattern-matching-related methods to [PaymentMethod].
extension PaymentMethodPatterns on PaymentMethod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Cash value)?  cash,TResult Function( Card value)?  card,TResult Function( Transfer value)?  transfer,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Cash() when cash != null:
return cash(_that);case Card() when card != null:
return card(_that);case Transfer() when transfer != null:
return transfer(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Cash value)  cash,required TResult Function( Card value)  card,required TResult Function( Transfer value)  transfer,}){
final _that = this;
switch (_that) {
case Cash():
return cash(_that);case Card():
return card(_that);case Transfer():
return transfer(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Cash value)?  cash,TResult? Function( Card value)?  card,TResult? Function( Transfer value)?  transfer,}){
final _that = this;
switch (_that) {
case Cash() when cash != null:
return cash(_that);case Card() when card != null:
return card(_that);case Transfer() when transfer != null:
return transfer(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  cash,TResult Function( String last4)?  card,TResult Function( String reference)?  transfer,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Cash() when cash != null:
return cash();case Card() when card != null:
return card(_that.last4);case Transfer() when transfer != null:
return transfer(_that.reference);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  cash,required TResult Function( String last4)  card,required TResult Function( String reference)  transfer,}) {final _that = this;
switch (_that) {
case Cash():
return cash();case Card():
return card(_that.last4);case Transfer():
return transfer(_that.reference);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  cash,TResult? Function( String last4)?  card,TResult? Function( String reference)?  transfer,}) {final _that = this;
switch (_that) {
case Cash() when cash != null:
return cash();case Card() when card != null:
return card(_that.last4);case Transfer() when transfer != null:
return transfer(_that.reference);case _:
  return null;

}
}

}

/// @nodoc


class Cash extends PaymentMethod {
  const Cash(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Cash);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PaymentMethod.cash()';
}


}




/// @nodoc


class Card extends PaymentMethod {
  const Card({required this.last4}): super._();
  

 final  String last4;

/// Create a copy of PaymentMethod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardCopyWith<Card> get copyWith => _$CardCopyWithImpl<Card>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Card&&(identical(other.last4, last4) || other.last4 == last4));
}


@override
int get hashCode => Object.hash(runtimeType,last4);

@override
String toString() {
  return 'PaymentMethod.card(last4: $last4)';
}


}

/// @nodoc
abstract mixin class $CardCopyWith<$Res> implements $PaymentMethodCopyWith<$Res> {
  factory $CardCopyWith(Card value, $Res Function(Card) _then) = _$CardCopyWithImpl;
@useResult
$Res call({
 String last4
});




}
/// @nodoc
class _$CardCopyWithImpl<$Res>
    implements $CardCopyWith<$Res> {
  _$CardCopyWithImpl(this._self, this._then);

  final Card _self;
  final $Res Function(Card) _then;

/// Create a copy of PaymentMethod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? last4 = null,}) {
  return _then(Card(
last4: null == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class Transfer extends PaymentMethod {
  const Transfer({required this.reference}): super._();
  

 final  String reference;

/// Create a copy of PaymentMethod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferCopyWith<Transfer> get copyWith => _$TransferCopyWithImpl<Transfer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transfer&&(identical(other.reference, reference) || other.reference == reference));
}


@override
int get hashCode => Object.hash(runtimeType,reference);

@override
String toString() {
  return 'PaymentMethod.transfer(reference: $reference)';
}


}

/// @nodoc
abstract mixin class $TransferCopyWith<$Res> implements $PaymentMethodCopyWith<$Res> {
  factory $TransferCopyWith(Transfer value, $Res Function(Transfer) _then) = _$TransferCopyWithImpl;
@useResult
$Res call({
 String reference
});




}
/// @nodoc
class _$TransferCopyWithImpl<$Res>
    implements $TransferCopyWith<$Res> {
  _$TransferCopyWithImpl(this._self, this._then);

  final Transfer _self;
  final $Res Function(Transfer) _then;

/// Create a copy of PaymentMethod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reference = null,}) {
  return _then(Transfer(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
