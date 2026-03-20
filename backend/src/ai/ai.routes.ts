import { Router } from 'express';
import { generateAnalysis, checkOllamaHealth } from './ollama.service';
import { getAuditInsights, getRealTimeSuggestions } from './insights.service';
import { requireAuth } from '../auth/auth.middleware';

const router = Router();

// Check AI service health
router.get('/health', async (req, res) => {
  const isHealthy = await checkOllamaHealth();
  res.json({ 
    available: isHealthy,
    model: process.env.OLLAMA_MODEL || 'phi3',
    timestamp: new Date().toISOString()
  });
});

// Analyze audit with AI
router.post('/analyze', requireAuth, async (req, res) => {
  try {
    const { auditData } = req.body;
    
    if (!auditData || !auditData.responses || !Array.isArray(auditData.responses)) {
      return res.status(400).json({ 
        success: false,
        error: 'Invalid audit data: responses array required' 
      });
    }

    // Build prompt for analysis
    const prompt = buildAuditPrompt(auditData);
    
    // Generate analysis via Ollama
    const analysisText = await generateAnalysis(prompt);
    
    // Parse structured response
    const parsed = parseAIResponse(analysisText);
    
    res.json({
      success: true,
      analysis: parsed,
      model: process.env.OLLAMA_MODEL || 'phi3',
      generatedAt: new Date().toISOString(),
    });
  } catch (error) {
    console.error('AI analysis error:', error);
    res.status(503).json({ 
      success: false,
      error: 'AI service unavailable',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Get audit insights with historical analysis
router.get('/insights/:auditId', requireAuth, async (req, res) => {
  try {
    const auditId = String(req.params.auditId);
    const organizationId = String(req.headers['x-organization-id'] || '');

    if (!organizationId) {
      return res.status(400).json({
        success: false,
        error: 'Organization ID required',
      });
    }

    const insights = await getAuditInsights(auditId, organizationId);

    if (!insights) {
      return res.status(404).json({
        success: false,
        error: 'Audit not found',
      });
    }

    res.json({
      success: true,
      insights,
    });
  } catch (error) {
    console.error('AI insights error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to generate insights',
      details: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});

// Get real-time suggestions for audit in progress
router.post('/real-time-suggestions/:auditId', requireAuth, async (req, res) => {
  try {
    const auditId = String(req.params.auditId);
    const organizationId = String(req.headers['x-organization-id'] || '');
    const { answers } = req.body as { answers: { questionId: string; value: string }[] };

    if (!organizationId) {
      return res.status(400).json({
        success: false,
        error: 'Organization ID required',
      });
    }

    if (!answers || !Array.isArray(answers)) {
      return res.status(400).json({
        success: false,
        error: 'Answers array required in request body',
      });
    }

    const suggestions = await getRealTimeSuggestions(auditId, organizationId, answers);

    if (!suggestions) {
      return res.status(404).json({
        success: false,
        error: 'Audit not found',
      });
    }

    res.json({
      success: true,
      suggestions,
    });
  } catch (error) {
    console.error('Real-time suggestions error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to generate suggestions',
      details: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});

function buildAuditPrompt(auditData: any): string {
  const { templateName, templateDescription, responses } = auditData;
  
  const formattedResponses = responses
    .map((r: any) => {
      const comment = r.comment ? ` (Note: ${r.comment})` : '';
      return `Question: ${r.questionText}\nRéponse: ${r.value}${comment}`;
    })
    .join('\n\n');

  return `Tu es un assistant d'audit. Analyse ces réponses et fournis une évaluation COURTE et DIRECTE.

TEMPLATE: ${templateName || 'Audit générique'}
${templateDescription ? `OBJECTIF: ${templateDescription}` : ''}

RÉPONSES:
${formattedResponses}

Fournis une analyse structurée en français:

## RÉSUMÉ
1 phrase résumant l'état global.

## POINTS_FORTS
- Élément conforme 1
- Élément conforme 2
(Maximum 3 points, format: "Élément - État")

## POINTS_DE_VIGILANCE  
- Élément non conforme 1 → Action immédiate
- Élément non conforme 2 → Action immédiate
(Maximum 3 points, format: "Problème → Solution courte")

## SCORE_ESTIMÉ
X/100

## RECOMMANDATIONS
- Action prioritaire 1
- Action prioritaire 2
(Maximum 3 actions concrètes et courtes)

SOIS CONCIS. Pas de détails superflus. Réponses directes et actionnables.`;
}

function parseAIResponse(text: string): any {
  const sections: Record<string, string> = {};
  const lines = text.split('\n');
  let currentSection = '';
  
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith('## ')) {
      currentSection = trimmed
        .replace('## ', '')
        .toUpperCase()
        .replace(/[\s-]+/g, '_');
      sections[currentSection] = '';
    } else if (currentSection && trimmed) {
      sections[currentSection] += trimmed + '\n';
    }
  }
  
  return {
    raw: text,
    summary: extractSection(sections, 'RÉSUMÉ') || extractSection(sections, 'RESUME'),
    strengths: extractListItems(sections['POINTS_FORTS'] || sections['POINTS_FORTS']),
    concerns: extractListItems(sections['POINTS_DE_VIGILANCE'] || sections['POINTS_DE_VIGILANCE']),
    estimatedScore: extractScore(sections['SCORE_ESTIMÉ'] || sections['SCORE_ESTIME']),
    recommendations: extractListItems(sections['RECOMMANDATIONS']),
  };
}

function extractSection(sections: Record<string, string>, key: string): string {
  return sections[key]?.trim() || '';
}

function extractListItems(text: string | undefined): string[] {
  if (!text) return [];
  return text
    .split('\n')
    .filter(line => line.trim().startsWith('-') || line.trim().startsWith('•'))
    .map(line => line.replace(/^[-•]\s*/, '').trim())
    .filter(item => item.length > 0);
}

function extractScore(text: string | undefined): number | null {
  if (!text) return null;
  const match = text.match(/(\d+)\s*\/\s*100/);
  return match ? parseInt(match[1], 10) : null;
}

export default router;
