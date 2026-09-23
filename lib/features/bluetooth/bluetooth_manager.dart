// lib/features/bluetooth/bluetooth_manager.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager extends ChangeNotifier {
  bool isScanning = false;
  List<ScanResult> scanResults = <ScanResult>[];
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? txCharacteristic;
  BluetoothCharacteristic? rxCharacteristic;
  String? lastError;

  static const String serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String characteristicUuidTx = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
  static const String characteristicUuidRx = 'd6ee5536-e810-449d-a481-799b66236319';

  StreamSubscription<bool>? _scanningSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  final StreamController<String> _incomingMovesController =
      StreamController<String>.broadcast();

  BluetoothManager() {
    _scanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
      isScanning = scanning;
      notifyListeners();
    });
  }

  Future<void> startScan() async {
    lastError = null;
    scanResults = <ScanResult>[];
    notifyListeners();

    try {
      if (!await FlutterBluePlus.isSupported) {
        throw StateError('البلوتوث غير مدعوم على هذا الجهاز');
      }

      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        throw StateError('فعّل البلوتوث ثم حاول البحث مرة أخرى');
      }

      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
        // Keep the strongest result for each device instead of adding duplicates.
        final byId = <String, ScanResult>{
          for (final result in scanResults) result.device.remoteId.toString(): result,
        };
        for (final result in results) {
          byId[result.device.remoteId.toString()] = result;
        }
        scanResults = byId.values.toList();
        notifyListeners();
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );
    } catch (error) {
      lastError = error.toString().replaceFirst('StateError: ', '');
      isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await stopScan();
      await _connectionSubscription?.cancel();
      await device.connect(timeout: const Duration(seconds: 15), autoConnect: false);
      connectedDevice = device;
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          connectedDevice = null;
          txCharacteristic = null;
          rxCharacteristic = null;
          notifyListeners();
        }
      });

      final services = await device.discoverServices();
      final service = services.cast<BluetoothService?>().firstWhere(
            (item) => item!.uuid.str128.toLowerCase() == serviceUuid,
            orElse: () => null,
          );
      if (service == null) throw StateError('خدمة الشطرنج غير موجودة على الجهاز');

      for (final characteristic in service.characteristics) {
        final uuid = characteristic.uuid.str128.toLowerCase();
        if (uuid == characteristicUuidTx) txCharacteristic = characteristic;
        if (uuid == characteristicUuidRx) rxCharacteristic = characteristic;
      }
      if (txCharacteristic == null || rxCharacteristic == null) {
        throw StateError('خصائص إرسال واستقبال الشطرنج غير موجودة');
      }

      await rxCharacteristic!.setNotifyValue(true);
      rxCharacteristic!.onValueReceived.listen((bytes) {
        final value = utf8.decode(bytes, allowMalformed: false).trim();
        if (value.isNotEmpty) _incomingMovesController.add(value);
      });
      notifyListeners();
      return true;
    } catch (error) {
      lastError = error.toString().replaceFirst('StateError: ', '');
      await disconnect();
      return false;
    }
  }

  Future<void> sendMove(String from, String to) async {
    final characteristic = txCharacteristic;
    if (characteristic == null) throw StateError('لا يوجد اتصال بلوتوث');
    await characteristic.write(
      utf8.encode('$from-$to\n'),
      withoutResponse: characteristic.properties.writeWithoutResponse,
    );
  }

  Stream<String> get incomingMoves => _incomingMovesController.stream;

  Future<void> disconnect() async {
    await connectedDevice?.disconnect();
    connectedDevice = null;
    txCharacteristic = null;
    rxCharacteristic = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanningSubscription?.cancel();
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _incomingMovesController.close();
    super.dispose();
  }
}
