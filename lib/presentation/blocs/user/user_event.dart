import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class UserLoadRequested extends UserEvent {
  const UserLoadRequested();
}

class UserAddRequested extends UserEvent {
  final String name;
  final String username;
  final String email;
  final String password;

  const UserAddRequested({
    required this.name,
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, username, email, password];
}

class UserUpdateRequested extends UserEvent {
  final int id;
  final String name;
  final String username;
  final String email;

  const UserUpdateRequested({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
  });

  @override
  List<Object?> get props => [id, name, username, email];
}

class UserDeleteRequested extends UserEvent {
  final int id;

  const UserDeleteRequested({required this.id});

  @override
  List<Object?> get props => [id];
}