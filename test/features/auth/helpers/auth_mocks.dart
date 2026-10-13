import 'package:demo/core/security/screen_protection.dart';
import 'package:demo/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:demo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:demo/features/auth/data/datasources/avatar_remote_data_source.dart';
import 'package:demo/features/auth/data/datasources/sign_up_remote_data_source.dart';
import 'package:demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:demo/features/auth/domain/repositories/avatar_repository.dart';
import 'package:demo/features/auth/domain/repositories/sign_up_repository.dart';
import 'package:demo/features/auth/domain/usecases/check_username_availability_use_case.dart';
import 'package:demo/features/auth/domain/usecases/complete_sign_up_use_case.dart';
import 'package:demo/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:demo/features/auth/domain/usecases/login_use_case.dart';
import 'package:demo/features/auth/domain/usecases/logout_use_case.dart';
import 'package:demo/features/auth/domain/usecases/send_confirmation_code_use_case.dart';
import 'package:demo/features/auth/domain/usecases/upload_avatar_use_case.dart';
import 'package:demo/features/auth/domain/usecases/verify_confirmation_code_use_case.dart';
import 'package:mockito/annotations.dart';

export 'auth_mocks.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
  MockSpec<AuthRemoteDataSource>(),
  MockSpec<SignUpRemoteDataSource>(),
  MockSpec<AvatarRemoteDataSource>(),
  MockSpec<SignUpRepository>(),
  MockSpec<AvatarRepository>(),
  MockSpec<AuthLocalDataSource>(),
  MockSpec<LoginUseCase>(),
  MockSpec<SendConfirmationCodeUseCase>(),
  MockSpec<VerifyConfirmationCodeUseCase>(),
  MockSpec<CheckUsernameAvailabilityUseCase>(),
  MockSpec<CompleteSignUpUseCase>(),
  MockSpec<UploadAvatarUseCase>(),
  MockSpec<LogoutUseCase>(),
  MockSpec<GetCurrentUserUseCase>(),
  MockSpec<ScreenProtection>(),
])
void main() {}
