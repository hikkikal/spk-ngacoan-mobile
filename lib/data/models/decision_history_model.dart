import 'package:equatable/equatable.dart';

class RankingItemModel extends Equatable {
  final int rank;
  final double appraisalScore;
  final int supplierId;
  final String supplierName;
  final String supplierCode;

  const RankingItemModel({
    required this.rank,
    required this.appraisalScore,
    required this.supplierId,
    required this.supplierName,
    required this.supplierCode,
  });

  factory RankingItemModel.fromJson(Map<String, dynamic> json) {
    final supplier = json['supplier'] as Map<String, dynamic>? ?? {};
    return RankingItemModel(
      rank: json['rank'] ?? 0,
      appraisalScore:
          double.tryParse(json['appraisal_score'].toString()) ?? 0.0,
      supplierId: json['supplier_id'] ?? 0,
      supplierName: supplier['name'] ?? '',
      supplierCode: supplier['code'] ?? '',
    );
  }

  @override
  List<Object?> get props => [rank, supplierId, appraisalScore];
}

class DecisionHistoryModel extends Equatable {
  final int id;
  final String? calculatedAt;
  final List<RankingItemModel> rankings;

  const DecisionHistoryModel({
    required this.id,
    this.calculatedAt,
    required this.rankings,
  });

  factory DecisionHistoryModel.fromJson(Map<String, dynamic> json) {
    final List rawRankings = json['rankings'] ?? [];
    final rankings = rawRankings
        .map((e) => RankingItemModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    return DecisionHistoryModel(
      id: json['id'],
      calculatedAt: json['calculated_at'],
      rankings: rankings,
    );
  }

  RankingItemModel? get topRanking =>
      rankings.isNotEmpty ? rankings.first : null;

  @override
  List<Object?> get props => [id, calculatedAt, rankings];
}