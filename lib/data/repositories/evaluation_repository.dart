import '../models/evaluation_model.dart';
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

  Future<void> bulkInsertEvaluations(List<Map<String, dynamic>> evaluations) async {
    await _dioClient.dio.post(
      ApiConstants.evaluationsBulk,
      data: {'evaluations': evaluations},
    );
  }

  Future<void> calculateEdas() async {
    await _dioClient.dio.post(ApiConstants.calculateEdas);
  }
}