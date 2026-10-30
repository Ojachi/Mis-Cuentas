DO $$
DECLARE fixture_business_id uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'; admin_id uuid := '11111111-1111-1111-1111-111111111111'; before_facts integer; before_effects integer; before_corrections integer; before_audits integer; rejected boolean := false;
BEGIN
  EXECUTE $create$CREATE FUNCTION harness.fail_correction_inverse() RETURNS trigger LANGUAGE plpgsql AS $trigger$
    BEGIN IF NEW.payload->>'kind' = 'correction_inverse' THEN RAISE EXCEPTION 'fixture inverse failure' USING ERRCODE='23514'; END IF; RETURN NEW; END
  $trigger$ $create$;
  EXECUTE 'CREATE TRIGGER correction_failure_fixture BEFORE INSERT ON public.financial_facts FOR EACH ROW EXECUTE FUNCTION harness.fail_correction_inverse()';
  SELECT count(*) INTO before_facts FROM public.financial_facts;
  SELECT count(*) INTO before_effects FROM public.financial_effects;
  SELECT count(*) INTO before_corrections FROM public.financial_corrections;
  SELECT count(*) INTO before_audits FROM public.financial_correction_audit;
  EXECUTE 'SET LOCAL ROLE authenticated'; PERFORM set_config('request.jwt.claim.sub',admin_id::text,true);
  BEGIN PERFORM public.correct_financial_operation(fixture_business_id,'00000000-0000-0000-0000-000000000200','00000000-0000-0000-0000-000000000303','{"version":"1","action":"void","reason":"Fixture failure"}'); EXCEPTION WHEN check_violation THEN rejected := SQLERRM='fixture inverse failure'; END;
  EXECUTE 'RESET ROLE';
  IF NOT rejected OR before_facts <> (SELECT count(*) FROM public.financial_facts)
    OR before_effects <> (SELECT count(*) FROM public.financial_effects)
    OR before_corrections <> (SELECT count(*) FROM public.financial_corrections)
    OR before_audits <> (SELECT count(*) FROM public.financial_correction_audit) THEN
    RAISE EXCEPTION 'inverse fixture failure left partial correction state';
  END IF;
  EXECUTE 'DROP TRIGGER correction_failure_fixture ON public.financial_facts';
  EXECUTE 'DROP FUNCTION harness.fail_correction_inverse()';
END $$;
