import 'package:anu_timetable/data/repositories/user_repository.dart';
import 'package:anu_timetable/domain/model/user.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:flutter/material.dart';

class UserVM extends ChangeNotifier {
  UserVM({required UserRepository userRepository})
    : _userRepository = userRepository;

  final UserRepository _userRepository;

  User? currentUser;

  Future<User> signInWithGoogle() async {
    final result = await _userRepository.signInWithGoogle();
    switch(result) {
      case Ok():
        currentUser = result.value;
        notifyListeners();
        return result.value;
      case Error():
        throw result.error;
    }
  }

  Future<void> loadCurrentUser() async {
    bool isLoading = true;
    notifyListeners();
    final result = await _userRepository.getCurrentUser();
    switch(result) {
      case Ok():
        currentUser = result.value;
      case Error():
        throw result.error;
    }
    isLoading = false;
    print(currentUser!.displayName);
    notifyListeners();
  }
}