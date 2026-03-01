import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../air_monitor_game.dart';

class ToxicityBar extends PositionComponent
    with HasGameReference<AirMonitorGame> {
  ToxicityBar() : super(size: Vector2(150, 16));

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Anchor to top right of the game view
    anchor = Anchor.topLeft;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Keep it centered at the top whenever the screen resizes
    position = Vector2(size.x / 2, 10);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Calculate percentage
    final fraction = (game.currentToxicity / game.maxToxicity).clamp(0.0, 1.0);

    // Determine color based on severity
    Color barColor = Colors.greenAccent;
    if (fraction > 0.5) barColor = Colors.orangeAccent;
    if (fraction > 0.8) barColor = Colors.redAccent;

    // Draw Background (Dark Gray)
    final bgRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(8)),
      Paint()..color = Colors.black45,
    );

    // Draw Foreground Fill
    final fillRect = Rect.fromLTWH(0, 0, size.x * fraction, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, const Radius.circular(8)),
      Paint()..color = barColor,
    );

    // Add a label
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );
    final textSpan = TextSpan(text: 'TOXICITY', style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );
  }
}
