import 'dart:math';
import 'package:flutter/material.dart';

class GameUtils {
  static final Random _random = Random();

  static int getRandomInt(int min, int max) {
    return min + _random.nextInt(max - min + 1);
  }

  static double getRandomDouble(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  static List<T> shuffleList<T>(List<T> list) {
    final shuffled = List<T>.from(list);
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    return shuffled;
  }

  static Color getRandomColor() {
    return Color.fromARGB(
      255,
      _random.nextInt(256),
      _random.nextInt(256),
      _random.nextInt(256),
    );
  }

  static List<Color> getRandomDistinctColors(int count) {
    final colors = [];
    while (colors.length < count) {
      final color = getRandomColor();
      if (!colors.any((c) => _colorsAreSimilar(c, color))) {
        colors.add(color);
      }
    }
    return colors.cast<Color>();
  }

  static bool _colorsAreSimilar(Color a, Color b) {
    final rDiff = (a.red - b.red).abs();
    final gDiff = (a.green - b.green).abs();
    final bDiff = (a.blue - b.blue).abs();
    return rDiff < 50 && gDiff < 50 && bDiff < 50;
  }
}
