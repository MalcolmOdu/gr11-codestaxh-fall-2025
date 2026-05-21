const { onCall, HttpsError } = require('firebase-functions/v1/https');
const admin = require('firebase-admin');
admin.initializeApp();

// GEMINI_API_KEY is set in functions/.env (never committed to git).
// See functions/.env.example for the required format.
const GEMINI_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

async function callGemini(prompt) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw new HttpsError('internal', 'Gemini API key not configured.');

  const response = await fetch(`${GEMINI_URL}?key=${apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.3, maxOutputTokens: 200 },
    }),
  });

  if (response.status === 429) throw new HttpsError('resource-exhausted', 'Gemini rate limit reached.');
  if (!response.ok) throw new HttpsError('internal', `Gemini API error: ${response.status}`);

  const data = await response.json();
  return data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
}

// Returns comma-separated tag suggestions for a code snippet.
exports.suggestTags = onCall(async (data) => {
  const { code, language } = data;
  if (!code || !language) throw new HttpsError('invalid-argument', 'Missing code or language.');

  const prompt = `Analyze this ${language} code and suggest 3-5 relevant tags for categorization.\n\nCode:\n${code}\n\nReturn ONLY a comma-separated list of tags. No explanation, no formatting, just tags.\nExample: authentication, API, REST, security`;
  const text = await callGemini(prompt);
  return { tags: text };
});

// Returns a plain-English explanation of a code snippet.
exports.explainCode = onCall(async (data) => {
  const { code, language } = data;
  if (!code || !language) throw new HttpsError('invalid-argument', 'Missing code or language.');

  const prompt = `Explain what this ${language} code does in 2-3 clear sentences.\nUse simple language that a beginner can understand. Focus on WHAT the code does, not HOW it works.\n\nCode:\n${code}\n\nProvide a concise explanation (2-3 sentences maximum):`;
  const text = await callGemini(prompt);
  return { explanation: text };
});
