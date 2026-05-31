import '../models/decision_history_model.dart';
import '../models/decision_history_detail_model.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class DecisionHistoryRepository {
  final DioClient _dioClient;

  DecisionHistoryRepository({required DioClient dioClient})
      : _dioClient = dioClient;

  Future<List<DecisionHistoryModel>> getDecisionHistories() async {
    final response = await _dioClient.dio.get(ApiConstants.decisionHistories);
    final List data = response.data['data'];
    return data.map((e) => DecisionHistoryModel.fromJson(e)).toList();
  }

  /// Fetch detail history beserta EDAS matrices.
  /// Jika endpoint detail mengembalikan `edas` object (AV, PDA, NDA, final),
  /// maka matrices akan di-parse. Jika tidak ada, fallback ke rankings saja.
  Future<DecisionHistoryDetailModel> getDecisionHistoryDetail(
    DecisionHistoryModel historyMeta,
  ) async {
    final response = await _dioClient.dio.get(
      '${ApiConstants.decisionHistories}/${historyMeta.id}',
    );

    final responseData = response.data['data'];

    // Cek apakah response adalah object dengan rankings + edas matrices,
    // atau array rankings langsung (format lama).
    if (responseData is Map<String, dynamic>) {
      // Format baru: { rankings: [...], edas: { av: [...], pda: [...], nda: [...], final: [...] } }
      final List rawRankings = responseData['rankings'] ?? [];
      final Map<String, dynamic>? edasData =
          responseData['edas'] as Map<String, dynamic>?;

      return DecisionHistoryDetailModel.fromFullResponse(
        historyId: historyMeta.id,
        calculatedAt: historyMeta.calculatedAt,
        rawRankings: rawRankings,
        edasData: edasData,
      );
    } else {
      // Format lama: array of rankings langsung
      final List rawRankings = responseData as List;
      return DecisionHistoryDetailModel.fromRankings(
        historyId: historyMeta.id,
        calculatedAt: historyMeta.calculatedAt,
        rawRankings: rawRankings,
      );
    }
  }
}