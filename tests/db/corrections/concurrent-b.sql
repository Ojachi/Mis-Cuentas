DO $$
DECLARE ready boolean := false; result jsonb;
BEGIN
  PERFORM set_config('application_name','micu-correction-race-b',true);
  FOR attempt IN 1..400 LOOP
    IF EXISTS(SELECT 1 FROM pg_locks WHERE locktype='advisory' AND objid=424242 AND granted) THEN ready := true; EXIT; END IF;
    PERFORM pg_sleep(0.05);
  END LOOP;
  IF NOT ready THEN RAISE EXCEPTION 'first correction session never held the fixture lock'; END IF;
  EXECUTE 'SET LOCAL ROLE authenticated'; PERFORM set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',true);
  result := public.correct_financial_operation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','00000000-0000-0000-0000-000000000200','00000000-0000-0000-0000-000000000202','{"version":"1","action":"void","reason":"Race B"}');
  INSERT INTO harness.correction_race_results VALUES ('b',result);
END $$;
