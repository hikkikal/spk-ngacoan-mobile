import '../models/user_model.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class UserRepository {
  final DioClient _dioClient;

  UserRepository({required DioClient dioClient}) : _dioClient = dioClient;

  Future<List<UserModel>> getUsers() async {
    final response = await _dioClient.dio.get(ApiConstants.users);
    final List data = response.data['data'];
    return data.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> addUser({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    await _dioClient.dio.post(
      ApiConstants.users,
      data: {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      },
    );
  }

  Future<void> updateUser({
    required int id,
    required String name,
    required String username,
    required String email,
  }) async {
    await _dioClient.dio.put(
      '${ApiConstants.users}/$id',
      data: {
        'name': name,
        'username': username,
        'email': email,
      },
    );
  }

  Future<void> deleteUser(int id) async {
    await _dioClient.dio.delete('${ApiConstants.users}/$id');
  }
}