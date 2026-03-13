-- Supabase RPC function to increment a usage stat atomically.
-- Run this in Supabase Dashboard > SQL Editor after 003_usage_stats.sql.

create or replace function increment_usage_stat(
  p_user_id uuid,
  p_stat_date date,
  p_stat_name text,
  p_amount int default 1
)
returns void
language plpgsql
security definer
as $$
begin
  -- Insert if not exists
  insert into public.usage_stats (user_id, stat_date)
  values (p_user_id, p_stat_date)
  on conflict (user_id, stat_date) do nothing;

  -- Update the specific stat
  execute format(
    'update public.usage_stats set %I = coalesce(%I, 0) + $1, updated_at = now() where user_id = $2 and stat_date = $3',
    p_stat_name, p_stat_name
  )
  using p_amount, p_user_id, p_stat_date;
end;
$$;

-- Grant execute to authenticated users
grant execute on function increment_usage_stat to authenticated;
