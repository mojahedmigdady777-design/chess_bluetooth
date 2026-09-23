// lib/features/chess_game/chess_logic.dart

import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

class ChessLogic extends ChangeNotifier {
  late final ChessBoardController controller;
  bool isBluetoothMode = false;
  bool isMyTurn = true;
  PlayerColor myColor = PlayerColor.white;
  List<String> moveHistory = <String>[];
  int whiteTimeRemaining = 600;
  int blackTimeRemaining = 600;

  ChessLogic() {
    controller = ChessBoardController();
    controller.addListener(() {
      _updateMoveHistory();
      notifyListeners();
    });
  }

  void _updateMoveHistory() {
    final pgn = controller.getSan().toString().trim();
    moveHistory = pgn.isEmpty
        ? <String>[]
        : pgn.replaceAll(RegExp(r'\d+\.\s*'), '').split(RegExp(r'\s+'));
  }

  void setupGame({required bool bluetoothMode, required PlayerColor playerColor}) {
    isBluetoothMode = bluetoothMode;
    myColor = playerColor;
    resetGame();
  }

  void resetGame() {
    controller.clearBoard();
    moveHistory = <String>[];
    whiteTimeRemaining = 600;
    blackTimeRemaining = 600;
    isMyTurn = !isBluetoothMode || myColor == PlayerColor.white;
    notifyListeners();
  }

  void makeOpponentMove(String from, String to) {
    if (!isBluetoothMode || isMyTurn) return;
    controller.makeMove(from: from, to: to);
    isMyTurn = true;
    notifyListeners();
  }

  void completeLocalMove() {
    if (isBluetoothMode) {
      isMyTurn = false;
      notifyListeners();
    }
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
    if (!isBluetoothMode) controller.undoMove();
  }

  bool get isClockExpired => whiteTimeRemaining == 0 || blackTimeRemaining == 0;
  bool get isGameOver => controller.isGameOver();
  bool get isCheckMate => controller.isCheckMate();
  bool get isDraw => controller.isDraw();
}
