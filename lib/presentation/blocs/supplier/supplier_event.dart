import 'package:equatable/equatable.dart';

abstract class SupplierEvent extends Equatable {
  const SupplierEvent();

  @override
  List<Object?> get props => [];
}

class SupplierLoadRequested extends SupplierEvent {
  const SupplierLoadRequested();
}

class SupplierAddRequested extends SupplierEvent {
  final String name;
  final String address;
  final String? phone;

  const SupplierAddRequested({
    required this.name,
    required this.address,
    this.phone,
  });

  @override
  List<Object?> get props => [name, address, phone];
}

class SupplierUpdateRequested extends SupplierEvent {
  final int id;
  final String name;
  final String address;
  final String? phone;

  const SupplierUpdateRequested({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
  });

  @override
  List<Object?> get props => [id, name, address, phone];
}

class SupplierDeleteRequested extends SupplierEvent {
  final int id;

  const SupplierDeleteRequested({required this.id});

  @override
  List<Object?> get props => [id];
}