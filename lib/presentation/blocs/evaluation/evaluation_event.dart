import 'package:equatable/equatable.dart';

abstract class EvaluationEvent extends Equatable {
  const EvaluationEvent();

  @override
  List<Object?> get props => [];
}

class EvaluationLoadRequested extends EvaluationEvent {
  const EvaluationLoadRequested();
}

class EvaluationBulkSaveRequested extends EvaluationEvent {
  final List<Map<String, dynamic>> evaluations;

  const EvaluationBulkSaveRequested({required this.evaluations});

  @override
  List<Object?> get props => [evaluations];
}