DO $$
DECLARE
  b uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  admin uuid := '11111111-1111-1111-1111-111111111111';
  operator_id uuid := '22222222-2222-2222-2222-222222222222';
  original_op uuid := '00000000-0000-0000-0000-000000000100';
  inverse_op uuid; inverse_id uuid; reused jsonb; operator_replay jsonb;
  inverse_hash text; audit_hash text; canonical_inverse_hash text; equivalent_time jsonb;
  before_facts integer; before_effects integer; before_groups integer; before_audits integer;
BEGIN
  SELECT operation_id, id INTO inverse_op, inverse_id
  FROM public.financial_facts WHERE payload->>'kind' = 'correction_inverse' ORDER BY accepted_at LIMIT 1;
  SELECT count(*) INTO before_facts FROM public.financial_facts;
  SELECT count(*) INTO before_effects FROM public.financial_effects;
  SELECT count(*) INTO before_groups FROM public.financial_corrections;
  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub', admin::text, true);
  BEGIN
    PERFORM public.correct_financial_operation(b, '00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000300',
      '{"version":"1","action":"replace","reason":"Correct supplier invoice","replacement":{"version":"1","kind":"purchase","account":"cash","amount":"15000","supplier":"Vendor","lines":[{"name":"Sausage","quantity":"1","unitPrice":"15000","total":"15000"}],"occurredAt":"2026-10-20T10:00:00-05:00","clientCreatedAt":"2026-10-29T12:00:00-05:00"}}');
    RAISE EXCEPTION 'correction receipt accepted a different target revision';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
  IF (SELECT count(*) FROM public.financial_facts) <> before_facts
    OR (SELECT count(*) FROM public.financial_effects) <> before_effects
    OR (SELECT count(*) FROM public.financial_corrections) <> before_groups THEN
    RAISE EXCEPTION 'cross-target correction receipt mutated financial state';
  END IF;
  EXECUTE 'RESET ROLE';
  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub', operator_id::text, true);
  SELECT count(*) INTO before_audits FROM public.financial_correction_audit;
  operator_replay := public.correct_financial_operation(b, original_op, '00000000-0000-0000-0000-000000000300',
    '{"version":"1","action":"replace","reason":"Correct supplier invoice","replacement":{"version":"1","kind":"purchase","account":"cash","amount":"15000","supplier":"Vendor","lines":[{"name":"Sausage","quantity":"1","unitPrice":"15000","total":"15000"}],"occurredAt":"2026-10-20T10:00:00-05:00","clientCreatedAt":"2026-10-29T12:00:00-05:00"}}');
  IF operator_replay->>'status' <> 'denied'
    OR (SELECT count(*) FROM public.financial_correction_audit) <> before_audits + 1 THEN
    RAISE EXCEPTION 'Operator replay did not return a distinct denial audit';
  END IF;
  EXECUTE 'RESET ROLE';
  SELECT f.payload_hash, a.payload_hash, encode(sha256(convert_to(public.canonical_posting(f.payload), 'UTF8')), 'hex')
  INTO inverse_hash, audit_hash, canonical_inverse_hash
  FROM public.financial_facts f JOIN public.financial_audit a ON a.fact_id=f.id WHERE f.id=inverse_id;
  IF inverse_hash <> canonical_inverse_hash OR audit_hash <> canonical_inverse_hash THEN
    RAISE EXCEPTION 'inverse fact and audit hashes do not match the inverse payload';
  END IF;
  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub', admin::text, true);
  SELECT count(*) INTO before_facts FROM public.financial_facts;
  SELECT count(*) INTO before_effects FROM public.financial_effects;
  SELECT count(*) INTO before_groups FROM public.financial_corrections;
  BEGIN
    PERFORM public.correct_financial_operation(b, inverse_op, '00000000-0000-0000-0000-000000000401',
      '{"version":"1","action":"void","reason":"Probe inverse target"}');
    RAISE EXCEPTION 'inverse correction artifact was accepted as a target';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  IF (SELECT count(*) FROM public.financial_facts) <> before_facts
    OR (SELECT count(*) FROM public.financial_effects) <> before_effects
    OR (SELECT count(*) FROM public.financial_corrections) <> before_groups THEN
    RAISE EXCEPTION 'inverse target rejection mutated financial state';
  END IF;
  equivalent_time := public.correct_financial_operation(b, '00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000402',
    '{"version":"1","action":"replace","reason":"Equivalent instant","replacement":{"version":"1","kind":"expense","account":"cash","amount":"100","description":"Invalid target","occurredAt":"2026-10-20T15:00:00Z","clientCreatedAt":"2026-10-29T12:00:00-05:00"}}');
  IF equivalent_time->>'status' <> 'accepted' THEN RAISE EXCEPTION 'equivalent occurrence instant was rejected'; END IF;
  PERFORM public.post_financial_operation(b, '00000000-0000-0000-0000-000000000103',
    '{"version":"1","kind":"expense","account":"cash","amount":"100","description":"Changed instant target","occurredAt":"2026-10-20T10:00:00-05:00","clientCreatedAt":"2026-10-20T10:01:00-05:00"}');
  SELECT count(*) INTO before_facts FROM public.financial_facts;
  SELECT count(*) INTO before_effects FROM public.financial_effects;
  SELECT count(*) INTO before_groups FROM public.financial_corrections;
  BEGIN
    PERFORM public.correct_financial_operation(b, '00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000403',
      '{"version":"1","action":"replace","reason":"Changed instant","replacement":{"version":"1","kind":"expense","account":"cash","amount":"100","description":"Changed instant target","occurredAt":"2026-10-20T15:00:01Z","clientCreatedAt":"2026-10-29T12:00:00-05:00"}}');
    RAISE EXCEPTION 'changed occurrence instant was accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  IF (SELECT count(*) FROM public.financial_facts) <> before_facts
    OR (SELECT count(*) FROM public.financial_effects) <> before_effects
    OR (SELECT count(*) FROM public.financial_corrections) <> before_groups THEN
    RAISE EXCEPTION 'changed occurrence instant rejection mutated financial state';
  END IF;
  EXECUTE 'RESET ROLE';
END $$;
