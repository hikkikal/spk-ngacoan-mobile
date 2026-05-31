import 'package:equatable/equatable.dart';
import '../../../../data/models/decision_history_detail_model.dart';

abstract class DecisionResultState extends Equatable {
  const DecisionResultState();

  @override
  List<Object?> get props => [];
}

class DecisionResultInitial extends DecisionResultState {
  const DecisionResultInitial();
}

class DecisionResultLoading extends DecisionResultState {
  const DecisionResultLoading();
}

class DecisionResultLoaded extends DecisionResultState {
  final DecisionHistoryDetailModel detail;

  const DecisionResultLoaded({required this.detail});

  @override
  List<Object?> get props => [detail];
}

class DecisionResultEmpty extends DecisionResultState {
  const DecisionResultEmpty();
}

class DecisionResultError extends DecisionResultState {
  final String message;
  const DecisionResultError({required this.message});

  @override
  List<Object?> get props => [message];
}

class DecisionResultHitungLoading extends DecisionResultState {
  final DecisionHistoryDetailModel? previousDetail;
  const DecisionResultHitungLoading({this.previousDetail});

  @override
  List<Object?> get props => [previousDetail];
}