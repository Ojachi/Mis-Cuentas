DO $$
DECLARE business_id uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'; actor uuid := '22222222-2222-2222-2222-222222222222'; payload jsonb := '{"version":"1","kind":"sale","account":"cash","amount":"24000","lines":[{"name":"Hot dog","quantity":"2","unitPrice":"12000","total":"24000"}]}'::jsonb; first_receipt jsonb; second_receipt jsonb;
BEGIN
  -- Trusted owner fixture provisions the same synthetic identities as access tests.
  CREATE TABLE harness.posting_race_results (caller text PRIMARY KEY, receipt jsonb NOT NULL);
  GRANT USAGE ON SCHEMA harness TO authenticated;
  GRANT INSERT, SELECT ON harness.posting_race_results TO authenticated;
  INSERT INTO auth.users (id,instance_id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
  VALUES ('11111111-1111-1111-1111-111111111111','00000000-0000-0000-0000-000000000000','authenticated','authenticated','admin@posting.test','$2a$10$7EqJtq98hPqEX7fNZaFWoO.VaLcjxYwP6B8Zx4B8nbh2yB01uE4mK',now(),'{}','{}',now(),now()), (actor,'00000000-0000-0000-0000-000000000000','authenticated','authenticated','operator@posting.test','$2a$10$7EqJtq98hPqEX7fNZaFWoO.VaLcjxYwP6B8Zx4B8nbh2yB01uE4mK',now(),'{}','{}',now(),now()) ON CONFLICT DO NOTHING;
  INSERT INTO public.businesses (id,name) VALUES (business_id,'Posting fixture') ON CONFLICT DO NOTHING;
  INSERT INTO public.business_memberships (business_id,user_id,role) VALUES (business_id,actor,'Operator'),(business_id,'11111111-1111-1111-1111-111111111111','Administrator') ON CONFLICT DO NOTHING;
  EXECUTE 'SET LOCAL ROLE authenticated'; PERFORM set_config('request.jwt.claim.sub',actor::text,true); payload := payload || '{"occurredAt":"2026-10-24T12:00:00-05:00","clientCreatedAt":"2026-10-24T12:01:00-05:00"}'::jsonb;
  first_receipt := public.post_financial_operation(business_id,'00000000-0000-0000-0000-000000000001',payload);
  second_receipt := public.post_financial_operation(business_id,'00000000-0000-0000-0000-000000000001',payload);
  IF first_receipt <> second_receipt OR (SELECT count(*) FROM public.financial_facts) <> 1 OR (SELECT count(*) FROM public.financial_effects) <> 2 THEN RAISE EXCEPTION 'replay duplicated posting'; END IF;
  BEGIN PERFORM public.post_financial_operation(business_id,'00000000-0000-0000-0000-000000000001',payload || '{"amount":"1"}'::jsonb); RAISE EXCEPTION 'hash mismatch accepted'; EXCEPTION WHEN unique_violation THEN NULL; END;
  PERFORM public.post_financial_operation(business_id,'00000000-0000-0000-0000-000000000002','{"version":"1","kind":"purchase","account":"bank","amount":"12000","supplier":"Vendor","lines":[{"name":"Sausage","quantity":"1","unitPrice":"12000","total":"12000"}],"occurredAt":"2026-10-24T12:00:00-05:00","clientCreatedAt":"2026-10-24T12:01:00-05:00"}'::jsonb);
  PERFORM public.post_financial_operation(business_id,'00000000-0000-0000-0000-000000000003','{"version":"1","kind":"expense","account":"cash","amount":"3000","description":"Gas","occurredAt":"2026-10-24T12:00:00-05:00","clientCreatedAt":"2026-10-24T12:01:00-05:00"}'::jsonb);
  PERFORM public.post_financial_operation(business_id,'00000000-0000-0000-0000-000000000004','{"version":"1","kind":"contribution","account":"bank","amount":"10000","occurredAt":"2026-10-24T12:00:00-05:00","clientCreatedAt":"2026-10-24T12:01:00-05:00"}'::jsonb);
  PERFORM public.post_financial_operation(business_id,'00000000-0000-0000-0000-000000000005','{"version":"1","kind":"withdrawal","account":"cash","amount":"4000","occurredAt":"2026-10-24T12:00:00-05:00","clientCreatedAt":"2026-10-24T12:01:00-05:00"}'::jsonb);
  PERFORM public.post_financial_operation(business_id,'00000000-0000-0000-0000-000000000006','{"version":"1","kind":"cash_to_bank","amount":"8000","occurredAt":"2026-10-24T12:00:00-05:00","clientCreatedAt":"2026-10-24T12:01:00-05:00"}'::jsonb);
  PERFORM public.post_financial_operation(business_id,'00000000-0000-0000-0000-000000000007','{"version":"1","kind":"bank_to_cash","amount":"8000","occurredAt":"2026-10-24T12:00:00-05:00","clientCreatedAt":"2026-10-24T12:01:00-05:00"}'::jsonb);
  IF (SELECT count(*) FROM public.financial_facts) <> 7 OR (SELECT count(*) FROM public.financial_audit) <> 7 OR (SELECT count(*) FROM public.financial_receipts) <> 7 THEN RAISE EXCEPTION 'seven operations were not fully audited'; END IF;
  BEGIN INSERT INTO public.financial_facts (business_id,operation_id,actor_id,kind,payload,payload_hash) VALUES (business_id,gen_random_uuid(),actor,'sale',payload,'x'); RAISE EXCEPTION 'direct insert accepted'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  EXECUTE 'RESET ROLE'; RAISE NOTICE 'PASS posting: canonical replay and direct-write denial';
END $$;
