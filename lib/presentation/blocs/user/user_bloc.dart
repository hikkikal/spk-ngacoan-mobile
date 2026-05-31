import 'package:flutter_bloc/flutter_bloc.dart';
import 'user_event.dart';
import 'user_state.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepository;

  UserBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(UserInitial()) {
    on<UserLoadRequested>(_onLoad);
    on<UserAddRequested>(_onAdd);
    on<UserUpdateRequested>(_onUpdate);
    on<UserDeleteRequested>(_onDelete);
  }

  List<UserModel> _currentList() {
    final s = state;
    if (s is UserLoaded) return s.users;
    if (s is UserActionLoading) return s.users;
    if (s is UserActionSuccess) return s.users;
    if (s is UserActionError) return s.users;
    return [];
  }

  Future<void> _onLoad(
    UserLoadRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final users = await _userRepository.getUsers();
      emit(UserLoaded(users));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onAdd(
    UserAddRequested event,
    Emitter<UserState> emit,
  ) async {
    final current = _currentList();
    emit(UserActionLoading(current));
    try {
      await _userRepository.addUser(
        name: event.name,
        username: event.username,
        email: event.email,
        password: event.password,
      );
      final updated = await _userRepository.getUsers();
      emit(UserActionSuccess(updated, 'User berhasil ditambahkan'));
    } catch (e) {
      emit(UserActionError(current, e.toString()));
    }
  }

  Future<void> _onUpdate(
    UserUpdateRequested event,
    Emitter<UserState> emit,
  ) async {
    final current = _currentList();
    emit(UserActionLoading(current));
    try {
      await _userRepository.updateUser(
        id: event.id,
        name: event.name,
        username: event.username,
        email: event.email,
      );
      final updated = await _userRepository.getUsers();
      emit(UserActionSuccess(updated, 'User berhasil diperbarui'));
    } catch (e) {
      emit(UserActionError(current, e.toString()));
    }
  }

  Future<void> _onDelete(
    UserDeleteRequested event,
    Emitter<UserState> emit,
  ) async {
    final current = _currentList();
    emit(UserActionLoading(current));
    try {
      await _userRepository.deleteUser(event.id);
      final updated = await _userRepository.getUsers();
      emit(UserActionSuccess(updated, 'User berhasil dihapus'));
    } catch (e) {
      emit(UserActionError(current, e.toString()));
    }
  }
}