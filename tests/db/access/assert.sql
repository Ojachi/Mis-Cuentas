DO $$
BEGIN
  IF (SELECT count(*) FROM public.business_memberships WHERE business_id = 'dddddddd-dddd-dddd-dddd-dddddddddddd' AND active AND role = 'Administrator') <> 1 THEN
    RAISE EXCEPTION 'concurrent last Administrator protection did not retain exactly one Administrator';
  END IF;
  IF (SELECT count(*) FROM public.business_memberships WHERE business_id = 'dddddddd-dddd-dddd-dddd-dddddddddddd' AND NOT active) <> 1 THEN
    RAISE EXCEPTION 'rejected concurrent deactivation changed more than one membership';
  END IF;
  IF (SELECT count(*) FROM public.business_memberships WHERE business_id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee' AND active AND role = 'Administrator') <> 1 THEN
    RAISE EXCEPTION 'concurrent last Administrator demotion did not retain exactly one Administrator';
  END IF;
  IF (SELECT count(*) FROM public.business_memberships WHERE business_id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee' AND active AND role = 'Operator') <> 1 THEN
    RAISE EXCEPTION 'rejected concurrent demotion changed more than one membership';
  END IF;
  RAISE NOTICE 'PASS access: tenant RLS, identity FK, role RPCs, and serialized last-Administrator changes.';
END $$;
