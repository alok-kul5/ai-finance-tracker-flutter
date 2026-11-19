-- Kharcha optional sync: one table of opaque records per user.
--
-- The phone's SQLite database is the source of truth. Each record carries the
-- client's own `updated_at` (ms since epoch) for last-write-wins, and the
-- server stamps every accepted write with a monotonically increasing `seq`
-- that clients use as their pull cursor (so device clocks never decide what
-- is "new" on the server).

create sequence if not exists public.kharcha_records_seq;

create table if not exists public.kharcha_records (
  user_id    uuid    not null default auth.uid() references auth.users (id) on delete cascade,
  kind       text    not null check (kind in ('txn', 'budget', 'merchant')),
  id         text    not null,
  updated_at bigint  not null,
  deleted    boolean not null default false,
  data       jsonb   not null default '{}'::jsonb,
  seq        bigint  not null default nextval('public.kharcha_records_seq'),
  primary key (user_id, kind, id)
);

create index if not exists kharcha_records_user_seq on public.kharcha_records (user_id, seq);

-- Last write wins, enforced on the server too: an upsert carrying an older
-- updated_at than the stored row is silently dropped. Accepted writes get a
-- fresh seq so other devices pull them.
create or replace function public.kharcha_records_lww()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.user_id := (select auth.uid());
  if tg_op = 'UPDATE' then
    if new.updated_at < old.updated_at then
      return null; -- keep the newer row
    end if;
  end if;
  new.seq := nextval('public.kharcha_records_seq');
  return new;
end;
$$;

drop trigger if exists kharcha_records_lww on public.kharcha_records;
create trigger kharcha_records_lww
  before insert or update on public.kharcha_records
  for each row execute function public.kharcha_records_lww();

-- Row level security: every user (anonymous sign-in is enough) reads and
-- writes only their own rows. No deletes: records are soft-deleted.
alter table public.kharcha_records enable row level security;

drop policy if exists "own rows: select" on public.kharcha_records;
create policy "own rows: select" on public.kharcha_records
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "own rows: insert" on public.kharcha_records;
create policy "own rows: insert" on public.kharcha_records
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "own rows: update" on public.kharcha_records;
create policy "own rows: update" on public.kharcha_records
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

grant usage on sequence public.kharcha_records_seq to authenticated;
grant select, insert, update on public.kharcha_records to authenticated;
