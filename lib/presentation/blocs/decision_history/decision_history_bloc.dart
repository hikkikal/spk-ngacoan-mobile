import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repositories/decision_history_repository.dart';
import '../../../../data/repositories/evaluation_repository.dart';
import '../../../../data/models/decision_history_model.dart';
import '../../../../data/calculators/edas_calculator.dart';
import 'decision_history_event.dart';
import 'decision_history_state.dart';

class DecisionHistoryBloc
    extends Bloc<DecisionHistoryEvent, DecisionHistoryState> {
  final DecisionHistoryRepository _historyRepository;
  final EvaluationRepository _evaluationRepository;

  DecisionHistoryBloc({
    required DecisionHistoryRepository historyRepository,
    required EvaluationRepository evaluationRepository,
  })  : _historyRepository = historyRepository,
        _evaluationRepository = evaluationRepository,
        super(const DecisionHistoryInitial()) {
    on<DecisionHistoryLoadRequested>(_onLoadRequested);
    on<DecisionHistoryAuditRequested>(_onAuditRequested);
  }

  List<DecisionHistoryModel> _currentHistories() {
    final s = state;
    if (s is DecisionHistoryLoaded) return s.histories;
    if (s is DecisionHistoryAuditLoading) return s.histories;
    if (s is DecisionHistoryAuditLoaded) return s.histories;
    if (s is DecisionHistoryAuditError) return s.histories;
    return [];
  }

  Future<void> _onLoadRequested(
    DecisionHistoryLoadRequested event,
    Emitter<DecisionHistoryState> emit,
  ) async {
    emit(const DecisionHistoryLoading());
    try {
      final histories = await _historyRepository.getDecisionHistories();
      if (histories.isEmpty) {
        emit(const DecisionHistoryEmpty());
        return;
      }
      histories.sort((a, b) => b.id.compareTo(a.id));
      emit(DecisionHistoryLoaded(histories: histories));
    } catch (e) {
      emit(DecisionHistoryError(message: e.toString()));
    }
  }

  Future<void> _onAuditRequested(
    DecisionHistoryAuditRequested event,
    Emitter<DecisionHistoryState> emit,
  ) async {
    final current = _currentHistories();
    emit(DecisionHistoryAuditLoading(
      histories: current,
      loadingId: event.id,
    ));
    try {
      final meta = current.firstWhere((h) => h.id == event.id);

      // Fetch evaluations lalu hitung EDAS di Flutter
      final evaluations = await _evaluationRepository.getEvaluations();
      final detail = EdasCalculator.calculate(
        historyId: meta.id,
        calculatedAt: meta.calculatedAt,
        evaluations: evaluations,
      );

      emit(DecisionHistoryAuditLoaded(histories: current, detail: detail));
    } catch (e) {
      emit(DecisionHistoryAuditError(
          histories: current, message: e.toString()));
    }
  }
}