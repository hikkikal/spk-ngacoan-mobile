import 'package:equatable/equatable.dart';

abstract class DecisionResultEvent extends Equatable {
  const DecisionResultEvent();

  @override
  List<Object?> get props => [];
}

class DecisionResultLoadRequested extends DecisionResultEvent {
  const DecisionResultLoadRequested();
}

class DecisionResultHitungUlang extends DecisionResultEvent {
  const DecisionResultHitungUlang();
}