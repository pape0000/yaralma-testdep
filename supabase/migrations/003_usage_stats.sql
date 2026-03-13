-- YARALMA Phase 8: usage_stats table for Jom Report weekly summaries.
-- Run this in Supabase Dashboard > SQL Editor after 002_lock_windows.sql.

-- Usage statistics: tracks daily events for weekly Jom Report
create table if not exists public.usage_stats (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  stat_date date not null default current_date,
  screen_time_minutes int default 0,
  locks_honored int default 0,
  locks_bypassed int default 0,
  shorts_blocked int default 0,
  searches_blocked int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id, stat_date)
);

create index if not exists idx_usage_stats_user_date on public.usage_stats(user_id, stat_date);

alter table public.usage_stats enable row level security;

-- Users can read their own stats
create policy "Users can read own usage_stats"
  on public.usage_stats for select
  using (auth.uid() = user_id);

-- Service role inserts/updates stats (RLS bypassed for service role)

comment on table public.usage_stats is 'Daily usage statistics for Jom Report (screen time, locks, blocks).';
