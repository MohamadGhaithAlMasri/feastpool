-- 1. Create the device_tokens table to track FCM tokens per user
create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  token text not null unique,
  platform text, -- web, android, ios
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security (RLS)
alter table public.device_tokens enable row level security;

-- Create policy to allow authenticated users to insert/update their own tokens
create policy "Users can insert their own device tokens"
  on public.device_tokens
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update their own device tokens"
  on public.device_tokens
  for update
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can delete their own device tokens"
  on public.device_tokens
  for delete
  to authenticated
  using (auth.uid() = user_id);

-- 2. Optional: Setup a webhook or Trigger to automatically fire a function when a new session starts
-- Note: You would deploy a Supabase Edge Function named 'send-session-notification'
-- and configure it as a trigger:
--
-- create trigger on_session_started
--   after insert on public.pool_sessions
--   for each row
--   when (new.is_active = true)
--   execute function supabase_functions.http_request(
--     'http://localhost:54321/functions/v1/send-session-notification', -- Replace with your deployed Edge Function URL
--     'POST',
--     '{"Content-Type":"application/json"}',
--     '{}',
--     '1000'
--   );
