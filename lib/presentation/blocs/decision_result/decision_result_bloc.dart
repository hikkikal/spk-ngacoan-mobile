import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repositories/decision_history_repository.dart';
import '../../../../data/repositories/evaluation_repository.dart';
import '../../../../data/calculators/edas_calculator.dart';
import 'decision_result_event.dart';
import 'decision_result_state.dart';

class DecisionResultBloc
    extends Bloc<DecisionResultEvent, DecisionResultState> {
  final DecisionHistoryRepository _historyRepository;
  final EvaluationRepository _evaluationRepository;

  DecisionResultBloc({
    required DecisionHistoryRepository historyRepository,
    required EvaluationRepository evaluationRepository,
  })  : _historyRepository = historyRepository,
        _evaluationRepository = evaluationRepository,
        super(const DecisionResultInitial()) {
    on<DecisionResultLoadRequested>(_onLoadRequested);
    on<DecisionResultHitungUlang>(_onHitungUlang);
  }

  Future<void> _onLoadRequested(
    DecisionResultLoadRequested event,
    Emitter<DecisionResultState> emit,
  ) async {
    emit(const DecisionResultLoading());
    try {
      final histories = await _historyRepository.getDecisionHistories();
      if (histories.isEmpty) {
        emit(const DecisionResultEmpty());
        return;
      }
      histories.sort((a, b) => b.id.compareTo(a.id));
      final latest = histories.first;

      // Fetch evaluations & hitung EDAS di Flutter
      final evaluations = await _evaluationRepository.getEvaluations();
      final detail = EdasCalculator.calculate(
        historyId: latest.id,
        calculatedAt: latest.calculatedAt,
        evaluations: evaluations,
      );

      emit(DecisionResultLoaded(detail: detail));
    } catch (e) {
      emit(DecisionResultError(message: e.toString()));
    }
  }

  Future<void> _onHitungUlang(
    DecisionResultHitungUlang event,
    Emitter<DecisionResultState> emit,
  ) async {
    final prev = state is DecisionResultLoaded
        ? (state as DecisionResultLoaded).detail
        : null;
    emit(DecisionResultHitungLoading(previousDetail: prev));
    try {
      await _evaluationRepository.calculateEdas();

      final histories = await _historyRepository.getDecisionHistories();
      if (histories.isEmpty) {
        emit(const DecisionResultEmpty());
        return;
      }
      histories.sort((a, b) => b.id.compareTo(a.id));
      final latest = histories.first;

      final evaluations = await _evaluationRepository.getEvaluations();
      final detail = EdasCalculator.calculate(
        historyId: latest.id,
        calculatedAt: latest.calculatedAt,
        evaluations: evaluations,
      );

      emit(DecisionResultLoaded(detail: detail));
    } catch (e) {
      emit(DecisionResultError(message: e.toString()));
    }
  }
}