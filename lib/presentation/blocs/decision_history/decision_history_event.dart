import 'package:equatable/equatable.dart';

abstract class DecisionHistoryEvent extends Equatable {
  const DecisionHistoryEvent();

  @override
  List<Object?> get props => [];
}

class DecisionHistoryLoadRequested extends DecisionHistoryEvent {
  const DecisionHistoryLoadRequested();
}

class DecisionHistoryAuditRequested extends DecisionHistoryEvent {
  final int id;
  const DecisionHistoryAuditRequested({required this.id});

  @override
  List<Object?> get props => [id];
}