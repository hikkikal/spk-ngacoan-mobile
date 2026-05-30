import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _dashboardRepository;

  DashboardBloc({required DashboardRepository dashboardRepository})
      : _dashboardRepository = dashboardRepository,
        super(const DashboardInitial()) {
    on<DashboardStatsRequested>(_onStatsRequested);
    on<DashboardStatsRefreshed>(_onStatsRefreshed);
  }

  Future<void> _onStatsRequested(
    DashboardStatsRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    await _fetchStats(emit);
  }

  Future<void> _onStatsRefreshed(
    DashboardStatsRefreshed event,
    Emitter<DashboardState> emit,
  ) async {
    // Refresh tanpa loading state — biar tidak flicker
    await _fetchStats(emit);
  }

  Future<void> _fetchStats(Emitter<DashboardState> emit) async {
    try {
      final stats = await _dashboardRepository.getDashboardStats();
      emit(DashboardLoaded(stats: stats));
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }
}