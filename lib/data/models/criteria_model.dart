import 'package:equatable/equatable.dart';

class CriteriaModel extends Equatable {
  final int id;
  final String code;
  final String name;
  final String type;
  final double weightInput;
  final double? normalizedWeight;

  const CriteriaModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.weightInput,
    this.normalizedWeight,
  });

  factory CriteriaModel.fromJson(Map<String, dynamic> json) {
    return CriteriaModel(
      id: json['id'],
      code: json['code'] ?? '',
      name: json['name'],
      type: json['type'],
      weightInput: (json['weight_input'] as num).toDouble(),
      normalizedWeight: json['normalized_weight'] != null
          ? (json['normalized_weight'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'type': type,
      'weight_input': weightInput,
      'normalized_weight': normalizedWeight,
    };
  }

  @override
  List<Object?> get props => [id, code, name, type, weightInput, normalizedWeight];
}