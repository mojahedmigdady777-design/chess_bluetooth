// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'features/menu/home_page.dart';
import 'features/chess_game/chess_logic.dart';
import 'features/bluetooth/bluetooth_manager.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChessLogic()),
        ChangeNotifierProvider(create: (_) => BluetoothManager()),
      ],
      child: const ChessApp(),
    ),
  );
}

class ChessApp extends StatelessWidget {
  const ChessApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'شطرنج المحترفين',
      theme: ChessTheme.themeData,
      home: const HomePage(),
    );
  }
}