// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SettingsDto {

 String get themeMode; String get language; bool get biometricConfirmation;
/// Create a copy of SettingsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsDtoCopyWith<SettingsDto> get copyWith => _$SettingsDtoCopyWithImpl<SettingsDto>(this as SettingsDto, _$identity);

  /// Serializes this SettingsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SettingsDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsDto&&(identical(other.themeMode, _this.themeMode) || other.themeMode == _this.themeMode)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.biometricConfirmation, _this.biometricConfirmation) || other.biometricConfirmation == _this.biometricConfirmation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SettingsDto;
  return Object.hash(runtimeType,_this.themeMode,_this.language,_this.biometricConfirmation);
}

@override
String toString() {
  final _this = this as SettingsDto;
  return 'SettingsDto(themeMode: ${_this.themeMode}, language: ${_this.language}, biometricConfirmation: ${_this.biometricConfirmation})';
}


}

/// @nodoc
abstract mixin class $SettingsDtoCopyWith<$Res>  {
  factory $SettingsDtoCopyWith(SettingsDto value, $Res Function(SettingsDto) _then) = _$SettingsDtoCopyWithImpl;
@useResult
$Res call({
 String themeMode, String language, bool biometricConfirmation
});




}
/// @nodoc
class _$SettingsDtoCopyWithImpl<$Res>
    implements $SettingsDtoCopyWith<$Res> {
  _$SettingsDtoCopyWithImpl(this._self, this._then);

  final SettingsDto _self;
  final $Res Function(SettingsDto) _then;

/// Create a copy of SettingsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeMode = null,Object? language = null,Object? biometricConfirmation = null,}) {
  return _then(SettingsDto(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,biometricConfirmation: null == biometricConfirmation ? _self.biometricConfirmation : biometricConfirmation // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SettingsDto].
extension SettingsDtoPatterns on SettingsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingsDto value)  $default,){
final _that = this;
switch (_that) {
case _SettingsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingsDto value)?  $default,){
final _that = this;
switch (_that) {
case _SettingsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String themeMode,  String language,  bool biometricConfirmation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsDto() when $default != null:
return $default(_that.themeMode,_that.language,_that.biometricConfirmation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String themeMode,  String language,  bool biometricConfirmation)  $default,) {final _that = this;
switch (_that) {
case _SettingsDto():
return $default(_that.themeMode,_that.language,_that.biometricConfirmation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String themeMode,  String language,  bool biometricConfirmation)?  $default,) {final _that = this;
switch (_that) {
case _SettingsDto() when $default != null:
return $default(_that.themeMode,_that.language,_that.biometricConfirmation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SettingsDto implements SettingsDto {
  const _SettingsDto({this.themeMode = 'system', this.language = 'system', this.biometricConfirmation = false});
  factory _SettingsDto.fromJson(Map<String, dynamic> json) => _$SettingsDtoFromJson(json);

@override@JsonKey() final  String themeMode;
@override@JsonKey() final  String language;
@override@JsonKey() final  bool biometricConfirmation;

/// Create a copy of SettingsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsDtoCopyWith<_SettingsDto> get copyWith => __$SettingsDtoCopyWithImpl<_SettingsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettingsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsDto&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.language, language) || other.language == language)&&(identical(other.biometricConfirmation, biometricConfirmation) || other.biometricConfirmation == biometricConfirmation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,themeMode,language,biometricConfirmation);
}

@override
String toString() {
    return 'SettingsDto(themeMode: $themeMode, language: $language, biometricConfirmation: $biometricConfirmation)';
}


}

/// @nodoc
abstract mixin class _$SettingsDtoCopyWith<$Res> implements $SettingsDtoCopyWith<$Res> {
  factory _$SettingsDtoCopyWith(_SettingsDto value, $Res Function(_SettingsDto) _then) = __$SettingsDtoCopyWithImpl;
@override @useResult
$Res call({
 String themeMode, String language, bool biometricConfirmation
});




}
/// @nodoc
class __$SettingsDtoCopyWithImpl<$Res>
    implements _$SettingsDtoCopyWith<$Res> {
  __$SettingsDtoCopyWithImpl(this._self, this._then);

  final _SettingsDto _self;
  final $Res Function(_SettingsDto) _then;

/// Create a copy of SettingsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? themeMode = null,Object? language = null,Object? biometricConfirmation = null,}) {
  return _then(_SettingsDto(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,biometricConfirmation: null == biometricConfirmation ? _self.biometricConfirmation : biometricConfirmation // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
