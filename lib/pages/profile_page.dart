

import 'package:anu_timetable/model/events.dart';
import 'package:anu_timetable/model/user.dart';
import 'package:anu_timetable/widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double panelWidth = 250;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<UserVM>(
      builder: (context, userVM, child)
        => Stack(
          children: [
            AnimatedPositioned(
              left:  isOpen ? -panelWidth : 0,
              duration: Duration(milliseconds: 200),
              child: _MainPage(screenWidth: screenWidth,
                onTap: () => setState(() => isOpen = !isOpen))),
            if (isOpen) 
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => isOpen = false))),
            AnimatedPositioned(
              left: isOpen ? screenWidth - panelWidth : screenWidth,
              duration: Duration(milliseconds: 200),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 1,
                      height: screenHeight,
                      color: colorScheme.surfaceContainerHighest),
                    _Drawer(panelWidth: panelWidth)
                  ]))
          ]));
  }
}

class _Drawer extends StatelessWidget {
  const _Drawer({
    required this.panelWidth,
  });

  final double panelWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(top: 70),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colorScheme.surfaceContainerHighest, width: 1)),
        ),
        padding: EdgeInsets.all(20),
        width: panelWidth,
        child: Consumer<UserVM>(
          builder: (context, userVM, child) {
            return Column(
              spacing: 20,
              children: [
                _SyncButton(userVM: userVM),
                _LogOutButton(userVM: userVM),
                _DeleteAccountButton(userVM: userVM),
              ]);
          })));
  }
}

class _MainPage extends StatelessWidget {
  const _MainPage({
    required this.screenWidth,
    required this.onTap
  });

  final double screenWidth;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(15),
        width: screenWidth,
        child: Column(
          spacing: 20,
            children: [
              _Details(onTap: onTap),
              _ClassList()
      ])));
  }
}

class _SyncButton extends StatelessWidget {
  const _SyncButton({required this.userVM});

  final UserVM userVM;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.push('/syncAnu'),
      child: Text("Sync With My Timetable", style: TextStyle(
        decorationColor: colorScheme.onSurface,
        fontWeight: FontWeight.w400,
        fontSize: 15, color: colorScheme.onSurface)));
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
          message: "Are you sure you want to log out?", actionButtonText: null, cancelIsPrimary: true).result;
        if (result != null) userVM.signOut.execute();
      },
      child: Text("Log Out", style: TextStyle(
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
          message: "Are you sure you want to delete your account? This action can't be undone", actionButtonText: null, cancelIsPrimary: true).result;
        if (result != null) userVM.deleteAccount.execute();
      },
      child: Text("Delete Account", style: TextStyle(
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

class _Details extends StatelessWidget {
  const _Details({required this.onTap});

  final VoidCallback onTap;

  String getInitials(String name) => name.isNotEmpty
    ? name.trim().split(RegExp(' +')).map((s) => s[0]).take(2).join() : '';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<UserVM>(
      builder: (context, userVM, child) {
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
            Expanded(
              child: Column(
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
                ]),
            ),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.menu,
                    color: colorScheme.onSurface))),
          ]);
      });
  }
}