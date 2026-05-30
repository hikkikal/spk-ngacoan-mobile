import 'package:equatable/equatable.dart';

class CriteriaModel extends Equatable {
  final int id;
  final String name;
  final String type;
  final double weightInput;
  final double? weightNormalized;

  const CriteriaModel({
    required this.id,
    required this.name,
    required this.type,
    required this.weightInput,
    this.weightNormalized,
  });

  factory CriteriaModel.fromJson(Map<String, dynamic> json) {
    return CriteriaModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      weightInput: (json['weight_input'] as num).toDouble(),
      weightNormalized: json['weight_normalized'] != null
          ? (json['weight_normalized'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'weight_input': weightInput,
      'weight_normalized': weightNormalized,
    };
  }

  @override
  List<Object?> get props => [id, name, type, weightInput, weightNormalized];
}