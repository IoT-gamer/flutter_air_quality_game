import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';

import '../cubit/ble_scanner_cubit.dart';
import 'air_monitor_game.dart';
import 'components/air_monitor_background.dart';
import 'components/sensor_spawn_manager.dart';

class AirMonitorWorld extends World with HasGameReference<AirMonitorGame> {
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await add(AirMonitorBackground());

    final zoneSize = game.size;
    final topLeft = Vector2(-zoneSize.x / 2, -zoneSize.y / 2);

    // Set individual spawn limits
    final pmSpawns = 8; // for each particulate type
    final gasSpawns = 6; // for each voc and nox
    final co2Spawns = 4;

    await add(
      FlameBlocProvider<BleScannerCubit, BleScannerState>.value(
        value: game.bleScannerCubit,
        children: [
          // --- Particulates ---
          SensorSpawnManager(
            assetFolder: 'pm1',
            maxSensorValue: 100,
            maxSpawnCount: pmSpawns,
            valueSelector: (s) => s.pm1p0,
            zoneSize: zoneSize,
            position: topLeft,
          ),
          SensorSpawnManager(
            assetFolder: 'pm2p5',
            maxSensorValue: 150,
            maxSpawnCount: pmSpawns,
            valueSelector: (s) => s.pm2p5,
            zoneSize: zoneSize,
            position: topLeft,
          ),
          SensorSpawnManager(
            assetFolder: 'pm4',
            maxSensorValue: 150,
            maxSpawnCount: pmSpawns,
            valueSelector: (s) => s.pm4p0,
            zoneSize: zoneSize,
            position: topLeft,
          ),
          SensorSpawnManager(
            assetFolder: 'pm10',
            maxSensorValue: 200,
            maxSpawnCount: pmSpawns,
            valueSelector: (s) => s.pm10p0,
            zoneSize: zoneSize,
            position: topLeft,
          ),

          // --- Gases ---
          SensorSpawnManager(
            assetFolder: 'voc',
            maxSensorValue: 500,
            maxSpawnCount: gasSpawns,
            valueSelector: (s) => s.voc,
            zoneSize: zoneSize,
            position: topLeft,
          ),
          SensorSpawnManager(
            assetFolder: 'nox',
            maxSensorValue: 500,
            maxSpawnCount: gasSpawns,
            valueSelector: (s) => s.nox,
            zoneSize: zoneSize,
            position: topLeft,
          ),

          // --- CO2 ---
          SensorSpawnManager(
            assetFolder: 'co2_low', //for < 1000ppm
            highAssetFolder: 'co2_high', // for >= 1000ppm
            highThreshold: 1000,
            maxSensorValue: 2000,
            maxSpawnCount: co2Spawns,
            valueSelector: (s) => s.co2,
            zoneSize: zoneSize,
            position: topLeft,
          ),
        ],
      ),
    );
  }
}
