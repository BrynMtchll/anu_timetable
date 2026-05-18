import 'package:anu_timetable/data/repositories/user_repository.dart';
import 'package:anu_timetable/domain/model/user.dart';
import 'package:anu_timetable/util/command.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:flutter/material.dart';

class UserVM extends ChangeNotifier {
  late Command0<void> signInWithGoogle;
  late Command0<void> loadCurrentUser;
  late Command1<void, DateTime> loadYear;

  UserVM({required UserRepository userRepository})
    : _userRepository = userRepository {
      signInWithGoogle = Command0(_signInWithGoogle);
      loadCurrentUser = Command0(_loadCurrentUser);
    }

  final UserRepository _userRepository;
  
  User? currentUser;

  Future<Result> _signInWithGoogle() async {
    final result = await _userRepository.signInWithGoogle();
    switch(result) {
      case Ok():
        currentUser = result.value;
        notifyListeners();
        return result;
      case Error():
        throw result;
    }
  }

  Future<Result> _loadCurrentUser() async {
    notifyListeners();
    final result = await _userRepository.getCurrentUser();
    switch(result) {
      case Ok():
        currentUser = result.value;
      case Error():
        throw result.error;
    }
    notifyListeners();
    return Result.ok(currentUser);
  }
}