/**
 * Vercel Serverless Function: Fetch prayer times from Aladhan API
 * and save lock windows to Supabase.
 *
 * POST /api/prayer-times
 * Body: { userId: string, latitude: number, longitude: number, date?: string (DD-MM-YYYY) }
 *
 * Uses Aladhan API (free, no API key required).
 */

const { createClient } = require('@supabase/supabase-js');

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const url = process.env.SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !serviceKey) {
    return res.status(500).json({ error: 'Server misconfigured: missing Supabase credentials' });
  }

  const { userId, latitude, longitude, date } = req.body || {};

  if (!userId || typeof latitude !== 'number' || typeof longitude !== 'number') {
    return res.status(400).json({ error: 'Missing required fields: userId, latitude, longitude' });
  }

  try {
    // Fetch prayer times from Aladhan API
    const today = date || formatDate(new Date());
    const aladhanUrl = `https://api.aladhan.com/v1/timings/${today}?latitude=${latitude}&longitude=${longitude}&method=3`;

    const aladhanRes = await fetch(aladhanUrl);
    if (!aladhanRes.ok) {
      return res.status(502).json({ error: 'Failed to fetch prayer times from Aladhan' });
    }

    const aladhanData = await aladhanRes.json();
    const timings = aladhanData?.data?.timings;

    if (!timings) {
      return res.status(502).json({ error: 'Invalid response from Aladhan API' });
    }

    // Parse prayer times into lock windows (each prayer locks for ~20 minutes)
    const lockDurationMinutes = 20;
    const dateStr = aladhanData?.data?.date?.gregorian?.date; // DD-MM-YYYY
    const [day, month, year] = dateStr ? dateStr.split('-') : today.split('-');
    const isoDatePrefix = `${year}-${month}-${day}`;

    const prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    const lockWindows = [];

    for (const prayer of prayers) {
      const timeStr = timings[prayer]; // e.g. "05:30"
      if (!timeStr) continue;

      const [hours, minutes] = timeStr.split(':').map(Number);
      const startTime = new Date(`${isoDatePrefix}T${timeStr}:00`);
      const endTime = new Date(startTime.getTime() + lockDurationMinutes * 60 * 1000);

      lockWindows.push({
        user_id: userId,
        start_time: startTime.toISOString(),
        end_time: endTime.toISOString(),
        lock_type: prayer.toLowerCase(),
      });
    }

    // Save lock windows to Supabase (upsert by deleting old ones for this date first)
    const supabase = createClient(url, serviceKey, { auth: { persistSession: false } });

    // Delete existing prayer lock windows for this user for today
    const startOfDay = new Date(`${isoDatePrefix}T00:00:00Z`);
    const endOfDay = new Date(`${isoDatePrefix}T23:59:59Z`);

    await supabase
      .from('lock_windows')
      .delete()
      .eq('user_id', userId)
      .in('lock_type', ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'])
      .gte('start_time', startOfDay.toISOString())
      .lte('start_time', endOfDay.toISOString());

    // Insert new lock windows
    const { error: insertError } = await supabase.from('lock_windows').insert(lockWindows);

    if (insertError) {
      console.error('Insert error:', insertError);
      return res.status(500).json({ error: 'Failed to save lock windows' });
    }

    return res.status(200).json({
      success: true,
      date: dateStr || today,
      timings: {
        Fajr: timings.Fajr,
        Dhuhr: timings.Dhuhr,
        Asr: timings.Asr,
        Maghrib: timings.Maghrib,
        Isha: timings.Isha,
      },
      lockWindowsCount: lockWindows.length,
    });
  } catch (err) {
    console.error('Error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

function formatDate(d) {
  const day = String(d.getDate()).padStart(2, '0');
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const year = d.getFullYear();
  return `${day}-${month}-${year}`;
}
