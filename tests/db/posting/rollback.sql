DO $$
DECLARE before_state text; after_state text; rejected boolean := false;
BEGIN
  CREATE FUNCTION harness.fail_second_transfer_leg() RETURNS trigger LANGUAGE plpgsql AS $trigger$
  BEGIN
    IF NEW.account='bank' AND EXISTS(SELECT 1 FROM public.financial_facts WHERE id=NEW.fact_id AND operation_id='00000000-0000-0000-0000-000000000098') THEN
      RAISE EXCEPTION 'fixture second transfer leg failure' USING ERRCODE='23514';
    END IF;
    RETURN NEW;
  END $trigger$;
  CREATE TRIGGER posting_failure_fixture BEFORE INSERT ON public.financial_effects FOR EACH ROW EXECUTE FUNCTION harness.fail_second_transfer_leg();
  SELECT md5(jsonb_build_array(
    (SELECT jsonb_agg(to_jsonb(t) ORDER BY id) FROM public.financial_facts t),
    (SELECT jsonb_agg(to_jsonb(t) ORDER BY id) FROM public.financial_effects t),
    (SELECT jsonb_agg(to_jsonb(t) ORDER BY id) FROM public.financial_audit t),
    (SELECT jsonb_agg(to_jsonb(t) ORDER BY business_id,operation_id) FROM public.financial_receipts t))::text) INTO before_state;
  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',true);
  BEGIN
    PERFORM public.post_financial_operation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','00000000-0000-0000-0000-000000000098',
      '{"version":"1","kind":"cash_to_bank","amount":"8000","occurredAt":"2026-10-24T12:00:00-05:00","clientCreatedAt":"2026-10-24T12:00:00-05:00"}');
  EXCEPTION WHEN check_violation THEN
    IF SQLERRM <> 'fixture second transfer leg failure' THEN RAISE; END IF;
    rejected := true;
  END;
  EXECUTE 'RESET ROLE';
  SELECT md5(jsonb_build_array(
    (SELECT jsonb_agg(to_jsonb(t) ORDER BY id) FROM public.financial_facts t),
    (SELECT jsonb_agg(to_jsonb(t) ORDER BY id) FROM public.financial_effects t),
    (SELECT jsonb_agg(to_jsonb(t) ORDER BY id) FROM public.financial_audit t),
    (SELECT jsonb_agg(to_jsonb(t) ORDER BY business_id,operation_id) FROM public.financial_receipts t))::text) INTO after_state;
  IF NOT rejected OR before_state <> after_state THEN RAISE EXCEPTION 'second-leg failure did not roll back all four tables'; END IF;
  DROP TRIGGER posting_failure_fixture ON public.financial_effects;
  DROP FUNCTION harness.fail_second_transfer_leg();
END $$;
