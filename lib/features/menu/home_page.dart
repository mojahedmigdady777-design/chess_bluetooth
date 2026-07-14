// lib/features/menu/home_page.dart

import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../chess_game/game_page.dart';
import '../bluetooth/bluetooth_search_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ChessTheme.primaryDark,
              Color(0xFF2D1B10),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.grid_on,
                    size: 100,
                    color: ChessTheme.accentGold,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'شطرنج المحترفين',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'تحدى أصدقائك على نفس الجهاز أو عبر البلوتوث',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 60),

                  _buildMenuButton(
                    context: context,
                    title: 'لعب محلي (جهاز واحد)',
                    icon: Icons.people_rounded,
                    color: ChessTheme.accentGold,
                    textColor: ChessTheme.primaryDark,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GamePage(isBluetoothMode: false),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildMenuButton(
                    context: context,
                    title: 'لعب عبر البلوتوث',
                    icon: Icons.bluetooth_audio_rounded,
                    color: Colors.blue[700]!,
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BluetoothSearchPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}