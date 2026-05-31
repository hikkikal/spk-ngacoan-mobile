import 'package:flutter_bloc/flutter_bloc.dart';
import 'criteria_event.dart';
import 'criteria_state.dart';
import '../../../data/models/criteria_model.dart';
import '../../../data/repositories/criteria_repository.dart';

class CriteriaBloc extends Bloc<CriteriaEvent, CriteriaState> {
  final CriteriaRepository _criteriaRepository;

  CriteriaBloc({required CriteriaRepository criteriaRepository})
      : _criteriaRepository = criteriaRepository,
        super(CriteriaInitial()) {
    on<CriteriaLoadRequested>(_onLoad);
    on<CriteriaAddRequested>(_onAdd);
    on<CriteriaUpdateRequested>(_onUpdate);
    on<CriteriaDeleteRequested>(_onDelete);
  }

  List<CriteriaModel> _currentList() {
    final s = state;
    if (s is CriteriaLoaded) return s.criterias;
    if (s is CriteriaActionLoading) return s.criterias;
    if (s is CriteriaActionSuccess) return s.criterias;
    if (s is CriteriaActionError) return s.criterias;
    return [];
  }

  Future<void> _onLoad(
    CriteriaLoadRequested event,
    Emitter<CriteriaState> emit,
  ) async {
    emit(CriteriaLoading());
    try {
      final criterias = await _criteriaRepository.getCriteria();
      emit(CriteriaLoaded(criterias));
    } catch (e) {
      emit(CriteriaError(e.toString()));
    }
  }

  Future<void> _onAdd(
    CriteriaAddRequested event,
    Emitter<CriteriaState> emit,
  ) async {
    final current = _currentList();
    emit(CriteriaActionLoading(current));
    try {
      await _criteriaRepository.addCriteria(
        name: event.name,
        type: event.type,
        weightInput: event.weightInput,
      );
      final updated = await _criteriaRepository.getCriteria();
      emit(CriteriaActionSuccess(updated, 'Kriteria berhasil ditambahkan'));
    } catch (e) {
      emit(CriteriaActionError(current, e.toString()));
    }
  }

  Future<void> _onUpdate(
    CriteriaUpdateRequested event,
    Emitter<CriteriaState> emit,
  ) async {
    final current = _currentList();
    emit(CriteriaActionLoading(current));
    try {
      await _criteriaRepository.updateCriteria(
        id: event.id,
        name: event.name,
        type: event.type,
        weightInput: event.weightInput,
      );
      final updated = await _criteriaRepository.getCriteria();
      emit(CriteriaActionSuccess(updated, 'Kriteria berhasil diperbarui'));
    } catch (e) {
      emit(CriteriaActionError(current, e.toString()));
    }
  }

  Future<void> _onDelete(
    CriteriaDeleteRequested event,
    Emitter<CriteriaState> emit,
  ) async {
    final current = _currentList();
    emit(CriteriaActionLoading(current));
    try {
      await _criteriaRepository.deleteCriteria(event.id);
      final updated = await _criteriaRepository.getCriteria();
      emit(CriteriaActionSuccess(updated, 'Kriteria berhasil dihapus'));
    } catch (e) {
      emit(CriteriaActionError(current, e.toString()));
    }
  }
}