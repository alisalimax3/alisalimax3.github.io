-- CineHub 3099 — السحابة الكاملة (الصقه في Supabase > SQL Editor > Run)
create table if not exists events(
 id bigserial primary key, created_at timestamptz default now(),
 source text, gross numeric default 0, fee numeric default 0,
 status text default 'settled', ref text);
alter table events enable row level security;
drop policy if exists ev_read on events;  create policy ev_read  on events for select using(true);
drop policy if exists ev_write on events; create policy ev_write on events for insert with check(true);

create table if not exists comments(
 id bigserial primary key, created_at timestamptz default now(),
 item_id text, handle text, body text, stars int default 0);
alter table comments enable row level security;
drop policy if exists cm_all on comments; create policy cm_all on comments for all using(true) with check(true);
create index if not exists comments_item on comments(item_id);

create table if not exists invites(
 id bigserial primary key, created_at timestamptz default now(),
 code text, ref_by text, ua text);
alter table invites enable row level security;
drop policy if exists iv_all on invites; create policy iv_all on invites for all using(true) with check(true);

create table if not exists subs(
 id bigserial primary key, created_at timestamptz default now(),
 handle text, plan text, amount numeric default 0, gateway text, ref text);
alter table subs enable row level security;
drop policy if exists sb_all on subs; create policy sb_all on subs for all using(true) with check(true);

create or replace view v_revenue as
 select source, sum(gross) as gross, sum(fee) as fee, count(*) as n
 from events where status not in ('test','track') group by source order by gross desc;

create or replace view v_top as
 select ref, count(*) as n from events
 where status = 'track' and ref is not null group by ref order by n desc limit 50;
