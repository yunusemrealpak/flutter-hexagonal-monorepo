// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shipment_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShipmentSummary {

/// The identifier, as a plain string.
///
/// Not a `ShipmentId`: a summary is what a list renders, and re-parsing
/// eleven hundred identifiers to draw a screen buys nothing. The caller
/// that acts on a row parses it once, at the point of acting.
 String get id;/// The number on the label.
 String get barcode;/// Where the shipment is.
 ShipmentStatus get status;/// Who receives it.
 String get consigneeName;/// Where it is going, as it would be written on the label.
 String get address;
/// Create a copy of ShipmentSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShipmentSummaryCopyWith<ShipmentSummary> get copyWith => _$ShipmentSummaryCopyWithImpl<ShipmentSummary>(this as ShipmentSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShipmentSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.status, status) || other.status == status)&&(identical(other.consigneeName, consigneeName) || other.consigneeName == consigneeName)&&(identical(other.address, address) || other.address == address));
}


@override
int get hashCode => Object.hash(runtimeType,id,barcode,status,consigneeName,address);

@override
String toString() {
  return 'ShipmentSummary(id: $id, barcode: $barcode, status: $status, consigneeName: $consigneeName, address: $address)';
}


}

/// @nodoc
abstract mixin class $ShipmentSummaryCopyWith<$Res>  {
  factory $ShipmentSummaryCopyWith(ShipmentSummary value, $Res Function(ShipmentSummary) _then) = _$ShipmentSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String barcode, ShipmentStatus status, String consigneeName, String address
});


$ShipmentStatusCopyWith<$Res> get status;

}
/// @nodoc
class _$ShipmentSummaryCopyWithImpl<$Res>
    implements $ShipmentSummaryCopyWith<$Res> {
  _$ShipmentSummaryCopyWithImpl(this._self, this._then);

  final ShipmentSummary _self;
  final $Res Function(ShipmentSummary) _then;

/// Create a copy of ShipmentSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? barcode = null,Object? status = null,Object? consigneeName = null,Object? address = null,}) {
  return _then(ShipmentSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShipmentStatus,consigneeName: null == consigneeName ? _self.consigneeName : consigneeName // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of ShipmentSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShipmentStatusCopyWith<$Res> get status {
  
  return $ShipmentStatusCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}
}


/// Adds pattern-matching-related methods to [ShipmentSummary].
extension ShipmentSummaryPatterns on ShipmentSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShipmentSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShipmentSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShipmentSummary value)  $default,){
final _that = this;
switch (_that) {
case _ShipmentSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShipmentSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ShipmentSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String barcode,  ShipmentStatus status,  String consigneeName,  String address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShipmentSummary() when $default != null:
return $default(_that.id,_that.barcode,_that.status,_that.consigneeName,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String barcode,  ShipmentStatus status,  String consigneeName,  String address)  $default,) {final _that = this;
switch (_that) {
case _ShipmentSummary():
return $default(_that.id,_that.barcode,_that.status,_that.consigneeName,_that.address);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String barcode,  ShipmentStatus status,  String consigneeName,  String address)?  $default,) {final _that = this;
switch (_that) {
case _ShipmentSummary() when $default != null:
return $default(_that.id,_that.barcode,_that.status,_that.consigneeName,_that.address);case _:
  return null;

}
}

}

/// @nodoc


class _ShipmentSummary extends ShipmentSummary {
  const _ShipmentSummary({required this.id, required this.barcode, required this.status, required this.consigneeName, required this.address}): super._();
  

/// The identifier, as a plain string.
///
/// Not a `ShipmentId`: a summary is what a list renders, and re-parsing
/// eleven hundred identifiers to draw a screen buys nothing. The caller
/// that acts on a row parses it once, at the point of acting.
@override final  String id;
/// The number on the label.
@override final  String barcode;
/// Where the shipment is.
@override final  ShipmentStatus status;
/// Who receives it.
@override final  String consigneeName;
/// Where it is going, as it would be written on the label.
@override final  String address;

/// Create a copy of ShipmentSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShipmentSummaryCopyWith<_ShipmentSummary> get copyWith => __$ShipmentSummaryCopyWithImpl<_ShipmentSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShipmentSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.status, status) || other.status == status)&&(identical(other.consigneeName, consigneeName) || other.consigneeName == consigneeName)&&(identical(other.address, address) || other.address == address));
}


@override
int get hashCode => Object.hash(runtimeType,id,barcode,status,consigneeName,address);

@override
String toString() {
  return 'ShipmentSummary(id: $id, barcode: $barcode, status: $status, consigneeName: $consigneeName, address: $address)';
}


}

/// @nodoc
abstract mixin class _$ShipmentSummaryCopyWith<$Res> implements $ShipmentSummaryCopyWith<$Res> {
  factory _$ShipmentSummaryCopyWith(_ShipmentSummary value, $Res Function(_ShipmentSummary) _then) = __$ShipmentSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String barcode, ShipmentStatus status, String consigneeName, String address
});


@override $ShipmentStatusCopyWith<$Res> get status;

}
/// @nodoc
class __$ShipmentSummaryCopyWithImpl<$Res>
    implements _$ShipmentSummaryCopyWith<$Res> {
  __$ShipmentSummaryCopyWithImpl(this._self, this._then);

  final _ShipmentSummary _self;
  final $Res Function(_ShipmentSummary) _then;

/// Create a copy of ShipmentSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? barcode = null,Object? status = null,Object? consigneeName = null,Object? address = null,}) {
  return _then(_ShipmentSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShipmentStatus,consigneeName: null == consigneeName ? _self.consigneeName : consigneeName // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ShipmentSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShipmentStatusCopyWith<$Res> get status {
  
  return $ShipmentStatusCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}
}

// dart format on
