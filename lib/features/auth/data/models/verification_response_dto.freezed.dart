// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verification_response_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VerificationResponseDto {

 String get verificationToken;
/// Create a copy of VerificationResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationResponseDtoCopyWith<VerificationResponseDto> get copyWith => _$VerificationResponseDtoCopyWithImpl<VerificationResponseDto>(this as VerificationResponseDto, _$identity);

  /// Serializes this VerificationResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationResponseDto&&(identical(other.verificationToken, verificationToken) || other.verificationToken == verificationToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,verificationToken);

@override
String toString() {
  return 'VerificationResponseDto(verificationToken: $verificationToken)';
}


}

/// @nodoc
abstract mixin class $VerificationResponseDtoCopyWith<$Res>  {
  factory $VerificationResponseDtoCopyWith(VerificationResponseDto value, $Res Function(VerificationResponseDto) _then) = _$VerificationResponseDtoCopyWithImpl;
@useResult
$Res call({
 String verificationToken
});




}
/// @nodoc
class _$VerificationResponseDtoCopyWithImpl<$Res>
    implements $VerificationResponseDtoCopyWith<$Res> {
  _$VerificationResponseDtoCopyWithImpl(this._self, this._then);

  final VerificationResponseDto _self;
  final $Res Function(VerificationResponseDto) _then;

/// Create a copy of VerificationResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? verificationToken = null,}) {
  return _then(_self.copyWith(
verificationToken: null == verificationToken ? _self.verificationToken : verificationToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VerificationResponseDto].
extension VerificationResponseDtoPatterns on VerificationResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerificationResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerificationResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerificationResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _VerificationResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerificationResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _VerificationResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String verificationToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerificationResponseDto() when $default != null:
return $default(_that.verificationToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String verificationToken)  $default,) {final _that = this;
switch (_that) {
case _VerificationResponseDto():
return $default(_that.verificationToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String verificationToken)?  $default,) {final _that = this;
switch (_that) {
case _VerificationResponseDto() when $default != null:
return $default(_that.verificationToken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerificationResponseDto implements VerificationResponseDto {
  const _VerificationResponseDto({required this.verificationToken});
  factory _VerificationResponseDto.fromJson(Map<String, dynamic> json) => _$VerificationResponseDtoFromJson(json);

@override final  String verificationToken;

/// Create a copy of VerificationResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationResponseDtoCopyWith<_VerificationResponseDto> get copyWith => __$VerificationResponseDtoCopyWithImpl<_VerificationResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerificationResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerificationResponseDto&&(identical(other.verificationToken, verificationToken) || other.verificationToken == verificationToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,verificationToken);

@override
String toString() {
  return 'VerificationResponseDto(verificationToken: $verificationToken)';
}


}

/// @nodoc
abstract mixin class _$VerificationResponseDtoCopyWith<$Res> implements $VerificationResponseDtoCopyWith<$Res> {
  factory _$VerificationResponseDtoCopyWith(_VerificationResponseDto value, $Res Function(_VerificationResponseDto) _then) = __$VerificationResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 String verificationToken
});




}
/// @nodoc
class __$VerificationResponseDtoCopyWithImpl<$Res>
    implements _$VerificationResponseDtoCopyWith<$Res> {
  __$VerificationResponseDtoCopyWithImpl(this._self, this._then);

  final _VerificationResponseDto _self;
  final $Res Function(_VerificationResponseDto) _then;

/// Create a copy of VerificationResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? verificationToken = null,}) {
  return _then(_VerificationResponseDto(
verificationToken: null == verificationToken ? _self.verificationToken : verificationToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
