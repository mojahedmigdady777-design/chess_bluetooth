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
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<BluetoothManager>().startScan());
  }

  @override
  void dispose() { _radarController.dispose(); context.read<BluetoothManager>().stopScan(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<BluetoothManager>();
    return Scaffold(
      backgroundColor: ChessTheme.background,
      appBar: AppBar(title: const Text('البحث عن أجهزة'), actions: [IconButton(icon: Icon(bt.isScanning ? Icons.stop : Icons.search), onPressed: bt.isScanning ? bt.stopScan : bt.startScan)]),
      body: Column(children: [
        const SizedBox(height: 20),
        if (bt.isScanning) RotationTransition(turns: _radarController, child: const Icon(Icons.bluetooth_searching_rounded, color: Colors.white, size: 80)) else const Icon(Icons.bluetooth_disabled_rounded, color: Colors.white30, size: 80),
        const SizedBox(height: 16),
        Text(bt.lastError ?? (bt.isScanning ? 'جاري البحث عن خصوم قريبين...' : 'اضغط على بحث لبدء العثور على أجهزة'), style: TextStyle(color: bt.lastError == null ? Colors.white70 : Colors.redAccent), textAlign: TextAlign.center),
        const Divider(color: Colors.white24, height: 40),
        Expanded(child: bt.scanResults.isEmpty ? const Center(child: Text('لم يتم العثور على أجهزة بعد', style: TextStyle(color: Colors.white38))) : ListView.builder(itemCount: bt.scanResults.length, itemBuilder: (_, index) {
          final result = bt.scanResults[index];
          final name = result.device.platformName.isNotEmpty ? result.device.platformName : result.device.remoteId.toString();
          return Card(color: ChessTheme.primaryDark, margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: ListTile(leading: const Icon(Icons.bluetooth, color: Colors.blueAccent), title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text(result.device.remoteId.toString(), style: const TextStyle(color: Colors.white54)), trailing: ElevatedButton(onPressed: () async {
            showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
            final ok = await bt.connectToDevice(result.device);
            if (!context.mounted) return;
            Navigator.pop(context);
            if (ok) { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GamePage(isBluetoothMode: true))); } else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(bt.lastError ?? 'فشل الاتصال بالجهاز'))); }
          }, child: const Text('اتصال'))));
        }))
      ]),
    );
  }
}
