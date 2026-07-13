-- Finisseur serveur Switchgrid : colonne d'empreinte de sondage.
-- Le client actif rafraichit last_polled_at ~toutes les 8s (via finalizeRec).
-- Le cron finisseur ne reprend une demande que si last_polled_at est null ou
-- vieux de >90s → il ne double-traite jamais un onglet client encore ouvert.
alter table public.switchgrid_requests
  add column if not exists last_polled_at timestamptz;
