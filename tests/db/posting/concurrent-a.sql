DO $$
DECLARE waiting boolean := false; receipt jsonb;
BEGIN
  PERFORM set_config('application_name','micu-posting-race-a',true);
  PERFORM 1 FROM public.businesses WHERE id='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' FOR UPDATE;
  PERFORM pg_advisory_xact_lock(424241);
  FOR attempt IN 1..400 LOOP
    PERFORM pg_stat_clear_snapshot();
    IF EXISTS(SELECT 1 FROM pg_stat_activity WHERE application_name='micu-posting-race-b' AND wait_event_type='Lock') THEN waiting := true; EXIT; END IF;
    PERFORM pg_sleep(0.05);
  END LOOP;
  IF NOT waiting THEN RAISE EXCEPTION 'second session never contended on the business lock'; END IF;
  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',true);
  receipt := public.post_financial_operation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','00000000-0000-0000-0000-000000000099',
    '{"version":"1","kind":"contribution","amount":"100","account":"cash","occurredAt":"2026-10-24T12:00:00-05:00","clientCreatedAt":"2026-10-24T12:00:00-05:00"}');
  INSERT INTO harness.posting_race_results VALUES('a',receipt);
END $$;
