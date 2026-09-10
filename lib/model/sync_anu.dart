import 'package:anu_timetable/data/repositories/event_repository_firebase.dart';
import 'package:anu_timetable/data/repositories/user_repository_firebase.dart';
import 'package:anu_timetable/data/services/ics_service.dart';
import 'package:anu_timetable/domain/model/event_rule.dart';
import 'package:anu_timetable/domain/model/user.dart';
import 'package:anu_timetable/util/command.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';

class SyncAnuVM extends ChangeNotifier {
  static final loginSuccessMarker = "mytimetable.anu.edu.au/even/student?ss=";
  final EventRepositoryFirebase _eventRepository;
  final UserRepositoryFirebase _userRepository;
  late Command1<void, Uri> loadAndSyncIcs;
  final _icsService = IcsService();
  bool _authorised = false;

  SyncAnuVM({required UserRepositoryFirebase userRepository, required EventRepositoryFirebase eventRepository})
    : _eventRepository = eventRepository, _userRepository = userRepository {
    loadAndSyncIcs = Command1(_loadAndSyncIcs);
  }

  bool get authorised => _authorised;

  set authorised(newVal) {
    if (_authorised != newVal) {
      _authorised = newVal;
      notifyListeners();
    }
  }

  Future<Result> _loadAndSyncIcs(Uri iCalUrl) async {
    final iCalResult = await _icsService.fetchIcs(iCalUrl);
    switch (iCalResult) {
      case Error<String>():
        throw iCalResult.error;
      case Ok<String>():
    }
    final parseResult = await _icsService.parseIcs(iCalResult.value);

    switch(parseResult) {
      case Error<List<EventRule>>():
        throw parseResult.error;
      case Ok<List<EventRule>>():
    }
    final eventRules = parseResult.value;
    final setRulesResult = await _eventRepository.setEventRules(eventRules);
    switch(setRulesResult) {
      case Error():
        throw setRulesResult.error;
      case Ok():
    }

    final userResult = await _userRepository.getCurrentUser();
    switch(userResult) {
      case Error<User>():
        throw userResult.error;
      case Ok<User>():
    }
    final user = userResult.value;
    Set<String> ids = eventRules.map((eventRule) => eventRule.id).toSet();
    final setUserKeysResult = await _userRepository.setUserEventRuleKeys(user.uid, ids);
    switch(setUserKeysResult) {
      case Ok():
        break;
      case Error():
        throw setUserKeysResult.error;
    }
    final (keysRemoved, keysAdded) = setUserKeysResult.value;
    
    final removeFromGroupsResult = await _userRepository.removeFromGroups(user.uid, keysRemoved);
    switch(removeFromGroupsResult) {
      case Ok():
        break;
      case Error():
        throw removeFromGroupsResult.error;
    }
    final addToGroupsResult = await _userRepository.addToGroups(user.uid, ids);
    switch(addToGroupsResult) {
      case Ok():
        return Result.ok(null);
      case Error():
        throw addToGroupsResult.error;
    }
  }

  void onReceivedError(InAppWebViewController controller, WebResourceRequest request, WebResourceError error, BuildContext context) {
    print(error);
    context.pop();
  }

  void onLoadStop(InAppWebViewController controller, WebUri? url) async {
    if (!url.toString().contains(loginSuccessMarker)) {
      return;
    }
    authorised = true;
    final result = await controller.evaluateJavascript(source: 'iCalURL');
    if (result == null || result == 'null') {
      throw Exception("no iCal URL found");
    }
    await loadAndSyncIcs.execute(Uri.parse(result as String));
  }
}