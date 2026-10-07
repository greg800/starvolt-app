-- Grille TURPE / taxes du « gain batterie réel », éditable depuis l'admin
-- (page Prix spot → Hypothèses). Une seule ligne (id = 1), grille en jsonb ;
-- le front garde la même grille en dur comme valeur de repli.
begin;
create table if not exists public.turpe_stockage (
  id          int primary key default 1 check (id = 1),
  grille      jsonb not null,
  updated_at  timestamptz not null default now(),
  updated_by  text
);
alter table public.turpe_stockage enable row level security;
drop policy if exists lecture on public.turpe_stockage;
create policy lecture on public.turpe_stockage for select to authenticated using (true);
drop policy if exists admin_ecriture on public.turpe_stockage;
create policy admin_ecriture on public.turpe_stockage for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

insert into public.turpe_stockage (id, grille, updated_by) values (1, $j$
{
  "dateEffet": "1er août 2026",
  "cta": 15,
  "tva": 20,
  "domaines": {
    "bt36":  { "option": "Courte utilisation 4 plages",
               "soutirage": { "HPH": 7.72, "HCH": 4.09, "HPB": 1.71, "HCB": 1.20 },
               "injection": 0, "puissance": 10.42, "gestion": 26.95, "comptage": 22.67, "accise": 3.062 },
    "bt250": { "option": "Courte utilisation 4 plages",
               "soutirage": { "HPH": 7.12, "HCH": 4.34, "HPB": 2.19, "HCB": 1.57 },
               "injection": 0, "puissance": 18.15, "gestion": 366.14, "comptage": 291.88, "accise": 0 },
    "hta":   { "option": "Courte utilisation 5 plages, pointe fixe",
               "soutirage": { "P": 5.91, "HPH": 4.36, "HCH": 2.05, "HPB": 1.04, "HCB": 0.71 },
               "injection": 0, "puissance": 14.85, "gestion": 732.28, "comptage": 387.84, "accise": 0 }
  }
}
$j$::jsonb, 'seed CRE 2026-105') on conflict (id) do nothing;
commit;
