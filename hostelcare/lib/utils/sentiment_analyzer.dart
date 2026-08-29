import 'package:flutter/material.dart';

class SentimentResult {
  final double score;
  final String label; // 'positive' | 'negative' | 'neutral'
  final String formattedScore;
  final String displayText;
  final Color color;
  final IconData icon;

  const SentimentResult({
    required this.score,
    required this.label,
    required this.formattedScore,
    required this.displayText,
    required this.color,
    required this.icon,
  });
}

class SentimentAnalyzer {
  static const Map<String, double> _wordWeights = {
    // Positive
    'fast': 3.0,
    'quick': 3.0,
    'speedy': 3.0,
    'prompt': 3.0,
    'polite': 3.0,
    'kind': 3.0,
    'respectful': 3.0,
    'courteous': 3.0,
    'clean': 3.0,
    'neat': 3.0,
    'thorough': 3.0,
    'excellent': 4.0,
    'awesome': 4.0,
    'great': 3.0,
    'good': 2.0,
    'fixed': 3.0,
    'repaired': 3.0,
    'satisfied': 3.0,
    'happy': 3.0,
    'helpful': 3.0,
    'perfect': 4.0,
    'thanks': 2.0,
    'thank': 2.0,
    'superb': 4.0,
    'wonderful': 4.0,
    'professional': 3.0,
    'solved': 3.0,

    // Negative
    'slow': -3.0,
    'late': -3.0,
    'delayed': -3.0,
    'rude': -4.0,
    'unpolite': -3.0,
    'disrespectful': -4.0,
    'dirty': -3.0,
    'messy': -3.0,
    'careless': -3.0,
    'poor': -3.0,
    'bad': -3.0,
    'worst': -4.0,
    'terrible': -4.0,
    'horrible': -4.0,
    'awful': -4.0,
    'unresolved': -4.0,
    'unfixed': -4.0,
    'broken': -2.0,
    'useless': -4.0,
    'unhelpful': -3.0,
    'unhappy': -3.0,
    'disappointed': -3.0,
    'waste': -3.0,
    'sluggish': -3.0,
  };

  static const Map<String, double> _emojiWeights = {
    '⚡': 2.0,
    '😊': 3.0,
    '😃': 3.0,
    '👍': 3.0,
    '✨': 3.0,
    '❤️': 4.0,
    '⭐': 2.0,
    '🙌': 3.0,
    '🔥': 3.0,
    '😟': -3.0,
    '😡': -4.0,
    '😠': -3.0,
    '👎': -3.0,
    '❌': -3.0,
    '🤮': -4.0,
    '😞': -3.0,
    '💔': -3.0,
  };

  /// Analyzes text and returns structured sentiment result
  static SentimentResult analyze(String? text, {double? serverScore, String? serverLabel}) {
    if (serverScore != null && serverLabel != null && serverLabel.isNotEmpty) {
      return _buildResult(serverScore, serverLabel);
    }

    if (text == null || text.trim().isEmpty) {
      return _buildResult(0.0, 'neutral');
    }

    final rawText = text.trim();
    final lowerText = rawText.toLowerCase();
    final RegExp wordRegExp = RegExp(r'\b[a-z]+\b');
    final matches = wordRegExp.allMatches(lowerText).map((m) => m.group(0)!);

    double totalScore = 0.0;
    int count = 0;

    for (final word in matches) {
      if (_wordWeights.containsKey(word)) {
        totalScore += _wordWeights[word]!;
        count++;
      }
    }

    for (final entry in _emojiWeights.entries) {
      if (rawText.contains(entry.key)) {
        totalScore += entry.value;
        count++;
      }
    }

    double finalScore = 0.0;
    if (count > 0) {
      finalScore = totalScore / count;
      // Normalize to -1.0 .. +1.0
      finalScore = (finalScore / 4.0).clamp(-1.0, 1.0);
    }

    String label = 'neutral';
    if (finalScore > 0.05) {
      label = 'positive';
    } else if (finalScore < -0.05) {
      label = 'negative';
    }

    return _buildResult(finalScore, label);
  }

  static SentimentResult _buildResult(double score, String label) {
    final double clampedScore = score.clamp(-1.0, 1.0);
    final String formatted = clampedScore >= 0
        ? '+${clampedScore.toStringAsFixed(2)}'
        : clampedScore.toStringAsFixed(2);

    final String displayLabel = label.substring(0, 1).toUpperCase() + label.substring(1).toLowerCase();

    Color color;
    IconData icon;

    switch (label.toLowerCase()) {
      case 'positive':
        color = const Color(0xFF10B981); // Emerald Green
        icon = Icons.sentiment_satisfied_alt_rounded;
        break;
      case 'negative':
        color = const Color(0xFFEF4444); // Crimson Red
        icon = Icons.sentiment_very_dissatisfied_rounded;
        break;
      case 'neutral':
      default:
        color = const Color(0xFF6B7280); // Neutral Grey
        icon = Icons.sentiment_neutral_rounded;
        break;
    }

    return SentimentResult(
      score: clampedScore,
      label: label.toLowerCase(),
      formattedScore: formatted,
      displayText: '$displayLabel ($formatted)',
      color: color,
      icon: icon,
    );
  }
}
