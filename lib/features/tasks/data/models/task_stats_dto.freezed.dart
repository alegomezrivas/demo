// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_stats_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskStatsDto {

 int get total; int get done; int get overdue; int get highPriorityPending;
/// Create a copy of TaskStatsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskStatsDtoCopyWith<TaskStatsDto> get copyWith => _$TaskStatsDtoCopyWithImpl<TaskStatsDto>(this as TaskStatsDto, _$identity);

  /// Serializes this TaskStatsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskStatsDto&&(identical(other.total, total) || other.total == total)&&(identical(other.done, done) || other.done == done)&&(identical(other.overdue, overdue) || other.overdue == overdue)&&(identical(other.highPriorityPending, highPriorityPending) || other.highPriorityPending == highPriorityPending));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,done,overdue,highPriorityPending);

@override
String toString() {
  return 'TaskStatsDto(total: $total, done: $done, overdue: $overdue, highPriorityPending: $highPriorityPending)';
}


}

/// @nodoc
abstract mixin class $TaskStatsDtoCopyWith<$Res>  {
  factory $TaskStatsDtoCopyWith(TaskStatsDto value, $Res Function(TaskStatsDto) _then) = _$TaskStatsDtoCopyWithImpl;
@useResult
$Res call({
 int total, int done, int overdue, int highPriorityPending
});




}
/// @nodoc
class _$TaskStatsDtoCopyWithImpl<$Res>
    implements $TaskStatsDtoCopyWith<$Res> {
  _$TaskStatsDtoCopyWithImpl(this._self, this._then);

  final TaskStatsDto _self;
  final $Res Function(TaskStatsDto) _then;

/// Create a copy of TaskStatsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? done = null,Object? overdue = null,Object? highPriorityPending = null,}) {
  return _then(_self.copyWith(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as int,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as int,highPriorityPending: null == highPriorityPending ? _self.highPriorityPending : highPriorityPending // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskStatsDto].
extension TaskStatsDtoPatterns on TaskStatsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskStatsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskStatsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskStatsDto value)  $default,){
final _that = this;
switch (_that) {
case _TaskStatsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskStatsDto value)?  $default,){
final _that = this;
switch (_that) {
case _TaskStatsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int total,  int done,  int overdue,  int highPriorityPending)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskStatsDto() when $default != null:
return $default(_that.total,_that.done,_that.overdue,_that.highPriorityPending);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int total,  int done,  int overdue,  int highPriorityPending)  $default,) {final _that = this;
switch (_that) {
case _TaskStatsDto():
return $default(_that.total,_that.done,_that.overdue,_that.highPriorityPending);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int total,  int done,  int overdue,  int highPriorityPending)?  $default,) {final _that = this;
switch (_that) {
case _TaskStatsDto() when $default != null:
return $default(_that.total,_that.done,_that.overdue,_that.highPriorityPending);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskStatsDto implements TaskStatsDto {
  const _TaskStatsDto({required this.total, required this.done, required this.overdue, required this.highPriorityPending});
  factory _TaskStatsDto.fromJson(Map<String, dynamic> json) => _$TaskStatsDtoFromJson(json);

@override final  int total;
@override final  int done;
@override final  int overdue;
@override final  int highPriorityPending;

/// Create a copy of TaskStatsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskStatsDtoCopyWith<_TaskStatsDto> get copyWith => __$TaskStatsDtoCopyWithImpl<_TaskStatsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskStatsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskStatsDto&&(identical(other.total, total) || other.total == total)&&(identical(other.done, done) || other.done == done)&&(identical(other.overdue, overdue) || other.overdue == overdue)&&(identical(other.highPriorityPending, highPriorityPending) || other.highPriorityPending == highPriorityPending));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,done,overdue,highPriorityPending);

@override
String toString() {
  return 'TaskStatsDto(total: $total, done: $done, overdue: $overdue, highPriorityPending: $highPriorityPending)';
}


}

/// @nodoc
abstract mixin class _$TaskStatsDtoCopyWith<$Res> implements $TaskStatsDtoCopyWith<$Res> {
  factory _$TaskStatsDtoCopyWith(_TaskStatsDto value, $Res Function(_TaskStatsDto) _then) = __$TaskStatsDtoCopyWithImpl;
@override @useResult
$Res call({
 int total, int done, int overdue, int highPriorityPending
});




}
/// @nodoc
class __$TaskStatsDtoCopyWithImpl<$Res>
    implements _$TaskStatsDtoCopyWith<$Res> {
  __$TaskStatsDtoCopyWithImpl(this._self, this._then);

  final _TaskStatsDto _self;
  final $Res Function(_TaskStatsDto) _then;

/// Create a copy of TaskStatsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? done = null,Object? overdue = null,Object? highPriorityPending = null,}) {
  return _then(_TaskStatsDto(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as int,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as int,highPriorityPending: null == highPriorityPending ? _self.highPriorityPending : highPriorityPending // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
