import 'package:equatable/equatable.dart';
import '../../../../data/models/decision_history_model.dart';
import '../../../../data/models/decision_history_detail_model.dart';

abstract class DecisionHistoryState extends Equatable {
  const DecisionHistoryState();

  @override
  List<Object?> get props => [];
}

class DecisionHistoryInitial extends DecisionHistoryState {
  const DecisionHistoryInitial();
}

class DecisionHistoryLoading extends DecisionHistoryState {
  const DecisionHistoryLoading();
}

class DecisionHistoryLoaded extends DecisionHistoryState {
  final List<DecisionHistoryModel> histories;

  const DecisionHistoryLoaded({required this.histories});

  @override
  List<Object?> get props => [histories];
}

class DecisionHistoryEmpty extends DecisionHistoryState {
  const DecisionHistoryEmpty();
}

class DecisionHistoryError extends DecisionHistoryState {
  final String message;
  const DecisionHistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}

// State saat load detail audit (list tetap tampil, dialog loading)
class DecisionHistoryAuditLoading extends DecisionHistoryState {
  final List<DecisionHistoryModel> histories;
  final int loadingId;

  const DecisionHistoryAuditLoading({
    required this.histories,
    required this.loadingId,
  });

  @override
  List<Object?> get props => [histories, loadingId];
}

class DecisionHistoryAuditLoaded extends DecisionHistoryState {
  final List<DecisionHistoryModel> histories;
  final DecisionHistoryDetailModel detail;

  const DecisionHistoryAuditLoaded({
    required this.histories,
    required this.detail,
  });

  @override
  List<Object?> get props => [histories, detail];
}

class DecisionHistoryAuditError extends DecisionHistoryState {
  final List<DecisionHistoryModel> histories;
  final String message;

  const DecisionHistoryAuditError({
    required this.histories,
    required this.message,
  });

  @override
  List<Object?> get props => [histories, message];
}