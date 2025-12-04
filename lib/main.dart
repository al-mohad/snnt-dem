import 'package:flutter/material.dart';

import 'screens/reels_player_screen.dart';

void main() {
  runApp(const SinntsPlayerExampleApp());
}

class SinntsPlayerExampleApp extends StatelessWidget {
  const SinntsPlayerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SINNTS Timeline Player - Reels Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const ReelsPlayerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
