import '../models/decision_history_model.dart';
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

  Future<DecisionHistoryModel> getDecisionHistoryById(int id) async {
    final response = await _dioClient.dio.get(
      '${ApiConstants.decisionHistories}/$id',
    );
    return DecisionHistoryModel.fromJson(response.data['data']);
  }
}