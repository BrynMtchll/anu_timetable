import 'package:flutter/material.dart';
import 'package:anu_timetable/pages/dummy.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
        margin: const EdgeInsets.all(8.0),
        child: TextButton(onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const DummyPage())
          );
        }, child: Text("button"))
      );
  }
}