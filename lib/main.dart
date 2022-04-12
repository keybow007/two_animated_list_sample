import 'package:flutter/material.dart';

import 'home_screen.dart';

/*
* This task can be broken into 2 parts.
*
* First, use an AnimatedList instead of a regular ListView,
* so that when an item is removed, you can control its "exit animation" and shrink its size,
* thus making other items slowly move upwards to fill in its spot.
*
* Secondly, while the item is being removed from the first list,
* make an OverlayEntry and animate its position, to create an illusion of the item flying.
* Once the flying is finished, we can remove the overlay and insert the item in the actual destination list.
*
* */

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}




