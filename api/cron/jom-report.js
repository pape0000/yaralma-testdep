/**
 * Vercel Cron Function: Send weekly Jom Report via WhatsApp.
 *
 * Schedule: Every Sunday at 08:00 AM (configure in vercel.json)
 * GET /api/cron/jom-report
 *
 * This function:
 * 1. Finds all users with whatsapp_phone linked
 * 2. Aggregates usage_stats for the past 7 days
 * 3. Sends a formatted "Jom Report" via Twilio WhatsApp API
 */

const { createClient } = require('@supabase/supabase-js');

module.exports = async (req, res) => {
  // Verify cron secret
  const cronSecret = process.env.CRON_SECRET;
  if (cronSecret && req.headers['authorization'] !== `Bearer ${cronSecret}`) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const twilioSid = process.env.TWILIO_ACCOUNT_SID;
  const twilioToken = process.env.TWILIO_AUTH_TOKEN;
  const twilioFrom = process.env.TWILIO_WHATSAPP_FROM; // e.g. "whatsapp:+14155238886"

  if (!supabaseUrl || !supabaseServiceKey) {
    return res.status(500).json({ error: 'Missing Supabase credentials' });
  }

  if (!twilioSid || !twilioToken || !twilioFrom) {
    return res.status(500).json({ error: 'Missing Twilio credentials' });
  }

  try {
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { persistSession: false },
    });

    // Get users with WhatsApp linked
    const { data: users, error: usersErr } = await supabase
      .from('profiles')
      .select('id, whatsapp_phone, faith_shield')
      .not('whatsapp_phone', 'is', null);

    if (usersErr) {
      console.error('Error fetching users:', usersErr);
      return res.status(500).json({ error: 'Database error' });
    }

    if (!users || users.length === 0) {
      return res.status(200).json({ success: true, message: 'No users with WhatsApp linked', sent: 0 });
    }

    // Calculate date range (past 7 days)
    const today = new Date();
    const weekAgo = new Date(today);
    weekAgo.setDate(weekAgo.getDate() - 7);
    const weekAgoStr = weekAgo.toISOString().split('T')[0];

    let sentCount = 0;
    const errors = [];

    for (const user of users) {
      try {
        // Get stats for the past week
        const { data: stats, error: statsErr } = await supabase
          .from('usage_stats')
          .select('screen_time_minutes, locks_honored, locks_bypassed, shorts_blocked, searches_blocked')
          .eq('user_id', user.id)
          .gte('stat_date', weekAgoStr);

        if (statsErr) {
          errors.push({ userId: user.id, error: statsErr.message });
          continue;
        }

        // Aggregate stats
        const totals = (stats || []).reduce(
          (acc, s) => ({
            screenTime: acc.screenTime + (s.screen_time_minutes || 0),
            locksHonored: acc.locksHonored + (s.locks_honored || 0),
            locksBypassed: acc.locksBypassed + (s.locks_bypassed || 0),
            shortsBlocked: acc.shortsBlocked + (s.shorts_blocked || 0),
            searchesBlocked: acc.searchesBlocked + (s.searches_blocked || 0),
          }),
          { screenTime: 0, locksHonored: 0, locksBypassed: 0, shortsBlocked: 0, searchesBlocked: 0 }
        );

        // Format the Jom Report message
        const message = formatJomReport(totals, user.faith_shield);

        // Send via Twilio WhatsApp
        const phone = normalizePhone(user.whatsapp_phone);
        await sendWhatsAppMessage(twilioSid, twilioToken, twilioFrom, phone, message);
        sentCount++;
      } catch (err) {
        errors.push({ userId: user.id, error: err.message });
      }
    }

    return res.status(200).json({
      success: true,
      sent: sentCount,
      errors: errors.length > 0 ? errors : undefined,
    });
  } catch (err) {
    console.error('Cron error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

function formatJomReport(totals, faithShield) {
  const hours = Math.floor(totals.screenTime / 60);
  const mins = totals.screenTime % 60;
  const screenTimeStr = hours > 0 ? `${hours}h ${mins}m` : `${mins}m`;

  const greeting = faithShield === 'christian' ? 'Blessed Sunday!' : 'Jom Report 🦁';

  let report = `${greeting}\n\n`;
  report += `📊 *Weekly Summary*\n`;
  report += `━━━━━━━━━━━━━━━━━━\n`;
  report += `📱 Screen time: ${screenTimeStr}\n`;
  report += `🙏 Holy Locks honored: ${totals.locksHonored}\n`;

  if (totals.locksBypassed > 0) {
    report += `⚠️ Locks bypassed: ${totals.locksBypassed}\n`;
  }

  if (totals.shortsBlocked > 0) {
    report += `🚫 Shorts blocked: ${totals.shortsBlocked}\n`;
  }

  if (totals.searchesBlocked > 0) {
    report += `🔍 Searches blocked: ${totals.searchesBlocked}\n`;
  }

  report += `━━━━━━━━━━━━━━━━━━\n`;
  report += `\nKeep guiding with love. 💚`;

  return report;
}

function normalizePhone(phone) {
  if (!phone) return '';
  // Remove "whatsapp:" prefix if present
  let p = phone.replace(/^whatsapp:/i, '');
  // Keep only digits and leading +
  p = p.replace(/[^\d+]/g, '');
  return p;
}

async function sendWhatsAppMessage(sid, token, from, to, body) {
  const url = `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`;
  const auth = Buffer.from(`${sid}:${token}`).toString('base64');

  const toFormatted = to.startsWith('+') ? `whatsapp:${to}` : `whatsapp:+${to}`;

  const params = new URLSearchParams();
  params.append('From', from);
  params.append('To', toFormatted);
  params.append('Body', body);

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${auth}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: params.toString(),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Twilio error: ${response.status} - ${errText}`);
  }

  return response.json();
}
