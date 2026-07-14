// lib/features/chess_game/chess_logic.dart

import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

class ChessLogic extends ChangeNotifier {
  late ChessBoardController controller;
  bool isBluetoothMode = false;
  bool isMyTurn = true;
  PlayerColor myColor = PlayerColor.white;
  List<String> moveHistory = [];
  int whiteTimeRemaining = 600;
  int blackTimeRemaining = 600;

  ChessLogic() {
    controller = ChessBoardController();
    _initListener();
  }

  void _initListener() {
    controller.addListener(() {
      _updateMoveHistory();
      notifyListeners();
    });
  }

  void _updateMoveHistory() {
    final String pgn = controller.getSan().toString();
    if (pgn.isNotEmpty) {
      moveHistory = pgn
          .replaceAll(RegExp(r'\d+\.\s*'), '')
          .trim()
          .split(' ')
          .where((move) => move.isNotEmpty)
          .toList();
    } else {
      moveHistory = [];
    }
  }

  void setupGame({required bool bluetoothMode, required PlayerColor playerColor}) {
    isBluetoothMode = bluetoothMode;
    myColor = playerColor;
    if (isBluetoothMode) {
      isMyTurn = (myColor == PlayerColor.white);
    } else {
      isMyTurn = true;
    }
    resetGame();
  }

  void resetGame() {
    controller.clearBoard();
    moveHistory = [];
    whiteTimeRemaining = 600;
    blackTimeRemaining = 600;
    if (isBluetoothMode) {
      isMyTurn = (myColor == PlayerColor.white);
    } else {
      isMyTurn = true;
    }
    notifyListeners();
  }

  void makeOpponentMove(String from, String to) {
    controller.makeMove(from: from, to: to);
    isMyTurn = true;
    notifyListeners();
  }

  void decreaseWhiteTime() {
    if (whiteTimeRemaining > 0) {
      whiteTimeRemaining--;
      notifyListeners();
    }
  }

  void decreaseBlackTime() {
    if (blackTimeRemaining > 0) {
      blackTimeRemaining--;
      notifyListeners();
    }
  }

  void undoLastMove() {
    if (!isBluetoothMode) {
      controller.undoMove();
      notifyListeners();
    }
  }

  bool get isGameOver => controller.isGameOver();
  bool get isCheckMate => controller.isCheckMate();
  bool get isDraw => controller.isDraw();
}