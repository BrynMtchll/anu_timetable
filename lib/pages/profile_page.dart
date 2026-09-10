

import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/model/user.dart';
import 'package:anu_timetable/widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Consumer<UserVM>(
        builder: (context, userVM, child)
          => Container(
            padding: EdgeInsets.all(15),
            child: Column(
              spacing: 20,
                children: [
                  _Details(userVM: userVM),
                  _ClassList(),
                  _SyncButton(),
                  _LogOutButton(userVM: userVM),
                  _DeleteAccountButton(userVM: userVM),
            ]))));
  }
}

class _LogOutButton extends StatelessWidget {
  const _LogOutButton({required this.userVM});

  final UserVM userVM;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        final result = await showSuggestedActionDialog(context: context, title: "Log Out",
          message: "Are you sure you want to log out?", actionButtonText: null).result;
        if (result != null) userVM.signOut.execute();
      },
      child: Text("Log out", style: TextStyle(
        decoration: TextDecoration.underline,
        decorationColor: colorScheme.onSurface,
        fontWeight: FontWeight.w400,
        fontSize: 15, color: colorScheme.onSurface)));
  }
}
class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton({required this.userVM});

  final UserVM userVM;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        final result = await showSuggestedActionDialog(context: context, title: "Delete Account",
          message: "Are you sure you want to delete your account? This action can't be undone", actionButtonText: null).result;
        if (result != null) userVM.deleteAccount.execute();
      },
      child: Text("Delete Account", style: TextStyle(
        decoration: TextDecoration.underline,
        decorationColor: colorScheme.error,
        fontWeight: FontWeight.w400,
        fontSize: 15, color: colorScheme.error)));
  }
}

class _ClassList extends StatelessWidget {
  const _ClassList();

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Text("Your Classes",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: colorScheme.onSurface)),
        Consumer<UserEventsVM>(
          builder: (context, userEventsVM, child) {
            final classes = userEventsVM.getClasses();
            return Column(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (title, summary) in classes)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(title, 
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                      Text(summary, style: TextStyle(fontSize: 12))
                    ])
              ]);
            })
      ]));
  }
}

class _SyncButton extends StatelessWidget {
  const _SyncButton();

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.push('/syncAnu'),
      child: Center(
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            border: BoxBorder.all(color: colorScheme.onSurface, width: 0.4),
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(30)),
          child: Center(
            child: Text(
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 15),
                "Sync With MyTimetable")))));
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.userVM});

  final UserVM userVM;

  String getInitials(String name) => name.isNotEmpty
    ? name.trim().split(RegExp(' +')).map((s) => s[0]).take(2).join() : '';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      spacing: 20,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: colorScheme.surfaceContainerHigh),
          child: Center(
            child: Text(
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 25),
              getInitials(userVM.currentUser?.displayName ?? '')))),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18),
              userVM.currentUser?.displayName ?? ''),
            Text(
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 15),
              userVM.currentUser?.email ?? ''),
          ])
      ]);
  }
}