// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verify_code_request_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VerifyCodeRequestDto {

 String get email; String get code;
/// Create a copy of VerifyCodeRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifyCodeRequestDtoCopyWith<VerifyCodeRequestDto> get copyWith => _$VerifyCodeRequestDtoCopyWithImpl<VerifyCodeRequestDto>(this as VerifyCodeRequestDto, _$identity);

  /// Serializes this VerifyCodeRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyCodeRequestDto&&(identical(other.email, email) || other.email == email)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,code);

@override
String toString() {
  return 'VerifyCodeRequestDto(email: $email, code: $code)';
}


}

/// @nodoc
abstract mixin class $VerifyCodeRequestDtoCopyWith<$Res>  {
  factory $VerifyCodeRequestDtoCopyWith(VerifyCodeRequestDto value, $Res Function(VerifyCodeRequestDto) _then) = _$VerifyCodeRequestDtoCopyWithImpl;
@useResult
$Res call({
 String email, String code
});




}
/// @nodoc
class _$VerifyCodeRequestDtoCopyWithImpl<$Res>
    implements $VerifyCodeRequestDtoCopyWith<$Res> {
  _$VerifyCodeRequestDtoCopyWithImpl(this._self, this._then);

  final VerifyCodeRequestDto _self;
  final $Res Function(VerifyCodeRequestDto) _then;

/// Create a copy of VerifyCodeRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? code = null,}) {
  return _then(_self.copyWith(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VerifyCodeRequestDto].
extension VerifyCodeRequestDtoPatterns on VerifyCodeRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerifyCodeRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerifyCodeRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerifyCodeRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _VerifyCodeRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerifyCodeRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _VerifyCodeRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  String code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerifyCodeRequestDto() when $default != null:
return $default(_that.email,_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  String code)  $default,) {final _that = this;
switch (_that) {
case _VerifyCodeRequestDto():
return $default(_that.email,_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  String code)?  $default,) {final _that = this;
switch (_that) {
case _VerifyCodeRequestDto() when $default != null:
return $default(_that.email,_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerifyCodeRequestDto implements VerifyCodeRequestDto {
  const _VerifyCodeRequestDto({required this.email, required this.code});
  factory _VerifyCodeRequestDto.fromJson(Map<String, dynamic> json) => _$VerifyCodeRequestDtoFromJson(json);

@override final  String email;
@override final  String code;

/// Create a copy of VerifyCodeRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerifyCodeRequestDtoCopyWith<_VerifyCodeRequestDto> get copyWith => __$VerifyCodeRequestDtoCopyWithImpl<_VerifyCodeRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerifyCodeRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerifyCodeRequestDto&&(identical(other.email, email) || other.email == email)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,code);

@override
String toString() {
  return 'VerifyCodeRequestDto(email: $email, code: $code)';
}


}

/// @nodoc
abstract mixin class _$VerifyCodeRequestDtoCopyWith<$Res> implements $VerifyCodeRequestDtoCopyWith<$Res> {
  factory _$VerifyCodeRequestDtoCopyWith(_VerifyCodeRequestDto value, $Res Function(_VerifyCodeRequestDto) _then) = __$VerifyCodeRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String email, String code
});




}
/// @nodoc
class __$VerifyCodeRequestDtoCopyWithImpl<$Res>
    implements _$VerifyCodeRequestDtoCopyWith<$Res> {
  __$VerifyCodeRequestDtoCopyWithImpl(this._self, this._then);

  final _VerifyCodeRequestDto _self;
  final $Res Function(_VerifyCodeRequestDto) _then;

/// Create a copy of VerifyCodeRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? code = null,}) {
  return _then(_VerifyCodeRequestDto(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
