DO $$
DECLARE fixture jsonb := __POSTING_FIXTURE__; receipt jsonb;
BEGIN
  IF public.canonical_posting(fixture->'payload') <> fixture->>'canonical' THEN RAISE EXCEPTION 'SQL canonical bytes differ from TypeScript fixture'; END IF;
  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',true);
  receipt := public.post_financial_operation('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','00000000-0000-0000-0000-000000000097',fixture->'payload');
  IF receipt->>'hash' <> fixture->>'hash' THEN RAISE EXCEPTION 'TypeScript/PostgreSQL SHA256 parity failed'; END IF;
END $$;
