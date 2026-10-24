DO $$
BEGIN
  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub', '66666666-6666-6666-6666-666666666666', true);
  PERFORM public.deactivate_business_member('dddddddd-dddd-dddd-dddd-dddddddddddd', '55555555-5555-5555-5555-555555555555');
END $$;
