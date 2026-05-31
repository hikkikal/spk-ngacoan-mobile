import 'package:equatable/equatable.dart';

class DashboardStatsModel extends Equatable {
  final int totalCriteria;
  final int totalSuppliers;
  final String? topSupplier;
  final String systemStatus;

  const DashboardStatsModel({
    required this.totalCriteria,
    required this.totalSuppliers,
    this.topSupplier,
    required this.systemStatus,
  });

  // Helper: cek apakah sistem optimal
  bool get matrixReady => systemStatus.toLowerCase() == 'optimal';

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalCriteria: json['total_criteria'] ?? 0,
      totalSuppliers: json['total_suppliers'] ?? 0,
      topSupplier: json['top_supplier'],
      systemStatus: json['system_status'] ?? '-',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_criteria': totalCriteria,
      'total_suppliers': totalSuppliers,
      'top_supplier': topSupplier,
      'system_status': systemStatus,
    };
  }

  @override
  List<Object?> get props => [totalCriteria, totalSuppliers, topSupplier, systemStatus];
}