import 'package:equatable/equatable.dart';
import '../../../../data/models/supplier_model.dart';

abstract class SupplierState extends Equatable {
  const SupplierState();

  @override
  List<Object?> get props => [];
}

class SupplierInitial extends SupplierState {
  const SupplierInitial();
}

class SupplierLoading extends SupplierState {
  const SupplierLoading();
}

class SupplierLoaded extends SupplierState {
  final List<SupplierModel> suppliers;

  const SupplierLoaded({required this.suppliers});

  @override
  List<Object?> get props => [suppliers];
}

class SupplierError extends SupplierState {
  final String message;

  const SupplierError({required this.message});

  @override
  List<Object?> get props => [message];
}

class SupplierActionLoading extends SupplierState {
  final List<SupplierModel> suppliers;

  const SupplierActionLoading({required this.suppliers});

  @override
  List<Object?> get props => [suppliers];
}

class SupplierActionSuccess extends SupplierState {
  final List<SupplierModel> suppliers;
  final String message;

  const SupplierActionSuccess({
    required this.suppliers,
    required this.message,
  });

  @override
  List<Object?> get props => [suppliers, message];
}

class SupplierActionError extends SupplierState {
  final List<SupplierModel> suppliers;
  final String message;

  const SupplierActionError({
    required this.suppliers,
    required this.message,
  });

  @override
  List<Object?> get props => [suppliers, message];
}