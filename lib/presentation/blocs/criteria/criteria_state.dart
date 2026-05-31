import 'package:equatable/equatable.dart';
import '../../../data/models/criteria_model.dart';

abstract class CriteriaState extends Equatable {
  const CriteriaState();

  @override
  List<Object?> get props => [];
}

class CriteriaInitial extends CriteriaState {}

class CriteriaLoading extends CriteriaState {}

class CriteriaLoaded extends CriteriaState {
  final List<CriteriaModel> criterias;

  const CriteriaLoaded(this.criterias);

  @override
  List<Object?> get props => [criterias];
}

class CriteriaActionLoading extends CriteriaState {
  final List<CriteriaModel> criterias;

  const CriteriaActionLoading(this.criterias);

  @override
  List<Object?> get props => [criterias];
}

class CriteriaActionSuccess extends CriteriaState {
  final List<CriteriaModel> criterias;
  final String message;

  const CriteriaActionSuccess(this.criterias, this.message);

  @override
  List<Object?> get props => [criterias, message];
}

class CriteriaActionError extends CriteriaState {
  final List<CriteriaModel> criterias;
  final String message;

  const CriteriaActionError(this.criterias, this.message);

  @override
  List<Object?> get props => [criterias, message];
}

class CriteriaError extends CriteriaState {
  final String message;

  const CriteriaError(this.message);

  @override
  List<Object?> get props => [message];
}