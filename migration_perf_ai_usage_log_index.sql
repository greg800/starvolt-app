-- Fix P2 : index manquant sur ai_usage_log — utilisé par le rate-limiting de
-- toutes les fonctions IA. Sans cet index, chaque appel fait un full-scan.
CREATE INDEX IF NOT EXISTS idx_ai_usage_log_rate_limit
  ON public.ai_usage_log (feature, user_email, created_at DESC);
