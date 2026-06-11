import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repositories/decision_history_repository.dart';
import '../../../../data/repositories/evaluation_repository.dart';
import '../../../../data/repositories/criteria_repository.dart';
import 'decision_result_event.dart';
import 'decision_result_state.dart';

class DecisionResultBloc
    extends Bloc<DecisionResultEvent, DecisionResultState> {
  final DecisionHistoryRepository _historyRepository;
  final EvaluationRepository _evaluationRepository;
  final CriteriaRepository _criteriaRepository;

  DecisionResultBloc({
    required DecisionHistoryRepository historyRepository,
    required EvaluationRepository evaluationRepository,
    required CriteriaRepository criteriaRepository,
  })  : _historyRepository = historyRepository,
        _evaluationRepository = evaluationRepository,
        _criteriaRepository = criteriaRepository,
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

      // Ambil detail dari endpoint history (format lama / format baru)
      final detail =
          await _historyRepository.getDecisionHistoryDetail(latest);

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
      // Fetch kriteria terlebih dahulu — diperlukan untuk mapping ID → kode
      final criteriaList = await _criteriaRepository.getCriteria();

      // Panggil /calculate-edas dan parse langsung dari response-nya
      // (tidak perlu fetch ulang ke /decision-histories)
      final detail = await _evaluationRepository.calculateEdas(
        criteriaList: criteriaList,
      );

      emit(DecisionResultLoaded(detail: detail));
    } catch (e) {
      emit(DecisionResultError(message: e.toString()));
    }
  }
}