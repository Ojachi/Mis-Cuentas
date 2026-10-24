DO $$
BEGIN
  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub', 'bbbbbbbb-1111-1111-1111-111111111111', true);
  PERFORM public.update_business_member_role(
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    'aaaaaaaa-1111-1111-1111-111111111111',
    'Operator'
  );
END $$;
