-- ==========================================
-- 1. Setup 'profiles' Table Columns & RLS
-- ==========================================
-- Ensure 'profiles' table has 'avatar_url' column of type text
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS name text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS department text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role text DEFAULT 'employee';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS ledger_balance numeric(10, 2) DEFAULT 0.00;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS meals_ordered integer DEFAULT 0;

-- Enable Row Level Security on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing profiles policies if they exist to avoid conflict
DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;

-- Create policies
CREATE POLICY "Profiles are viewable by authenticated users"
  ON public.profiles FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE TO authenticated
  USING (auth.uid() = id);

-- ==========================================
-- 2. Setup 'pool_sessions' Table Columns
-- ==========================================
-- Add 'category' column to pool_sessions
ALTER TABLE public.pool_sessions ADD COLUMN IF NOT EXISTS category text;

-- ==========================================
-- 3. Setup 'clearance_requests' Table
-- ==========================================
CREATE TABLE IF NOT EXISTS public.clearance_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  username text NOT NULL,
  room text NOT NULL,
  reason text NOT NULL DEFAULT 'Cash Handover',
  amount numeric(10, 2) NOT NULL DEFAULT 0.00,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for clearance_requests
ALTER TABLE public.clearance_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any to prevent conflicts
DROP POLICY IF EXISTS "Users can view their own clearance requests" ON public.clearance_requests;
DROP POLICY IF EXISTS "Users can insert their own clearance requests" ON public.clearance_requests;
DROP POLICY IF EXISTS "Admins have full access to clearance requests" ON public.clearance_requests;

-- Create clearance policies
CREATE POLICY "Users can view their own clearance requests"
  ON public.clearance_requests FOR SELECT TO authenticated
  USING (auth.uid() = profile_id);

CREATE POLICY "Users can insert their own clearance requests"
  ON public.clearance_requests FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Admins have full access to clearance requests"
  ON public.clearance_requests FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ==========================================
-- 4. Setup Storage Bucket 'avatars' & Policies
-- ==========================================
-- Create the public storage bucket for avatars
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing storage policies on objects if any
DROP POLICY IF EXISTS "Allow public read access on avatars" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated uploads to avatars" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete or update their own avatars" ON storage.objects;

-- Create public read policy on avatars
CREATE POLICY "Allow public read access on avatars"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'avatars');

-- Create authenticated insert/upload policy on avatars
CREATE POLICY "Allow authenticated uploads to avatars"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars');

-- Create authenticated update/delete policy on avatars
CREATE POLICY "Allow users to delete or update their own avatars"
  ON storage.objects FOR ALL TO authenticated
  USING (bucket_id = 'avatars');
