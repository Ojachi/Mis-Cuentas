DO $$
BEGIN
  EXECUTE 'SET LOCAL ROLE anon';
  BEGIN
    PERFORM public.has_active_business_membership(
      'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
      'aaaaaaaa-1111-1111-1111-111111111111'
    );
    RAISE EXCEPTION 'anonymous helper execution unexpectedly succeeded';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END $$;
