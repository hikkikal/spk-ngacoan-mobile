import 'package:equatable/equatable.dart';

class EvaluationModel extends Equatable {
  final int id;
  final int supplierId;
  final String supplierCode;
  final String supplierName;
  final int criterionId;
  final String criterionCode;
  final String criterionName;
  final String criterionType; // 'benefit' | 'cost'
  final double normalizedWeight;
  final double actualValue;

  const EvaluationModel({
    required this.id,
    required this.supplierId,
    this.supplierCode = '',
    this.supplierName = '',
    required this.criterionId,
    this.criterionCode = '',
    this.criterionName = '',
    this.criterionType = 'benefit',
    this.normalizedWeight = 0.0,
    required this.actualValue,
  });

  factory EvaluationModel.fromJson(Map<String, dynamic> json) {
    final supplier = json['supplier'] as Map<String, dynamic>? ?? {};
    final criterion = json['criterion'] as Map<String, dynamic>? ?? {};
    return EvaluationModel(
      id: json['id'],
      supplierId: json['supplier_id'],
      supplierCode: supplier['code'] ?? '',
      supplierName: supplier['name'] ?? '',
      criterionId: json['criterion_id'],
      criterionCode: criterion['code'] ?? '',
      criterionName: criterion['name'] ?? '',
      criterionType: criterion['type'] ?? 'benefit',
      normalizedWeight:
          double.tryParse(criterion['normalized_weight'].toString()) ?? 0.0,
      actualValue: double.tryParse(json['actual_value'].toString()) ?? 0.0,
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

  bool get isBenefit => criterionType == 'benefit';

  @override
  List<Object?> get props => [id, supplierId, criterionId, actualValue];
}