// lib/features/bluetooth/bluetooth_search_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bluetooth_manager.dart';
import '../chess_game/game_page.dart';
import '../../core/theme.dart';

class BluetoothSearchPage extends StatefulWidget {
  const BluetoothSearchPage({Key? key}) : super(key: key);

  @override
  State<BluetoothSearchPage> createState() => _BluetoothSearchPageState();
}

class _BluetoothSearchPageState extends State<BluetoothSearchPage> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BluetoothManager>(context, listen: false).startScan();
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btManager = Provider.of<BluetoothManager>(context);

    return Scaffold(
      backgroundColor: ChessTheme.background,
      appBar: AppBar(
        title: const Text('البحث عن أجهزة'),
        actions: [
          IconButton(
            icon: Icon(btManager.isScanning ? Icons.stop : Icons.search),
            onPressed: () {
              if (btManager.isScanning) {
                btManager.stopScan();
              } else {
                btManager.startScan();
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          if (btManager.isScanning)
            Center(
              child: RotationTransition(
                turns: _radarController,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.blue.withOpacity(0.1),
                        Colors.blue.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bluetooth_searching_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            )
          else
            const Center(
              child: Icon(
                Icons.bluetooth_disabled_rounded,
                color: Colors.white30,
                size: 80,
              ),
            ),
          
          const SizedBox(height: 20),
          Text(
            btManager.isScanning ? 'جاري البحث عن خصوم قريبين...' : 'اضغط على بحث لبدء العثور على أجهزة',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const Divider(color: Colors.white24, height: 40),

          Expanded(
            child: btManager.scanResults.isEmpty
                ? const Center(
                    child: Text(
                      'لم يتم العثور على أجهزة بعد',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    itemCount: btManager.scanResults.length,
                    itemBuilder: (context, index) {
                      final result = btManager.scanResults[index];
                      final deviceName = result.device.platformName.isNotEmpty
                          ? result.device.platformName
                          : result.device.remoteId.toString();

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: ChessTheme.primaryDark,
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth, color: Colors.blueAccent),
                          title: Text(
                            deviceName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            result.device.remoteId.toString(),
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            onPressed: () async {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(child: CircularProgressIndicator()),
                              );

                              bool success = await btManager.connectToDevice(result.device);
                              
                              if (context.mounted) {
                                Navigator.pop(context);
                                if (success) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const GamePage(isBluetoothMode: true),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('فشل الاتصال للجهاز!')),
                                  );
                                }
                              }
                            },
                            child: const Text('اتصال'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}