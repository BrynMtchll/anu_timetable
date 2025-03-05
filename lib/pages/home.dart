import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(15),
      child: Column(
        children: [
          _profile(),
          SizedBox(height: 30),
          _upcomingClasses(),
          SizedBox(height: 30),
          _freinds()
        ]));
  }

  Column _freinds() {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
                  "Friends"),
                Text("plus icon")
              ]),
            SizedBox(height: 5),
            Column(
              children: [
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(5))),
                SizedBox(height: 5),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(5))),
                SizedBox(height: 5),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(5)))
              ]),
            SizedBox(height: 10),
            Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
                color: Colors.grey[20]),
              child: Align(
                alignment: Alignment.center,
                child: Text("See All Friends")))
          ]);
  }

  Column _upcomingClasses() {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20),
              "Upcoming Classes"),
            SizedBox(height: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(5))),
                SizedBox(height: 5),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(5))),
                SizedBox(height: 5),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(5)))
              ])
          ]);
  }

  Row _profile() {
    return Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(30))),
            Padding(
              padding: EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                    "Brynly Mitchell"),
                  Text("u7088495@anu.edu.au"),
                ]))
          ]);
  }
}