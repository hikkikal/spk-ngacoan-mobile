import '../models/evaluation_model.dart';
import '../models/decision_history_detail_model.dart';
import '../models/criteria_model.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class EvaluationRepository {
  final DioClient _dioClient;

  EvaluationRepository({required DioClient dioClient})
      : _dioClient = dioClient;

  Future<List<EvaluationModel>> getEvaluations() async {
    final response = await _dioClient.dio.get(ApiConstants.evaluations);
    final List data = response.data['data'];
    return data.map((e) => EvaluationModel.fromJson(e)).toList();
  }

  Future<void> bulkInsertEvaluations(
      List<Map<String, dynamic>> evaluations) async {
    await _dioClient.dio.post(
      ApiConstants.evaluationsBulk,
      data: {'evaluations': evaluations},
    );
  }

  /// Panggil /calculate-edas dan langsung parse hasilnya.
  /// Membutuhkan [criteriaList] agar key ID numerik bisa dikonversi
  /// ke kode kriteria yang readable (C1, C2, …).
  Future<DecisionHistoryDetailModel> calculateEdas({
    required List<CriteriaModel> criteriaList,
  }) async {
    final response =
        await _dioClient.dio.post(ApiConstants.calculateEdas);

    // response.data = { meta: {...}, data: { rankings: [...], calculation_steps: {...} } }
    final data = response.data['data'] as Map<String, dynamic>;

    // historyId dan calculatedAt tidak ada di response ini,
    // pakai 0 dan null sebagai placeholder —
    // jika diperlukan bisa fetch /decision-histories setelahnya.
    return DecisionHistoryDetailModel.fromCalculateEdas(
      historyId: 0,
      calculatedAt: null,
      responseData: data,
      criteriaList: criteriaList,
    );
  }
}