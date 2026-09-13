import 'package:anu_timetable/widgets/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomDialog extends StatelessWidget {
  const CustomDialog({
    super.key,
    required this.title,
    this.content,
    required this.actions,
  });

  final String title;
  final Widget? content;
  final List<CustomButton> actions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      backgroundColor: colorScheme.surfaceContainer,
      child: IntrinsicHeight(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(title, style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18))),
            if (content != null)
              Container(
                padding: EdgeInsets.only(left: 20, right: 20, bottom: 5),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 400),
                  child: SingleChildScrollView(
                    child: content)),
              ),
            Container(
              padding: EdgeInsets.all(15),
              child: Row(
                spacing: 10,
                children: actions.map((a) => Expanded(child: a)).toList()))
          ])));
  }
}

/// Tracks the status of a dialog, in being still open or already closed.
///
/// Use [T] to identify the outcome of the interaction:
/// - Pass `void` for an informational dialog with just the option to dismiss.
/// - For confirmation dialogs with an option to dismiss
///   plus an option to proceed with an action, pass `bool`.
///   The action button should pass true for Navigator.pop's `result` argument.
/// - For dialogs with an option to dismiss plus multiple other options,
///   pass a custom enum.
/// For the latter two cases, a cancel button should call Navigator.pop
/// with null for the `result` argument, to match what Flutter does
/// when you dismiss the dialog by tapping outside its area.
///
/// See also:
///  * [showDialog], whose return value this class is intended to wrap.
class DialogStatus<T> {
  const DialogStatus(this.result);

  /// Resolves when the dialog is closed.
  ///
  /// If this completes with null, the dialog was dismissed.
  /// Otherwise, completes with a [T] identifying the interaction's outcome.
  ///
  /// See, e.g., [showSuggestedActionDialog].
  final Future<T?> result;
}

/// Displays an [AlertDialog] with a dismiss button
/// and optional "Learn more" button, and gives haptic feedback.
///
/// The [DialogStatus.result] field of the return value can be used
/// for waiting for the dialog to be closed.
///
/// Prose in [message] should have final punctuation:
///   https://github.com/zulip/zulip-flutter/pull/1498#issuecomment-2853578577
///
/// The context argument should be a descendant of the app's main [Navigator].
// This API is inspired by [ScaffoldManager.showSnackBar].  We wrap
// [showDialog]'s return value, a [Future], inside [DialogStatus]
// whose documentation can be accessed.  This helps avoid confusion when
// interpreting the meaning of the [Future].
DialogStatus<void> showErrorDialog({
  required BuildContext context,
  required String title,
  String? message,
  Uri? learnMoreButtonUrl,
}) {
  HapticFeedback.errorNotification();
  final future = showDialog<void>(
    context: context,
    builder: (BuildContext context) => CustomDialog(
      title: title,
      content: message != null ? Text(message) : null,
      actions: [
        CustomButton(
        onPressed: () => Navigator.pop(context),
        isPrimary: true,
        text: "continue")
      ]));
  return DialogStatus(future);
}

/// Displays an alert dialog with a cancel button and an action button.
///
/// The [DialogStatus.result] Future gives true if the action button was tapped.
/// If the dialog was canceled,
/// either with the cancel button or by tapping outside the dialog's area,
/// it completes with null.
///
/// The context argument should be a descendant of the app's main [Navigator].
DialogStatus<bool> showSuggestedActionDialog({
  required BuildContext context,
  required String title,
  String? message,
  required String? actionButtonText,
  bool cancelIsPrimary = false,
  bool isPrimary = false,
  bool destructiveActionButton = false,
}) {
  final future = showDialog<bool>(
    context: context,
    builder: (BuildContext context) => CustomDialog(
      title: title,
      content: message != null ? Text(message) : null,
      actions: [
        CustomButton(
          onPressed: () => Navigator.pop<bool>(context, null),
          isPrimary: cancelIsPrimary,
          text: "cancel"),
        CustomButton(
          onPressed: () => Navigator.pop<bool>(context, true),
          isPrimary: isPrimary,
          text: actionButtonText ?? "continue"),
      ]));
  return DialogStatus(future);
}
