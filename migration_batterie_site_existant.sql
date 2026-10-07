-- Gain réel : option « batterie intégrée à un site existant » (derrière le
-- compteur d'un site déjà raccordé) + taux d'accise non exonéré par domaine.
begin;
alter table public.spot_batterie_params add column if not exists integration text not null default 'seule'
  check (integration in ('seule', 'site'));
alter table public.spot_batterie_params add column if not exists site_kva numeric;
alter table public.spot_batterie_params add column if not exists puissance_ajoutee_kva numeric;
-- Accise au taux normal (charge non distinguée de la consommation du site), c€/kWh.
update public.turpe_stockage set grille = jsonb_set(jsonb_set(jsonb_set(grille,
  '{domaines,bt36,acciseTaxee}', '3.062'), '{domaines,bt250,acciseTaxee}', '2.635'), '{domaines,hta,acciseTaxee}', '2.635')
where id = 1 and grille->'domaines'->'bt36'->'acciseTaxee' is null;
commit;
