import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import '../cubit/ble_scanner_cubit.dart';
import 'air_monitor_world.dart';
import 'components/toxicity_bar.dart'; // We will create this next

class AirMonitorGame extends FlameGame with HasGameReference<AirMonitorGame> {
  final BleScannerCubit bleScannerCubit;
  late final AirMonitorWorld airMonitorWorld;
  late AudioPool popSoundPool;

  int score = 0;

  // --- TOXICITY SYSTEM ---
  int currentToxicity = 0;
  final int maxToxicity = 50; // Game over if 50 pollutants are on screen
  bool isGameOver = false;

  AirMonitorGame({
    super.children,
    super.world,
    super.camera,
    required this.bleScannerCubit,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // This automatically uses Flame's global audio cache
    popSoundPool = await FlameAudio.createPool(
      'fx/pop.wav',
      minPlayers: 2,
      maxPlayers: 5, // Caps the max overlapping sounds to prevent crashes
    );

    airMonitorWorld = AirMonitorWorld();
    world = airMonitorWorld;

    // UI Elements
    camera.viewport.add(ScoreDisplay());
    camera.viewport.add(ToxicityBar());
  }

  @override
  void onRemove() {
    // Fire-and-forget the disposal since onRemove is synchronous
    popSoundPool.dispose();
    super.onRemove();
  }

  void increaseScore(int points) {
    score += points;
  }

  void checkGameOver() {
    if (currentToxicity >= maxToxicity && !isGameOver) {
      isGameOver = true;
      pauseEngine(); // Freeze the game

      // Show the Game Over warning
      camera.viewport.add(
        TextComponent(
          text: 'TOXICITY CRITICAL!\nOpen a Window!',
          position: camera.viewport.size / 2,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.black54,
            ),
          ),
        ),
      );
    }
  }
}

// --- SCORE UI COMPONENT ---
class ScoreDisplay extends TextComponent with HasGameReference<AirMonitorGame> {
  ScoreDisplay()
    : super(
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 4.0, color: Colors.black87)],
          ),
        ),
      );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    position = Vector2(10, 10);
  }

  @override
  void update(double dt) {
    super.update(dt);
    text = 'Purified: ${game.score}';
  }
}
