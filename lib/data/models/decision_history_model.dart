import 'package:equatable/equatable.dart';

class DecisionHistoryModel extends Equatable {
  final int id;
  final String? calculatedAt;
  final List<dynamic>? results;

  const DecisionHistoryModel({
    required this.id,
    this.calculatedAt,
    this.results,
  });

  factory DecisionHistoryModel.fromJson(Map<String, dynamic> json) {
    return DecisionHistoryModel(
      id: json['id'],
      calculatedAt: json['calculated_at'],
      results: json['results'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'calculated_at': calculatedAt,
      'results': results,
    };
  }

  @override
  List<Object?> get props => [id, calculatedAt, results];
}