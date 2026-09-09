import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A platform-appropriate action for [AlertDialog.adaptive]'s [actions] param.
///
/// [isDefaultAction] and [isDestructiveAction] are ignored on Android
/// because Material Design doesn't specify corresponding styles.
Widget _adaptiveAction({
  required VoidCallback onPressed,
  required bool isDefaultAction,
  bool isDestructiveAction = false,
  required String text,
}) {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return TextButton(
        onPressed: onPressed,
        child: Text(text, textAlign: TextAlign.end));
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return CupertinoDialogAction(
        onPressed: onPressed,
        isDefaultAction: isDefaultAction,
        isDestructiveAction: isDestructiveAction,
        child: Text(text));
  }
}

/// Platform-appropriate content for [AlertDialog.adaptive]'s [content] param.
Widget? _adaptiveContent(Widget? content) {
  if (content == null) return null;

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      // [AlertDialog] does not create a [SingleChildScrollView];
      // callers are asked to do that themselves, to handle long content.
      return SingleChildScrollView(child: content);

    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      // A [SingleChildScrollView] (wrapping both title and content) is already
      // created by [CupertinoAlertDialog].
      return DefaultTextStyle.merge(
        // The "alert description" is start-aligned in one example in Apple's
        // HIG document:
        //   https://developer.apple.com/design/human-interface-guidelines/alerts#Anatomy
        // (Confusingly, in 2025-10, it's center-aligned in the graphic at the
        // *top* of that page; shrug.)
        textAlign: TextAlign.start,
        child: content);
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
    builder: (BuildContext context) => AlertDialog.adaptive(
      title: Text(title),
      content: message != null ? _adaptiveContent(Text(message)) : null,
      actions: [
        _adaptiveAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          text: "continue"),
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
  bool destructiveActionButton = false,
}) {
  final future = showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog.adaptive(
      title: Text(title),
      content: message != null ? _adaptiveContent(Text(message)) : null,
      actions: [
        _adaptiveAction(
          onPressed: () => Navigator.pop<bool>(context, null),
          isDefaultAction: false,
          text: "cancel"),
        _adaptiveAction(
          onPressed: () => Navigator.pop<bool>(context, true),
          isDefaultAction: true,
          isDestructiveAction: destructiveActionButton,
          text: actionButtonText ?? "continue"),
      ]));
  return DialogStatus(future);
}
