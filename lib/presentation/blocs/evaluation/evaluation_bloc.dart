import 'package:flutter_bloc/flutter_bloc.dart';
import 'evaluation_event.dart';
import 'evaluation_state.dart';
import '../../../data/repositories/evaluation_repository.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../data/repositories/criteria_repository.dart';

class EvaluationBloc extends Bloc<EvaluationEvent, EvaluationState> {
  final EvaluationRepository _evaluationRepository;
  final SupplierRepository _supplierRepository;
  final CriteriaRepository _criteriaRepository;

  EvaluationBloc({
    required EvaluationRepository evaluationRepository,
    required SupplierRepository supplierRepository,
    required CriteriaRepository criteriaRepository,
  })  : _evaluationRepository = evaluationRepository,
        _supplierRepository = supplierRepository,
        _criteriaRepository = criteriaRepository,
        super(EvaluationInitial()) {
    on<EvaluationLoadRequested>(_onLoad);
    on<EvaluationBulkSaveRequested>(_onBulkSave);
  }

  Future<void> _onLoad(
    EvaluationLoadRequested event,
    Emitter<EvaluationState> emit,
  ) async {
    emit(EvaluationLoading());
    try {
      final suppliers = await _supplierRepository.getSuppliers();
      final criterias = await _criteriaRepository.getCriteria();
      final evaluations = await _evaluationRepository.getEvaluations();
      emit(EvaluationLoaded(
        suppliers: suppliers,
        criterias: criterias,
        evaluations: evaluations,
      ));
    } catch (e) {
      emit(EvaluationError(e.toString()));
    }
  }

  Future<void> _onBulkSave(
    EvaluationBulkSaveRequested event,
    Emitter<EvaluationState> emit,
  ) async {
    final current = state;
    if (current is EvaluationLoaded) {
      emit(EvaluationSaving(
        suppliers: current.suppliers,
        criterias: current.criterias,
        evaluations: current.evaluations,
      ));
      try {
        await _evaluationRepository.bulkInsertEvaluations(event.evaluations);
        final updated = await _evaluationRepository.getEvaluations();
        emit(EvaluationSaveSuccess(
          suppliers: current.suppliers,
          criterias: current.criterias,
          evaluations: updated,
        ));
      } catch (e) {
        emit(EvaluationSaveError(
          suppliers: current.suppliers,
          criterias: current.criterias,
          evaluations: current.evaluations,
          message: e.toString(),
        ));
      }
    }
  }
}