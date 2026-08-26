// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PaymentStatus {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PaymentStatus()';
}


}

/// @nodoc
class $PaymentStatusCopyWith<$Res>  {
$PaymentStatusCopyWith(PaymentStatus _, $Res Function(PaymentStatus) __);
}


/// Adds pattern-matching-related methods to [PaymentStatus].
extension PaymentStatusPatterns on PaymentStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NothingToCollect value)?  nothingToCollect,TResult Function( Outstanding value)?  outstanding,TResult Function( SettledInFull value)?  settled,TResult Function( Refunded value)?  refunded,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NothingToCollect() when nothingToCollect != null:
return nothingToCollect(_that);case Outstanding() when outstanding != null:
return outstanding(_that);case SettledInFull() when settled != null:
return settled(_that);case Refunded() when refunded != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NothingToCollect value)  nothingToCollect,required TResult Function( Outstanding value)  outstanding,required TResult Function( SettledInFull value)  settled,required TResult Function( Refunded value)  refunded,}){
final _that = this;
switch (_that) {
case NothingToCollect():
return nothingToCollect(_that);case Outstanding():
return outstanding(_that);case SettledInFull():
return settled(_that);case Refunded():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NothingToCollect value)?  nothingToCollect,TResult? Function( Outstanding value)?  outstanding,TResult? Function( SettledInFull value)?  settled,TResult? Function( Refunded value)?  refunded,}){
final _that = this;
switch (_that) {
case NothingToCollect() when nothingToCollect != null:
return nothingToCollect(_that);case Outstanding() when outstanding != null:
return outstanding(_that);case SettledInFull() when settled != null:
return settled(_that);case Refunded() when refunded != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  nothingToCollect,TResult Function( Money amount)?  outstanding,TResult Function( Money amount,  DateTime at)?  settled,TResult Function( Money amount,  DateTime at)?  refunded,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NothingToCollect() when nothingToCollect != null:
return nothingToCollect();case Outstanding() when outstanding != null:
return outstanding(_that.amount);case SettledInFull() when settled != null:
return settled(_that.amount,_that.at);case Refunded() when refunded != null:
return refunded(_that.amount,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  nothingToCollect,required TResult Function( Money amount)  outstanding,required TResult Function( Money amount,  DateTime at)  settled,required TResult Function( Money amount,  DateTime at)  refunded,}) {final _that = this;
switch (_that) {
case NothingToCollect():
return nothingToCollect();case Outstanding():
return outstanding(_that.amount);case SettledInFull():
return settled(_that.amount,_that.at);case Refunded():
return refunded(_that.amount,_that.at);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  nothingToCollect,TResult? Function( Money amount)?  outstanding,TResult? Function( Money amount,  DateTime at)?  settled,TResult? Function( Money amount,  DateTime at)?  refunded,}) {final _that = this;
switch (_that) {
case NothingToCollect() when nothingToCollect != null:
return nothingToCollect();case Outstanding() when outstanding != null:
return outstanding(_that.amount);case SettledInFull() when settled != null:
return settled(_that.amount,_that.at);case Refunded() when refunded != null:
return refunded(_that.amount,_that.at);case _:
  return null;

}
}

}

/// @nodoc


class NothingToCollect extends PaymentStatus {
  const NothingToCollect(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NothingToCollect);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PaymentStatus.nothingToCollect()';
}


}




/// @nodoc


class Outstanding extends PaymentStatus {
  const Outstanding(this.amount): super._();
  

 final  Money amount;

/// Create a copy of PaymentStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutstandingCopyWith<Outstanding> get copyWith => _$OutstandingCopyWithImpl<Outstanding>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Outstanding&&(identical(other.amount, amount) || other.amount == amount));
}


@override
int get hashCode => Object.hash(runtimeType,amount);

@override
String toString() {
  return 'PaymentStatus.outstanding(amount: $amount)';
}


}

/// @nodoc
abstract mixin class $OutstandingCopyWith<$Res> implements $PaymentStatusCopyWith<$Res> {
  factory $OutstandingCopyWith(Outstanding value, $Res Function(Outstanding) _then) = _$OutstandingCopyWithImpl;
@useResult
$Res call({
 Money amount
});




}
/// @nodoc
class _$OutstandingCopyWithImpl<$Res>
    implements $OutstandingCopyWith<$Res> {
  _$OutstandingCopyWithImpl(this._self, this._then);

  final Outstanding _self;
  final $Res Function(Outstanding) _then;

/// Create a copy of PaymentStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? amount = null,}) {
  return _then(Outstanding(
null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,
  ));
}


}

/// @nodoc


class SettledInFull extends PaymentStatus {
  const SettledInFull({required this.amount, required this.at}): super._();
  

 final  Money amount;
 final  DateTime at;

/// Create a copy of PaymentStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettledInFullCopyWith<SettledInFull> get copyWith => _$SettledInFullCopyWithImpl<SettledInFull>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettledInFull&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.at, at) || other.at == at));
}


@override
int get hashCode => Object.hash(runtimeType,amount,at);

@override
String toString() {
  return 'PaymentStatus.settled(amount: $amount, at: $at)';
}


}

/// @nodoc
abstract mixin class $SettledInFullCopyWith<$Res> implements $PaymentStatusCopyWith<$Res> {
  factory $SettledInFullCopyWith(SettledInFull value, $Res Function(SettledInFull) _then) = _$SettledInFullCopyWithImpl;
@useResult
$Res call({
 Money amount, DateTime at
});




}
/// @nodoc
class _$SettledInFullCopyWithImpl<$Res>
    implements $SettledInFullCopyWith<$Res> {
  _$SettledInFullCopyWithImpl(this._self, this._then);

  final SettledInFull _self;
  final $Res Function(SettledInFull) _then;

/// Create a copy of PaymentStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? at = null,}) {
  return _then(SettledInFull(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class Refunded extends PaymentStatus {
  const Refunded({required this.amount, required this.at}): super._();
  

 final  Money amount;
 final  DateTime at;

/// Create a copy of PaymentStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RefundedCopyWith<Refunded> get copyWith => _$RefundedCopyWithImpl<Refunded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Refunded&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.at, at) || other.at == at));
}


@override
int get hashCode => Object.hash(runtimeType,amount,at);

@override
String toString() {
  return 'PaymentStatus.refunded(amount: $amount, at: $at)';
}


}

/// @nodoc
abstract mixin class $RefundedCopyWith<$Res> implements $PaymentStatusCopyWith<$Res> {
  factory $RefundedCopyWith(Refunded value, $Res Function(Refunded) _then) = _$RefundedCopyWithImpl;
@useResult
$Res call({
 Money amount, DateTime at
});




}
/// @nodoc
class _$RefundedCopyWithImpl<$Res>
    implements $RefundedCopyWith<$Res> {
  _$RefundedCopyWithImpl(this._self, this._then);

  final Refunded _self;
  final $Res Function(Refunded) _then;

/// Create a copy of PaymentStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? at = null,}) {
  return _then(Refunded(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
