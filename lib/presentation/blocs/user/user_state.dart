import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<UserModel> users;

  const UserLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class UserActionLoading extends UserState {
  final List<UserModel> users;

  const UserActionLoading(this.users);

  @override
  List<Object?> get props => [users];
}

class UserActionSuccess extends UserState {
  final List<UserModel> users;
  final String message;

  const UserActionSuccess(this.users, this.message);

  @override
  List<Object?> get props => [users, message];
}

class UserActionError extends UserState {
  final List<UserModel> users;
  final String message;

  const UserActionError(this.users, this.message);

  @override
  List<Object?> get props => [users, message];
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}