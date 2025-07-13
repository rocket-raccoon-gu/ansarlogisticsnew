import 'package:get_it/get_it.dart';
import 'package:api_gateway/api_gateway.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:dio/dio.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/usecases/login_cases.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/register_cases.dart';
import '../../features/auth/presentation/cubit/register_cubit.dart';
import '../../features/auth/presentation/cubit/info_data_cubit.dart';
import '../services/firebase_service.dart';
import '../services/firebase_auth_service.dart';

final getIt = GetIt.instance;

void setupDependencyInjection() {
  // Core network
  getIt.registerLazySingleton(() => Dio());

  // API Gateway
  getIt.registerLazySingleton(() => HttpClient());
  getIt.registerLazySingleton(() => WebSocketClient());
  getIt.registerLazySingleton(() => ApiService(getIt<HttpClient>()));
  getIt.registerLazySingleton(
    () => ApiGateway(
      httpClient: getIt<HttpClient>(),
      webSocketClient: getIt<WebSocketClient>(),
      apiService: getIt<ApiService>(),
    ),
  );

  // Firebase Services
  getIt.registerLazySingleton(() => FirebaseAuthService());

  // Auth
  getIt.registerLazySingleton(
    () => AuthRemoteDatasource(apiGateway: getIt<ApiGateway>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () =>
        AuthRepositoryImpl(authRemoteDatasource: getIt<AuthRemoteDatasource>()),
  );
  getIt.registerLazySingleton(
    () => LoginCases(authRepository: getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton(
    () => RegisterCases(authRepository: getIt<AuthRepository>()),
  );

  // Cubit
  getIt.registerFactory(() => AuthCubit(loginCases: getIt<LoginCases>()));
  getIt.registerFactory(
    () => RegisterCubit(registerCases: getIt<RegisterCases>()),
  );
  getIt.registerFactory(
    () => InfoDataCubit(authRepository: getIt<AuthRepository>()),
  );
}
