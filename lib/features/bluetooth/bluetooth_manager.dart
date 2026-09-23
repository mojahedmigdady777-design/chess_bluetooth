// lib/features/bluetooth/bluetooth_manager.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothManager extends ChangeNotifier {
  bool isScanning = false;
  List<ScanResult> scanResults = <ScanResult>[];
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? txCharacteristic;
  BluetoothCharacteristic? rxCharacteristic;
  String? lastError;

  static const serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const txUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
  static const rxUuid = 'd6ee5536-e810-449d-a481-799b66236319';

  StreamSubscription<bool>? _scanningSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;
  final _incomingMoves = StreamController<String>.broadcast();
  String _receiveBuffer = '';

  BluetoothManager() {
    _scanningSubscription = FlutterBluePlus.isScanning.listen((value) {
      isScanning = value;
      notifyListeners();
    });
  }

  Future<bool> _requestPermissions() async {
    final permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      if (await Permission.location.isGranted == false) Permission.location,
    ];
    final statuses = await permissions.request();
    final scanOk = statuses[Permission.bluetoothScan]?.isGranted ?? true;
    final connectOk = statuses[Permission.bluetoothConnect]?.isGranted ?? true;
    final locationOk = statuses[Permission.location]?.isGranted ?? true;
    if (!scanOk || !connectOk || !locationOk) {
      lastError = 'يجب السماح بصلاحيات البلوتوث والموقع للبحث عن الأجهزة';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> startScan() async {
    lastError = null;
    scanResults = <ScanResult>[];
    notifyListeners();
    try {
      if (!await FlutterBluePlus.isSupported) throw StateError('البلوتوث غير مدعوم');
      if (!await _requestPermissions()) return;
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        throw StateError('فعّل البلوتوث ثم حاول مرة أخرى');
      }
      await stopScan();
      _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
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
      lastError = null;
      if (!await _requestPermissions()) return false;
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
      BluetoothService? service;
      for (final candidate in services) {
        if (candidate.uuid.str128.toLowerCase() == serviceUuid) {
          service = candidate;
          break;
        }
      }
      if (service == null) throw StateError('خدمة الشطرنج غير موجودة على الجهاز');

      for (final characteristic in service.characteristics) {
        final uuid = characteristic.uuid.str128.toLowerCase();
        if (uuid == txUuid) txCharacteristic = characteristic;
        if (uuid == rxUuid) rxCharacteristic = characteristic;
      }
      if (txCharacteristic == null || rxCharacteristic == null) {
        throw StateError('خصائص الإرسال والاستقبال غير موجودة');
      }
      await rxCharacteristic!.setNotifyValue(true);
      await _notificationSubscription?.cancel();
      _notificationSubscription = rxCharacteristic!.onValueReceived.listen(_handleBytes);
      notifyListeners();
      return true;
    } catch (error) {
      lastError = error.toString().replaceFirst('StateError: ', '');
      await disconnect();
      return false;
    }
  }

  void _handleBytes(List<int> bytes) {
    _receiveBuffer += utf8.decode(bytes, allowMalformed: true);
    final lines = _receiveBuffer.split('\n');
    _receiveBuffer = lines.removeLast();
    for (final line in lines) {
      final value = line.trim();
      if (RegExp(r'^[a-h][1-8]-[a-h][1-8]$').hasMatch(value)) {
        _incomingMoves.add(value);
      }
    }
    // Also support peripherals that do not append a newline.
    final value = _receiveBuffer.trim();
    if (RegExp(r'^[a-h][1-8]-[a-h][1-8]$').hasMatch(value)) {
      _incomingMoves.add(value);
      _receiveBuffer = '';
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

  Stream<String> get incomingMoves => _incomingMoves.stream;

  Future<void> disconnect() async {
    await _notificationSubscription?.cancel();
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
    _notificationSubscription?.cancel();
    _incomingMoves.close();
    super.dispose();
  }
}
