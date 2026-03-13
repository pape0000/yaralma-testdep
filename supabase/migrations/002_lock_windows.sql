-- YARALMA Phase 7: lock_windows table for Holy Lock (prayer times & Mass).
-- Run this in Supabase Dashboard > SQL Editor after 001_initial.sql.

-- Add location to profiles (lat/lng for prayer time calculation)
alter table public.profiles
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

-- Lock windows: scheduled periods when is_locked should be true
create table if not exists public.lock_windows (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  start_time timestamptz not null,
  end_time timestamptz not null,
  lock_type text not null check (lock_type in ('fajr', 'dhuhr', 'asr', 'maghrib', 'isha', 'mass', 'ramadan', 'lent')),
  created_at timestamptz default now()
);

create index if not exists idx_lock_windows_user on public.lock_windows(user_id);
create index if not exists idx_lock_windows_time on public.lock_windows(start_time, end_time);

alter table public.lock_windows enable row level security;

-- Users can read their own lock windows
create policy "Users can read own lock_windows"
  on public.lock_windows for select
  using (auth.uid() = user_id);

-- Service role inserts/updates lock windows (no policy needed; RLS bypassed)

comment on table public.lock_windows is 'Scheduled lock periods for Holy Lock (prayer times, Mass, Ramadan, Lent).';
