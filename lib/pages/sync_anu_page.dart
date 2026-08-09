import 'package:anu_timetable/model/sync_anu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

class SyncAnuPage extends StatelessWidget {
  const SyncAnuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final syncAnuVM = Provider.of<SyncAnuVM>(context, listen: false);
    return SafeArea(
      child: Consumer<SyncAnuVM>(
        builder: (BuildContext context, SyncAnuVM syncAnuVMLive, Widget? child)
          => Visibility(
            visible: true,
            child: child!),
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri('https://mytimetable.anu.edu.au/even/student')),
          initialSettings: InAppWebViewSettings(useOnDownloadStart: true),
          onDownloadStartRequest: (controller, downloadRequest) async {
            syncAnuVM.loadAndSyncIcs.execute(Uri.parse(downloadRequest.url.toString()));
          },
          onReceivedError: (controller, request, error) 
            => syncAnuVM.onReceivedError(controller, request, error, context),
          onLoadStop: syncAnuVM.onLoadStop)));
  }
}