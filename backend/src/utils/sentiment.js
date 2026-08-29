const natural = require('natural');

const analyzer = new natural.SentimentAnalyzer('English', natural.PorterStemmer, 'afinn');
const tokenizer = new natural.WordTokenizer();

// Domain-specific hostel service sentiment lexicon & weights
const customLexicon = {
  // Positive words & phrases
  fast: 3,
  quick: 3,
  speedy: 3,
  prompt: 3,
  polite: 3,
  kind: 3,
  respectful: 3,
  courteous: 3,
  clean: 3,
  neat: 3,
  thorough: 3,
  excellent: 4,
  awesome: 4,
  great: 3,
  good: 2,
  fixed: 3,
  repaired: 3,
  satisfied: 3,
  happy: 3,
  helpful: 3,
  perfect: 4,
  thanks: 2,
  thank: 2,
  superb: 4,
  wonderful: 4,
  professional: 3,
  solved: 3,

  // Negative words & phrases
  slow: -3,
  late: -3,
  delayed: -3,
  rude: -4,
  unpolite: -3,
  disrespectful: -4,
  dirty: -3,
  messy: -3,
  careless: -3,
  poor: -3,
  bad: -3,
  worst: -4,
  terrible: -4,
  horrible: -4,
  awful: -4,
  unresolved: -4,
  unfixed: -4,
  broken: -2,
  useless: -4,
  unhelpful: -3,
  unhappy: -3,
  disappointed: -3,
  waste: -3,
  sluggish: -3,
};

// Emoji sentiment weights
const emojiLexicon = {
  '⚡': 2,
  '😊': 3,
  '😃': 3,
  '👍': 3,
  '✨': 3,
  '❤️': 4,
  '⭐': 2,
  '🙌': 3,
  '🔥': 3,
  '😟': -3,
  '😡': -4,
  '😠': -3,
  '👎': -3,
  '❌': -3,
  '🤮': -4,
  '😞': -3,
  '💔': -3,
};

/**
 * Analyzes feedback text and returns sentiment score & label
 * @param {string} text - Feedback comment text
 * @returns {object} { score: number, label: 'positive' | 'negative' | 'neutral', normalizedScore: string }
 */
function analyzeSentiment(text) {
  if (!text || typeof text !== 'string' || text.trim().length === 0) {
    return {
      score: 0.0,
      label: 'neutral',
      normalizedScore: '0.00',
    };
  }

  const rawText = text.trim();
  const lowerText = rawText.toLowerCase();

  // Tokenize text
  const tokens = tokenizer.tokenize(lowerText) || lowerText.split(/\s+/);
  
  // Base score from natural SentimentAnalyzer
  let naturalScore = 0;
  try {
    naturalScore = analyzer.getSentiment(tokens) || 0;
  } catch (e) {
    naturalScore = 0;
  }

  // Calculate custom lexicon score
  let customScore = 0;
  let matchesCount = 0;

  tokens.forEach((token) => {
    if (customLexicon[token] !== undefined) {
      customScore += customLexicon[token];
      matchesCount++;
    }
  });

  // Calculate emoji score
  for (const [emoji, val] of Object.entries(emojiLexicon)) {
    if (rawText.includes(emoji)) {
      customScore += val;
      matchesCount++;
    }
  }

  // Combine natural score and custom score
  let totalScore = naturalScore * 2 + (matchesCount > 0 ? customScore / matchesCount : 0);

  // If no words matched in natural or custom, check raw text for substrings
  if (totalScore === 0 && matchesCount === 0) {
    for (const [word, val] of Object.entries(customLexicon)) {
      if (lowerText.includes(word)) {
        customScore += val;
        matchesCount++;
      }
    }
    if (matchesCount > 0) {
      totalScore = customScore / matchesCount;
    }
  }

  // Clamp totalScore between -1.0 and +1.0
  let normalized = Math.max(-1.0, Math.min(1.0, Math.round(totalScore * 100) / 100));

  // Determine label
  let label = 'neutral';
  if (normalized > 0.05) {
    label = 'positive';
  } else if (normalized < -0.05) {
    label = 'negative';
  }

  return {
    score: normalized,
    label: label,
    normalizedScore: (normalized >= 0 ? `+${normalized.toFixed(2)}` : normalized.toFixed(2)),
  };
}

module.exports = {
  analyzeSentiment,
};
