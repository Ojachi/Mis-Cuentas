DO $$
DECLARE
  synthetic_id uuid := '11111111-1111-1111-1111-111111111111';
BEGIN
  IF (SELECT count(*) FROM harness.seeded_identities) <> 2 THEN
    RAISE EXCEPTION 'expected two synthetic harness identities';
  END IF;

  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub', synthetic_id::text, true);
  IF auth.uid() <> synthetic_id THEN
    RAISE EXCEPTION 'auth.uid() did not read the synthetic request identity';
  END IF;

  CREATE TEMP TABLE transaction_smoke (id integer PRIMARY KEY);
  INSERT INTO transaction_smoke VALUES (1);
  IF (SELECT count(*) FROM transaction_smoke) <> 1 THEN
    RAISE EXCEPTION 'transaction smoke did not retain its insert';
  END IF;

  EXECUTE 'RESET ROLE';
  RAISE NOTICE 'PASS database harness: seeded IDs, auth helper, and transaction.';
END $$;
