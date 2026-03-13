/**
 * Vercel Cron Function: Check lock_windows and set is_locked accordingly.
 *
 * Schedule: Every 5 minutes (configure in vercel.json)
 * GET /api/cron/holy-lock
 *
 * This function:
 * 1. Finds all users with active lock windows (start_time <= now <= end_time)
 * 2. Sets is_locked = true for those users
 * 3. Sets is_locked = false for users whose lock window just ended
 */

const { createClient } = require('@supabase/supabase-js');

module.exports = async (req, res) => {
  // Optional: Verify cron secret to prevent unauthorized calls
  const cronSecret = process.env.CRON_SECRET;
  if (cronSecret && req.headers['authorization'] !== `Bearer ${cronSecret}`) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const url = process.env.SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !serviceKey) {
    return res.status(500).json({ error: 'Server misconfigured' });
  }

  try {
    const supabase = createClient(url, serviceKey, { auth: { persistSession: false } });
    const now = new Date().toISOString();

    // Find all users with active lock windows right now
    const { data: activeWindows, error: activeErr } = await supabase
      .from('lock_windows')
      .select('user_id')
      .lte('start_time', now)
      .gte('end_time', now);

    if (activeErr) {
      console.error('Error fetching active windows:', activeErr);
      return res.status(500).json({ error: 'Database error' });
    }

    const activeUserIds = [...new Set((activeWindows || []).map((w) => w.user_id))];

    // Set is_locked = true for users with active windows
    if (activeUserIds.length > 0) {
      const { error: lockErr } = await supabase
        .from('profiles')
        .update({ is_locked: true })
        .in('id', activeUserIds);

      if (lockErr) {
        console.error('Error locking users:', lockErr);
      }
    }

    // Find users who were locked but no longer have active windows
    // (Users with is_locked = true but not in activeUserIds)
    const { data: lockedProfiles, error: lockedErr } = await supabase
      .from('profiles')
      .select('id')
      .eq('is_locked', true);

    if (lockedErr) {
      console.error('Error fetching locked profiles:', lockedErr);
      return res.status(500).json({ error: 'Database error' });
    }

    const lockedUserIds = (lockedProfiles || []).map((p) => p.id);
    const toUnlock = lockedUserIds.filter((id) => !activeUserIds.includes(id));

    if (toUnlock.length > 0) {
      const { error: unlockErr } = await supabase
        .from('profiles')
        .update({ is_locked: false })
        .in('id', toUnlock);

      if (unlockErr) {
        console.error('Error unlocking users:', unlockErr);
      }
    }

    return res.status(200).json({
      success: true,
      timestamp: now,
      locked: activeUserIds.length,
      unlocked: toUnlock.length,
    });
  } catch (err) {
    console.error('Cron error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};
