-- ══════════════════════════════════════════════════════════════
-- HOLLA URBAN — Supabase Schema
-- Coller ce SQL dans l'éditeur SQL de ton dashboard Supabase
-- ══════════════════════════════════════════════════════════════

-- ── Extensions ────────────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ── Profiles (extension de auth.users) ────────────────────────
create table public.profiles (
  id          uuid references auth.users on delete cascade primary key,
  full_name   text,
  phone       text,
  role        text check (role in ('client','partner','delivery','provider','admin')),
  avatar_url  text,
  city        text,
  is_active   boolean default true,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- ── Partenaires (restaurant, boutique, commerçant) ────────────
create table public.partners (
  id              uuid references public.profiles on delete cascade primary key,
  business_name   text not null,
  business_type   text check (business_type in ('restaurant','shop','market','pharmacy','other')),
  address         text,
  lat             double precision,
  lng             double precision,
  is_open         boolean default true,
  rating          numeric(2,1) default 0,
  total_orders    int default 0,
  cover_url       text,
  description     text
);

-- ── Livreurs ──────────────────────────────────────────────────
create table public.delivery_agents (
  id                 uuid references public.profiles on delete cascade primary key,
  vehicle_type       text check (vehicle_type in ('moto','car','bicycle','foot')),
  plate              text,
  is_available       boolean default false,
  current_lat        double precision,
  current_lng        double precision,
  total_deliveries   int default 0,
  rating             numeric(2,1) default 0,
  today_earnings     int default 0
);

-- ── Prestataires de services ──────────────────────────────────
create table public.service_providers (
  id              uuid references public.profiles on delete cascade primary key,
  specialty       text not null,
  bio             text,
  hourly_rate     int,
  is_available    boolean default true,
  rating          numeric(2,1) default 0,
  total_jobs      int default 0
);

-- ── Commandes ─────────────────────────────────────────────────
create table public.orders (
  id                  uuid default gen_random_uuid() primary key,
  order_number        text unique default 'HL-' || floor(random()*90000+10000)::text,
  client_id           uuid references public.profiles not null,
  partner_id          uuid references public.partners,
  delivery_agent_id   uuid references public.delivery_agents,
  status              text default 'pending' check (
                        status in ('pending','confirmed','preparing','on_the_way','delivered','cancelled')
                      ),
  delivery_address    text not null,
  delivery_lat        double precision,
  delivery_lng        double precision,
  subtotal            int not null,
  service_fee         int default 500,
  delivery_fee        int default 2000,
  total               int not null,
  payment_method      text check (payment_method in ('mtn','orange','card','cash')),
  payment_status      text default 'pending' check (payment_status in ('pending','paid','failed')),
  payment_ref         text,
  notes               text,
  created_at          timestamptz default now(),
  updated_at          timestamptz default now()
);

-- ── Articles de commande ──────────────────────────────────────
create table public.order_items (
  id            uuid default gen_random_uuid() primary key,
  order_id      uuid references public.orders on delete cascade,
  product_name  text not null,
  quantity      int default 1,
  unit_price    int not null,
  total_price   int not null
);

-- ── Demandes de services (prestataires) ───────────────────────
create table public.service_requests (
  id              uuid default gen_random_uuid() primary key,
  client_id       uuid references public.profiles not null,
  provider_id     uuid references public.service_providers,
  specialty       text not null,
  description     text,
  address         text,
  scheduled_at    timestamptz,
  status          text default 'pending' check (
                    status in ('pending','accepted','in_progress','completed','cancelled')
                  ),
  estimated_price int,
  total           int,
  created_at      timestamptz default now()
);

-- ── Paiements ─────────────────────────────────────────────────
create table public.payments (
  id            uuid default gen_random_uuid() primary key,
  order_id      uuid references public.orders,
  request_id    uuid references public.service_requests,
  amount        int not null,
  currency      text default 'XAF',
  method        text not null,
  phone         text,
  campay_ref    text,
  status        text default 'pending' check (status in ('pending','successful','failed')),
  created_at    timestamptz default now()
);

-- ── Table administrateurs ─────────────────────────────────────
create table public.administrators (
  id           uuid references public.profiles on delete cascade primary key,
  access_level int default 1,  -- 1=moderateur, 2=admin, 3=super_admin
  can_delete   boolean default false,
  can_ban      boolean default true,
  notes        text,
  created_at   timestamptz default now()
);

-- ══════════════════════════════════════════════════════════════
-- RLS (Row Level Security)
-- ══════════════════════════════════════════════════════════════

alter table public.profiles          enable row level security;
alter table public.partners          enable row level security;
alter table public.delivery_agents   enable row level security;
alter table public.service_providers enable row level security;
alter table public.orders            enable row level security;
alter table public.order_items       enable row level security;
alter table public.service_requests  enable row level security;
alter table public.payments          enable row level security;

-- Profiles: chacun lit/modifie le sien; tout le monde peut lire
create policy "profiles_public_read"    on public.profiles for select using (true);
create policy "profiles_self_update"    on public.profiles for update using (auth.uid() = id);

-- Partners: lecture publique, modif par le partenaire lui-même
create policy "partners_public_read"    on public.partners for select using (true);
create policy "partners_self_write"     on public.partners for all using (auth.uid() = id);

-- Delivery agents: lecture publique
create policy "delivery_public_read"    on public.delivery_agents for select using (true);
create policy "delivery_self_write"     on public.delivery_agents for all using (auth.uid() = id);

-- Service providers: lecture publique
create policy "provider_public_read"    on public.service_providers for select using (true);
create policy "provider_self_write"     on public.service_providers for all using (auth.uid() = id);

-- Orders: client voit les siennes, partner/livreur voient les leurs
create policy "orders_client"           on public.orders for all    using (auth.uid() = client_id);
create policy "orders_partner_read"     on public.orders for select using (auth.uid() = partner_id);
create policy "orders_delivery_read"    on public.orders for select using (auth.uid() = delivery_agent_id);
create policy "orders_delivery_update"  on public.orders for update using (auth.uid() = delivery_agent_id);
create policy "orders_partner_update"   on public.orders for update using (auth.uid() = partner_id);

-- Order items: lié aux orders
create policy "items_via_order"         on public.order_items for all using (
  exists (select 1 from public.orders o where o.id = order_id and (
    o.client_id = auth.uid() or o.partner_id = auth.uid() or o.delivery_agent_id = auth.uid()
  ))
);

-- Service requests
create policy "req_client"              on public.service_requests for all    using (auth.uid() = client_id);
create policy "req_provider_read"       on public.service_requests for select using (auth.uid() = provider_id);
create policy "req_provider_update"     on public.service_requests for update using (auth.uid() = provider_id);

-- Payments: liés à l'utilisateur
create policy "payments_owner"          on public.payments for all using (
  exists (select 1 from public.orders o where o.id = order_id and o.client_id = auth.uid())
);

-- ══════════════════════════════════════════════════════════════
-- RLS Administrateur — bypass total (lecture + écriture)
-- L'admin voit et peut modifier toutes les données
-- ══════════════════════════════════════════════════════════════
alter table public.administrators enable row level security;
create policy "admin_self"              on public.administrators for all using (auth.uid() = id);

create or replace function public.is_admin()
returns boolean as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$ language sql security definer stable;

create policy "admin_all_profiles"      on public.profiles          for all using (public.is_admin());
create policy "admin_all_partners"      on public.partners          for all using (public.is_admin());
create policy "admin_all_delivery"      on public.delivery_agents   for all using (public.is_admin());
create policy "admin_all_providers"     on public.service_providers for all using (public.is_admin());
create policy "admin_all_orders"        on public.orders            for all using (public.is_admin());
create policy "admin_all_items"         on public.order_items       for all using (public.is_admin());
create policy "admin_all_requests"      on public.service_requests  for all using (public.is_admin());
create policy "admin_all_payments"      on public.payments          for all using (public.is_admin());

-- ══════════════════════════════════════════════════════════════
-- Trigger: créer un profil automatiquement à l'inscription
-- ══════════════════════════════════════════════════════════════
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'phone'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ══════════════════════════════════════════════════════════════
-- Trigger: updated_at auto
-- ══════════════════════════════════════════════════════════════
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at before update on public.profiles
  for each row execute procedure public.set_updated_at();

create trigger orders_updated_at before update on public.orders
  for each row execute procedure public.set_updated_at();

-- ══════════════════════════════════════════════════════════════
-- Realtime: activer pour orders et delivery_agents
-- (dans Supabase dashboard > Database > Replication)
-- ══════════════════════════════════════════════════════════════
-- alter publication supabase_realtime add table public.orders;
-- alter publication supabase_realtime add table public.delivery_agents;
