import '../models/criteria_model.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class CriteriaRepository {
  final DioClient _dioClient;

  CriteriaRepository({required DioClient dioClient})
      : _dioClient = dioClient;

  Future<List<CriteriaModel>> getCriteria() async {
    final response = await _dioClient.dio.get(ApiConstants.criteria);
    final List data = response.data['data'];
    return data.map((e) => CriteriaModel.fromJson(e)).toList();
  }

  Future<CriteriaModel> addCriteria({
    required String name,
    required String type,
    required int weightInput,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.criteria,
      data: {'name': name, 'type': type, 'weight_input': weightInput},
    );
    return CriteriaModel.fromJson(response.data['data']);
  }

  Future<CriteriaModel> updateCriteria({
    required int id,
    required String name,
    required String type,
    required int weightInput,
  }) async {
    final response = await _dioClient.dio.put(
      '${ApiConstants.criteria}/$id',
      data: {'name': name, 'type': type, 'weight_input': weightInput},
    );
    return CriteriaModel.fromJson(response.data['data']);
  }

  Future<void> deleteCriteria(int id) async {
    await _dioClient.dio.delete('${ApiConstants.criteria}/$id');
  }
}