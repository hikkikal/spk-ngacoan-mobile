import 'package:flutter/material.dart';
import 'core/network/dio_client.dart';
import 'core/services/secure_storage_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/supplier_repository.dart';
import 'data/repositories/criteria_repository.dart';
import 'data/repositories/evaluation_repository.dart';
import 'data/repositories/decision_history_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/user_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init services
  final secureStorage = SecureStorageService();
  final dioClient = DioClient();

  // Init repositories
  final authRepository = AuthRepository(
    dioClient: dioClient,
    secureStorage: secureStorage,
  );
  final supplierRepository = SupplierRepository(dioClient: dioClient);
  final criteriaRepository = CriteriaRepository(dioClient: dioClient);
  final evaluationRepository = EvaluationRepository(dioClient: dioClient);
  final decisionHistoryRepository = DecisionHistoryRepository(dioClient: dioClient);
  final dashboardRepository = DashboardRepository(dioClient: dioClient);
  final userRepository = UserRepository(dioClient: dioClient);

  // Init auth bloc
  final authBloc = AuthBloc(authRepository: authRepository)
    ..add(AuthCheckRequested());

  runApp(
    MyApp(
      authBloc: authBloc,
      authRepository: authRepository,
      supplierRepository: supplierRepository,
      criteriaRepository: criteriaRepository,
      evaluationRepository: evaluationRepository,
      decisionHistoryRepository: decisionHistoryRepository,
      dashboardRepository: dashboardRepository,
      userRepository: userRepository,
    ),
  );
}