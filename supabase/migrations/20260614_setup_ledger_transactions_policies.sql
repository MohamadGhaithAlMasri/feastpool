-- 1. Enable Row Level Security (RLS) on ledger_transactions
ALTER TABLE public.ledger_transactions ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies if any to prevent conflicts
DROP POLICY IF EXISTS "Users can view their own transactions" ON public.ledger_transactions;
DROP POLICY IF EXISTS "Users can insert their own transactions" ON public.ledger_transactions;
DROP POLICY IF EXISTS "Admins have full access to transactions" ON public.ledger_transactions;

-- 3. Policy: Allow users to view their own ledger transactions
CREATE POLICY "Users can view their own transactions"
  ON public.ledger_transactions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = profile_id);

-- 4. Policy: Allow users to insert their own ledger transactions (needed to save order history on checkout)
CREATE POLICY "Users can insert their own transactions"
  ON public.ledger_transactions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = profile_id);

-- 5. Policy: Allow admins to manage/record transactions (needed to record payment received settlement)
CREATE POLICY "Admins have full access to transactions"
  ON public.ledger_transactions
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
