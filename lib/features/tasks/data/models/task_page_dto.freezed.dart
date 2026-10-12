// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_page_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskPageDto {

 List<TaskDto> get items; int get page; int get pageSize; int get total;
/// Create a copy of TaskPageDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskPageDtoCopyWith<TaskPageDto> get copyWith => _$TaskPageDtoCopyWithImpl<TaskPageDto>(this as TaskPageDto, _$identity);

  /// Serializes this TaskPageDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskPageDto&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),page,pageSize,total);

@override
String toString() {
  return 'TaskPageDto(items: $items, page: $page, pageSize: $pageSize, total: $total)';
}


}

/// @nodoc
abstract mixin class $TaskPageDtoCopyWith<$Res>  {
  factory $TaskPageDtoCopyWith(TaskPageDto value, $Res Function(TaskPageDto) _then) = _$TaskPageDtoCopyWithImpl;
@useResult
$Res call({
 List<TaskDto> items, int page, int pageSize, int total
});




}
/// @nodoc
class _$TaskPageDtoCopyWithImpl<$Res>
    implements $TaskPageDtoCopyWith<$Res> {
  _$TaskPageDtoCopyWithImpl(this._self, this._then);

  final TaskPageDto _self;
  final $Res Function(TaskPageDto) _then;

/// Create a copy of TaskPageDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? page = null,Object? pageSize = null,Object? total = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<TaskDto>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskPageDto].
extension TaskPageDtoPatterns on TaskPageDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskPageDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskPageDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskPageDto value)  $default,){
final _that = this;
switch (_that) {
case _TaskPageDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskPageDto value)?  $default,){
final _that = this;
switch (_that) {
case _TaskPageDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TaskDto> items,  int page,  int pageSize,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskPageDto() when $default != null:
return $default(_that.items,_that.page,_that.pageSize,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TaskDto> items,  int page,  int pageSize,  int total)  $default,) {final _that = this;
switch (_that) {
case _TaskPageDto():
return $default(_that.items,_that.page,_that.pageSize,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TaskDto> items,  int page,  int pageSize,  int total)?  $default,) {final _that = this;
switch (_that) {
case _TaskPageDto() when $default != null:
return $default(_that.items,_that.page,_that.pageSize,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskPageDto implements TaskPageDto {
  const _TaskPageDto({required final  List<TaskDto> items, required this.page, required this.pageSize, required this.total}): _items = items;
  factory _TaskPageDto.fromJson(Map<String, dynamic> json) => _$TaskPageDtoFromJson(json);

 final  List<TaskDto> _items;
@override List<TaskDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int page;
@override final  int pageSize;
@override final  int total;

/// Create a copy of TaskPageDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskPageDtoCopyWith<_TaskPageDto> get copyWith => __$TaskPageDtoCopyWithImpl<_TaskPageDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskPageDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskPageDto&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),page,pageSize,total);

@override
String toString() {
  return 'TaskPageDto(items: $items, page: $page, pageSize: $pageSize, total: $total)';
}


}

/// @nodoc
abstract mixin class _$TaskPageDtoCopyWith<$Res> implements $TaskPageDtoCopyWith<$Res> {
  factory _$TaskPageDtoCopyWith(_TaskPageDto value, $Res Function(_TaskPageDto) _then) = __$TaskPageDtoCopyWithImpl;
@override @useResult
$Res call({
 List<TaskDto> items, int page, int pageSize, int total
});




}
/// @nodoc
class __$TaskPageDtoCopyWithImpl<$Res>
    implements _$TaskPageDtoCopyWith<$Res> {
  __$TaskPageDtoCopyWithImpl(this._self, this._then);

  final _TaskPageDto _self;
  final $Res Function(_TaskPageDto) _then;

/// Create a copy of TaskPageDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? page = null,Object? pageSize = null,Object? total = null,}) {
  return _then(_TaskPageDto(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<TaskDto>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
