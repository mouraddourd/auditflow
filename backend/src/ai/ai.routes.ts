import { Router } from 'express';
import { generateAnalysis, checkOllamaHealth } from './ollama.service';
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

function buildAuditPrompt(auditData: any): string {
  const { templateName, templateDescription, responses } = auditData;
  
  const formattedResponses = responses
    .map((r: any) => {
      const comment = r.comment ? ` (Note: ${r.comment})` : '';
      return `Question: ${r.questionText}\nRéponse: ${r.value}${comment}`;
    })
    .join('\n\n');

  return `Tu es un assistant d'analyse d'audit générique et objectif.

TEMPLATE: ${templateName || 'Audit générique'}
${templateDescription ? `OBJECTIF: ${templateDescription}` : ''}

RÉPONSES DE L'AUDIT:
${formattedResponses}

Fournis une analyse structurée en français:

## RÉSUMÉ
2-3 phrases décrivant l'état global de cet audit.

## POINTS_FORTS
- Point fort 1
- Point fort 2

## POINTS_DE_VIGILANCE  
- Point à améliorer 1
- Point à améliorer 2

## SCORE_ESTIMÉ
X/100 (justifie en 1 phrase)

## RECOMMANDATIONS
- Action recommandée 1
- Action recommandée 2

Reste factuel, concis et objectif. Ne pas inventer d'informations.`;
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
