-- Add category column to pool_sessions if it doesn't exist
ALTER TABLE public.pool_sessions ADD COLUMN IF NOT EXISTS category text;
