import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/supplier_repository.dart';
import 'data/repositories/criteria_repository.dart';
import 'data/repositories/evaluation_repository.dart';
import 'data/repositories/decision_history_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/dashboard/dashboard_bloc.dart';
import 'presentation/blocs/supplier/supplier_bloc.dart';
import 'presentation/blocs/decision_result/decision_result_bloc.dart';
import 'presentation/blocs/decision_history/decision_history_bloc.dart';
import 'package:go_router/go_router.dart';

class MyApp extends StatefulWidget {
  final AuthBloc authBloc;
  final AuthRepository authRepository;
  final SupplierRepository supplierRepository;
  final CriteriaRepository criteriaRepository;
  final EvaluationRepository evaluationRepository;
  final DecisionHistoryRepository decisionHistoryRepository;
  final DashboardRepository dashboardRepository;

  const MyApp({
    super.key,
    required this.authBloc,
    required this.authRepository,
    required this.supplierRepository,
    required this.criteriaRepository,
    required this.evaluationRepository,
    required this.decisionHistoryRepository,
    required this.dashboardRepository,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.router(widget.authBloc);
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.authRepository),
        RepositoryProvider.value(value: widget.supplierRepository),
        RepositoryProvider.value(value: widget.criteriaRepository),
        RepositoryProvider.value(value: widget.evaluationRepository),
        RepositoryProvider.value(value: widget.decisionHistoryRepository),
        RepositoryProvider.value(value: widget.dashboardRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: widget.authBloc),
          BlocProvider(
            create: (context) => DashboardBloc(
              dashboardRepository: context.read<DashboardRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => SupplierBloc(
              supplierRepository: context.read<SupplierRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => DecisionResultBloc(
              historyRepository: context.read<DecisionHistoryRepository>(),
              evaluationRepository: context.read<EvaluationRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => DecisionHistoryBloc(
              evaluationRepository: context.read<EvaluationRepository>(),
              historyRepository: context.read<DecisionHistoryRepository>(),
            ),
          ),
        ],
        child: MaterialApp.router(
          title: 'SPK Ngacoan',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: _router,
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.authBloc.close();
    super.dispose();
  }
}