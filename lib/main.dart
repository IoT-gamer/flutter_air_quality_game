// File: lib/main.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/ble_scanner_cubit.dart';
import 'game/air_monitor_game.dart';
import 'history_screen.dart';
import 'pollutant_guide_screen.dart';

void main() {
  runApp(
    BlocProvider(
      create: (context) => BleScannerCubit(),
      child: const PicoTimeSetterApp(),
    ),
  );
}

class PicoTimeSetterApp extends StatelessWidget {
  const PicoTimeSetterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pico SEN66 Air Quality',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: const BleScannerScreen(),
    );
  }
}

class BleScannerScreen extends StatefulWidget {
  const BleScannerScreen({super.key});

  @override
  State<BleScannerScreen> createState() => _BleScannerScreenState();
}

class _BleScannerScreenState extends State<BleScannerScreen> {
  late final AirMonitorGame _game;

  @override
  void initState() {
    super.initState();
    _game = AirMonitorGame(bleScannerCubit: context.read<BleScannerCubit>());
  }

  void _showSnackBar(BuildContext context, String message, bool isError) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BleScannerCubit>().state;
    final cubit = context.read<BleScannerCubit>();
    final isScanning = state.status == BleScannerStatus.scanning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pico SEN66 Air Quality'),
        actions: [
          if (state.connectedDevice != null && state.batteryLevel != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    Icon(
                      state.batteryLevel! > 20
                          ? Icons.battery_full
                          : Icons.battery_alert,
                      color: state.batteryLevel! > 20
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.batteryLevel}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Pollutant Guide',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PollutantGuideScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(isScanning ? Icons.stop_circle_outlined : Icons.search),
            onPressed: isScanning ? cubit.stopScan : cubit.startScan,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusDisplay(context, state),
          if (state.connectedDevice != null)
            _buildConnectedDeviceCard(context, state)
          else
            _buildScanResultList(context, state),
        ],
      ),
    );
  }

  Widget _buildStatusDisplay(BuildContext context, BleScannerState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Text(
        state.statusMessage,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildConnectedDeviceCard(
    BuildContext context,
    BleScannerState state,
  ) {
    final device = state.connectedDevice!;
    final cubit = context.read<BleScannerCubit>();

    return Expanded(
      child: SingleChildScrollView(
        child: Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  device.platformName.isNotEmpty
                      ? device.platformName
                      : "Unknown Device",
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                Text(
                  device.remoteId.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // --- SEN66 UNIFIED DATA GRID ---
                const Text(
                  "SEN66 Environmental Data",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _buildDataTile(
                      "PM 1.0",
                      state.pm1p0 != null ? "${state.pm1p0}" : "--",
                      "µg/m³",
                      Colors.purpleAccent,
                    ),
                    _buildDataTile(
                      "PM 2.5",
                      state.pm2p5 != null ? "${state.pm2p5}" : "--",
                      "µg/m³",
                      _getPmColor(state.pm2p5 ?? 0),
                    ),
                    _buildDataTile(
                      "PM 4.0",
                      state.pm4p0 != null ? "${state.pm4p0}" : "--",
                      "µg/m³",
                      Colors.blueAccent,
                    ),
                    _buildDataTile(
                      "PM 10.0",
                      state.pm10p0 != null ? "${state.pm10p0}" : "--",
                      "µg/m³",
                      Colors.teal,
                    ),
                    _buildDataTile(
                      "Temp",
                      state.temp != null
                          ? state.temp!.toStringAsFixed(1)
                          : "--",
                      "°C",
                      Colors.orangeAccent,
                    ),
                    _buildDataTile(
                      "Humidity",
                      state.hum != null ? state.hum!.toStringAsFixed(1) : "--",
                      "%",
                      Colors.cyan,
                    ),
                    _buildDataTile(
                      "VOC",
                      state.voc != null ? "${state.voc}" : "--",
                      "Index",
                      Colors.deepPurple,
                    ),
                    _buildDataTile(
                      "NOx",
                      state.nox != null ? "${state.nox}" : "--",
                      "Index",
                      Colors.redAccent,
                    ),
                    _buildDataTile(
                      "CO2",
                      state.co2 != null ? "${state.co2}" : "--",
                      "ppm",
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- GAME WIDGET ---
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BlocProvider.value(
                      value: context.read<BleScannerCubit>(),
                      child: GameWidget(game: _game),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- ACTIONS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: const Text('Sync Time'),
                      onPressed: () async {
                        final (success, msg) = await cubit.syncTime();
                        _showSnackBar(context, msg, !success);
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.analytics),
                      label: const Text('History'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<BleScannerCubit>(),
                              child: const HistoryScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: cubit.disconnect,
                  child: const Text('Disconnect'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTile(String label, String value, String unit, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: value == "--" ? Colors.grey : Colors.white,
            ),
          ),
          Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Color _getPmColor(int pm) {
    if (pm <= 12) return Colors.greenAccent;
    if (pm <= 35) return Colors.yellow;
    if (pm <= 55) return Colors.orange;
    return Colors.redAccent;
  }

  Widget _buildScanResultList(BuildContext context, BleScannerState state) {
    final cubit = context.read<BleScannerCubit>();

    if (state.status == BleScannerStatus.connecting) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }
    return Expanded(
      child: ListView.builder(
        itemCount: state.scanResults.length,
        itemBuilder: (context, index) {
          final result = state.scanResults[index];
          final deviceName = result.device.platformName.isNotEmpty
              ? result.device.platformName
              : "Unknown Device";
          return ListTile(
            leading: const Icon(Icons.bluetooth),
            title: Text(deviceName),
            subtitle: Text(result.device.remoteId.toString()),
            trailing: Text("${result.rssi} dBm"),
            onTap: () => cubit.connectToDevice(result.device),
          );
        },
      ),
    );
  }
}
