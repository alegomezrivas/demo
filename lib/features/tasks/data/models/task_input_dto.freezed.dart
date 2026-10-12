// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_input_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskInputDto {

 String get title; String get description; String get priority; bool get isDone; String? get dueDate;
/// Create a copy of TaskInputDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskInputDtoCopyWith<TaskInputDto> get copyWith => _$TaskInputDtoCopyWithImpl<TaskInputDto>(this as TaskInputDto, _$identity);

  /// Serializes this TaskInputDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TaskInputDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskInputDto&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.isDone, _this.isDone) || other.isDone == _this.isDone)&&(identical(other.dueDate, _this.dueDate) || other.dueDate == _this.dueDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TaskInputDto;
  return Object.hash(runtimeType,_this.title,_this.description,_this.priority,_this.isDone,_this.dueDate);
}

@override
String toString() {
  final _this = this as TaskInputDto;
  return 'TaskInputDto(title: ${_this.title}, description: ${_this.description}, priority: ${_this.priority}, isDone: ${_this.isDone}, dueDate: ${_this.dueDate})';
}


}

/// @nodoc
abstract mixin class $TaskInputDtoCopyWith<$Res>  {
  factory $TaskInputDtoCopyWith(TaskInputDto value, $Res Function(TaskInputDto) _then) = _$TaskInputDtoCopyWithImpl;
@useResult
$Res call({
 String title, String description, String priority, bool isDone, String? dueDate
});




}
/// @nodoc
class _$TaskInputDtoCopyWithImpl<$Res>
    implements $TaskInputDtoCopyWith<$Res> {
  _$TaskInputDtoCopyWithImpl(this._self, this._then);

  final TaskInputDto _self;
  final $Res Function(TaskInputDto) _then;

/// Create a copy of TaskInputDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? description = null,Object? priority = null,Object? isDone = null,Object? dueDate = freezed,}) {
  return _then(TaskInputDto(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,isDone: null == isDone ? _self.isDone : isDone // ignore: cast_nullable_to_non_nullable
as bool,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskInputDto].
extension TaskInputDtoPatterns on TaskInputDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskInputDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskInputDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskInputDto value)  $default,){
final _that = this;
switch (_that) {
case _TaskInputDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskInputDto value)?  $default,){
final _that = this;
switch (_that) {
case _TaskInputDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String description,  String priority,  bool isDone,  String? dueDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskInputDto() when $default != null:
return $default(_that.title,_that.description,_that.priority,_that.isDone,_that.dueDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String description,  String priority,  bool isDone,  String? dueDate)  $default,) {final _that = this;
switch (_that) {
case _TaskInputDto():
return $default(_that.title,_that.description,_that.priority,_that.isDone,_that.dueDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String description,  String priority,  bool isDone,  String? dueDate)?  $default,) {final _that = this;
switch (_that) {
case _TaskInputDto() when $default != null:
return $default(_that.title,_that.description,_that.priority,_that.isDone,_that.dueDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskInputDto implements TaskInputDto {
  const _TaskInputDto({required this.title, required this.description, required this.priority, required this.isDone, this.dueDate});
  factory _TaskInputDto.fromJson(Map<String, dynamic> json) => _$TaskInputDtoFromJson(json);

@override final  String title;
@override final  String description;
@override final  String priority;
@override final  bool isDone;
@override final  String? dueDate;

/// Create a copy of TaskInputDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskInputDtoCopyWith<_TaskInputDto> get copyWith => __$TaskInputDtoCopyWithImpl<_TaskInputDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskInputDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskInputDto&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.isDone, isDone) || other.isDone == isDone)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,description,priority,isDone,dueDate);
}

@override
String toString() {
    return 'TaskInputDto(title: $title, description: $description, priority: $priority, isDone: $isDone, dueDate: $dueDate)';
}


}

/// @nodoc
abstract mixin class _$TaskInputDtoCopyWith<$Res> implements $TaskInputDtoCopyWith<$Res> {
  factory _$TaskInputDtoCopyWith(_TaskInputDto value, $Res Function(_TaskInputDto) _then) = __$TaskInputDtoCopyWithImpl;
@override @useResult
$Res call({
 String title, String description, String priority, bool isDone, String? dueDate
});




}
/// @nodoc
class __$TaskInputDtoCopyWithImpl<$Res>
    implements _$TaskInputDtoCopyWith<$Res> {
  __$TaskInputDtoCopyWithImpl(this._self, this._then);

  final _TaskInputDto _self;
  final $Res Function(_TaskInputDto) _then;

/// Create a copy of TaskInputDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? description = null,Object? priority = null,Object? isDone = null,Object? dueDate = freezed,}) {
  return _then(_TaskInputDto(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,isDone: null == isDone ? _self.isDone : isDone // ignore: cast_nullable_to_non_nullable
as bool,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
