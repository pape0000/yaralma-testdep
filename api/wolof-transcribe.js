/**
 * Vercel Serverless Function: Wolof Speech-to-Text using Hugging Face
 *
 * POST /api/wolof-transcribe
 * Body: { audioBase64: string } (base64 encoded audio)
 *
 * Uses SpeechBrain wav2vec2 model for Wolof ASR via Hugging Face Inference API.
 * Free tier: ~30K requests/month
 */

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const hfToken = process.env.HUGGINGFACE_API_TOKEN;
  if (!hfToken) {
    return res.status(500).json({ error: 'Hugging Face API token not configured' });
  }

  const { audioBase64 } = req.body || {};
  if (!audioBase64) {
    return res.status(400).json({ error: 'Missing audioBase64 in request body' });
  }

  try {
    // Convert base64 to buffer
    const audioBuffer = Buffer.from(audioBase64, 'base64');

    // Call Hugging Face Inference API with SpeechBrain Wolof model
    const response = await fetch(
      'https://api-inference.huggingface.co/models/speechbrain/asr-wav2vec2-dvoice-wolof',
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${hfToken}`,
          'Content-Type': 'audio/wav',
        },
        body: audioBuffer,
      }
    );

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Hugging Face API error:', errorText);
      return res.status(502).json({ error: 'ASR service error', details: errorText });
    }

    const result = await response.json();

    // Extract transcription text
    const transcription = result.text || (Array.isArray(result) ? result[0]?.text : '');

    return res.status(200).json({
      success: true,
      transcription: transcription,
      raw: result,
    });
  } catch (err) {
    console.error('Transcription error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};
