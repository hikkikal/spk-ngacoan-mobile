import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repositories/supplier_repository.dart';
import '../../../../data/models/supplier_model.dart';
import 'supplier_event.dart';
import 'supplier_state.dart';

class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  final SupplierRepository _supplierRepository;

  SupplierBloc({required SupplierRepository supplierRepository})
      : _supplierRepository = supplierRepository,
        super(const SupplierInitial()) {
    on<SupplierLoadRequested>(_onLoadRequested);
    on<SupplierAddRequested>(_onAddRequested);
    on<SupplierUpdateRequested>(_onUpdateRequested);
    on<SupplierDeleteRequested>(_onDeleteRequested);
  }

  List<SupplierModel> _currentSuppliers() {
    final state = this.state;
    if (state is SupplierLoaded) return state.suppliers;
    if (state is SupplierActionLoading) return state.suppliers;
    if (state is SupplierActionSuccess) return state.suppliers;
    if (state is SupplierActionError) return state.suppliers;
    return [];
  }

  Future<void> _onLoadRequested(
    SupplierLoadRequested event,
    Emitter<SupplierState> emit,
  ) async {
    emit(const SupplierLoading());
    try {
      final suppliers = await _supplierRepository.getSuppliers();
      emit(SupplierLoaded(suppliers: suppliers));
    } catch (e) {
      emit(SupplierError(message: e.toString()));
    }
  }

  Future<void> _onAddRequested(
    SupplierAddRequested event,
    Emitter<SupplierState> emit,
  ) async {
    final current = _currentSuppliers();
    emit(SupplierActionLoading(suppliers: current));
    try {
      await _supplierRepository.addSupplier(
        name: event.name,
        address: event.address,
        phone: event.phone,
      );
      final suppliers = await _supplierRepository.getSuppliers();
      emit(SupplierActionSuccess(
        suppliers: suppliers,
        message: 'Supplier berhasil ditambahkan.',
      ));
    } catch (e) {
      emit(SupplierActionError(suppliers: current, message: e.toString()));
    }
  }

  Future<void> _onUpdateRequested(
    SupplierUpdateRequested event,
    Emitter<SupplierState> emit,
  ) async {
    final current = _currentSuppliers();
    emit(SupplierActionLoading(suppliers: current));
    try {
      await _supplierRepository.updateSupplier(
        id: event.id,
        name: event.name,
        address: event.address,
        phone: event.phone,
      );
      final suppliers = await _supplierRepository.getSuppliers();
      emit(SupplierActionSuccess(
        suppliers: suppliers,
        message: 'Supplier berhasil diperbarui.',
      ));
    } catch (e) {
      emit(SupplierActionError(suppliers: current, message: e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
    SupplierDeleteRequested event,
    Emitter<SupplierState> emit,
  ) async {
    final current = _currentSuppliers();
    emit(SupplierActionLoading(suppliers: current));
    try {
      await _supplierRepository.deleteSupplier(event.id);
      final suppliers = await _supplierRepository.getSuppliers();
      emit(SupplierActionSuccess(
        suppliers: suppliers,
        message: 'Supplier berhasil dihapus.',
      ));
    } catch (e) {
      emit(SupplierActionError(suppliers: current, message: e.toString()));
    }
  }
}