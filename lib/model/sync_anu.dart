import 'package:anu_timetable/data/repositories/event_repository.dart';
import 'package:anu_timetable/data/repositories/user_repository.dart';
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
  final EventRepository _eventRepository;
  final UserRepository _userRepository;
  late Command1<void, Uri> loadAndSyncIcs;
  final _icsService = IcsService();
  bool _authorised = false;

  SyncAnuVM({required UserRepository userRepository, required EventRepository eventRepository})
    : _eventRepository = eventRepository, _userRepository = userRepository {
    loadAndSyncIcs = Command1(_loadAndSyncIcs);
  }

  bool get authorised => _authorised;

  set authorised(newVal) {
    if (authorised != newVal) {
      authorised = newVal;
      notifyListeners();
    }
  }

  Future<Result> _loadAndSyncIcs(Uri iCalUrl) async {
    final iCalResult = await _icsService.fetchIcs(iCalUrl);
    switch (iCalResult) {
      case Ok<String>(): 
        break;
      case Error<String>():
        throw iCalResult.error;
    }
    final eventRulesResult = await _icsService.parseIcs(iCalResult.value);

    switch(eventRulesResult) {
      case Ok<List<EventRule>>():
      break;
      case Error<List<EventRule>>():
        throw eventRulesResult.error;
    }

    final eventRulesAddedResult = await _eventRepository.addEventRules(eventRulesResult.value);
    switch(eventRulesAddedResult) {
      case Ok<List<EventRule>>():
        break;
      case Error<List<EventRule>>():
        throw eventRulesAddedResult.error;
    }

    final eventRulesAdded = eventRulesAddedResult.value;

    if (eventRulesAdded.isEmpty) {
      print("already synced!");
      return Result.ok(null);
    }
    
    final userResult = await _userRepository.getCurrentUser();
    switch(userResult) {
      case Ok<User>():
        break;
      case Error<User>():
        throw userResult.error;
    }
    Set<String> eventRulesAddedKeys = eventRulesResult.value.map((eventRule) => eventRule.key!).toSet();
    final addedToUserResult = await _userRepository.addEventRulesToUser(userResult.value.uid, eventRulesAddedKeys);
    switch(addedToUserResult) {
      case Ok():
        break;
      case Error():
        throw addedToUserResult.error;
    }

    final addedToGroupResult = await _userRepository.addUserToGroup(userResult.value, eventRulesAddedKeys);
    switch(addedToGroupResult) {
      case Ok():
        return Result.ok(null);
      case Error():
        throw addedToGroupResult.error;
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