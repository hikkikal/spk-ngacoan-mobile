import 'package:equatable/equatable.dart';

class DashboardStatsModel extends Equatable {
  final int totalCriteria;
  final int totalSuppliers;
  final String? topSupplier;
  final bool matrixReady;

  const DashboardStatsModel({
    required this.totalCriteria,
    required this.totalSuppliers,
    this.topSupplier,
    required this.matrixReady,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalCriteria: json['total_criteria'] ?? 0,
      totalSuppliers: json['total_suppliers'] ?? 0,
      topSupplier: json['top_supplier'],
      matrixReady: json['matrix_ready'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_criteria': totalCriteria,
      'total_suppliers': totalSuppliers,
      'top_supplier': topSupplier,
      'matrix_ready': matrixReady,
    };
  }

  @override
  List<Object?> get props => [totalCriteria, totalSuppliers, topSupplier, matrixReady];
}