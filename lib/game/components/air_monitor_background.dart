import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';

import '../../cubit/ble_scanner_cubit.dart';
import '../air_monitor_game.dart';
import 'air_monitor_background_controller.dart';

class AirMonitorBackground extends PositionComponent
    with HasGameReference<AirMonitorGame> {
  late final List<Sprite> aqiSprites;
  late final SpriteComponent _layer1;
  late final SpriteComponent _layer2;

  double _targetIndex = 0.0;
  double _currentIndex = 0.0;

  // Controls how fast the animation catches up to the sensor reading.
  // Higher = faster transition.
  final double _lerpSpeed = 3.0;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    // Load 24 sprites: 1.jpg to 24.jpg
    final spriteFutures = List.generate(
      24,
      (index) => Sprite.load('background/${index + 1}.jpg'),
    );
    aqiSprites = await Future.wait(spriteFutures);

    // Initialize the two rendering layers
    _layer1 = SpriteComponent(sprite: aqiSprites[0], anchor: Anchor.center);
    _layer2 = SpriteComponent(sprite: aqiSprites[1], anchor: Anchor.center)
      ..setOpacity(0);

    add(_layer1);
    add(_layer2);

    // Set parent size and center the layers
    size = aqiSprites[0].srcSize;
    anchor = Anchor.center;
    _layer1.position = size / 2;
    _layer2.position = size / 2;

    await add(
      FlameBlocProvider<BleScannerCubit, BleScannerState>.value(
        value: game.bleScannerCubit,
        children: [AirMonitorBackgroundController()],
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Only animate if there is a difference between current and target
    if ((_currentIndex - _targetIndex).abs() > 0.001) {
      // Smoothly move the current index towards the target index
      _currentIndex += (_targetIndex - _currentIndex) * _lerpSpeed * dt;

      // Extract the integer bounds and the fractional remainder
      int baseIndex = _currentIndex.floor().clamp(0, 23);
      int nextIndex = (baseIndex + 1).clamp(0, 23);
      double fraction = _currentIndex - baseIndex;

      // Apply to sprites
      _layer1.sprite = aqiSprites[baseIndex];
      _layer2.sprite = aqiSprites[nextIndex];

      // Fade in the top layer based on the decimal fraction
      _layer2.setOpacity(fraction);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (this.size.y > 0) {
      final double scaleFactor = size.y / this.size.y;
      scale = Vector2.all(scaleFactor);
    }
  }

  // Receives a continuous double instead of an int to drive smooth cross-fading
  void setTargetAqiIndex(double index) {
    _targetIndex = index.clamp(0.0, 23.0);
  }
}
