-- ============================================================
-- HOLLA Urban — Schema additions
-- À appliquer après schema.sql dans le dashboard Supabase
-- ============================================================

-- ── Table ratings ────────────────────────────────────────────
create table public.ratings (
  id           uuid        default gen_random_uuid() primary key,
  order_id     uuid        references public.orders,
  reviewer_id  uuid        references public.profiles not null,
  target_id    uuid        not null,
  target_type  text        check (target_type in ('partner', 'delivery', 'provider')),
  score        int         check (score between 1 and 5),
  comment      text,
  created_at   timestamptz default now()
);

-- Activer RLS
alter table public.ratings enable row level security;

-- Politique : seul l'auteur peut insérer sa notation
create policy "ratings_insert" on public.ratings
  for insert
  with check (auth.uid() = reviewer_id);

-- Politique : tout le monde peut lire les notations
create policy "ratings_read" on public.ratings
  for select
  using (true);

-- Politique : les admins ont accès total
create policy "admin_ratings" on public.ratings
  for all
  using (public.is_admin());

-- ── Index pour optimiser les requêtes fréquentes ─────────────
create index if not exists ratings_order_id_idx      on public.ratings (order_id);
create index if not exists ratings_target_id_idx     on public.ratings (target_id);
create index if not exists ratings_reviewer_id_idx   on public.ratings (reviewer_id);

-- ── Vue : note moyenne par cible (partenaire/livreur/prestataire) ─
create or replace view public.target_avg_ratings as
  select
    target_id,
    target_type,
    round(avg(score)::numeric, 1) as avg_score,
    count(*)                       as total_ratings
  from public.ratings
  group by target_id, target_type;

-- Accès public en lecture sur la vue
grant select on public.target_avg_ratings to anon, authenticated;

-- ============================================================
-- ── Table disputes (litiges clients) ─────────────────────────
-- ============================================================

create table public.disputes (
  id           uuid        default gen_random_uuid() primary key,
  order_id     uuid        references public.orders,
  client_id    uuid        references public.profiles not null,
  reason       text        not null,
  description  text,
  status       text        default 'open'
                           check (status in ('open', 'in_review', 'resolved', 'rejected')),
  admin_note   text,
  created_at   timestamptz default now(),
  resolved_at  timestamptz
);

-- Activer RLS
alter table public.disputes enable row level security;

-- Le client peut lire et créer ses propres litiges
create policy "disputes_client" on public.disputes
  for all
  using (auth.uid() = client_id);

-- Les admins ont accès à tous les litiges
create policy "disputes_admin" on public.disputes
  for all
  using (public.is_admin());

-- Index pour optimiser les requêtes
create index if not exists disputes_order_id_idx   on public.disputes (order_id);
create index if not exists disputes_client_id_idx  on public.disputes (client_id);
create index if not exists disputes_status_idx     on public.disputes (status);
