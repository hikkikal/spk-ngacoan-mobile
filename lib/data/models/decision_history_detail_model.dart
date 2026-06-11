import 'package:equatable/equatable.dart';
import 'decision_history_model.dart';
import 'criteria_model.dart';

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

  final List<String> criteriaHeaders;
  final List<EdasAvModel> avMatrix;
  final List<EdasMatrixRowModel> pdaMatrix;
  final List<EdasMatrixRowModel> ndaMatrix;
  final List<EdasFinalRowModel> finalMatrix;

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

  // ── Factory: dari response /calculate-edas ─────────────────────────────────
  //
  // Format response:
  //   data.rankings[]  → rank, supplier_id, supplier{code,name}, appraisal_score
  //   data.calculation_steps:
  //     average_solutions  : { "criteriaId": value }
  //     pda_matrix         : { "supplierId": { "criteriaId": value } }
  //     nda_matrix         : { "supplierId": { "criteriaId": value } }
  //     sp_scores          : { "supplierId": value }
  //     sn_scores          : { "supplierId": value }
  //     nsp_scores         : { "supplierId": value }
  //     nss_scores         : { "supplierId": value }
  //     as_scores          : { "supplierId": value }
  //
  // criteriaList dioper dari luar (hasil GET /criteria) agar label
  // kolom menggunakan kode kriteria yang sebenarnya (C1, C2, …) bukan ID.
  factory DecisionHistoryDetailModel.fromCalculateEdas({
    required int historyId,
    String? calculatedAt,
    required Map<String, dynamic> responseData,
    required List<CriteriaModel> criteriaList,
  }) {
    // ── Peta ID → kode kriteria ──────────────────────────────────────────────
    final Map<String, String> criteriaCodeById = {
      for (final c in criteriaList) c.id.toString(): c.code,
    };

    // ── Rankings ─────────────────────────────────────────────────────────────
    final List rawRankings = responseData['rankings'] as List? ?? [];
    final rankings = rawRankings
        .map((e) => RankingItemModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    final steps = responseData['calculation_steps'] as Map<String, dynamic>?;
    if (steps == null) {
      return DecisionHistoryDetailModel(
        historyId: historyId,
        calculatedAt: calculatedAt,
        rankings: rankings,
      );
    }

    // ── Ordered criteria headers (pakai urutan dari average_solutions) ───────
    final avRaw = steps['average_solutions'] as Map<String, dynamic>? ?? {};
    final List<String> criteriaHeaders = avRaw.keys
        .map((id) => criteriaCodeById[id] ?? 'C$id')
        .toList();

    // ── AV Matrix ─────────────────────────────────────────────────────────────
    final List<EdasAvModel> avMatrix = avRaw.entries.map((e) {
      return EdasAvModel(
        criteriaCode: criteriaCodeById[e.key] ?? 'C${e.key}',
        avValue: double.tryParse(e.value.toString()) ?? 0.0,
      );
    }).toList();

    // ── Supplier info dari rankings ──────────────────────────────────────────
    final Map<String, String> supplierNameById = {};
    final Map<String, String> supplierCodeById = {};
    for (final r in rankings) {
      supplierNameById[r.supplierId.toString()] = r.supplierName;
      supplierCodeById[r.supplierId.toString()] = r.supplierCode;
    }

    // ── Helper: parse { "supplierId": { "criteriaId": value } } ─────────────
    List<EdasMatrixRowModel> parseMatrixRows(Map<String, dynamic> raw) {
      return raw.entries.map((supplierEntry) {
        final sid = supplierEntry.key;
        final criteriaMap = supplierEntry.value as Map<String, dynamic>;
        final Map<String, double> values = {};
        for (final ce in criteriaMap.entries) {
          final code = criteriaCodeById[ce.key] ?? 'C${ce.key}';
          values[code] = double.tryParse(ce.value.toString()) ?? 0.0;
        }
        return EdasMatrixRowModel(
          supplierId: int.tryParse(sid) ?? 0,
          supplierName: supplierNameById[sid] ?? '',
          supplierCode: supplierCodeById[sid] ?? '',
          criteriaValues: values,
        );
      }).toList()
        ..sort((a, b) => a.supplierCode.compareTo(b.supplierCode));
    }

    final pdaMatrix = parseMatrixRows(
        steps['pda_matrix'] as Map<String, dynamic>? ?? {});
    final ndaMatrix = parseMatrixRows(
        steps['nda_matrix'] as Map<String, dynamic>? ?? {});

    // ── Final matrix (SP, SN, NSP, NSS, AS) ──────────────────────────────────
    final spRaw  = steps['sp_scores']  as Map<String, dynamic>? ?? {};
    final snRaw  = steps['sn_scores']  as Map<String, dynamic>? ?? {};
    final nspRaw = steps['nsp_scores'] as Map<String, dynamic>? ?? {};
    final nssRaw = steps['nss_scores'] as Map<String, dynamic>? ?? {};
    final asRaw  = steps['as_scores']  as Map<String, dynamic>? ?? {};

    final List<EdasFinalRowModel> finalMatrix = spRaw.keys.map((sid) {
      return EdasFinalRowModel(
        supplierId: int.tryParse(sid) ?? 0,
        supplierName: supplierNameById[sid] ?? '',
        supplierCode: supplierCodeById[sid] ?? '',
        scoreSp: double.tryParse(spRaw[sid].toString()) ?? 0.0,
        scoreSn: double.tryParse(snRaw[sid]?.toString() ?? '0') ?? 0.0,
        nsp: double.tryParse(nspRaw[sid]?.toString() ?? '0') ?? 0.0,
        nss: double.tryParse(nssRaw[sid]?.toString() ?? '0') ?? 0.0,
        appraisalScore: double.tryParse(asRaw[sid]?.toString() ?? '0') ?? 0.0,
      );
    }).toList()
      ..sort((a, b) => b.appraisalScore.compareTo(a.appraisalScore));

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

  // ── Factory: dari response GET /decision-histories/{id} ──────────────────
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

    final List<EdasAvModel> avMatrix = [];
    final List<String> criteriaHeaders = [];
    final rawAv = edasData['av'] as List? ?? [];
    for (final e in rawAv) {
      final av = EdasAvModel.fromJson(e as Map<String, dynamic>);
      avMatrix.add(av);
      criteriaHeaders.add(av.criteriaCode);
    }

    final List<EdasMatrixRowModel> pdaMatrix =
        _parseMatrixRows(edasData['pda'], rankings, 'pda_value');
    final List<EdasMatrixRowModel> ndaMatrix =
        _parseMatrixRows(edasData['nda'], rankings, 'nda_value');

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