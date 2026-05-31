import 'package:equatable/equatable.dart';
import 'decision_history_model.dart';

// ─── EDAS Matrix Models ───────────────────────────────────────────────────────

class EdasAvModel extends Equatable {
  final String criteriaCode;
  final double avValue;

  const EdasAvModel({required this.criteriaCode, required this.avValue});

  factory EdasAvModel.fromJson(Map<String, dynamic> json) {
    return EdasAvModel(
      criteriaCode: json['criteria_code'] ?? json['criteria']?['code'] ?? '',
      avValue: double.tryParse(json['av_value'].toString()) ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [criteriaCode, avValue];
}

class EdasMatrixRowModel extends Equatable {
  final int supplierId;
  final String supplierName;
  final String supplierCode;
  final Map<String, double> criteriaValues; // key: criteriaCode, value: score

  const EdasMatrixRowModel({
    required this.supplierId,
    required this.supplierName,
    required this.supplierCode,
    required this.criteriaValues,
  });

  @override
  List<Object?> get props => [supplierId, criteriaValues];
}

class EdasFinalRowModel extends Equatable {
  final int supplierId;
  final String supplierName;
  final String supplierCode;
  final double scoreSp;
  final double scoreSn;
  final double nsp;
  final double nss;
  final double appraisalScore;

  const EdasFinalRowModel({
    required this.supplierId,
    required this.supplierName,
    required this.supplierCode,
    required this.scoreSp,
    required this.scoreSn,
    required this.nsp,
    required this.nss,
    required this.appraisalScore,
  });

  @override
  List<Object?> get props => [supplierId, appraisalScore];
}

// ─── Main Detail Model ────────────────────────────────────────────────────────

class DecisionHistoryDetailModel extends Equatable {
  final int historyId;
  final String? calculatedAt;
  final List<RankingItemModel> rankings;

  // EDAS computation matrices (nullable — hanya ada jika API mengembalikannya)
  final List<String> criteriaHeaders;       // ['C1', 'C2', ...]
  final List<EdasAvModel> avMatrix;         // Tab 1: Solusi AV
  final List<EdasMatrixRowModel> pdaMatrix; // Tab 2: Matriks PDA
  final List<EdasMatrixRowModel> ndaMatrix; // Tab 3: Matriks NDA
  final List<EdasFinalRowModel> finalMatrix; // Tab 4: SP, SN & AS

  const DecisionHistoryDetailModel({
    required this.historyId,
    this.calculatedAt,
    required this.rankings,
    this.criteriaHeaders = const [],
    this.avMatrix = const [],
    this.pdaMatrix = const [],
    this.ndaMatrix = const [],
    this.finalMatrix = const [],
  });

  bool get hasEdasMatrices => avMatrix.isNotEmpty;

  factory DecisionHistoryDetailModel.fromRankings({
    required int historyId,
    String? calculatedAt,
    required List<dynamic> rawRankings,
  }) {
    final rankings = rawRankings
        .map((e) => RankingItemModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    return DecisionHistoryDetailModel(
      historyId: historyId,
      calculatedAt: calculatedAt,
      rankings: rankings,
    );
  }

  /// Factory untuk response lengkap yang mengandung EDAS matrices
  factory DecisionHistoryDetailModel.fromFullResponse({
    required int historyId,
    String? calculatedAt,
    required List<dynamic> rawRankings,
    Map<String, dynamic>? edasData,
  }) {
    final rankings = rawRankings
        .map((e) => RankingItemModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    if (edasData == null) {
      return DecisionHistoryDetailModel(
        historyId: historyId,
        calculatedAt: calculatedAt,
        rankings: rankings,
      );
    }

    // ── Parse AV ──────────────────────────────────────────────────────────────
    final List<EdasAvModel> avMatrix = [];
    final List<String> criteriaHeaders = [];
    final rawAv = edasData['av'] as List? ?? [];
    for (final e in rawAv) {
      final av = EdasAvModel.fromJson(e as Map<String, dynamic>);
      avMatrix.add(av);
      criteriaHeaders.add(av.criteriaCode);
    }

    // ── Parse PDA ─────────────────────────────────────────────────────────────
    final List<EdasMatrixRowModel> pdaMatrix =
        _parseMatrixRows(edasData['pda'], rankings, 'pda_value');

    // ── Parse NDA ─────────────────────────────────────────────────────────────
    final List<EdasMatrixRowModel> ndaMatrix =
        _parseMatrixRows(edasData['nda'], rankings, 'nda_value');

    // ── Parse Final (SP, SN, NSP, NSS, AS) ───────────────────────────────────
    final List<EdasFinalRowModel> finalMatrix = [];
    final rawFinal = edasData['final'] as List? ?? [];
    for (final e in rawFinal) {
      final item = e as Map<String, dynamic>;
      final supplier = item['supplier'] as Map<String, dynamic>? ?? {};
      finalMatrix.add(EdasFinalRowModel(
        supplierId: item['supplier_id'] ?? 0,
        supplierName: supplier['name'] ?? '',
        supplierCode: supplier['code'] ?? '',
        scoreSp: double.tryParse(item['score_sp'].toString()) ?? 0.0,
        scoreSn: double.tryParse(item['score_sn'].toString()) ?? 0.0,
        nsp: double.tryParse(item['nsp'].toString()) ?? 0.0,
        nss: double.tryParse(item['nss'].toString()) ?? 0.0,
        appraisalScore:
            double.tryParse(item['appraisal_score'].toString()) ?? 0.0,
      ));
    }
    finalMatrix.sort((a, b) => b.appraisalScore.compareTo(a.appraisalScore));

    return DecisionHistoryDetailModel(
      historyId: historyId,
      calculatedAt: calculatedAt,
      rankings: rankings,
      criteriaHeaders: criteriaHeaders,
      avMatrix: avMatrix,
      pdaMatrix: pdaMatrix,
      ndaMatrix: ndaMatrix,
      finalMatrix: finalMatrix,
    );
  }

  static List<EdasMatrixRowModel> _parseMatrixRows(
    dynamic rawData,
    List<RankingItemModel> rankings,
    String valueKey,
  ) {
    if (rawData == null) return [];
    final List raw = rawData as List;

    // Group by supplier_id
    final Map<int, Map<String, double>> grouped = {};
    final Map<int, Map<String, String>> supplierInfo = {};

    for (final e in raw) {
      final item = e as Map<String, dynamic>;
      final supplier = item['supplier'] as Map<String, dynamic>? ?? {};
      final supplierId = item['supplier_id'] as int? ?? 0;
      final criteriaCode =
          item['criteria_code'] ?? item['criteria']?['code'] ?? '';
      final value = double.tryParse(item[valueKey].toString()) ?? 0.0;

      grouped.putIfAbsent(supplierId, () => {})[criteriaCode] = value;
      supplierInfo.putIfAbsent(supplierId, () => {
            'name': supplier['name'] ?? '',
            'code': supplier['code'] ?? '',
          });
    }

    return grouped.entries.map((entry) {
      final info = supplierInfo[entry.key] ?? {};
      return EdasMatrixRowModel(
        supplierId: entry.key,
        supplierName: info['name'] ?? '',
        supplierCode: info['code'] ?? '',
        criteriaValues: entry.value,
      );
    }).toList()
      ..sort((a, b) => a.supplierCode.compareTo(b.supplierCode));
  }

  RankingItemModel? get topSupplier =>
      rankings.isNotEmpty ? rankings.first : null;

  @override
  List<Object?> get props => [historyId, calculatedAt, rankings];
}