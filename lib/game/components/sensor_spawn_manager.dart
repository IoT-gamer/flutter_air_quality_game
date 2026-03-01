import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import '../../cubit/ble_scanner_cubit.dart';
import 'floating_sensor_character.dart';

class SensorSpawnManager extends PositionComponent
    with FlameBlocListenable<BleScannerCubit, BleScannerState> {
  final String assetFolder;
  final String? highAssetFolder; // Optional folder for high concentration
  final double? highThreshold; // The sensor value that triggers the swap

  final double maxSensorValue;
  final int maxSpawnCount;
  final num? Function(BleScannerState) valueSelector;
  final Random _random = Random();

  // Tracks which folder is currently being used for spawning
  String _currentActiveFolder;

  SensorSpawnManager({
    required this.assetFolder,
    this.highAssetFolder,
    this.highThreshold,
    required this.maxSensorValue,
    required this.maxSpawnCount,
    required this.valueSelector,
    required Vector2 zoneSize,
    super.position,
  }) : _currentActiveFolder = assetFolder,
       super(size: zoneSize);

  @override
  void onNewState(BleScannerState state) {
    // Get the current sensor value
    final currentVal = valueSelector(state)?.toDouble() ?? 0.0;

    // Determine which folder to use based on the threshold
    String targetFolder = assetFolder;
    if (highThreshold != null && highAssetFolder != null) {
      if (currentVal >= highThreshold!) {
        targetFolder = highAssetFolder!;
      }
    }

    // If the state flipped (low to high, or high to low), purge the old sprites
    // This allows them to instantly respawn with the correct visual threat level.
    if (_currentActiveFolder != targetFolder) {
      removeAll(children);
      _currentActiveFolder = targetFolder;
    }

    // Calculate how many sprites we should have
    final fraction = (currentVal / maxSensorValue).clamp(0.0, 1.0);
    final targetCount = (fraction * maxSpawnCount).round();

    updateChildCount(targetCount, _currentActiveFolder);
  }

  void updateChildCount(int targetCount, String folderToSpawn) {
    final currentCount = children.length;

    if (currentCount < targetCount) {
      // Spawn the difference using the active folder
      final toAdd = targetCount - currentCount;
      for (int i = 0; i < toAdd; i++) {
        add(
          FloatingSensorCharacter(
            assetFolder: folderToSpawn,
            zoneSize: size,
            position: Vector2(
              _random.nextDouble() * (size.x - 40),
              _random.nextDouble() * (size.y - 40),
            ),
          ),
        );
      }
    } else if (currentCount > targetCount) {
      // Remove the difference
      final toRemove = currentCount - targetCount;
      for (int i = 0; i < toRemove; i++) {
        if (children.isNotEmpty) {
          remove(children.last);
        }
      }
    }
  }
}
