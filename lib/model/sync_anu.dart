import 'package:anu_timetable/data/repositories/event_repository_firebase.dart';
import 'package:anu_timetable/data/repositories/user_repository_firebase.dart';
import 'package:anu_timetable/data/services/ics_service.dart';
import 'package:anu_timetable/domain/model/event_rule.dart';
import 'package:anu_timetable/domain/model/user.dart';
import 'package:anu_timetable/util/command.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:anu_timetable/widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';

class SyncAnuVM extends ChangeNotifier {
  static final loginSuccessMarker = "mytimetable.anu.edu.au/even/student?ss=";
  final EventRepositoryFirebase _eventRepository;
  final UserRepositoryFirebase _userRepository;
  late Command1<void, Uri> loadAndSyncIcs;
  final _icsService = IcsService();

  SyncAnuVM({required UserRepositoryFirebase userRepository, required EventRepositoryFirebase eventRepository})
    : _eventRepository = eventRepository, _userRepository = userRepository {
    loadAndSyncIcs = Command1(_loadAndSyncIcs);
  }

  Future<Result> _loadAndSyncIcs(Uri iCalUrl) async {
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
        return Result.ok(null);
      case Error():
        return addToGroupsResult;
    }
  }

  void onReceivedError(InAppWebViewController controller, WebResourceRequest request, WebResourceError error, BuildContext context) {
    print(error);
    context.pop();
  }

  void onLoadStop(InAppWebViewController controller, WebUri? url, BuildContext context) async {
    if (!url.toString().contains(loginSuccessMarker)) {
      return;
    }
    final result = await controller.evaluateJavascript(source: 'iCalURL');
    if (result == null || result == 'null') {
      throw Exception("no iCal URL found");
    }

    if (context.mounted) {
      context.pop();
    }
    await loadAndSyncIcs.execute(Uri.parse(result as String));
    
    if (loadAndSyncIcs.error) {
      if (context.mounted) {
        final dialogStatus = showErrorDialog(context: context, title: (loadAndSyncIcs.result as Error).error.toString());
        await dialogStatus.result;
      }
    }
  }
}