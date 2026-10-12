import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/network/dio_exception_mapper.dart';
import 'package:demo/features/tasks/data/datasources/tasks_endpoints.dart';
import 'package:demo/features/tasks/data/models/task_dto.dart';
import 'package:demo/features/tasks/data/models/task_input_dto.dart';
import 'package:demo/features/tasks/data/models/task_page_dto.dart';
import 'package:demo/features/tasks/data/models/task_stats_dto.dart';
import 'package:demo/features/tasks/domain/entities/task_query.dart';
import 'package:dio/dio.dart';

/// Remote access to the tasks API; throws [AppException]s only.
abstract interface class TasksRemoteDataSource {
  /// Fetches one page matching [query].
  Future<TaskPageDto> getTasks(TaskQuery query);

  /// Fetches one task.
  Future<TaskDto> getTask(String id);

  /// Creates a task.
  Future<TaskDto> createTask(TaskInputDto input);

  /// Replaces a task.
  Future<TaskDto> updateTask(String id, TaskInputDto input);

  /// Deletes a task.
  Future<void> deleteTask(String id);

  /// Fetches the aggregated statistics.
  Future<TaskStatsDto> getStats();
}

/// [TasksRemoteDataSource] backed by Dio.
class TasksRemoteDataSourceImpl implements TasksRemoteDataSource {
  /// Creates the data source.
  const TasksRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<TaskPageDto> getTasks(TaskQuery query) async {
    final data = await _send(
      'GET',
      TasksEndpoints.tasks,
      queryParameters: {
        'page': query.page,
        'pageSize': query.pageSize,
        if (query.search.isNotEmpty) 'q': query.search,
        if (query.status != TaskStatusFilter.all) 'status': query.status.name,
        if (query.priority != null) 'priority': query.priority!.name,
      },
    );
    return _parse<TaskPageDto>(data, TaskPageDto.fromJson);
  }

  @override
  Future<TaskDto> getTask(String id) async {
    final data = await _send('GET', TasksEndpoints.task(id));
    return _parse<TaskDto>(data, TaskDto.fromJson);
  }

  @override
  Future<TaskDto> createTask(TaskInputDto input) async {
    final data = await _send(
      'POST',
      TasksEndpoints.tasks,
      body: input.toJson(),
    );
    return _parse<TaskDto>(data, TaskDto.fromJson);
  }

  @override
  Future<TaskDto> updateTask(String id, TaskInputDto input) async {
    final data = await _send(
      'PUT',
      TasksEndpoints.task(id),
      body: input.toJson(),
    );
    return _parse<TaskDto>(data, TaskDto.fromJson);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _send('DELETE', TasksEndpoints.task(id));
  }

  @override
  Future<TaskStatsDto> getStats() async {
    final data = await _send('GET', TasksEndpoints.stats);
    return _parse<TaskStatsDto>(data, TaskStatsDto.fromJson);
  }

  Future<Map<String, dynamic>?> _send(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        path,
        data: body,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
      return response.data;
    } on DioException catch (error) {
      throw DioExceptionMapper.map(error);
    }
  }

  T _parse<T>(
    Map<String, dynamic>? data,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (data == null) throw const ServerException(code: 'empty_response');
    try {
      return fromJson(data);
    } on FormatException {
      throw const ServerException(code: 'invalid_response');
      // ignore: avoid_catching_errors, generated fromJson throws TypeError on bad data
    } on TypeError {
      throw const ServerException(code: 'invalid_response');
    }
  }
}
