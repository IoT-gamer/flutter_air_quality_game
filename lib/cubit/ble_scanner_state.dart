part of 'ble_scanner_cubit.dart';

enum BleScannerStatus {
  initial,
  permissionsGranted,
  permissionsDenied,
  scanning,
  scanFinished,
  connecting,
  connected,
  error,
}

class BleScannerState extends Equatable {
  final BleScannerStatus status;
  final List<ScanResult> scanResults;
  final BluetoothDevice? connectedDevice;
  final String statusMessage;
  final bool isLoading;
  final List<String> logLines;

  // SEN66 Live Data Fields
  final int? pm1p0;
  final int? pm2p5;
  final int? pm4p0;
  final int? pm10p0;
  final double? temp;
  final double? hum;
  final int? voc;
  final int? nox;
  final int? co2;

  const BleScannerState({
    this.status = BleScannerStatus.initial,
    this.scanResults = const [],
    this.connectedDevice,
    this.statusMessage = "Requesting permissions...",
    this.isLoading = false,
    this.logLines = const [],
    this.pm1p0,
    this.pm2p5,
    this.pm4p0,
    this.pm10p0,
    this.temp,
    this.hum,
    this.voc,
    this.nox,
    this.co2,
  });

  BleScannerState copyWith({
    BleScannerStatus? status,
    List<ScanResult>? scanResults,
    BluetoothDevice? Function()? connectedDevice,
    String? statusMessage,
    bool? isLoading,
    List<String>? logLines,
    int? pm1p0,
    int? pm2p5,
    int? pm4p0,
    int? pm10p0,
    double? temp,
    double? hum,
    int? voc,
    int? nox,
    int? co2,
  }) {
    return BleScannerState(
      status: status ?? this.status,
      scanResults: scanResults ?? this.scanResults,
      connectedDevice: connectedDevice != null
          ? connectedDevice()
          : this.connectedDevice,
      statusMessage: statusMessage ?? this.statusMessage,
      isLoading: isLoading ?? this.isLoading,
      logLines: logLines ?? this.logLines,
      pm1p0: pm1p0 ?? this.pm1p0,
      pm2p5: pm2p5 ?? this.pm2p5,
      pm4p0: pm4p0 ?? this.pm4p0,
      pm10p0: pm10p0 ?? this.pm10p0,
      temp: temp ?? this.temp,
      hum: hum ?? this.hum,
      voc: voc ?? this.voc,
      nox: nox ?? this.nox,
      co2: co2 ?? this.co2,
    );
  }

  @override
  List<Object?> get props => [
    status,
    scanResults,
    connectedDevice,
    statusMessage,
    isLoading,
    logLines,
    pm1p0,
    pm2p5,
    pm4p0,
    pm10p0,
    temp,
    hum,
    voc,
    nox,
    co2,
  ];
}
