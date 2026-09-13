import 'package:anu_timetable/data/repositories/event_repository_firebase.dart';
import 'package:anu_timetable/data/repositories/user_repository_firebase.dart';
import 'package:anu_timetable/data/services/ics_service.dart';
import 'package:anu_timetable/domain/model/event_rule.dart';
import 'package:anu_timetable/domain/model/user.dart';
import 'package:anu_timetable/util/command.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:anu_timetable/widgets/dialog.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class UserVM extends ChangeNotifier {
  late Command0<void> signInWithMicrosoft;
  late Command0<void> signOut;
  late Command0<void> deleteAccount;
  late Command0<void> loadCurrentUser;
  late Command1<void, DateTime> loadYear;
  late Command1<void, Uri> loadAndSyncIcs;

  final _icsService = IcsService();
  final UserRepositoryFirebase _userRepository;
  final EventRepositoryFirebase _eventRepository;


  UserVM({required UserRepositoryFirebase userRepository, required EventRepositoryFirebase eventRepository})
    : _userRepository = userRepository, _eventRepository = eventRepository {
      signInWithMicrosoft = Command0(_signInWithMicrosoft);
      loadCurrentUser = Command0(_loadCurrentUser);
      signOut = Command0(_signOut);
      deleteAccount = Command0(_deleteAccount);
      loadAndSyncIcs = Command1(_loadAndSyncIcs);

      FirebaseAuth.instance.authStateChanges().listen((u) async {
        if (_userRepository.loading) return;
        print("auth state changed");
        notifyListeners();
      });
    }
  
  User? get currentUser => _userRepository.currentUser;
  bool get triedInitialSync => _userRepository.triedInitialSync;

  Future<Result<void>> _signInWithMicrosoft() async {
    final result = await _userRepository.signInWithMicrosoft();
    notifyListeners();
    return result;
    // switch(result) {
    //   case Ok():
    //     notifyListeners();
    //     return result;
    //   case Error():
    //     return result;
    // }
  }

  Future<Result<void>> _signOut() async {
    final result = await _userRepository.signOut();
    switch(result) {
      case Ok():
        return result;
      case Error():
        throw result;
    }
  }

  Future<Result<void>> _deleteAccount() async {
    final result = await _userRepository.deleteAccount();
    
    switch(result) {
      case Ok():
        CookieManager cookieManager = CookieManager.instance();
        await cookieManager.deleteAllCookies();
        return result;
      case Error():
        throw result;
    }
  }

  Future<Result<void>> _loadCurrentUser() async {
    final result = await _userRepository.getCurrentUser();
    print(result);
    switch(result) {
      case Ok():
        print("current user loaded");
        // notifyListeners();
      case Error():
        print(result.error);
        // notifyListeners();
        return result;
    }
    return Result.ok(null);
  }

  Future<Result> addICalUrl(Uri iCalUrl) async {
    return await _userRepository.addICalUrl(iCalUrl);
  }

  Future<Result> _loadAndSyncIcs(Uri iCalUrl) async {
    _userRepository.triedInitialSync = false;
    final iCalResult = await _icsService.fetchIcs(iCalUrl);
    switch (iCalResult) {
      case Error<String>():
        return iCalResult;
      case Ok<String>():
    }
    final parseResult = await _icsService.parseIcs(iCalResult.value);
    switch (parseResult) {
      case Error<List<EventRule>>():
        return parseResult;
      case Ok<List<EventRule>>():
    }
    final eventRules = parseResult.value;

    final setRulesResult = await _eventRepository.setEventRules(eventRules);
    switch(setRulesResult) {
      case Error():
        return setRulesResult;
      case Ok():
    }

    final userResult = await _userRepository.getCurrentUser();
    switch(userResult) {
      case Error<User>():
        return userResult;
      case Ok<User>():
    }
    final user = userResult.value;
    Set<String> ids = eventRules.map((eventRule) => eventRule.id).toSet();
    final setUserKeysResult = await _userRepository.setUserEventRuleKeys(user.uid, ids);
    switch(setUserKeysResult) {
      case Error():
        return setUserKeysResult;
      case Ok():
    }
    final (keysRemoved, keysAdded) = setUserKeysResult.value;
    
    final removeFromGroupsResult = await _userRepository.removeFromGroups(user.uid, keysRemoved);
    switch(removeFromGroupsResult) {
      case Error():
        return removeFromGroupsResult;
      case Ok():
    }

    final addToGroupsResult = await _userRepository.addToGroups(user.uid, ids);
    switch(addToGroupsResult) {
      case Ok():
        notifyListeners();
        return Result.ok(null);
      case Error():
        return addToGroupsResult;
    }
  }
}