import 'dart:math';

class SentimentAnalyzer {
  // In a production app, this would connect to a real NLP service
  // or use an on-device ML model. For this demo, we'll simulate results.
  
  Map<String, double> analyzeSentiment(String text) {
    if (text.isEmpty) {
      return {
        'positive': 0.0,
        'negative': 0.0,
        'neutral': 1.0,
        'confidence': 0.5,
      };
    }
    
    // Simple keyword-based sentiment analysis
    final lowerText = text.toLowerCase();
    
    // Check for positive sentiment keywords
    final positiveKeywords = [
      'good', 'great', 'excellent', 'beneficial', 'agree', 'support',
      'helpful', 'effective', 'important', 'positive', 'advantage',
      'approve', 'like', 'reasonable', 'fair', 'balanced'
    ];
    
    // Check for negative sentiment keywords
    final negativeKeywords = [
      'bad', 'wrong', 'disagree', 'not', 'terrible', 'poor', 'ineffective',
      'problem', 'issue', 'concerned', 'worried', 'damage', 'harm',
      'waste', 'fail', 'unfair', 'reject', 'unbalanced'
    ];
    
    // Count occurrences
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (final word in positiveKeywords) {
      if (lowerText.contains(word)) {
        positiveCount++;
      }
    }
    
    for (final word in negativeKeywords) {
      if (lowerText.contains(word)) {
        negativeCount++;
      }
    }
    
    // Calculate sentiment scores
    final totalTerms = positiveCount + negativeCount;
    double positive = 0.5;
    double negative = 0.5;
    double neutral = 0.5;
    
    if (totalTerms > 0) {
      positive = positiveCount / (totalTerms * 2);
      negative = negativeCount / (totalTerms * 2);
      
      // Adjust for text length - longer text is less likely to be completely neutral
      final textLengthFactor = min(text.length / 100, 1.0);
      neutral = max(0.0, 1.0 - (positive + negative)) * (1.0 - textLengthFactor);
      
      // Normalize to ensure they sum to 1.0
      final total = positive + negative + neutral;
      if (total > 0) {
        positive = positive / total;
        negative = negative / total;
        neutral = neutral / total;
      }
    }
    
    // Add a confidence score
    final double confidence = 0.5 + min(totalTerms / 10, 0.4);
    
    // Add some randomness to make it more realistic
    final random = Random();
    final randomFactor = 0.1;  // Maximum random adjustment
    
    positive = _clamp(positive + (random.nextDouble() * randomFactor * 2 - randomFactor));
    negative = _clamp(negative + (random.nextDouble() * randomFactor * 2 - randomFactor));
    neutral = _clamp(neutral + (random.nextDouble() * randomFactor * 2 - randomFactor));
    
    // Re-normalize
    final total = positive + negative + neutral;
    positive = positive / total;
    negative = negative / total;
    neutral = neutral / total;
    
    return {
      'positive': positive,
      'negative': negative,
      'neutral': neutral,
      'confidence': confidence,
    };
  }
  
  List<String> extractKeywords(String text) {
    if (text.isEmpty) {
      return [];
    }
    
    // In a real implementation, this would use NLP techniques like TF-IDF
    // For this demo, we'll use a list of policy-related keywords
    final List<String> policyKeywords = [
      'budget', 'cost', 'economy', 'education', 'healthcare', 'environment',
      'sustainable', 'infrastructure', 'security', 'welfare', 'technology',
      'innovation', 'regulation', 'taxes', 'subsidies', 'funding', 'investment',
      'public', 'private', 'partnership', 'reform', 'equity', 'equality',
      'justice', 'efficient', 'effective', 'impact', 'community', 'society',
      'individual', 'rights', 'responsibility', 'future', 'present', 'tradition',
      'progress', 'conservative', 'progressive', 'moderate', 'radical',
      'development', 'growth', 'protection', 'access', 'opportunity'
    ];
    
    final lowerText = text.toLowerCase();
    final List<String> foundKeywords = [];
    
    for (final keyword in policyKeywords) {
      if (lowerText.contains(keyword)) {
        foundKeywords.add(keyword);
      }
    }
    
    // Limit to most relevant keywords (5 max)
    if (foundKeywords.length > 5) {
      foundKeywords.length = 5;
    }
    
    return foundKeywords;
  }
  
  List<String> identifyEthicalConcepts(String text) {
    if (text.isEmpty) {
      return [];
    }
    
    // In a real implementation, this would use NLP and a knowledge graph
    // For this demo, we'll use simple keyword mapping to ethical concepts
    final Map<String, List<String>> ethicalConceptKeywords = {
      'fairness': ['fair', 'unfair', 'equal', 'unequal', 'equality', 'inequality', 'justice', 'unjust', 'equitable'],
      'autonomy': ['choice', 'freedom', 'liberty', 'right', 'rights', 'autonomy', 'agency', 'control', 'independence'],
      'beneficence': ['good', 'benefit', 'help', 'welfare', 'wellbeing', 'care', 'support', 'assist', 'improve'],
      'non-maleficence': ['harm', 'hurt', 'damage', 'risk', 'danger', 'negative', 'protect', 'safe', 'safety'],
      'utility': ['outcome', 'result', 'consequence', 'impact', 'effect', 'effective', 'efficient', 'utility', 'useful'],
      'sustainability': ['sustainable', 'future', 'long-term', 'environment', 'preservation', 'conserve', 'maintain'],
      'responsibility': ['duty', 'obligation', 'responsible', 'accountability', 'liable', 'answerable'],
      'transparency': ['transparent', 'open', 'clear', 'disclosure', 'honesty', 'truthful', 'information'],
    };
    
    final lowerText = text.toLowerCase();
    final Set<String> detectedConcepts = {};
    
    ethicalConceptKeywords.forEach((concept, keywords) {
      for (final keyword in keywords) {
        if (lowerText.contains(keyword)) {
          detectedConcepts.add(concept);
          break;
        }
      }
    });
    
    return detectedConcepts.toList();
  }
  
  double _clamp(double value) {
    return max(0.0, min(1.0, value));
  }
}