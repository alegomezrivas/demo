// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'complete_sign_up_request_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CompleteSignUpRequestDto {

 String get verificationToken; String get name; String get username; String get password;
/// Create a copy of CompleteSignUpRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompleteSignUpRequestDtoCopyWith<CompleteSignUpRequestDto> get copyWith => _$CompleteSignUpRequestDtoCopyWithImpl<CompleteSignUpRequestDto>(this as CompleteSignUpRequestDto, _$identity);

  /// Serializes this CompleteSignUpRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompleteSignUpRequestDto&&(identical(other.verificationToken, verificationToken) || other.verificationToken == verificationToken)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,verificationToken,name,username,password);

@override
String toString() {
  return 'CompleteSignUpRequestDto(verificationToken: $verificationToken, name: $name, username: $username, password: $password)';
}


}

/// @nodoc
abstract mixin class $CompleteSignUpRequestDtoCopyWith<$Res>  {
  factory $CompleteSignUpRequestDtoCopyWith(CompleteSignUpRequestDto value, $Res Function(CompleteSignUpRequestDto) _then) = _$CompleteSignUpRequestDtoCopyWithImpl;
@useResult
$Res call({
 String verificationToken, String name, String username, String password
});




}
/// @nodoc
class _$CompleteSignUpRequestDtoCopyWithImpl<$Res>
    implements $CompleteSignUpRequestDtoCopyWith<$Res> {
  _$CompleteSignUpRequestDtoCopyWithImpl(this._self, this._then);

  final CompleteSignUpRequestDto _self;
  final $Res Function(CompleteSignUpRequestDto) _then;

/// Create a copy of CompleteSignUpRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? verificationToken = null,Object? name = null,Object? username = null,Object? password = null,}) {
  return _then(_self.copyWith(
verificationToken: null == verificationToken ? _self.verificationToken : verificationToken // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CompleteSignUpRequestDto].
extension CompleteSignUpRequestDtoPatterns on CompleteSignUpRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompleteSignUpRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompleteSignUpRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompleteSignUpRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _CompleteSignUpRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompleteSignUpRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _CompleteSignUpRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String verificationToken,  String name,  String username,  String password)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompleteSignUpRequestDto() when $default != null:
return $default(_that.verificationToken,_that.name,_that.username,_that.password);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String verificationToken,  String name,  String username,  String password)  $default,) {final _that = this;
switch (_that) {
case _CompleteSignUpRequestDto():
return $default(_that.verificationToken,_that.name,_that.username,_that.password);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String verificationToken,  String name,  String username,  String password)?  $default,) {final _that = this;
switch (_that) {
case _CompleteSignUpRequestDto() when $default != null:
return $default(_that.verificationToken,_that.name,_that.username,_that.password);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompleteSignUpRequestDto implements CompleteSignUpRequestDto {
  const _CompleteSignUpRequestDto({required this.verificationToken, required this.name, required this.username, required this.password});
  factory _CompleteSignUpRequestDto.fromJson(Map<String, dynamic> json) => _$CompleteSignUpRequestDtoFromJson(json);

@override final  String verificationToken;
@override final  String name;
@override final  String username;
@override final  String password;

/// Create a copy of CompleteSignUpRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompleteSignUpRequestDtoCopyWith<_CompleteSignUpRequestDto> get copyWith => __$CompleteSignUpRequestDtoCopyWithImpl<_CompleteSignUpRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompleteSignUpRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompleteSignUpRequestDto&&(identical(other.verificationToken, verificationToken) || other.verificationToken == verificationToken)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,verificationToken,name,username,password);

@override
String toString() {
  return 'CompleteSignUpRequestDto(verificationToken: $verificationToken, name: $name, username: $username, password: $password)';
}


}

/// @nodoc
abstract mixin class _$CompleteSignUpRequestDtoCopyWith<$Res> implements $CompleteSignUpRequestDtoCopyWith<$Res> {
  factory _$CompleteSignUpRequestDtoCopyWith(_CompleteSignUpRequestDto value, $Res Function(_CompleteSignUpRequestDto) _then) = __$CompleteSignUpRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String verificationToken, String name, String username, String password
});




}
/// @nodoc
class __$CompleteSignUpRequestDtoCopyWithImpl<$Res>
    implements _$CompleteSignUpRequestDtoCopyWith<$Res> {
  __$CompleteSignUpRequestDtoCopyWithImpl(this._self, this._then);

  final _CompleteSignUpRequestDto _self;
  final $Res Function(_CompleteSignUpRequestDto) _then;

/// Create a copy of CompleteSignUpRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? verificationToken = null,Object? name = null,Object? username = null,Object? password = null,}) {
  return _then(_CompleteSignUpRequestDto(
verificationToken: null == verificationToken ? _self.verificationToken : verificationToken // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
