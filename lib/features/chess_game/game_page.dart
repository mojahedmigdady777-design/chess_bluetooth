// lib/features/chess_game/game_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'chess_logic.dart';
import '../../core/theme.dart';

class GamePage extends StatefulWidget {
  final bool isBluetoothMode;

  const GamePage({Key? key, required this.isBluetoothMode}) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  Timer? _gameTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chessLogic = Provider.of<ChessLogic>(context, listen: false);
      chessLogic.setupGame(
        bluetoothMode: widget.isBluetoothMode,
        playerColor: PlayerColor.white,
      );
      _startTimer();
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final chessLogic = Provider.of<ChessLogic>(context, listen: false);
      
      if (chessLogic.isGameOver) {
        _gameTimer?.cancel();
        _showGameOverDialog(chessLogic);
        return;
      }

      if (chessLogic.controller.game.turn == Chess.WHITE) {
        chessLogic.decreaseWhiteTime();
      } else {
        chessLogic.decreaseBlackTime();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showGameOverDialog(ChessLogic chessLogic) {
    String message = "انتهت اللعبة!";
    if (chessLogic.isCheckMate) {
      message = "كش ملك! انتهت المباراة بالفوز.";
    } else if (chessLogic.isDraw) {
      message = "تعادل!";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('نهاية المباراة', textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              chessLogic.resetGame();
              _startTimer();
            },
            child: const Text('إعادة اللعب'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('خروج للقائمة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chessLogic = Provider.of<ChessLogic>(context);

    return Scaffold(
      backgroundColor: ChessTheme.background,
      appBar: AppBar(
        title: Text(widget.isBluetoothMode ? 'مباراة بلوتوث' : 'مباراة محلية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              chessLogic.resetGame();
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildPlayerHeader(
              playerName: widget.isBluetoothMode ? 'الخصم (بلوتوث)' : 'اللاعب الأسود',
              time: _formatTime(chessLogic.blackTimeRemaining),
              avatarColor: Colors.black,
              textColor: Colors.white,
              isActive: chessLogic.controller.game.turn == Chess.BLACK,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ChessBoard(
                    controller: chessLogic.controller,
                    boardColor: BoardColor.brown,
                    boardWidth: MediaQuery.of(context).size.width - 24,
                    enableUserMoves: chessLogic.isMyTurn, 
                    onMove: () {
                      if (widget.isBluetoothMode) {
                        chessLogic.isMyTurn = false;
                      }
                    },
                  ),
                ),
              ),
            ),
            const Spacer(),
            _buildPlayerHeader(
              playerName: widget.isBluetoothMode ? 'أنت' : 'اللاعب الأبيض',
              time: _formatTime(chessLogic.whiteTimeRemaining),
              avatarColor: Colors.white,
              textColor: Colors.black,
              isActive: chessLogic.controller.game.turn == Chess.WHITE,
            ),
            _buildControlBar(chessLogic),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerHeader({
    String playerName = "new player",
    String time = "00:00",
    required Color avatarColor,
    required Color textColor,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: isActive ? Colors.black26 : Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: avatarColor,
                radius: 18,
                child: Icon(Icons.person, color: textColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                playerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? ChessTheme.accentGold : Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: isActive ? ChessTheme.primaryDark : Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: TextStyle(
                    color: isActive ? ChessTheme.primaryDark : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(ChessLogic chessLogic) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: ChessTheme.primaryDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white, size: 26),
            onPressed: widget.isBluetoothMode ? null : () => chessLogic.undoLastMove(),
            tooltip: 'تراجع (محلي فقط)',
          ),
          IconButton(
            icon: const Icon(Icons.flag, color: Colors.redAccent, size: 26),
            onPressed: () {
              _gameTimer?.cancel();
              _showGameOverDialog(chessLogic);
            },
            tooltip: 'استسلام',
          ),
        ],
      ),
    );
  }
}