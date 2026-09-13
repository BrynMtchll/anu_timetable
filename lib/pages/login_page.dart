import 'package:anu_timetable/model/user.dart';
import 'package:anu_timetable/widgets/button.dart';
import 'package:anu_timetable/widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_timetable/util/result.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 50, horizontal: 30),
          child: Center(
            child: Column(
              spacing: 20,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Welcome", style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 30,
                  fontWeight: FontWeight.w600)),
                Text("Please sign in using your ANU student email.",
                  style: TextStyle(fontSize: 15)),
                Consumer<UserVM>(
                  builder: (context, userVM, child) => 
                    CustomButton(
                      text: "Sign In",
                      isPrimary: true,
                      onPressed: () async {
                        await userVM.signInWithMicrosoft.execute();
                        if (userVM.signInWithMicrosoft.error && context.mounted) {
                          showErrorDialog(context: context,
                            title: (userVM.signInWithMicrosoft.result! as Error).error.toString());
                      }
                    })),
                    Text("You will be prompted to do this twice. The second time is to connect to your MyTimetable.",
                    style: TextStyle(fontSize: 15))
              ])))));
  }
}
