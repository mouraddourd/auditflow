import axios from 'axios';

const OLLAMA_BASE_URL = process.env.OLLAMA_URL || 'http://localhost:11434';
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || 'phi3';

interface OllamaGenerateRequest {
  model: string;
  prompt: string;
  stream: boolean;
  options?: {
    temperature?: number;
    num_ctx?: number;
    top_p?: number;
  };
}

interface OllamaGenerateResponse {
  model: string;
  created_at: string;
  response: string;
  done: boolean;
}

export async function generateAnalysis(prompt: string): Promise<string> {
  const request: OllamaGenerateRequest = {
    model: OLLAMA_MODEL,
    prompt: prompt,
    stream: false,
    options: {
      temperature: 0.7,
      num_ctx: 4096,
      top_p: 0.9,
    },
  };

  try {
    const response = await axios.post<OllamaGenerateResponse>(
      `${OLLAMA_BASE_URL}/api/generate`,
      request,
      { timeout: 120000 } // 2 minutes for LLM generation
    );

    return response.data.response;
  } catch (error) {
    console.error('Ollama generation failed:', error);
    throw new Error('AI generation failed');
  }
}

export async function checkOllamaHealth(): Promise<boolean> {
  try {
    await axios.get(`${OLLAMA_BASE_URL}/api/tags`, { timeout: 5000 });
    return true;
  } catch {
    return false;
  }
}
