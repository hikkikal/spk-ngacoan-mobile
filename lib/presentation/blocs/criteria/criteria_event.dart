import 'package:equatable/equatable.dart';

abstract class CriteriaEvent extends Equatable {
  const CriteriaEvent();

  @override
  List<Object?> get props => [];
}

class CriteriaLoadRequested extends CriteriaEvent {
  const CriteriaLoadRequested();
}

class CriteriaAddRequested extends CriteriaEvent {
  final String name;
  final String type;
  final int weightInput;

  const CriteriaAddRequested({
    required this.name,
    required this.type,
    required this.weightInput,
  });

  @override
  List<Object?> get props => [name, type, weightInput];
}

class CriteriaUpdateRequested extends CriteriaEvent {
  final int id;
  final String name;
  final String type;
  final int weightInput;

  const CriteriaUpdateRequested({
    required this.id,
    required this.name,
    required this.type,
    required this.weightInput,
  });

  @override
  List<Object?> get props => [id, name, type, weightInput];
}

class CriteriaDeleteRequested extends CriteriaEvent {
  final int id;

  const CriteriaDeleteRequested({required this.id});

  @override
  List<Object?> get props => [id];
}