import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardStatsRequested extends DashboardEvent {
  const DashboardStatsRequested();
}

class DashboardStatsRefreshed extends DashboardEvent {
  const DashboardStatsRefreshed();
}