create extension if not exists pgcrypto;
create table if not exists profiles(id uuid primary key references auth.users(id) on delete cascade,full_name text,email text,role text not null default 'customer' check(role in('customer','admin')),created_at timestamptz not null default now());
create table if not exists products(id uuid primary key default gen_random_uuid(),slug text unique not null,name text not null,category text not null,description text,price_points bigint not null check(price_points>0),stock integer not null default 0 check(stock>=0),image_url text,specs jsonb not null default '{}'::jsonb,active boolean not null default true,created_at timestamptz not null default now());
create table if not exists point_transactions(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,type text not null check(type in('credit','debit','refund','adjustment')),points bigint not null check(points>0),provider text,provider_payment_id text,reference text,status text not null default 'pending' check(status in('pending','completed','failed','reversed')),created_at timestamptz not null default now());
create table if not exists orders(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete restrict,status text not null default 'pending' check(status in('pending','paid','processing','shipped','delivered','cancelled')),total_points bigint not null check(total_points>0),email text,delivery_address text,payment_id text,created_at timestamptz not null default now());
create table if not exists order_items(id uuid primary key default gen_random_uuid(),order_id uuid not null references orders(id) on delete cascade,product_id uuid not null references products(id),quantity integer not null check(quantity>0),unit_points bigint not null check(unit_points>0));
create or replace function points_balance(uid uuid) returns bigint language sql stable security definer set search_path=public as $$select coalesce(sum(case when type in('credit','refund','adjustment') and status='completed' then points when type='debit' and status='completed' then -points else 0 end),0) from point_transactions where user_id=uid$$;
create or replace function handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$begin insert into public.profiles(id,full_name,email) values(new.id,new.raw_user_meta_data->>'full_name',new.email) on conflict(id) do nothing; return new; end;$$;
drop trigger if exists on_auth_user_created on auth.users; create trigger on_auth_user_created after insert on auth.users for each row execute procedure handle_new_user();
alter table profiles enable row level security;alter table products enable row level security;alter table point_transactions enable row level security;alter table orders enable row level security;alter table order_items enable row level security;
drop policy if exists "public active products" on products;create policy "public active products" on products for select using(active=true);
drop policy if exists "own profile" on profiles;create policy "own profile" on profiles for select using(auth.uid()=id);
drop policy if exists "own transactions" on point_transactions;create policy "own transactions" on point_transactions for select using(auth.uid()=user_id);
drop policy if exists "own orders" on orders;create policy "own orders" on orders for select using(auth.uid()=user_id);
drop policy if exists "own order items" on order_items;create policy "own order items" on order_items for select using(exists(select 1 from orders o where o.id=order_id and o.user_id=auth.uid()));
insert into products(slug,name,category,description,price_points,stock,specs) values
('iphone-15','iPhone 15','iPhone','6.1-inch iPhone with USB-C.',25000,10,'{"storage":"128GB","chip":"A16 Bionic"}'),
('iphone-15-pro','iPhone 15 Pro','iPhone','Pro titanium iPhone.',32000,8,'{"storage":"256GB","chip":"A17 Pro"}'),
('iphone-16','iPhone 16','iPhone','Next-generation iPhone.',30000,10,'{"storage":"128GB","chip":"A18"}'),
('iphone-16-pro','iPhone 16 Pro','iPhone','Pro camera system and titanium design.',39000,8,'{"storage":"256GB","chip":"A18 Pro"}'),
('iphone-17','iPhone 17','iPhone','Latest-generation iPhone.',38000,10,'{"storage":"256GB"}'),
('iphone-17-pro','iPhone 17 Pro','iPhone','Premium Pro model.',48000,6,'{"storage":"256GB"}'),
('macbook-air','MacBook Air','Laptop','Lightweight Apple laptop.',65000,5,'{"chip":"Apple silicon","display":"13-inch"}'),
('macbook-pro','MacBook Pro','Laptop','Professional Apple laptop.',110000,4,'{"chip":"Apple silicon","display":"14-inch"}'),
('playstation-5','PlayStation 5','Gaming','Next-generation console.',55000,7,'{"edition":"Disc"}'),
('playstation-5-slim','PlayStation 5 Slim','Gaming','Slim PS5 console.',50000,7,'{"edition":"Disc"}')
on conflict(slug) do nothing;
