import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

part 'ble_scanner_state.dart';

// --- Pico Datalogger BLE Definitions ---
final Guid picoServiceUuid = Guid("0000aaa0-0000-1000-8000-00805f9b34fb");
final Guid picoTimeCharUuid = Guid("0000aaa1-0000-1000-8000-00805f9b34fb");
final Guid picoCommandCharUuid = Guid("0000aaa2-0000-1000-8000-00805f9b34fb");
final Guid picoDataCharUuid = Guid("0000aaa3-0000-1000-8000-00805f9b34fb");
final Guid picoSen66CharUuid = Guid(
  "0000aaa4-0000-1000-8000-00805f9b34fb",
); // Unified SEN66
final Guid picoBatteryCharUuid = Guid("0000aaa5-0000-1000-8000-00805f9b34fb");
// -----------------------------------------

class BleScannerCubit extends Cubit<BleScannerState> {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  BluetoothDevice? _internalDeviceRef;

  // --- CHARACTERISTIC REFS ---
  BluetoothCharacteristic? _timeCharacteristic;
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _dataCharacteristic;
  BluetoothCharacteristic? _liveSen66Characteristic;
  BluetoothCharacteristic? _batteryCharacteristic;

  // --- DATA STREAMING ---
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<List<int>>? _liveSen66Subscription;
  StreamSubscription<List<int>>? _batterySubscription;

  final List<int> _dataBuffer = [];
  final List<String> _tempLogBuffer = [];

  BleScannerCubit() : super(const BleScannerState()) {
    requestPermissions();
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    _dataSubscription?.cancel();
    _liveSen66Subscription?.cancel();
    _internalDeviceRef?.disconnect();
    return super.close();
  }

  Future<void> requestPermissions() async {
    emit(
      state.copyWith(
        status: BleScannerStatus.initial,
        statusMessage: "Requesting permissions...",
      ),
    );

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted) {
      emit(
        state.copyWith(
          status: BleScannerStatus.permissionsGranted,
          statusMessage: "Ready to scan. Press the scan icon.",
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: BleScannerStatus.permissionsDenied,
          statusMessage: "Permissions not granted.",
        ),
      );
    }
  }

  void startScan() {
    emit(
      state.copyWith(
        status: BleScannerStatus.scanning,
        scanResults: [],
        statusMessage: "Scanning for 'SEN66 Logger'...",
      ),
    );

    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen(
      _onScanResults,
      onError: (e) => emit(
        state.copyWith(
          status: BleScannerStatus.error,
          statusMessage: "Scan Error: $e",
        ),
      ),
    );

    FlutterBluePlus.startScan(
      withServices: [picoServiceUuid],
      timeout: const Duration(seconds: 15),
    );
  }

  void _onScanResults(List<ScanResult> results) {
    final filteredResults = results
        .where(
          (r) =>
              r.device.platformName.contains('SEN66 Logger') &&
              r.advertisementData.serviceUuids.contains(picoServiceUuid),
        )
        .toList();

    if (filteredResults.isEmpty && state.scanResults.isNotEmpty) return;

    String msg = state.statusMessage;
    if (state.status == BleScannerStatus.scanning) {
      msg = filteredResults.isEmpty
          ? "Scanning... No loggers found yet."
          : "Found logger! Tap to connect.";
    }
    emit(state.copyWith(scanResults: filteredResults, statusMessage: msg));
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();

    if (state.status == BleScannerStatus.scanning) {
      emit(
        state.copyWith(
          status: BleScannerStatus.scanFinished,
          statusMessage: "Scan stopped.",
        ),
      );
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (state.status == BleScannerStatus.connecting) return;

    emit(
      state.copyWith(
        status: BleScannerStatus.connecting,
        statusMessage: "Connecting to ${device.platformName}...",
      ),
    );

    try {
      stopScan();
      await device.connect(timeout: const Duration(seconds: 10));
      emit(state.copyWith(statusMessage: "Discovering services..."));

      List<BluetoothService> services = await device.discoverServices();

      BluetoothCharacteristic? foundTime,
          foundCmd,
          foundData,
          foundSen66,
          foundBattery;

      for (var service in services) {
        if (service.uuid == picoServiceUuid) {
          for (var char in service.characteristics) {
            if (char.uuid == picoTimeCharUuid) {
              foundTime = char;
            } else if (char.uuid == picoCommandCharUuid) {
              foundCmd = char;
            } else if (char.uuid == picoDataCharUuid) {
              foundData = char;
            } else if (char.uuid == picoSen66CharUuid) {
              foundSen66 = char;
            } else if (char.uuid == picoBatteryCharUuid) {
              foundBattery = char;
            }
          }
        }
      }

      if (foundTime != null &&
          foundCmd != null &&
          foundData != null &&
          foundSen66 != null &&
          foundBattery != null) {
        _internalDeviceRef = device;

        _timeCharacteristic = foundTime;
        _commandCharacteristic = foundCmd;
        _dataCharacteristic = foundData;
        _liveSen66Characteristic = foundSen66;
        _batteryCharacteristic = foundBattery;

        _startLiveSen66Subscription();
        _startBatterySubscription();

        emit(
          state.copyWith(
            status: BleScannerStatus.connected,
            connectedDevice: () => device,
            statusMessage: "Connected to ${device.platformName}!",
            scanResults: [],
          ),
        );

        // Auto Sync Time
        await syncTime();
      } else {
        await device.disconnect();
        emit(
          state.copyWith(
            status: BleScannerStatus.error,
            statusMessage: "Failed: Missing required characteristics.",
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: BleScannerStatus.error,
          statusMessage: "Connection Error: $e",
        ),
      );
    }
  }

  // --- LIVE SEN66 DATA ---
  void _startLiveSen66Subscription() async {
    if (_liveSen66Characteristic == null) return;

    await _liveSen66Subscription?.cancel();
    await _liveSen66Characteristic!.setNotifyValue(true);

    _liveSen66Subscription = _liveSen66Characteristic!.onValueReceived.listen(
      (chunk) {
        // Payload: 9 values * 2 bytes = 18 bytes
        if (chunk.length >= 18) {
          final view = ByteData.view(Uint8List.fromList(chunk).buffer);

          emit(
            state.copyWith(
              pm1p0: view.getUint16(0, Endian.little),
              pm2p5: view.getUint16(2, Endian.little),
              pm4p0: view.getUint16(4, Endian.little),
              pm10p0: view.getUint16(6, Endian.little),
              // Sensirion specific scaling logic applied directly
              hum: view.getInt16(8, Endian.little) / 100.0,
              temp: view.getInt16(10, Endian.little) / 200.0,
              voc: view.getInt16(12, Endian.little),
              nox: view.getInt16(14, Endian.little),
              co2: view.getUint16(16, Endian.little),
            ),
          );
        }
      },
      onError: (e) =>
          emit(state.copyWith(statusMessage: "SEN66 Stream Error: $e")),
    );
  }

  // --- BATTERY DATA ---
  void _startBatterySubscription() async {
    if (_batteryCharacteristic == null) return;
    await _batterySubscription?.cancel();
    await _batteryCharacteristic!.setNotifyValue(true);

    _batterySubscription = _batteryCharacteristic!.onValueReceived.listen((
      chunk,
    ) {
      // Payload: 1 byte (uint8)
      if (chunk.isNotEmpty) {
        emit(state.copyWith(batteryLevel: chunk[0]));
      }
    }, onError: (e) => print("Battery Stream Error: $e"));
  }

  // --- TIME SYNC ---
  Future<(bool, String)> syncTime() async {
    if (_timeCharacteristic == null) return (false, "Not connected");

    try {
      DateTime now = DateTime.now();
      Uint8List data = Uint8List(7);
      ByteData.view(data.buffer).setUint16(0, now.year, Endian.little);
      data[2] = now.month;
      data[3] = now.day;
      data[4] = now.hour;
      data[5] = now.minute;
      data[6] = now.second;
      await _timeCharacteristic!.write(data, withoutResponse: true);

      return (true, "Time Synced: ${now.toIso8601String()}");
    } catch (e) {
      return (false, "Sync Error: $e");
    }
  }

  // --- FILE STREAMING ---
  void _handleDataChunk(List<int> chunk) {
    _dataBuffer.addAll(chunk);

    String data = String.fromCharCodes(_dataBuffer);

    if (data.contains(r'$$EOT$$')) {
      String finalData = data.replaceAll(r'$$EOT$$', '');
      _processBufferLines(finalData, isEot: true);
      _cleanupDataStream();
      return;
    }

    int lastNewline = data.lastIndexOf('\n');

    if (lastNewline != -1) {
      String complete = data.substring(0, lastNewline);
      String partial = data.substring(lastNewline + 1);

      _processBufferLines(complete, isEot: false);
      _dataBuffer.clear();
      _dataBuffer.addAll(partial.codeUnits);
    }
  }

  void _processBufferLines(String data, {bool isEot = false}) {
    if (data.isEmpty && !isEot) return;

    final lines = data.split('\n').where((l) => l.isNotEmpty).toList();
    _tempLogBuffer.addAll(lines);

    if (isEot) {
      emit(
        state.copyWith(
          logLines: List.from(_tempLogBuffer),
          isLoading: false,
          statusMessage: "File received! (${_tempLogBuffer.length} lines)",
        ),
      );
      _tempLogBuffer.clear();
    }
  }

  void _cleanupDataStream() {
    _dataBuffer.clear();
    _dataSubscription?.cancel();
    _dataSubscription = null;
    _dataCharacteristic?.setNotifyValue(false);
  }

  Future<void> requestLogFile(String filename) async {
    if (_commandCharacteristic == null) return;

    _cleanupDataStream();
    _tempLogBuffer.clear();

    emit(
      state.copyWith(
        isLoading: true,
        logLines: [],
        statusMessage: "Requesting $filename...",
      ),
    );

    try {
      await _dataCharacteristic!.setNotifyValue(true);
      _dataSubscription = _dataCharacteristic!.onValueReceived.listen(
        _handleDataChunk,
        onError: (e) => emit(
          state.copyWith(isLoading: false, statusMessage: "Stream Error: $e"),
        ),
      );

      final cmd = "GET:$filename";
      await _commandCharacteristic!.write(cmd.codeUnits, withoutResponse: true);
    } catch (e) {
      emit(state.copyWith(isLoading: false, statusMessage: "Req Error: $e"));
    }
  }

  Future<void> disconnect() async {
    _cleanupDataStream();
    await _liveSen66Subscription?.cancel();
    await _batterySubscription?.cancel();
    await _internalDeviceRef?.disconnect();

    _internalDeviceRef = null;
    _timeCharacteristic = null;
    _liveSen66Characteristic = null;
    _commandCharacteristic = null;
    _dataCharacteristic = null;
    _batteryCharacteristic = null;

    emit(
      state.copyWith(
        status: BleScannerStatus.permissionsGranted,
        connectedDevice: () => null,
        statusMessage: "Disconnected.",
        isLoading: false,
        logLines: [],
        pm1p0: 0,
        pm2p5: 0,
        pm4p0: 0,
        pm10p0: 0,
        temp: 0.0,
        hum: 0.0,
        voc: 0,
        nox: 0,
        co2: 0,
        batteryLevel: null,
      ),
    );
  }
}
