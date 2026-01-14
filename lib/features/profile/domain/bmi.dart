import 'package:flutter/material.dart';

/// BMI (Body Mass Index) calculation and classification
/// Based on official WHO/CDC/NHS adult thresholds

/// BMI classification result
class BmiResult {
  final double bmiValue;
  final String categoryKey;
  final String labelText;
  final Color color;

  const BmiResult({
    required this.bmiValue,
    required this.categoryKey,
    required this.labelText,
    required this.color,
  });

  /// No BMI available (invalid input)
  factory BmiResult.unavailable() => const BmiResult(
        bmiValue: 0,
        categoryKey: 'unavailable',
        labelText: '—',
        color: Colors.grey,
      );

  String get formattedBmi => bmiValue.toStringAsFixed(1);
}

/// Compute BMI from height and weight
/// Returns null if inputs are invalid
double? computeBmi({
  required double heightCm,
  required double weightKg,
}) {
  if (heightCm <= 0 || weightKg <= 0) return null;

  final heightMeters = heightCm / 100;
  return weightKg / (heightMeters * heightMeters);
}

/// Classify BMI using official adult thresholds
/// WHO/CDC/NHS classifications:
/// - < 18.5: Underweight
/// - 18.5-24.9: Healthy
/// - 25.0-29.9: Overweight  
/// - >= 30.0: Obesity
BmiResult classifyBmi(double? bmi) {
  if (bmi == null || bmi <= 0) {
    return BmiResult.unavailable();
  }

  if (bmi < 18.5) {
    return BmiResult(
      bmiValue: bmi,
      categoryKey: 'underweight',
      labelText: 'Underweight',
      color: Colors.orange,
    );
  } else if (bmi < 25.0) {
    return BmiResult(
      bmiValue: bmi,
      categoryKey: 'healthy',
      labelText: 'Healthy',
      color: Colors.green,
    );
  } else if (bmi < 30.0) {
    return BmiResult(
      bmiValue: bmi,
      categoryKey: 'overweight',
      labelText: 'Overweight',
      color: Colors.orange,
    );
  } else {
    // >= 30.0
    return BmiResult(
      bmiValue: bmi,
      categoryKey: 'obesity',
      labelText: 'Obesity',
      color: Colors.red,
    );
  }
}

/// Safely parse number from text (handles Turkish comma)
double? parseNumber(String text) {
  if (text.trim().isEmpty) return null;
  
  // Normalize comma to dot (TR users type "73,5")
  final normalized = text.trim().replaceAll(',', '.');
  
  return double.tryParse(normalized);
}
