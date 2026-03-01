import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../air_monitor_game.dart';

class FloatingSensorCharacter extends SpriteAnimationComponent
    with HasGameReference<AirMonitorGame>, TapCallbacks {
  final String assetFolder;
  final Vector2 zoneSize;

  late Vector2 _velocity;
  final _random = Random();

  // Points awarded when this specific pollutant is tapped
  final int pointsValue;

  FloatingSensorCharacter({
    required this.assetFolder,
    required this.zoneSize,
    this.pointsValue = 10,
    super.position,
  }) : super(size: Vector2.all(40));

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the 24-frame looping animation
    final spritesFutures = List.generate(
      24,
      (i) => Sprite.load('$assetFolder/${i + 1}.png'),
    );
    animation = SpriteAnimation.spriteList(
      await Future.wait(spritesFutures),
      stepTime: 0.1,
      loop: true,
    );

    // Set a random drifting velocity
    _velocity = Vector2(
      (_random.nextDouble() - 0.5) * 60,
      (_random.nextDouble() - 0.5) * 60,
    );

    // Pulse gently to look alive
    add(
      ScaleEffect.by(
        Vector2.all(1.1),
        EffectController(duration: 1 + _random.nextDouble(), infinite: true),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move the character
    position += _velocity * dt;

    // Bounce off the edges of the screen/zone
    if (position.x <= 0 || position.x + size.x >= zoneSize.x) {
      _velocity.x *= -1;
      position.x = position.x.clamp(0, zoneSize.x - size.x);
    }
    if (position.y <= 0 || position.y + size.y >= zoneSize.y) {
      _velocity.y *= -1;
      position.y = position.y.clamp(0, zoneSize.y - size.y);
    }
  }

  // --- TOXICITY TRACKING ---
  @override
  void onMount() {
    super.onMount();
    // Add 1 to toxicity when this sprite appears on screen
    game.currentToxicity++;
    game.checkGameOver();
  }

  @override
  void onRemove() {
    super.onRemove();
    // Subtract 1 when tapped or despawned
    game.currentToxicity--;
  }

  // --- PLAYER INTERACTION & PARTICLES ---
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    // Prevent double-taps while it's already dying
    if (isRemoving || scale.x < 1.0) return;

    // Add points
    game.increaseScore(pointsValue);

    // Play the sound effect!
    game.popSoundPool.start();

    // Spawn the particle explosion
    _spawnParticles();

    // Shrink to zero and destroy
    add(
      ScaleEffect.to(
        Vector2.zero(),
        EffectController(
          duration: 0.15,
          curve: Curves.easeOut,
          onMax: () => removeFromParent(),
        ),
      ),
    );
  }

  void _spawnParticles() {
    // Generate a burst of 15 tiny fading particles
    final particleComponent = ParticleSystemComponent(
      particle: Particle.generate(
        count: 15,
        lifespan: 0.4, // They exist for 0.4 seconds
        generator: (i) {
          return AcceleratedParticle(
            // Start at the center of the current sprite
            position: position.clone() + (size / 2),
            // Shoot outward in random directions
            speed: Vector2(
              (_random.nextDouble() - 0.5) * 300,
              (_random.nextDouble() - 0.5) * 300,
            ),
            // Use ComputedParticle to dynamically change opacity over time
            child: ComputedParticle(
              renderer: (canvas, particle) {
                // particle.progress goes from 0.0 to 1.0 over its lifespan
                // We subtract it from 1.0 so it starts fully opaque and fades to transparent
                final opacity = (1.0 - particle.progress).clamp(0.0, 1.0);

                final paint = Paint()
                  ..color = Colors.white.withOpacity(opacity);

                // Draw a tiny circle with the fading paint
                canvas.drawCircle(Offset.zero, 2.5, paint);
              },
            ),
          );
        },
      ),
    );

    // Add the particles to the parent (the spawn manager)
    parent?.add(particleComponent);
  }
}
