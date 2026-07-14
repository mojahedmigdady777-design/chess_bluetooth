// lib/features/bluetooth/bluetooth_manager.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager extends ChangeNotifier {
  bool isScanning = false;
  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? txCharacteristic;
  BluetoothCharacteristic? rxCharacteristic;

  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String charactersticUuidTx = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String charactersticUuidRx = "d6ee5536-e810-449d-a481-799b66236319";

  StreamSubscription? scanSubscription;

  BluetoothManager() {
    FlutterBluePlus.isScanning.listen((scanning) {
      isScanning = scanning;
      notifyListeners();
    });
  }

  void startScan() async {
    scanResults.clear();
    notifyListeners();

    if (await FlutterBluePlus.isSupported == false) {
      return;
    }

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    scanSubscription?.cancel();
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      stopScan();
      await device.connect();
      connectedDevice = device;
      notifyListeners();

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString() == serviceUuid) {
          for (var char in service.characteristics) {
            if (char.uuid.toString() == charactersticUuidTx) {
              txCharacteristic = char;
            }
            if (char.uuid.toString() == charactersticUuidRx) {
              rxCharacteristic = char;
              await rxCharacteristic!.setNotifyValue(true);
            }
          }
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> sendMove(String from, String to) async {
    if (txCharacteristic != null) {
      String moveData = "$from-$to";
      List<int> bytes = utf8.encode(moveData);
      await txCharacteristic!.write(bytes);
    }
  }

  Stream<String>? get incomingMoves {
    return rxCharacteristic?.onValueReceived.map((bytes) {
      return utf8.decode(bytes);
    });
  }

  void disconnect() async {
    await connectedDevice?.disconnect();
    connectedDevice = null;
    txCharacteristic = null;
    rxCharacteristic = null;
    notifyListeners();
  }
}