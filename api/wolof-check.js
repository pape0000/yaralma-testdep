/**
 * Vercel Serverless Function: Check Wolof transcription for blocked keywords
 *
 * POST /api/wolof-check
 * Body: { transcription: string }
 *
 * Checks transcription against blocked Wolof keywords in Supabase.
 * Returns whether content should be muted.
 */

const { createClient } = require('@supabase/supabase-js');

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !supabaseKey) {
    return res.status(500).json({ error: 'Supabase not configured' });
  }

  const { transcription } = req.body || {};
  if (!transcription) {
    return res.status(400).json({ error: 'Missing transcription' });
  }

  try {
    const supabase = createClient(supabaseUrl, supabaseKey, {
      auth: { persistSession: false },
    });

    // Fetch blocked keywords (Wolof and French)
    const { data: keywords, error } = await supabase
      .from('blocked_keywords')
      .select('keyword')
      .in('language', ['wolof', 'french']);

    if (error) {
      console.error('Database error:', error);
      return res.status(500).json({ error: 'Database error' });
    }

    const blockedKeywords = (keywords || []).map((k) => k.keyword.toLowerCase());
    const transcriptionLower = transcription.toLowerCase();

    // Check for matches
    const foundKeywords = blockedKeywords.filter((keyword) =>
      transcriptionLower.includes(keyword)
    );

    const shouldMute = foundKeywords.length > 0;

    return res.status(200).json({
      success: true,
      shouldMute,
      foundKeywords,
      transcription,
    });
  } catch (err) {
    console.error('Check error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};
