import prisma from '../shared/prisma';

/**
 * Insights result from AI analysis with historical context
 */
export interface AuditInsights {
  currentAudit: {
    id: string;
    title: string;
    score: number | null;
    status: string;
    completedAt: Date | null;
  };
  history: {
    totalAudits: number;
    averageScore: number;
    trend: 'improving' | 'declining' | 'stable';
    previousScore: number | null;
  };
  anomalies: Anomaly[];
  patterns: Pattern[];
  generatedAt: Date;
}

/**
 * Detected anomaly in audit history
 */
export interface Anomaly {
  type: 'recurring_issue' | 'score_drop' | 'category_weakness';
  severity: 'high' | 'medium' | 'low';
  title: string;
  description: string;
  occurrences: number;
  firstSeen: Date;
  lastSeen: Date;
  affectedQuestions?: string[];
}

/**
 * Detected pattern in audit responses
 */
export interface Pattern {
  type: 'improvement' | 'decline' | 'stable';
  category?: string;
  description: string;
  dataPoints: number;
}

/**
 * Get audit insights with historical analysis
 * 
 * Analyzes:
 * - Score trends over time
 * - Recurring issues across audits
 * - Category performance patterns
 */
export async function getAuditInsights(
  auditId: string,
  organizationId: string,
  historyLimit: number = 10
): Promise<AuditInsights | null> {
  // Get current audit
  const currentAudit = await prisma.audit.findUnique({
    where: { id: auditId },
    include: {
      template: {
        include: {
          questions: true,
        },
      },
      answers: {
        include: {
          question: true,
        },
      },
    },
  });

  if (!currentAudit) {
    return null;
  }

  // Get historical audits from same template
  const historicalAudits = await prisma.audit.findMany({
    where: {
      templateId: currentAudit.templateId,
      organizationId,
      status: 'completed',
      id: { not: auditId },
    },
    include: {
      answers: {
        include: {
          question: true,
        },
      },
    },
    orderBy: { completedAt: 'desc' },
    take: historyLimit,
  });

  // Calculate history stats
  const scores = historicalAudits
    .map((a: { score: number | null }) => a.score)
    .filter((s: number | null): s is number => s !== null);

  const averageScore = scores.length > 0
    ? Math.round(scores.reduce((a: number, b: number) => a + b, 0) / scores.length)
    : 0;

  const previousScore = scores.length > 0 ? scores[0] : null;

  // Determine trend
  let trend: 'improving' | 'declining' | 'stable' = 'stable';
  if (scores.length >= 3) {
    const recent = scores.slice(0, 3);
    const older = scores.slice(3, 6);
    if (older.length > 0) {
      const recentAvg = recent.reduce((a: number, b: number) => a + b, 0) / recent.length;
      const olderAvg = older.reduce((a: number, b: number) => a + b, 0) / older.length;
      const diff = recentAvg - olderAvg;
      if (diff > 5) trend = 'improving';
      else if (diff < -5) trend = 'declining';
    }
  }

  // Detect anomalies
  const anomalies = detectAnomalies(currentAudit, historicalAudits);

  // Detect patterns
  const patterns = detectPatterns(currentAudit, historicalAudits);

  return {
    currentAudit: {
      id: currentAudit.id,
      title: currentAudit.title,
      score: currentAudit.score,
      status: currentAudit.status,
      completedAt: currentAudit.completedAt,
    },
    history: {
      totalAudits: historicalAudits.length,
      averageScore,
      trend,
      previousScore,
    },
    anomalies,
    patterns,
    generatedAt: new Date(),
  };
}

/**
 * Detect recurring issues and anomalies
 */
function detectAnomalies(
  currentAudit: any,
  historicalAudits: any[]
): Anomaly[] {
  const anomalies: Anomaly[] = [];

  // Detect recurring issues (same question with negative answers)
  const questionIssues = new Map<string, { count: number; dates: Date[]; questionText: string }>();

  // Process historical audits
  for (const audit of historicalAudits) {
    for (const answer of audit.answers) {
      const isNegative = isNegativeAnswer(answer.value);
      if (isNegative) {
        const qId = answer.questionId;
        const existing = questionIssues.get(qId) || { count: 0, dates: [] as Date[], questionText: answer.question?.text || '' };
        existing.count++;
        existing.dates.push(audit.completedAt || audit.createdAt);
        questionIssues.set(qId, existing);
      }
    }
  }

  // Check current audit for recurring issues
  for (const answer of currentAudit.answers) {
    const isNegative = isNegativeAnswer(answer.value);
    if (isNegative) {
      const qId = answer.questionId;
      const history = questionIssues.get(qId);
      if (history && history.count >= 2) {
        // Recurring issue detected (3+ total including current)
        anomalies.push({
          type: 'recurring_issue',
          severity: history.count >= 4 ? 'high' : history.count >= 3 ? 'medium' : 'low',
          title: `Problème récurrent: ${history.questionText}`,
          description: `Ce problème a été détecté ${history.count + 1} fois sur les ${historicalAudits.length + 1} derniers audits`,
          occurrences: history.count + 1,
          firstSeen: history.dates[history.dates.length - 1],
          lastSeen: new Date(),
          affectedQuestions: [history.questionText],
        });
      }
    }
  }

  // Detect score drops
  if (currentAudit.score && historicalAudits.length >= 3) {
    const recentScores = historicalAudits
      .slice(0, 3)
      .map((a: { score: number | null }) => a.score)
      .filter((s: number | null): s is number => s !== null);

    if (recentScores.length > 0) {
      const avgRecent = recentScores.reduce((a: number, b: number) => a + b, 0) / recentScores.length;
      const drop = avgRecent - (currentAudit.score || 0);
      if (drop > 15) {
        anomalies.push({
          type: 'score_drop',
          severity: drop > 25 ? 'high' : 'medium',
          title: 'Baisse significative du score',
          description: `Le score actuel (${currentAudit.score}%) est inférieur de ${Math.round(drop)}% à la moyenne récente`,
          occurrences: 1,
          firstSeen: new Date(),
          lastSeen: new Date(),
        });
      }
    }
  }

  return anomalies;
}

/**
 * Detect patterns in audit responses
 */
function detectPatterns(
  currentAudit: any,
  historicalAudits: any[]
): Pattern[] {
  const patterns: Pattern[] = [];

  if (historicalAudits.length < 2) {
    return patterns;
  }

  // Score trend pattern
  const scores = historicalAudits
    .map((a) => a.score)
    .filter((s): s is number => s !== null);

  if (scores.length >= 3) {
    const recent = scores.slice(0, Math.min(3, scores.length));
    const avgRecent = recent.reduce((a, b) => a + b, 0) / recent.length;

    if (currentAudit.score) {
      if (currentAudit.score > avgRecent + 10) {
        patterns.push({
          type: 'improvement',
          description: `Score en hausse: +${Math.round(currentAudit.score - avgRecent)}% par rapport à la moyenne récente`,
          dataPoints: recent.length,
        });
      } else if (currentAudit.score < avgRecent - 10) {
        patterns.push({
          type: 'decline',
          description: `Score en baisse: -${Math.round(avgRecent - currentAudit.score)}% par rapport à la moyenne récente`,
          dataPoints: recent.length,
        });
      }
    }
  }

  // Stability pattern
  if (scores.length >= 5) {
    const variance = calculateVariance(scores);
    if (variance < 25) {
      patterns.push({
        type: 'stable',
        description: 'Performance stable sur les derniers audits',
        dataPoints: scores.length,
      });
    }
  }

  return patterns;
}

/**
 * Check if an answer value is negative (non-conform)
 */
function isNegativeAnswer(value: string): boolean {
  const negativeValues = ['non', 'no', 'false', '0', '1', '2', 'mauvais', 'insuffisant', 'non conforme'];
  const lowerValue = value.toLowerCase().trim();
  return negativeValues.some((neg) => lowerValue.includes(neg));
}

/**
 * Calculate variance of numbers
 */
function calculateVariance(values: number[]): number {
  if (values.length === 0) return 0;
  const mean = values.reduce((a, b) => a + b, 0) / values.length;
  const squaredDiffs = values.map((v) => Math.pow(v - mean, 2));
  return squaredDiffs.reduce((a, b) => a + b, 0) / values.length;
}

/**
 * Real-time suggestions for audit in progress
 */
export interface RealTimeSuggestions {
  currentScore: number;
  predictedScore: number;
  confidence: number;
  alerts: Alert[];
  suggestions: string[];
  progress: number;
}

/**
 * Alert during audit
 */
export interface Alert {
  type: 'warning' | 'danger' | 'info';
  message: string;
  questionId?: string;
}

/**
 * Get real-time suggestions for audit in progress
 * 
 * Analyzes current answers and provides:
 * - Predicted final score
 * - Alerts for issues detected
 * - Suggestions for improvement
 */
export async function getRealTimeSuggestions(
  auditId: string,
  organizationId: string,
  currentAnswers: { questionId: string; value: string }[]
): Promise<RealTimeSuggestions | null> {
  // Get current audit
  const currentAudit = await prisma.audit.findUnique({
    where: { id: auditId },
    include: {
      template: {
        include: {
          questions: true,
        },
      },
    },
  });

  if (!currentAudit) {
    return null;
  }

  const totalQuestions = currentAudit.template.questions.length;
  const answeredCount = currentAnswers.length;
  const progress = totalQuestions > 0 ? (answeredCount / totalQuestions) * 100 : 0;

  // Calculate current score based on answers
  let currentScore = 0;
  let positiveCount = 0;

  for (const answer of currentAnswers) {
    if (isPositiveAnswer(answer.value)) {
      positiveCount++;
    }
  }

  if (answeredCount > 0) {
    currentScore = Math.round((positiveCount / answeredCount) * 100);
  }

  // Get historical data for prediction
  const historicalAudits = await prisma.audit.findMany({
    where: {
      templateId: currentAudit.templateId,
      organizationId,
      status: 'completed',
    },
    include: {
      answers: true,
    },
    orderBy: { completedAt: 'desc' },
    take: 5,
  });

  // Calculate predicted score
  let predictedScore = currentScore;
  let confidence = 0.5;

  if (historicalAudits.length > 0) {
    const historicalScores = historicalAudits
      .map((a: { score: number | null }) => a.score)
      .filter((s: number | null): s is number => s !== null);

    if (historicalScores.length > 0) {
      const avgHistorical = historicalScores.reduce((a: number, b: number) => a + b, 0) / historicalScores.length;
      
      // Weighted prediction: current progress + historical average
      const progressWeight = progress / 100;
      predictedScore = Math.round(
        currentScore * progressWeight + avgHistorical * (1 - progressWeight)
      );
      
      // Confidence increases with progress
      confidence = Math.min(0.9, 0.3 + (progress / 100) * 0.6);
    }
  }

  // Generate alerts
  const alerts: Alert[] = [];

  // Alert for low current score
  if (answeredCount >= 3 && currentScore < 50) {
    alerts.push({
      type: 'danger',
      message: `Score actuel faible (${currentScore}%). Des améliorations urgentes sont nécessaires.`,
    });
  } else if (answeredCount >= 3 && currentScore < 70) {
    alerts.push({
      type: 'warning',
      message: `Score actuel: ${currentScore}%. Attention, certains points nécessitent une vigilance.`,
    });
  }

  // Alert for predicted low score
  if (progress >= 30 && predictedScore < 60) {
    alerts.push({
      type: 'warning',
      message: `Score prédit: ${predictedScore}%. Tendance à la baisse détectée.`,
    });
  }

  // Generate suggestions
  const suggestions: string[] = [];

  if (currentScore < 70 && progress < 50) {
    suggestions.push('Concentrez-vous sur les questions restantes pour améliorer le score.');
  }

  if (historicalAudits.length > 0) {
    // Find recurring issues from history
    const questionIssues = new Map<string, number>();
    
    for (const audit of historicalAudits) {
      for (const answer of audit.answers) {
        if (isNegativeAnswer(answer.value)) {
          questionIssues.set(
            answer.questionId,
            (questionIssues.get(answer.questionId) || 0) + 1
          );
        }
      }
    }

    // Suggest checking questions with historical issues
    const recurringIssueQuestions = Array.from(questionIssues.entries())
      .filter(([, count]) => count >= 2)
      .map(([qId]) => qId);

    if (recurringIssueQuestions.length > 0) {
      suggestions.push('Vérifiez les zones ayant eu des problèmes récurrents dans les audits précédents.');
    }
  }

  return {
    currentScore,
    predictedScore,
    confidence,
    alerts,
    suggestions,
    progress,
  };
}

/**
 * Check if an answer value is positive (conform)
 */
function isPositiveAnswer(value: string): boolean {
  const positiveValues = ['oui', 'yes', 'true', 'conforme', 'bon', 'ok', '1'];
  const lowerValue = value.toLowerCase().trim();
  return positiveValues.some((pos) => lowerValue.includes(pos));
}
