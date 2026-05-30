import 'package:equatable/equatable.dart';

class EvaluationModel extends Equatable {
  final int id;
  final int supplierId;
  final int criterionId;
  final double actualValue;

  const EvaluationModel({
    required this.id,
    required this.supplierId,
    required this.criterionId,
    required this.actualValue,
  });

  factory EvaluationModel.fromJson(Map<String, dynamic> json) {
    return EvaluationModel(
      id: json['id'],
      supplierId: json['supplier_id'],
      criterionId: json['criterion_id'],
      actualValue: (json['actual_value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'criterion_id': criterionId,
      'actual_value': actualValue,
    };
  }

  @override
  List<Object?> get props => [id, supplierId, criterionId, actualValue];
}