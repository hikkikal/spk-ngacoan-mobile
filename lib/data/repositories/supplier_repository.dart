import '../models/supplier_model.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class SupplierRepository {
  final DioClient _dioClient;

  SupplierRepository({required DioClient dioClient})
      : _dioClient = dioClient;

  Future<List<SupplierModel>> getSuppliers() async {
    final response = await _dioClient.dio.get(ApiConstants.suppliers);
    final List data = response.data['data'];
    return data.map((e) => SupplierModel.fromJson(e)).toList();
  }

  Future<SupplierModel> addSupplier({
    required String name,
    required String address,
    String? phone,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.suppliers,
      data: {'name': name, 'address': address, 'phone': phone},
    );
    return SupplierModel.fromJson(response.data['data']);
  }

  Future<SupplierModel> updateSupplier({
    required int id,
    required String name,
    required String address,
    String? phone,
  }) async {
    final response = await _dioClient.dio.put(
      '${ApiConstants.suppliers}/$id',
      data: {'name': name, 'address': address, 'phone': phone},
    );
    return SupplierModel.fromJson(response.data['data']);
  }

  Future<void> deleteSupplier(int id) async {
    await _dioClient.dio.delete('${ApiConstants.suppliers}/$id');
  }
}