DO $$
DECLARE ready boolean := false; receipt jsonb;
BEGIN
  PERFORM set_config('application_name','micu-posting-race-b',true);
  FOR attempt IN 1..400 LOOP
    IF EXISTS(SELECT 1 FROM pg_locks WHERE locktype='advisory' AND objid=424241 AND granted) THEN ready := true; EXIT; END IF;
    PERFORM pg_sleep(0.05);
  END LOOP;
  IF NOT ready THEN RAISE EXCEPTION 'first session never held the fixture lock'; END IF;
  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',true);
  receipt := public.post_financial_operation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','00000000-0000-0000-0000-000000000099',
    '{"version":"1","kind":"contribution","amount":"100","account":"cash","occurredAt":"2026-10-24T12:00:00-05:00","clientCreatedAt":"2026-10-24T12:00:00-05:00"}');
  INSERT INTO harness.posting_race_results VALUES('b',receipt);
END $$;
