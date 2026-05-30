import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/dashboard_stats_model.dart';

class DashboardRepository {
  final DioClient _dioClient;

  DashboardRepository({required DioClient dioClient})
      : _dioClient = dioClient;

  Future<DashboardStatsModel> getDashboardStats() async {
    final response = await _dioClient.dio.get(ApiConstants.dashboardStats);
    return DashboardStatsModel.fromJson(response.data['data']);
  }
}