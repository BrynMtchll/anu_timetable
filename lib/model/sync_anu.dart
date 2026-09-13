import 'package:anu_timetable/model/user.dart';
import 'package:anu_timetable/util/result.dart';
import 'package:anu_timetable/widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

class SyncAnuVM extends ChangeNotifier {
  static final loginSuccessMarker = "mytimetable.anu.edu.au/even/student?ss=";

  SyncAnuVM();

  void onReceivedError(InAppWebViewController controller, WebResourceRequest request, WebResourceError error, BuildContext context) {
    // TODO
    // print(error);
    // context.pop();
  }

  void onLoadStop(InAppWebViewController controller, WebUri? url, BuildContext context) async {
    if (!url.toString().contains(loginSuccessMarker)) {
      return;
    }
    final result = await controller.evaluateJavascript(source: 'iCalURL');
    if (result == null || result == 'null') {
      throw Exception("no iCal URL found");
    }
    final iCalUrl = Uri.parse(result as String);
    if (context.mounted) {
      final UserVM userVM = context.read<UserVM>();
      await userVM.addICalUrl(iCalUrl);
      await userVM.loadAndSyncIcs.execute(iCalUrl);
      if (userVM.loadAndSyncIcs.error) {
        if (context.mounted) {
          final dialogStatus = showErrorDialog(context: context, title: (userVM.loadAndSyncIcs.result as Error).error.toString());
          await dialogStatus.result;
        }
      }
    }
  }
}