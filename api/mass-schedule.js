/**
 * Vercel Serverless Function: Set Sunday Mass lock windows for Christian users.
 *
 * POST /api/mass-schedule
 * Body: { userId: string }
 *
 * Creates lock windows for the next 4 Sundays: 08:00 - 11:30 local time.
 * Assumes user's timezone is stored in profile or defaults to Africa/Dakar.
 */

const { createClient } = require('@supabase/supabase-js');

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const url = process.env.SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !serviceKey) {
    return res.status(500).json({ error: 'Server misconfigured' });
  }

  const { userId, timezone } = req.body || {};

  if (!userId) {
    return res.status(400).json({ error: 'Missing required field: userId' });
  }

  try {
    const supabase = createClient(url, serviceKey, { auth: { persistSession: false } });

    // Compute next 4 Sundays
    const now = new Date();
    const sundays = [];
    let d = new Date(now);

    for (let i = 0; i < 28; i++) {
      d.setDate(d.getDate() + 1);
      if (d.getDay() === 0) {
        sundays.push(new Date(d));
        if (sundays.length >= 4) break;
      }
    }

    // Create lock windows for each Sunday 08:00 - 11:30
    // Using Africa/Dakar timezone (UTC+0) for simplicity
    const lockWindows = sundays.map((sunday) => {
      const dateStr = sunday.toISOString().split('T')[0]; // YYYY-MM-DD
      return {
        user_id: userId,
        start_time: `${dateStr}T08:00:00Z`,
        end_time: `${dateStr}T11:30:00Z`,
        lock_type: 'mass',
      };
    });

    // Delete existing mass lock windows for this user (for future dates)
    await supabase
      .from('lock_windows')
      .delete()
      .eq('user_id', userId)
      .eq('lock_type', 'mass')
      .gte('start_time', now.toISOString());

    // Insert new lock windows
    const { error: insertError } = await supabase.from('lock_windows').insert(lockWindows);

    if (insertError) {
      console.error('Insert error:', insertError);
      return res.status(500).json({ error: 'Failed to save mass schedule' });
    }

    return res.status(200).json({
      success: true,
      sundays: sundays.map((s) => s.toISOString().split('T')[0]),
      lockWindowsCount: lockWindows.length,
    });
  } catch (err) {
    console.error('Error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};
