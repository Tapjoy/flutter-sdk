import 'package:flutter/material.dart';
import 'navigation_widget.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

void main() {
  runApp(const App());
}
