import 'package:equatable/equatable.dart';
import '../../../data/models/supplier_model.dart';
import '../../../data/models/criteria_model.dart';
import '../../../data/models/evaluation_model.dart';

abstract class EvaluationState extends Equatable {
  const EvaluationState();

  @override
  List<Object?> get props => [];
}

class EvaluationInitial extends EvaluationState {}

class EvaluationLoading extends EvaluationState {}

class EvaluationLoaded extends EvaluationState {
  final List<SupplierModel> suppliers;
  final List<CriteriaModel> criterias;
  final List<EvaluationModel> evaluations;

  const EvaluationLoaded({
    required this.suppliers,
    required this.criterias,
    required this.evaluations,
  });

  @override
  List<Object?> get props => [suppliers, criterias, evaluations];
}

class EvaluationSaving extends EvaluationState {
  final List<SupplierModel> suppliers;
  final List<CriteriaModel> criterias;
  final List<EvaluationModel> evaluations;

  const EvaluationSaving({
    required this.suppliers,
    required this.criterias,
    required this.evaluations,
  });

  @override
  List<Object?> get props => [suppliers, criterias, evaluations];
}

class EvaluationSaveSuccess extends EvaluationState {
  final List<SupplierModel> suppliers;
  final List<CriteriaModel> criterias;
  final List<EvaluationModel> evaluations;

  const EvaluationSaveSuccess({
    required this.suppliers,
    required this.criterias,
    required this.evaluations,
  });

  @override
  List<Object?> get props => [suppliers, criterias, evaluations];
}

class EvaluationError extends EvaluationState {
  final String message;

  const EvaluationError(this.message);

  @override
  List<Object?> get props => [message];
}

class EvaluationSaveError extends EvaluationState {
  final List<SupplierModel> suppliers;
  final List<CriteriaModel> criterias;
  final List<EvaluationModel> evaluations;
  final String message;

  const EvaluationSaveError({
    required this.suppliers,
    required this.criterias,
    required this.evaluations,
    required this.message,
  });

  @override
  List<Object?> get props => [suppliers, criterias, evaluations, message];
}