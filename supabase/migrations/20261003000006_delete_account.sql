-- A signed-in user can delete their own account and everything that hangs off
-- it (profile, plans, logs, trials, runs, memberships: all cascade from
-- auth.users). Needed for store listings, and simply the right thing to offer.
--
-- Communities the user created that other people still belong to are kept:
-- the longest-standing other member becomes the owner. Communities with no one
-- else left go away with the account.

create or replace function public.delete_my_account() returns void
language plpgsql security definer set search_path = public, auth as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not_signed_in';
  end if;

  update public.community_members m set role = 'owner'
  where (m.community_id, m.user_id) in (
    select c.id,
           (select x.user_id from public.community_members x
            where x.community_id = c.id and x.user_id <> uid
            order by x.joined_at limit 1)
    from public.communities c
    where c.created_by = uid
      and exists (select 1 from public.community_members x
                  where x.community_id = c.id and x.user_id <> uid)
  );

  update public.communities c set created_by = (
    select x.user_id from public.community_members x
    where x.community_id = c.id and x.user_id <> uid
    order by x.joined_at limit 1
  )
  where c.created_by = uid
    and exists (select 1 from public.community_members x
                where x.community_id = c.id and x.user_id <> uid);

  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
