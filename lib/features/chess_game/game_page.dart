// lib/features/chess_game/game_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'chess_logic.dart';
import '../bluetooth/bluetooth_manager.dart';
import '../../core/theme.dart';

class GamePage extends StatefulWidget {
  final bool isBluetoothMode;
  const GamePage({Key? key, required this.isBluetoothMode}) : super(key: key);
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  Timer? _gameTimer;
  StreamSubscription<String>? _moveSubscription;
  bool _gameOverDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final logic = context.read<ChessLogic>();
      logic.setupGame(bluetoothMode: widget.isBluetoothMode, playerColor: PlayerColor.white);
      if (widget.isBluetoothMode) {
        _moveSubscription = context.read<BluetoothManager>().incomingMoves.listen((data) {
          final parts = data.split('-');
          if (parts.length == 2 && mounted) logic.makeOpponentMove(parts[0], parts[1]);
        });
      }
      _startTimer();
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _moveSubscription?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final logic = context.read<ChessLogic>();
      if (logic.isGameOver || logic.isClockExpired) {
        _gameTimer?.cancel();
        if (!_gameOverDialogShown) _showGameOverDialog(logic);
        return;
      }
      if (logic.controller.game.turn == Chess.WHITE) {
        logic.decreaseWhiteTime();
      } else {
        logic.decreaseBlackTime();
      }
    });
  }

  void _onMove() {
    final logic = context.read<ChessLogic>();
    if (!widget.isBluetoothMode || !logic.isMyTurn) return;
    final history = logic.controller.game.history;
    if (history.isEmpty) return;
    final move = history.last.toString();
    if (move.length >= 4) {
      context.read<BluetoothManager>().sendMove(move.substring(0, 2), move.substring(2, 4));
      logic.completeLocalMove();
    }
  }

  String _formatTime(int seconds) => '${seconds ~/ 60}'.padLeft(2, '0') + ':${(seconds % 60).toString().padLeft(2, '0')}';

  void _showGameOverDialog(ChessLogic logic) {
    if (!mounted || _gameOverDialogShown) return;
    _gameOverDialogShown = true;
    final message = logic.isClockExpired ? 'انتهى الوقت!' : logic.isCheckMate ? 'كش ملك! انتهت المباراة بالفوز.' : logic.isDraw ? 'تعادل!' : 'انتهت اللعبة!';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('نهاية المباراة', textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _gameOverDialogShown = false; logic.resetGame(); _startTimer(); }, child: const Text('إعادة اللعب')),
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('خروج للقائمة')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<ChessLogic>();
    return Scaffold(
      backgroundColor: ChessTheme.background,
      appBar: AppBar(title: Text(widget.isBluetoothMode ? 'مباراة بلوتوث' : 'مباراة محلية'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => logic.resetGame())]),
      body: SafeArea(child: Column(children: [
        _buildPlayerHeader(playerName: widget.isBluetoothMode ? 'الخصم (بلوتوث)' : 'اللاعب الأسود', time: _formatTime(logic.blackTimeRemaining), avatarColor: Colors.black, textColor: Colors.white, isActive: logic.controller.game.turn == Chess.BLACK),
        const Spacer(),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: ChessBoard(controller: logic.controller, boardColor: BoardColor.brown, boardWidth: MediaQuery.of(context).size.width - 24, enableUserMoves: logic.isMyTurn, onMove: _onMove))),
        const Spacer(),
        _buildPlayerHeader(playerName: widget.isBluetoothMode ? 'أنت' : 'اللاعب الأبيض', time: _formatTime(logic.whiteTimeRemaining), avatarColor: Colors.white, textColor: Colors.black, isActive: logic.controller.game.turn == Chess.WHITE),
        Container(padding: const EdgeInsets.symmetric(vertical: 12), color: ChessTheme.primaryDark, child: IconButton(icon: const Icon(Icons.undo, color: Colors.white, size: 26), onPressed: widget.isBluetoothMode ? null : logic.undoLastMove, tooltip: 'تراجع (محلي فقط)'),),
      ])),
    );
  }

  Widget _buildPlayerHeader({required String playerName, required String time, required Color avatarColor, required Color textColor, required bool isActive}) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: isActive ? Colors.black26 : Colors.transparent, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [CircleAvatar(backgroundColor: avatarColor, radius: 18, child: Icon(Icons.person, color: textColor, size: 20)), const SizedBox(width: 12), Text(playerName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: isActive ? ChessTheme.accentGold : Colors.black54, borderRadius: BorderRadius.circular(6)), child: Text(time, style: TextStyle(color: isActive ? ChessTheme.primaryDark : Colors.white, fontWeight: FontWeight.bold)))]));
}
