// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shipment_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShipmentStatus {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShipmentStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShipmentStatus()';
}


}

/// @nodoc
class $ShipmentStatusCopyWith<$Res>  {
$ShipmentStatusCopyWith(ShipmentStatus _, $Res Function(ShipmentStatus) __);
}


/// Adds pattern-matching-related methods to [ShipmentStatus].
extension ShipmentStatusPatterns on ShipmentStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ShipmentAwaitingAssignment value)?  awaitingAssignment,TResult Function( ShipmentAssignedToCourier value)?  assignedToCourier,TResult Function( ShipmentLoadedOnVehicle value)?  loadedOnVehicle,TResult Function( ShipmentOutForDelivery value)?  outForDelivery,TResult Function( ShipmentDeliveredToConsignee value)?  deliveredToConsignee,TResult Function( ShipmentUndeliverable value)?  undeliverable,TResult Function( ShipmentReturnedToDepot value)?  returnedToDepot,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ShipmentAwaitingAssignment() when awaitingAssignment != null:
return awaitingAssignment(_that);case ShipmentAssignedToCourier() when assignedToCourier != null:
return assignedToCourier(_that);case ShipmentLoadedOnVehicle() when loadedOnVehicle != null:
return loadedOnVehicle(_that);case ShipmentOutForDelivery() when outForDelivery != null:
return outForDelivery(_that);case ShipmentDeliveredToConsignee() when deliveredToConsignee != null:
return deliveredToConsignee(_that);case ShipmentUndeliverable() when undeliverable != null:
return undeliverable(_that);case ShipmentReturnedToDepot() when returnedToDepot != null:
return returnedToDepot(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ShipmentAwaitingAssignment value)  awaitingAssignment,required TResult Function( ShipmentAssignedToCourier value)  assignedToCourier,required TResult Function( ShipmentLoadedOnVehicle value)  loadedOnVehicle,required TResult Function( ShipmentOutForDelivery value)  outForDelivery,required TResult Function( ShipmentDeliveredToConsignee value)  deliveredToConsignee,required TResult Function( ShipmentUndeliverable value)  undeliverable,required TResult Function( ShipmentReturnedToDepot value)  returnedToDepot,}){
final _that = this;
switch (_that) {
case ShipmentAwaitingAssignment():
return awaitingAssignment(_that);case ShipmentAssignedToCourier():
return assignedToCourier(_that);case ShipmentLoadedOnVehicle():
return loadedOnVehicle(_that);case ShipmentOutForDelivery():
return outForDelivery(_that);case ShipmentDeliveredToConsignee():
return deliveredToConsignee(_that);case ShipmentUndeliverable():
return undeliverable(_that);case ShipmentReturnedToDepot():
return returnedToDepot(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ShipmentAwaitingAssignment value)?  awaitingAssignment,TResult? Function( ShipmentAssignedToCourier value)?  assignedToCourier,TResult? Function( ShipmentLoadedOnVehicle value)?  loadedOnVehicle,TResult? Function( ShipmentOutForDelivery value)?  outForDelivery,TResult? Function( ShipmentDeliveredToConsignee value)?  deliveredToConsignee,TResult? Function( ShipmentUndeliverable value)?  undeliverable,TResult? Function( ShipmentReturnedToDepot value)?  returnedToDepot,}){
final _that = this;
switch (_that) {
case ShipmentAwaitingAssignment() when awaitingAssignment != null:
return awaitingAssignment(_that);case ShipmentAssignedToCourier() when assignedToCourier != null:
return assignedToCourier(_that);case ShipmentLoadedOnVehicle() when loadedOnVehicle != null:
return loadedOnVehicle(_that);case ShipmentOutForDelivery() when outForDelivery != null:
return outForDelivery(_that);case ShipmentDeliveredToConsignee() when deliveredToConsignee != null:
return deliveredToConsignee(_that);case ShipmentUndeliverable() when undeliverable != null:
return undeliverable(_that);case ShipmentReturnedToDepot() when returnedToDepot != null:
return returnedToDepot(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  awaitingAssignment,TResult Function( ActorId courier)?  assignedToCourier,TResult Function( ActorId courier)?  loadedOnVehicle,TResult Function( ActorId courier)?  outForDelivery,TResult Function( String proofReference,  DateTime at)?  deliveredToConsignee,TResult Function( String reason,  DateTime at)?  undeliverable,TResult Function( DateTime at)?  returnedToDepot,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ShipmentAwaitingAssignment() when awaitingAssignment != null:
return awaitingAssignment();case ShipmentAssignedToCourier() when assignedToCourier != null:
return assignedToCourier(_that.courier);case ShipmentLoadedOnVehicle() when loadedOnVehicle != null:
return loadedOnVehicle(_that.courier);case ShipmentOutForDelivery() when outForDelivery != null:
return outForDelivery(_that.courier);case ShipmentDeliveredToConsignee() when deliveredToConsignee != null:
return deliveredToConsignee(_that.proofReference,_that.at);case ShipmentUndeliverable() when undeliverable != null:
return undeliverable(_that.reason,_that.at);case ShipmentReturnedToDepot() when returnedToDepot != null:
return returnedToDepot(_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  awaitingAssignment,required TResult Function( ActorId courier)  assignedToCourier,required TResult Function( ActorId courier)  loadedOnVehicle,required TResult Function( ActorId courier)  outForDelivery,required TResult Function( String proofReference,  DateTime at)  deliveredToConsignee,required TResult Function( String reason,  DateTime at)  undeliverable,required TResult Function( DateTime at)  returnedToDepot,}) {final _that = this;
switch (_that) {
case ShipmentAwaitingAssignment():
return awaitingAssignment();case ShipmentAssignedToCourier():
return assignedToCourier(_that.courier);case ShipmentLoadedOnVehicle():
return loadedOnVehicle(_that.courier);case ShipmentOutForDelivery():
return outForDelivery(_that.courier);case ShipmentDeliveredToConsignee():
return deliveredToConsignee(_that.proofReference,_that.at);case ShipmentUndeliverable():
return undeliverable(_that.reason,_that.at);case ShipmentReturnedToDepot():
return returnedToDepot(_that.at);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  awaitingAssignment,TResult? Function( ActorId courier)?  assignedToCourier,TResult? Function( ActorId courier)?  loadedOnVehicle,TResult? Function( ActorId courier)?  outForDelivery,TResult? Function( String proofReference,  DateTime at)?  deliveredToConsignee,TResult? Function( String reason,  DateTime at)?  undeliverable,TResult? Function( DateTime at)?  returnedToDepot,}) {final _that = this;
switch (_that) {
case ShipmentAwaitingAssignment() when awaitingAssignment != null:
return awaitingAssignment();case ShipmentAssignedToCourier() when assignedToCourier != null:
return assignedToCourier(_that.courier);case ShipmentLoadedOnVehicle() when loadedOnVehicle != null:
return loadedOnVehicle(_that.courier);case ShipmentOutForDelivery() when outForDelivery != null:
return outForDelivery(_that.courier);case ShipmentDeliveredToConsignee() when deliveredToConsignee != null:
return deliveredToConsignee(_that.proofReference,_that.at);case ShipmentUndeliverable() when undeliverable != null:
return undeliverable(_that.reason,_that.at);case ShipmentReturnedToDepot() when returnedToDepot != null:
return returnedToDepot(_that.at);case _:
  return null;

}
}

}

/// @nodoc


class ShipmentAwaitingAssignment extends ShipmentStatus {
  const ShipmentAwaitingAssignment(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShipmentAwaitingAssignment);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShipmentStatus.awaitingAssignment()';
}


}




/// @nodoc


class ShipmentAssignedToCourier extends ShipmentStatus {
  const ShipmentAssignedToCourier(this.courier): super._();
  

 final  ActorId courier;

/// Create a copy of ShipmentStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShipmentAssignedToCourierCopyWith<ShipmentAssignedToCourier> get copyWith => _$ShipmentAssignedToCourierCopyWithImpl<ShipmentAssignedToCourier>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShipmentAssignedToCourier&&(identical(other.courier, courier) || other.courier == courier));
}


@override
int get hashCode => Object.hash(runtimeType,courier);

@override
String toString() {
  return 'ShipmentStatus.assignedToCourier(courier: $courier)';
}


}

/// @nodoc
abstract mixin class $ShipmentAssignedToCourierCopyWith<$Res> implements $ShipmentStatusCopyWith<$Res> {
  factory $ShipmentAssignedToCourierCopyWith(ShipmentAssignedToCourier value, $Res Function(ShipmentAssignedToCourier) _then) = _$ShipmentAssignedToCourierCopyWithImpl;
@useResult
$Res call({
 ActorId courier
});




}
/// @nodoc
class _$ShipmentAssignedToCourierCopyWithImpl<$Res>
    implements $ShipmentAssignedToCourierCopyWith<$Res> {
  _$ShipmentAssignedToCourierCopyWithImpl(this._self, this._then);

  final ShipmentAssignedToCourier _self;
  final $Res Function(ShipmentAssignedToCourier) _then;

/// Create a copy of ShipmentStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? courier = null,}) {
  return _then(ShipmentAssignedToCourier(
null == courier ? _self.courier : courier // ignore: cast_nullable_to_non_nullable
as ActorId,
  ));
}


}

/// @nodoc


class ShipmentLoadedOnVehicle extends ShipmentStatus {
  const ShipmentLoadedOnVehicle(this.courier): super._();
  

 final  ActorId courier;

/// Create a copy of ShipmentStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShipmentLoadedOnVehicleCopyWith<ShipmentLoadedOnVehicle> get copyWith => _$ShipmentLoadedOnVehicleCopyWithImpl<ShipmentLoadedOnVehicle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShipmentLoadedOnVehicle&&(identical(other.courier, courier) || other.courier == courier));
}


@override
int get hashCode => Object.hash(runtimeType,courier);

@override
String toString() {
  return 'ShipmentStatus.loadedOnVehicle(courier: $courier)';
}


}

/// @nodoc
abstract mixin class $ShipmentLoadedOnVehicleCopyWith<$Res> implements $ShipmentStatusCopyWith<$Res> {
  factory $ShipmentLoadedOnVehicleCopyWith(ShipmentLoadedOnVehicle value, $Res Function(ShipmentLoadedOnVehicle) _then) = _$ShipmentLoadedOnVehicleCopyWithImpl;
@useResult
$Res call({
 ActorId courier
});




}
/// @nodoc
class _$ShipmentLoadedOnVehicleCopyWithImpl<$Res>
    implements $ShipmentLoadedOnVehicleCopyWith<$Res> {
  _$ShipmentLoadedOnVehicleCopyWithImpl(this._self, this._then);

  final ShipmentLoadedOnVehicle _self;
  final $Res Function(ShipmentLoadedOnVehicle) _then;

/// Create a copy of ShipmentStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? courier = null,}) {
  return _then(ShipmentLoadedOnVehicle(
null == courier ? _self.courier : courier // ignore: cast_nullable_to_non_nullable
as ActorId,
  ));
}


}

/// @nodoc


class ShipmentOutForDelivery extends ShipmentStatus {
  const ShipmentOutForDelivery(this.courier): super._();
  

 final  ActorId courier;

/// Create a copy of ShipmentStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShipmentOutForDeliveryCopyWith<ShipmentOutForDelivery> get copyWith => _$ShipmentOutForDeliveryCopyWithImpl<ShipmentOutForDelivery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShipmentOutForDelivery&&(identical(other.courier, courier) || other.courier == courier));
}


@override
int get hashCode => Object.hash(runtimeType,courier);

@override
String toString() {
  return 'ShipmentStatus.outForDelivery(courier: $courier)';
}


}

/// @nodoc
abstract mixin class $ShipmentOutForDeliveryCopyWith<$Res> implements $ShipmentStatusCopyWith<$Res> {
  factory $ShipmentOutForDeliveryCopyWith(ShipmentOutForDelivery value, $Res Function(ShipmentOutForDelivery) _then) = _$ShipmentOutForDeliveryCopyWithImpl;
@useResult
$Res call({
 ActorId courier
});




}
/// @nodoc
class _$ShipmentOutForDeliveryCopyWithImpl<$Res>
    implements $ShipmentOutForDeliveryCopyWith<$Res> {
  _$ShipmentOutForDeliveryCopyWithImpl(this._self, this._then);

  final ShipmentOutForDelivery _self;
  final $Res Function(ShipmentOutForDelivery) _then;

/// Create a copy of ShipmentStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? courier = null,}) {
  return _then(ShipmentOutForDelivery(
null == courier ? _self.courier : courier // ignore: cast_nullable_to_non_nullable
as ActorId,
  ));
}


}

/// @nodoc


class ShipmentDeliveredToConsignee extends ShipmentStatus {
  const ShipmentDeliveredToConsignee({required this.proofReference, required this.at}): super._();
  

 final  String proofReference;
 final  DateTime at;

/// Create a copy of ShipmentStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShipmentDeliveredToConsigneeCopyWith<ShipmentDeliveredToConsignee> get copyWith => _$ShipmentDeliveredToConsigneeCopyWithImpl<ShipmentDeliveredToConsignee>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShipmentDeliveredToConsignee&&(identical(other.proofReference, proofReference) || other.proofReference == proofReference)&&(identical(other.at, at) || other.at == at));
}


@override
int get hashCode => Object.hash(runtimeType,proofReference,at);

@override
String toString() {
  return 'ShipmentStatus.deliveredToConsignee(proofReference: $proofReference, at: $at)';
}


}

/// @nodoc
abstract mixin class $ShipmentDeliveredToConsigneeCopyWith<$Res> implements $ShipmentStatusCopyWith<$Res> {
  factory $ShipmentDeliveredToConsigneeCopyWith(ShipmentDeliveredToConsignee value, $Res Function(ShipmentDeliveredToConsignee) _then) = _$ShipmentDeliveredToConsigneeCopyWithImpl;
@useResult
$Res call({
 String proofReference, DateTime at
});




}
/// @nodoc
class _$ShipmentDeliveredToConsigneeCopyWithImpl<$Res>
    implements $ShipmentDeliveredToConsigneeCopyWith<$Res> {
  _$ShipmentDeliveredToConsigneeCopyWithImpl(this._self, this._then);

  final ShipmentDeliveredToConsignee _self;
  final $Res Function(ShipmentDeliveredToConsignee) _then;

/// Create a copy of ShipmentStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? proofReference = null,Object? at = null,}) {
  return _then(ShipmentDeliveredToConsignee(
proofReference: null == proofReference ? _self.proofReference : proofReference // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class ShipmentUndeliverable extends ShipmentStatus {
  const ShipmentUndeliverable({required this.reason, required this.at}): super._();
  

 final  String reason;
 final  DateTime at;

/// Create a copy of ShipmentStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShipmentUndeliverableCopyWith<ShipmentUndeliverable> get copyWith => _$ShipmentUndeliverableCopyWithImpl<ShipmentUndeliverable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShipmentUndeliverable&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.at, at) || other.at == at));
}


@override
int get hashCode => Object.hash(runtimeType,reason,at);

@override
String toString() {
  return 'ShipmentStatus.undeliverable(reason: $reason, at: $at)';
}


}

/// @nodoc
abstract mixin class $ShipmentUndeliverableCopyWith<$Res> implements $ShipmentStatusCopyWith<$Res> {
  factory $ShipmentUndeliverableCopyWith(ShipmentUndeliverable value, $Res Function(ShipmentUndeliverable) _then) = _$ShipmentUndeliverableCopyWithImpl;
@useResult
$Res call({
 String reason, DateTime at
});




}
/// @nodoc
class _$ShipmentUndeliverableCopyWithImpl<$Res>
    implements $ShipmentUndeliverableCopyWith<$Res> {
  _$ShipmentUndeliverableCopyWithImpl(this._self, this._then);

  final ShipmentUndeliverable _self;
  final $Res Function(ShipmentUndeliverable) _then;

/// Create a copy of ShipmentStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? at = null,}) {
  return _then(ShipmentUndeliverable(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class ShipmentReturnedToDepot extends ShipmentStatus {
  const ShipmentReturnedToDepot({required this.at}): super._();
  

 final  DateTime at;

/// Create a copy of ShipmentStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShipmentReturnedToDepotCopyWith<ShipmentReturnedToDepot> get copyWith => _$ShipmentReturnedToDepotCopyWithImpl<ShipmentReturnedToDepot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShipmentReturnedToDepot&&(identical(other.at, at) || other.at == at));
}


@override
int get hashCode => Object.hash(runtimeType,at);

@override
String toString() {
  return 'ShipmentStatus.returnedToDepot(at: $at)';
}


}

/// @nodoc
abstract mixin class $ShipmentReturnedToDepotCopyWith<$Res> implements $ShipmentStatusCopyWith<$Res> {
  factory $ShipmentReturnedToDepotCopyWith(ShipmentReturnedToDepot value, $Res Function(ShipmentReturnedToDepot) _then) = _$ShipmentReturnedToDepotCopyWithImpl;
@useResult
$Res call({
 DateTime at
});




}
/// @nodoc
class _$ShipmentReturnedToDepotCopyWithImpl<$Res>
    implements $ShipmentReturnedToDepotCopyWith<$Res> {
  _$ShipmentReturnedToDepotCopyWithImpl(this._self, this._then);

  final ShipmentReturnedToDepot _self;
  final $Res Function(ShipmentReturnedToDepot) _then;

/// Create a copy of ShipmentStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? at = null,}) {
  return _then(ShipmentReturnedToDepot(
at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
