import '../models/evaluation_model.dart';
import '../models/decision_history_model.dart';
import '../models/decision_history_detail_model.dart';

/// Menghitung semua matriks EDAS dari data evaluations.
/// Tidak memerlukan perubahan backend sama sekali.
class EdasCalculator {
  static DecisionHistoryDetailModel calculate({
    required int historyId,
    String? calculatedAt,
    required List<EvaluationModel> evaluations,
  }) {
    if (evaluations.isEmpty) {
      return DecisionHistoryDetailModel(
        historyId: historyId,
        calculatedAt: calculatedAt,
        rankings: [],
      );
    }

    // ── 1. Kelompokkan data ───────────────────────────────────────────────────
    final Map<String, _CriterionMeta> criteriaMeta = {};
    final Map<int, Map<String, double>> matrix = {};
    final Map<int, _SupplierInfo> supplierInfo = {};

    for (final e in evaluations) {
      criteriaMeta[e.criterionCode] = _CriterionMeta(
        code: e.criterionCode,
        name: e.criterionName,
        isBenefit: e.isBenefit,
        weight: e.normalizedWeight,
      );
      matrix.putIfAbsent(e.supplierId, () => {})[e.criterionCode] =
          e.actualValue;
      supplierInfo[e.supplierId] = _SupplierInfo(
        id: e.supplierId,
        code: e.supplierCode,
        name: e.supplierName,
      );
    }

    final criteriaList = criteriaMeta.keys.toList()..sort();
    final supplierIds = matrix.keys.toList()..sort();
    final n = supplierIds.length;

    // ── 2. AV ─────────────────────────────────────────────────────────────────
    final Map<String, double> av = {};
    for (final c in criteriaList) {
      final sum = supplierIds.fold<double>(
          0, (acc, s) => acc + (matrix[s]?[c] ?? 0));
      av[c] = sum / n;
    }

    final List<EdasAvModel> avMatrix = criteriaList
        .map((c) => EdasAvModel(criteriaCode: c, avValue: av[c]!))
        .toList();

    // ── 3. PDA & NDA ─────────────────────────────────────────────────────────
    final Map<int, Map<String, double>> pdaMap = {};
    final Map<int, Map<String, double>> ndaMap = {};

    for (final sid in supplierIds) {
      pdaMap[sid] = {};
      ndaMap[sid] = {};
      for (final c in criteriaList) {
        final xi = matrix[sid]?[c] ?? 0.0;
        final avC = av[c]!;
        final meta = criteriaMeta[c]!;

        if (meta.isBenefit) {
          pdaMap[sid]![c] = avC == 0 ? 0 : _max0((xi - avC) / avC);
          ndaMap[sid]![c] = avC == 0 ? 0 : _max0((avC - xi) / avC);
        } else {
          pdaMap[sid]![c] = avC == 0 ? 0 : _max0((avC - xi) / avC);
          ndaMap[sid]![c] = avC == 0 ? 0 : _max0((xi - avC) / avC);
        }
      }
    }

    final List<EdasMatrixRowModel> pdaMatrix = supplierIds.map((sid) {
      final info = supplierInfo[sid]!;
      return EdasMatrixRowModel(
        supplierId: sid,
        supplierCode: info.code,
        supplierName: info.name,
        criteriaValues: Map<String, double>.from(pdaMap[sid]!),
      );
    }).toList();

    final List<EdasMatrixRowModel> ndaMatrix = supplierIds.map((sid) {
      final info = supplierInfo[sid]!;
      return EdasMatrixRowModel(
        supplierId: sid,
        supplierCode: info.code,
        supplierName: info.name,
        criteriaValues: Map<String, double>.from(ndaMap[sid]!),
      );
    }).toList();

    // ── 4. SP & SN ────────────────────────────────────────────────────────────
    final Map<int, double> sp = {};
    final Map<int, double> sn = {};
    for (final sid in supplierIds) {
      sp[sid] = criteriaList.fold<double>(
        0,
        (acc, c) => acc + (criteriaMeta[c]!.weight * (pdaMap[sid]?[c] ?? 0)),
      );
      sn[sid] = criteriaList.fold<double>(
        0,
        (acc, c) => acc + (criteriaMeta[c]!.weight * (ndaMap[sid]?[c] ?? 0)),
      );
    }

    // ── 5. NSP, NSS & AS ─────────────────────────────────────────────────────
    final maxSp = sp.values.reduce((a, b) => a > b ? a : b);
    final maxSn = sn.values.reduce((a, b) => a > b ? a : b);

    final List<EdasFinalRowModel> finalMatrix = [];

    for (final sid in supplierIds) {
      final info = supplierInfo[sid]!;
      final nsp = maxSp == 0 ? 0.0 : sp[sid]! / maxSp;
      final nss = maxSn == 0 ? 0.0 : 1.0 - sn[sid]! / maxSn;
      final asScore = 0.5 * (nsp + nss);

      finalMatrix.add(EdasFinalRowModel(
        supplierId: sid,
        supplierCode: info.code,
        supplierName: info.name,
        scoreSp: sp[sid]!,
        scoreSn: sn[sid]!,
        nsp: nsp,
        nss: nss,
        appraisalScore: asScore,
      ));
    }

    finalMatrix.sort((a, b) => b.appraisalScore.compareTo(a.appraisalScore));

    // ── 6. Build RankingItemModel ─────────────────────────────────────────────
    final List<RankingItemModel> rankings = [];
    for (int i = 0; i < finalMatrix.length; i++) {
      final f = finalMatrix[i];
      rankings.add(RankingItemModel(
        rank: i + 1,
        appraisalScore: f.appraisalScore,
        supplierId: f.supplierId,
        supplierName: f.supplierName,
        supplierCode: f.supplierCode,
      ));
    }

    return DecisionHistoryDetailModel(
      historyId: historyId,
      calculatedAt: calculatedAt,
      rankings: rankings,
      criteriaHeaders: criteriaList,
      avMatrix: avMatrix,
      pdaMatrix: pdaMatrix,
      ndaMatrix: ndaMatrix,
      finalMatrix: finalMatrix,
    );
  }

  static double _max0(double v) => v < 0 ? 0 : v;
}

class _CriterionMeta {
  final String code;
  final String name;
  final bool isBenefit;
  final double weight;
  const _CriterionMeta({
    required this.code,
    required this.name,
    required this.isBenefit,
    required this.weight,
  });
}

class _SupplierInfo {
  final int id;
  final String code;
  final String name;
  const _SupplierInfo(
      {required this.id, required this.code, required this.name});
}