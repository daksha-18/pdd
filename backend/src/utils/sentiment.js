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
  like: 2,
  love: 3,
  nice: 2,
  fine: 2,
  recommend: 3,
  best: 4,
  well: 2,
  proper: 2,
  properly: 2,
};

const negationSet = new Set([
  'not', 'no', 'never', 'neither', 'nor', 'none', 'cannot', 'without',
  'hardly', 'scarcely', 'barely', 'lack', 'lacks', 'lacking',
  'isnt', "isn't", 'isn',
  'wasnt', "wasn't", 'wasn',
  'arent', "aren't", 'aren',
  'werent', "weren't", 'weren',
  'dont', "don't", 'don',
  'doesnt', "doesn't", 'doesn',
  'didnt', "didn't", 'didn',
  'cant', "can't",
  'couldnt', "couldn't", 'couldn',
  'wont', "won't", 'won',
  'wouldnt', "wouldn't", 'wouldn',
  'shouldnt', "shouldn't", 'shouldn',
  'havent', "haven't", 'haven',
  'hasnt', "hasn't", 'hasn',
  'hadnt', "hadn't", 'hadn',
]);

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

  // Tokenize text preserving word characters and apostrophes
  const tokens = lowerText.match(/\b[a-z']+\b/g) || tokenizer.tokenize(lowerText) || lowerText.split(/\s+/);
  
  // Base score from natural SentimentAnalyzer
  let naturalScore = 0;
  try {
    naturalScore = analyzer.getSentiment(tokens) || 0;
  } catch (e) {
    naturalScore = 0;
  }

  // Calculate custom lexicon score & count
  let customScore = 0;
  let matchesCount = 0;
  let hasNegation = false;

  tokens.forEach((token, index) => {
    const cleanToken = token.replace(/'/g, '');
    const key = customLexicon[token] !== undefined ? token : (customLexicon[cleanToken] !== undefined ? cleanToken : null);

    if (key !== null) {
      let weight = customLexicon[key];

      let isNegated = false;
      for (let lookback = 1; lookback <= 2; lookback++) {
        if (index - lookback >= 0) {
          const prevRaw = tokens[index - lookback];
          const prevClean = prevRaw.replace(/'/g, '');
          if (negationSet.has(prevRaw) || negationSet.has(prevClean)) {
            isNegated = true;
            hasNegation = true;
            break;
          }
        }
      }

      if (isNegated) {
        weight = -weight;
      }

      customScore += weight;
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

  // If no word/emoji tokens matched, check raw text for lexicon word substrings
  if (matchesCount === 0) {
    for (const [word, val] of Object.entries(customLexicon)) {
      if (lowerText.includes(word)) {
        let weight = val;
        if (lowerText.includes(`not ${word}`) || lowerText.includes(`no ${word}`) || lowerText.includes(`never ${word}`)) {
          weight = -weight;
          hasNegation = true;
        }
        customScore += weight;
        matchesCount++;
      }
    }
  }

  if (hasNegation && naturalScore !== 0) {
    naturalScore = -naturalScore;
  }

  let normCustom = 0;
  if (matchesCount > 0) {
    // Custom weights range between -4.0 and +4.0
    normCustom = Math.max(-1.0, Math.min(1.0, (customScore / matchesCount) / 4.0));
  }

  let normNatural = 0;
  if (naturalScore !== 0) {
    normNatural = Math.max(-1.0, Math.min(1.0, naturalScore / 4.0));
  }

  let textScore = 0;
  if (matchesCount > 0 && naturalScore !== 0) {
    textScore = normCustom * 0.7 + normNatural * 0.3;
  } else if (matchesCount > 0) {
    textScore = normCustom;
  } else if (naturalScore !== 0) {
    textScore = normNatural;
  }

  // Clamp textScore between -1.0 and +1.0
  let normalized = Math.max(-1.0, Math.min(1.0, Math.round(textScore * 100) / 100));

  // Determine label
  let label = 'neutral';
  if (normalized > 0.05) {
    label = 'positive';
  } else if (normalized < -0.05) {
    label = 'negative';
  }

  return {
    score: normalized,
    label,
    normalizedScore: (normalized >= 0 ? `+${normalized.toFixed(2)}` : normalized.toFixed(2)),
  };
}

module.exports = {
  analyzeSentiment,
};
