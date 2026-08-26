// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conflict_policy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConflictPolicy {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConflictPolicy);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConflictPolicy()';
}


}

/// @nodoc
class $ConflictPolicyCopyWith<$Res>  {
$ConflictPolicyCopyWith(ConflictPolicy _, $Res Function(ConflictPolicy) __);
}


/// Adds pattern-matching-related methods to [ConflictPolicy].
extension ConflictPolicyPatterns on ConflictPolicy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LastWriteWins value)?  lastWriteWins,TResult Function( ServerWins value)?  serverWins,TResult Function( ManualReview value)?  manualReview,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LastWriteWins() when lastWriteWins != null:
return lastWriteWins(_that);case ServerWins() when serverWins != null:
return serverWins(_that);case ManualReview() when manualReview != null:
return manualReview(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LastWriteWins value)  lastWriteWins,required TResult Function( ServerWins value)  serverWins,required TResult Function( ManualReview value)  manualReview,}){
final _that = this;
switch (_that) {
case LastWriteWins():
return lastWriteWins(_that);case ServerWins():
return serverWins(_that);case ManualReview():
return manualReview(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LastWriteWins value)?  lastWriteWins,TResult? Function( ServerWins value)?  serverWins,TResult? Function( ManualReview value)?  manualReview,}){
final _that = this;
switch (_that) {
case LastWriteWins() when lastWriteWins != null:
return lastWriteWins(_that);case ServerWins() when serverWins != null:
return serverWins(_that);case ManualReview() when manualReview != null:
return manualReview(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  lastWriteWins,TResult Function()?  serverWins,TResult Function()?  manualReview,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LastWriteWins() when lastWriteWins != null:
return lastWriteWins();case ServerWins() when serverWins != null:
return serverWins();case ManualReview() when manualReview != null:
return manualReview();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  lastWriteWins,required TResult Function()  serverWins,required TResult Function()  manualReview,}) {final _that = this;
switch (_that) {
case LastWriteWins():
return lastWriteWins();case ServerWins():
return serverWins();case ManualReview():
return manualReview();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  lastWriteWins,TResult? Function()?  serverWins,TResult? Function()?  manualReview,}) {final _that = this;
switch (_that) {
case LastWriteWins() when lastWriteWins != null:
return lastWriteWins();case ServerWins() when serverWins != null:
return serverWins();case ManualReview() when manualReview != null:
return manualReview();case _:
  return null;

}
}

}

/// @nodoc


class LastWriteWins extends ConflictPolicy {
  const LastWriteWins(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LastWriteWins);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConflictPolicy.lastWriteWins()';
}


}




/// @nodoc


class ServerWins extends ConflictPolicy {
  const ServerWins(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerWins);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConflictPolicy.serverWins()';
}


}




/// @nodoc


class ManualReview extends ConflictPolicy {
  const ManualReview(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ManualReview);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConflictPolicy.manualReview()';
}


}




// dart format on
