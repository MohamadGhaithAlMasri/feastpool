-- Create clearance_requests table
CREATE TABLE IF NOT EXISTS public.clearance_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  username text NOT NULL,
  room text NOT NULL,
  reason text NOT NULL DEFAULT 'Cash Handover',
  amount numeric(10, 2) NOT NULL DEFAULT 0.00,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.clearance_requests ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own clearance requests
CREATE POLICY "Users can view their own clearance requests"
  ON public.clearance_requests
  FOR SELECT
  TO authenticated
  USING (auth.uid() = profile_id);

-- Allow authenticated users to insert their own clearance requests
CREATE POLICY "Users can insert their own clearance requests"
  ON public.clearance_requests
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = profile_id);

-- Allow admins full access (select, delete) to manage clearance requests
CREATE POLICY "Admins have full access to clearance requests"
  ON public.clearance_requests
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
