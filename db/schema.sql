-- CineHub 3099 · مخطط Supabase (نفّذه في SQL Editor)
create table if not exists profiles(id uuid primary key references auth.users on delete cascade,
 email text,name text,phone text,ref_code text unique,ref_by text,xp int default 0,level int default 1,
 created_at timestamptz default now());
create table if not exists ledger(id bigserial primary key,uid uuid references auth.users on delete cascade,
 kind text,amount numeric(14,6) not null,src text,meta jsonb default '{}',at timestamptz default now());
create table if not exists withdrawals(id bigserial primary key,uid uuid references auth.users on delete cascade,
 ref text,amount numeric(14,6),method text,name text,account text,phone text,status text default 'pending',
 note text,at timestamptz default now(),paid_at timestamptz);
create table if not exists gift_codes(code text primary key,kind text,value numeric(14,6),max_uses int default 1,
 used int default 0,expires timestamptz,note text);
create table if not exists redemptions(id bigserial primary key,uid uuid,code text,at timestamptz default now());
create table if not exists tasks(uid uuid,key text,done_at timestamptz,primary key(uid,key));
create table if not exists networks_daily(d date,net text,impressions bigint,clicks bigint,revenue numeric(14,6),primary key(d,net));

alter table profiles enable row level security; alter table ledger enable row level security;
alter table withdrawals enable row level security; alter table redemptions enable row level security;
alter table gift_codes enable row level security; alter table tasks enable row level security;

create policy p_prof_self on profiles for all using(auth.uid()=id) with check(auth.uid()=id);
create policy p_led_self on ledger for select using(auth.uid()=uid);
create policy p_led_ins on ledger for insert with check(auth.uid()=uid);
create policy p_wd_self on withdrawals for all using(auth.uid()=uid) with check(auth.uid()=uid);
create policy p_gift_read on gift_codes for select using(true);
create policy p_red_self on redemptions for all using(auth.uid()=uid) with check(auth.uid()=uid);
create policy p_task_self on tasks for all using(auth.uid()=uid) with check(auth.uid()=uid);

create or replace view balances as select uid,sum(amount) bal from ledger group by uid;
create or replace function redeem_code(p_code text) returns json language plpgsql security definer as $$
declare g gift_codes; n int;
begin
 if auth.uid() is null then return json_build_object('ok',false,'why','login required'); end if;
 select * into g from gift_codes where code=p_code for update;
 if g is null then return json_build_object('ok',false,'why','كود غير صحيح'); end if;
 if g.used>=g.max_uses then return json_build_object('ok',false,'why','انتهت صلاحية الكود'); end if;
 select count(*) into n from redemptions where uid=auth.uid() and code=p_code;
 if n>0 then return json_build_object('ok',false,'why','استخدمته مسبقًا'); end if;
 update gift_codes set used=used+1 where code=p_code;
 insert into redemptions(uid,code) values(auth.uid(),p_code);
 if g.kind='usd' then insert into ledger(uid,kind,amount,src) values(auth.uid(),'gift',g.value,'code:'||p_code);
 elsif g.kind='xp' then update profiles set xp=xp+g.value::int where id=auth.uid(); end if;
 return json_build_object('ok',true,'kind',g.kind,'value',g.value);
end $$;

-- عدّاد عالمي حقيقي (اختياري مع Supabase)
create table if not exists hits(id bigserial primary key,kind text,at timestamptz default now());
alter table hits enable row level security;
create policy p_hits_ins on hits for insert with check(true);
create policy p_hits_sel on hits for select using(true);

create table if not exists comments(id bigserial primary key,uid uuid,page text,body text,at timestamptz default now());
alter table comments enable row level security;
create policy p_cm_ins on comments for insert with check(true);
create policy p_cm_sel on comments for select using(true);
