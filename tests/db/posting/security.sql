DO $$
DECLARE
  a uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  b uuid := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  foreign_user uuid := '33333333-3333-3333-3333-333333333333';
  payload jsonb := '{"version":"1","kind":"expense","amount":"100","account":"cash","description":"Gas","occurredAt":"2026-10-24T12:00:00-05:00","clientCreatedAt":"2026-10-24T12:00:00-05:00"}';
  invalid jsonb;
  field text;
  table_name text;
  statement text;
  before_hash text;
  denied boolean;
  rows_found integer;
BEGIN
  CREATE FUNCTION harness.posting_state() RETURNS text LANGUAGE sql SECURITY DEFINER SET search_path = pg_catalog AS $function$
    SELECT md5(jsonb_build_array(
      (SELECT jsonb_agg(to_jsonb(t) ORDER BY id) FROM public.financial_facts t),
      (SELECT jsonb_agg(to_jsonb(t) ORDER BY id) FROM public.financial_effects t),
      (SELECT jsonb_agg(to_jsonb(t) ORDER BY id) FROM public.financial_audit t),
      (SELECT jsonb_agg(to_jsonb(t) ORDER BY business_id,operation_id) FROM public.financial_receipts t)
    )::text);
  $function$;
  GRANT USAGE ON SCHEMA harness TO authenticated;
  GRANT EXECUTE ON FUNCTION harness.posting_state() TO authenticated;
  INSERT INTO auth.users(id,email,aud,role) VALUES(foreign_user,'foreign@posting.test','authenticated','authenticated');
  INSERT INTO public.businesses(id,name) VALUES(b,'Foreign posting fixture');
  INSERT INTO public.business_memberships(business_id,user_id,role) VALUES(b,foreign_user,'Administrator');
  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub',foreign_user::text,true);
  PERFORM public.post_financial_operation(b,'00000000-0000-0000-0000-000000000020',payload);
  before_hash := harness.posting_state();
  FOREACH table_name IN ARRAY ARRAY['financial_facts','financial_effects','financial_audit','financial_receipts'] LOOP
    EXECUTE format('SELECT count(*) FROM public.%I WHERE business_id=$1',table_name) INTO rows_found USING a;
    IF rows_found <> 0 THEN RAISE EXCEPTION 'foreign read exposed %',table_name; END IF;
    EXECUTE format('SELECT count(*) FROM public.%I WHERE business_id=$1',table_name) INTO rows_found USING b;
    IF rows_found = 0 THEN RAISE EXCEPTION 'same-tenant positive control missing %',table_name; END IF;
    FOREACH statement IN ARRAY ARRAY[
      format('INSERT INTO public.%I DEFAULT VALUES',table_name),
      format('UPDATE public.%I SET business_id=business_id',table_name),
      format('DELETE FROM public.%I',table_name)
    ] LOOP
      denied := false;
      BEGIN EXECUTE statement; EXCEPTION WHEN insufficient_privilege THEN denied := true; END;
      IF NOT denied THEN RAISE EXCEPTION 'direct DML permitted: %',statement; END IF;
    END LOOP;
  END LOOP;
  denied := false;
  BEGIN PERFORM public.post_financial_operation(a,'00000000-0000-0000-0000-000000000001',payload);
  EXCEPTION WHEN insufficient_privilege THEN denied := true; END;
  IF NOT denied THEN RAISE EXCEPTION 'foreign existing receipt exposed'; END IF;
  EXECUTE 'SET LOCAL ROLE anon';
  denied := false;
  BEGIN PERFORM public.post_financial_operation(a,gen_random_uuid(),payload);
  EXCEPTION WHEN insufficient_privilege THEN denied := true; END;
  IF NOT denied THEN RAISE EXCEPTION 'anonymous execute permitted'; END IF;
  EXECUTE 'RESET ROLE';
  IF harness.posting_state() <> before_hash THEN RAISE EXCEPTION 'denied access changed financial state'; END IF;

  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',true);
  before_hash := harness.posting_state();
  FOREACH field IN ARRAY ARRAY['version','kind','amount','account','description','occurredAt','clientCreatedAt'] LOOP
    FOREACH invalid IN ARRAY ARRAY[payload-field, jsonb_set(payload,ARRAY[field],'null'), jsonb_set(payload,ARRAY[field],'12')] LOOP
      denied := false;
      BEGIN PERFORM public.post_financial_operation(a,gen_random_uuid(),invalid);
      EXCEPTION WHEN invalid_parameter_value THEN denied := true; END;
      IF NOT denied THEN RAISE EXCEPTION 'invalid required field accepted: %',field; END IF;
    END LOOP;
  END LOOP;
  payload := payload - 'description' || '{"kind":"sale","lines":[{"name":"Hot dog","quantity":"1","unitPrice":"100","total":"100"}]}';
  FOREACH field IN ARRAY ARRAY['name','quantity','unitPrice','total'] LOOP
    FOREACH invalid IN ARRAY ARRAY[
      jsonb_set(payload,'{lines,0}',(payload#>'{lines,0}')-field),
      jsonb_set(payload,ARRAY['lines','0',field],'null'),
      jsonb_set(payload,ARRAY['lines','0',field],'12')
    ] LOOP
      denied := false;
      BEGIN PERFORM public.post_financial_operation(a,gen_random_uuid(),invalid);
      EXCEPTION WHEN invalid_parameter_value THEN denied := true; END;
      IF NOT denied THEN RAISE EXCEPTION 'invalid required snapshot field accepted: %',field; END IF;
    END LOOP;
  END LOOP;
  FOR invalid IN SELECT value FROM jsonb_array_elements(jsonb_build_array(
    jsonb_set(payload,'{lines,0,name}','" "'),
    payload || '{"description":"ignored"}',
    payload || '{"supplier":"ignored"}',
    payload || '{"kind":"contribution"}',
    payload || '{"kind":"cash_to_bank"}',
    payload || '{"occurredAt":"2026-02-30T12:00:00Z"}',
    payload || '{"clientCreatedAt":"2026-10-24T12:00:00"}'
  )) LOOP
    denied := false;
    BEGIN PERFORM public.post_financial_operation(a,gen_random_uuid(),invalid);
    EXCEPTION WHEN invalid_parameter_value THEN denied := true; END;
    IF NOT denied THEN RAISE EXCEPTION 'incompatible payload accepted: %',invalid; END IF;
  END LOOP;
  payload := payload || '{"kind":"purchase","supplier":"Vendor"}';
  FOREACH invalid IN ARRAY ARRAY[payload-'supplier',jsonb_set(payload,'{supplier}','null'),jsonb_set(payload,'{supplier}','12'),jsonb_set(payload,'{supplier}','" "')] LOOP
    denied := false;
    BEGIN PERFORM public.post_financial_operation(a,gen_random_uuid(),invalid);
    EXCEPTION WHEN invalid_parameter_value THEN denied := true; END;
    IF NOT denied THEN RAISE EXCEPTION 'invalid supplier accepted'; END IF;
  END LOOP;
  EXECUTE 'RESET ROLE';
  IF harness.posting_state() <> before_hash THEN RAISE EXCEPTION 'invalid payload changed state'; END IF;
  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM public.post_financial_operation(a,'00000000-0000-0000-0000-000000000096',
    '{"version":"1","kind":"purchase","amount":"10000","account":"bank","supplier":"Vendor","occurredAt":"2026-10-24T12:00:00-05:00","clientCreatedAt":"2026-10-24T12:00:00-05:00","lines":[{"name":"Sausage","quantity":"1.250","measure":"weight","unitPrice":"8000","total":"10000"}]}');
  EXECUTE 'RESET ROLE';
  RAISE NOTICE 'PASS posting security: four tables, three DML verbs, foreign receipts, anon and required-field rejection';
END $$;
