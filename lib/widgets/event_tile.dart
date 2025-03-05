import 'package:flutter/material.dart';

class EventTile extends StatelessWidget {
  final Size size;

  const EventTile({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 0.5),
        borderRadius: BorderRadius.all(Radius.circular(8)),
        color: ColorScheme.of(context).surfaceContainer),
      width: size.width,
      height: size.height,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600), "Hi"),
          Text(style: TextStyle(fontSize: 12), "Hey")
        ]));
  }
}
