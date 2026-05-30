import 'package:equatable/equatable.dart';

class SupplierModel extends Equatable {
  final int id;
  final String name;
  final String address;
  final String? phone;

  const SupplierModel({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
    };
  }

  @override
  List<Object?> get props => [id, name, address, phone];
}