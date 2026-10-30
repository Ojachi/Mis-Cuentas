DO $$
DECLARE
  fixture_business_id uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'; foreign_business uuid := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  operator_id uuid := '22222222-2222-2222-2222-222222222222'; foreign_id uuid := '33333333-3333-3333-3333-333333333333';
  request jsonb := '{"version":"1","action":"void","reason":"Not permitted"}'; result jsonb; before_facts integer; denied boolean := false; table_name text; statement text;
BEGIN
  INSERT INTO auth.users(id,instance_id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
  VALUES(foreign_id,'00000000-0000-0000-0000-000000000000','authenticated','authenticated','foreign@corrections.test','$2a$10$7EqJtq98hPqEX7fNZaFWoO.VaLcjxYwP6B8Zx4B8nbh2yB01uE4mK',now(),'{}','{}',now(),now());
  INSERT INTO public.businesses(id,name) VALUES(foreign_business,'Foreign corrections');
  INSERT INTO public.business_memberships(business_id,user_id,role) VALUES(foreign_business,foreign_id,'Administrator');
  SELECT count(*) INTO before_facts FROM public.financial_facts;
  EXECUTE 'SET LOCAL ROLE authenticated'; PERFORM set_config('request.jwt.claim.sub',operator_id::text,true);
  result := public.correct_financial_operation(fixture_business_id,'00000000-0000-0000-0000-000000000200','00000000-0000-0000-0000-000000000302',request);
  IF result->>'status' <> 'denied' OR (SELECT count(*) FROM public.financial_facts) <> before_facts
    OR NOT EXISTS(SELECT 1 FROM public.financial_correction_audit WHERE actor_id=operator_id AND event='denied' AND correction_id IS NULL) THEN
    RAISE EXCEPTION 'operator denial was not retained distinctly without financial mutation';
  END IF;
  FOREACH table_name IN ARRAY ARRAY['financial_corrections','financial_correction_audit'] LOOP
    FOREACH statement IN ARRAY ARRAY[format('INSERT INTO public.%I DEFAULT VALUES',table_name),format('UPDATE public.%I SET business_id=business_id',table_name),format('DELETE FROM public.%I',table_name)] LOOP
      denied := false; BEGIN EXECUTE statement; EXCEPTION WHEN insufficient_privilege THEN denied := true; END;
      IF NOT denied THEN RAISE EXCEPTION 'direct correction DML permitted: %',statement; END IF;
    END LOOP;
  END LOOP;
  EXECUTE 'SET LOCAL ROLE authenticated'; PERFORM set_config('request.jwt.claim.sub',foreign_id::text,true);
  IF EXISTS(SELECT 1 FROM public.financial_corrections c WHERE c.business_id=fixture_business_id) OR EXISTS(SELECT 1 FROM public.financial_correction_audit a WHERE a.business_id=fixture_business_id) THEN RAISE EXCEPTION 'foreign correction history exposed'; END IF;
  BEGIN PERFORM public.correct_financial_operation(fixture_business_id,'00000000-0000-0000-0000-000000000200','00000000-0000-0000-0000-000000000302',request); EXCEPTION WHEN insufficient_privilege THEN denied := true; END;
  IF NOT denied THEN RAISE EXCEPTION 'foreign correction receipt probe exposed'; END IF;
  EXECUTE 'SET LOCAL ROLE anon'; denied := false;
  BEGIN PERFORM public.correct_financial_operation(fixture_business_id,gen_random_uuid(),gen_random_uuid(),request); EXCEPTION WHEN insufficient_privilege THEN denied := true; END;
  IF NOT denied THEN RAISE EXCEPTION 'anonymous correction execute permitted'; END IF;
  EXECUTE 'RESET ROLE';
END $$;
