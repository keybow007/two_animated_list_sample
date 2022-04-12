import 'package:flutter/material.dart';

class Item extends StatelessWidget {
  final String text;

  const Item({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: CircleAvatar(
        child: Text(text),
        radius: 24,
      ),
    );
  }
}