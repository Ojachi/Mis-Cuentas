DO $$
DECLARE
  fixture_business_id uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  admin_id uuid := '11111111-1111-1111-1111-111111111111';
  operator_id uuid := '22222222-2222-2222-2222-222222222222';
  original uuid; receipt jsonb; replay jsonb; correction public.financial_corrections%ROWTYPE; replacement_operation uuid; chained jsonb; attention jsonb; void_target uuid; void_result jsonb; before_facts integer; before_effects integer; before_corrections integer;
BEGIN
  INSERT INTO auth.users (id,instance_id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
  VALUES (admin_id,'00000000-0000-0000-0000-000000000000','authenticated','authenticated','admin@corrections.test','$2a$10$7EqJtq98hPqEX7fNZaFWoO.VaLcjxYwP6B8Zx4B8nbh2yB01uE4mK',now(),'{}','{}',now(),now()),
    (operator_id,'00000000-0000-0000-0000-000000000000','authenticated','authenticated','operator@corrections.test','$2a$10$7EqJtq98hPqEX7fNZaFWoO.VaLcjxYwP6B8Zx4B8nbh2yB01uE4mK',now(),'{}','{}',now(),now());
  INSERT INTO public.businesses(id,name) VALUES (fixture_business_id,'Corrections fixture');
  INSERT INTO public.business_memberships(business_id,user_id,role) VALUES (fixture_business_id,admin_id,'Administrator'),(fixture_business_id,operator_id,'Operator');
  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub',admin_id::text,true);
  PERFORM public.post_financial_operation(fixture_business_id,'00000000-0000-0000-0000-000000000100',
    '{"version":"1","kind":"purchase","account":"cash","amount":"12000","supplier":"Vendor","lines":[{"name":"Sausage","quantity":"1","unitPrice":"12000","total":"12000"}],"occurredAt":"2026-10-20T10:00:00-05:00","clientCreatedAt":"2026-10-20T10:01:00-05:00"}');
  SELECT f.id INTO original FROM public.financial_facts f WHERE f.business_id=fixture_business_id AND f.operation_id='00000000-0000-0000-0000-000000000100';
  receipt := public.correct_financial_operation(fixture_business_id,'00000000-0000-0000-0000-000000000100','00000000-0000-0000-0000-000000000300',
    '{"version":"1","action":"replace","reason":"Correct supplier invoice","replacement":{"version":"1","kind":"purchase","account":"cash","amount":"15000","supplier":"Vendor","lines":[{"name":"Sausage","quantity":"1","unitPrice":"15000","total":"15000"}],"occurredAt":"2026-10-20T10:00:00-05:00","clientCreatedAt":"2026-10-29T12:00:00-05:00"}}');
  replay := public.correct_financial_operation(fixture_business_id,'00000000-0000-0000-0000-000000000100','00000000-0000-0000-0000-000000000300',
    '{"reason":"Correct supplier invoice","action":"replace","version":"1","replacement":{"amount":"15000","account":"cash","kind":"purchase","version":"1","supplier":"Vendor","lines":[{"total":"15000","unitPrice":"15000","quantity":"1","name":"Sausage"}],"clientCreatedAt":"2026-10-29T12:00:00-05:00","occurredAt":"2026-10-20T10:00:00-05:00"}}');
  IF receipt <> replay OR receipt->>'status' <> 'accepted' THEN RAISE EXCEPTION 'correction replay did not return the stored receipt'; END IF;
  SELECT * INTO correction FROM public.financial_corrections WHERE id=(receipt->>'correctionId')::uuid;
  IF correction.target_fact_id <> original OR correction.reason <> 'Correct supplier invoice' OR correction.actor_id <> admin_id
    OR correction.original_occurred_at <> '2026-10-20T15:00:00Z'::timestamptz OR correction.corrected_at < now() - interval '1 minute' THEN
    RAISE EXCEPTION 'correction linkage, actor, reason or timestamps were not retained';
  END IF;
  IF (SELECT sum(amount) FROM public.financial_effects WHERE account='profit') <> -15000
    OR (SELECT sum(amount) FROM public.financial_effects WHERE account='cash') <> -15000 THEN
    RAISE EXCEPTION '12000 to 15000 correction did not produce exact net effects';
  END IF;
  IF (SELECT occurred_at FROM public.financial_facts WHERE id=correction.inverse_fact_id) <> correction.original_occurred_at
    OR (SELECT occurred_at FROM public.financial_facts WHERE id=correction.replacement_fact_id) <> correction.original_occurred_at THEN
    RAISE EXCEPTION 'correction effects lost original reporting instant';
  END IF;
  PERFORM public.post_financial_operation(fixture_business_id,'00000000-0000-0000-0000-000000000102',
    '{"version":"1","kind":"expense","account":"cash","amount":"100","description":"Invalid target","occurredAt":"2026-10-20T10:00:00-05:00","clientCreatedAt":"2026-10-20T10:01:00-05:00"}');
  SELECT count(*) INTO before_facts FROM public.financial_facts;
  SELECT count(*) INTO before_effects FROM public.financial_effects;
  SELECT count(*) INTO before_corrections FROM public.financial_corrections;
  BEGIN
    PERFORM public.correct_financial_operation(fixture_business_id,'00000000-0000-0000-0000-000000000100','00000000-0000-0000-0000-000000000300',
      '{"version":"1","action":"void","reason":"Different request"}');
    RAISE EXCEPTION 'correction hash mismatch accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
  BEGIN
    PERFORM public.correct_financial_operation(fixture_business_id,'00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000304',
      '{"version":"1","action":"replace","reason":"Invalid replacement","replacement":{"version":"1","kind":"purchase","account":"cash","amount":"1","supplier":"Vendor","occurredAt":"2026-10-20T10:00:00-05:00","clientCreatedAt":"2026-10-29T12:00:00-05:00","lines":[]}}');
    RAISE EXCEPTION 'invalid replacement accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  IF before_facts <> (SELECT count(*) FROM public.financial_facts)
    OR before_effects <> (SELECT count(*) FROM public.financial_effects)
    OR before_corrections <> (SELECT count(*) FROM public.financial_corrections) THEN
    RAISE EXCEPTION 'invalid correction mutated financial state or left a success receipt';
  END IF;
  SELECT operation_id INTO replacement_operation FROM public.financial_facts WHERE id=correction.replacement_fact_id;
  chained := public.correct_financial_operation(fixture_business_id,replacement_operation,'00000000-0000-0000-0000-000000000305','{"version":"1","action":"void","reason":"Correct the replacement revision"}');
  attention := public.correct_financial_operation(fixture_business_id,'00000000-0000-0000-0000-000000000100','00000000-0000-0000-0000-000000000306','{"version":"1","action":"void","reason":"Do not repeat original"}');
  IF chained->>'status' <> 'accepted' OR attention->>'status' <> 'attention' THEN
    RAISE EXCEPTION 'corrections did not require the current replacement revision as target';
  END IF;
  BEGIN PERFORM public.correct_financial_operation(fixture_business_id,gen_random_uuid(),gen_random_uuid(),'{"version":"1","action":"void","reason":" "}'); RAISE EXCEPTION 'blank reason accepted'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  PERFORM public.post_financial_operation(fixture_business_id,'00000000-0000-0000-0000-000000000101',
    '{"version":"1","kind":"expense","account":"bank","amount":"3000","description":"Gas","occurredAt":"2026-10-21T10:00:00-05:00","clientCreatedAt":"2026-10-21T10:01:00-05:00"}');
  SELECT id INTO void_target FROM public.financial_facts WHERE operation_id='00000000-0000-0000-0000-000000000101';
  void_result := public.correct_financial_operation(fixture_business_id,'00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000301','{"version":"1","action":"void","reason":"Duplicate expense"}');
  IF void_result->>'status' <> 'accepted' OR (SELECT count(*) FROM public.financial_facts WHERE id=void_target) <> 1
    OR (SELECT sum(amount) FROM public.financial_effects WHERE fact_id IN (void_target,(void_result->>'inverseFactId')::uuid)) <> 0 THEN
    RAISE EXCEPTION 'void did not retain the original and remove only its effect';
  END IF;
  PERFORM public.post_financial_operation(fixture_business_id,'00000000-0000-0000-0000-000000000200',
    '{"version":"1","kind":"expense","account":"cash","amount":"100","description":"Race target","occurredAt":"2026-10-22T10:00:00-05:00","clientCreatedAt":"2026-10-22T10:01:00-05:00"}');
  EXECUTE 'RESET ROLE';
  CREATE TABLE harness.correction_race_results (caller text PRIMARY KEY, result jsonb NOT NULL);
  GRANT USAGE ON SCHEMA harness TO authenticated;
  GRANT INSERT, SELECT ON harness.correction_race_results TO authenticated;
END $$;
