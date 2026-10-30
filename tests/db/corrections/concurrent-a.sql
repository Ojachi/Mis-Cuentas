DO $$
DECLARE waiting boolean := false; result jsonb;
BEGIN
  PERFORM set_config('application_name','micu-correction-race-a',true);
  PERFORM 1 FROM public.businesses WHERE id='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' FOR UPDATE;
  PERFORM pg_advisory_xact_lock(424242);
  FOR attempt IN 1..400 LOOP
    PERFORM pg_stat_clear_snapshot();
    IF EXISTS(SELECT 1 FROM pg_stat_activity WHERE application_name='micu-correction-race-b' AND wait_event_type='Lock') THEN waiting := true; EXIT; END IF;
    PERFORM pg_sleep(0.05);
  END LOOP;
  IF NOT waiting THEN RAISE EXCEPTION 'second correction session never contended on the business lock'; END IF;
  EXECUTE 'SET LOCAL ROLE authenticated'; PERFORM set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',true);
  result := public.correct_financial_operation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','00000000-0000-0000-0000-000000000200','00000000-0000-0000-0000-000000000201','{"version":"1","action":"void","reason":"Race A"}');
  INSERT INTO harness.correction_race_results VALUES ('a',result);
END $$;
