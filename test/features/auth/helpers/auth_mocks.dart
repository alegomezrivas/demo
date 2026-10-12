import 'package:demo/core/security/screen_protection.dart';
import 'package:demo/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:demo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:demo/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:demo/features/auth/domain/usecases/login_use_case.dart';
import 'package:demo/features/auth/domain/usecases/logout_use_case.dart';
import 'package:demo/features/auth/domain/usecases/register_use_case.dart';
import 'package:mockito/annotations.dart';

export 'auth_mocks.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
  MockSpec<AuthRemoteDataSource>(),
  MockSpec<AuthLocalDataSource>(),
  MockSpec<LoginUseCase>(),
  MockSpec<RegisterUseCase>(),
  MockSpec<LogoutUseCase>(),
  MockSpec<GetCurrentUserUseCase>(),
  MockSpec<ScreenProtection>(),
])
void main() {}
