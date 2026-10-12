import 'package:demo/features/tasks/data/datasources/tasks_remote_data_source.dart';
import 'package:demo/features/tasks/domain/repositories/task_repository.dart';
import 'package:demo/features/tasks/domain/usecases/create_task_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/delete_task_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/get_task_stats_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/get_task_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/get_tasks_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/update_task_use_case.dart';
import 'package:mockito/annotations.dart';

export 'tasks_mocks.mocks.dart';

@GenerateNiceMocks([
  MockSpec<TaskRepository>(),
  MockSpec<TasksRemoteDataSource>(),
  MockSpec<GetTasksUseCase>(),
  MockSpec<GetTaskUseCase>(),
  MockSpec<CreateTaskUseCase>(),
  MockSpec<UpdateTaskUseCase>(),
  MockSpec<DeleteTaskUseCase>(),
  MockSpec<GetTaskStatsUseCase>(),
])
void main() {}
