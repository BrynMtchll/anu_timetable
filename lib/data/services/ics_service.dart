import 'package:anu_timetable/domain/model/event_rule.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:enough_icalendar/enough_icalendar.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart';

class IcsService {
  Future<Result<String>> fetchIcs(Uri iCalUrl) async {
    try {
      final cookies = await CookieManager.instance().getCookies(
        url: WebUri(iCalUrl.toString()),
      );
      final cookieHeader = cookies.map((c) => '${c.name}=${c.value}').join('; ');
      final response = await get(iCalUrl, headers: {'Cookie': cookieHeader});

      if (response.statusCode == 200) {
        return Result.ok(response.body);
      } else {
        return Result.error(Exception("error: ${response.statusCode}"));
      }
    } catch (e) {
      return Result.error(Exception(e));
    }
  }

  // all those with same description belong to the same rule
  Future<Result<List<EventRule>>> parseIcs(String icsStr) async {
    // print(icsStr);
    final icalendar = VComponent.parse(icsStr) as VCalendar;
    final List<EventRule> eventRules = [];
    for (final child in icalendar.children) {
      if (child.name == "VEVENT") {
        eventRules.add(EventRule.fromIcs(child as VEvent));
      }
    }
    return Result.ok(eventRules);
  }
}