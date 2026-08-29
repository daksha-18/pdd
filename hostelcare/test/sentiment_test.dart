import 'package:flutter_test/flutter_test.dart';
import 'package:hostelcare/utils/sentiment_analyzer.dart';

void main() {
  test('Sentiment analyzer handles negations', () {
    final notGood = SentimentAnalyzer.analyze('not good');
    expect(notGood.label, equals('negative'));
    expect(notGood.score, lessThan(0.0));

    final good = SentimentAnalyzer.analyze('good');
    expect(good.label, equals('positive'));
    expect(good.score, greaterThan(0.0));

    final notClean = SentimentAnalyzer.analyze('not clean');
    expect(notClean.label, equals('negative'));

    final notBad = SentimentAnalyzer.analyze('not bad');
    expect(notBad.label, equals('positive'));
  });
}
