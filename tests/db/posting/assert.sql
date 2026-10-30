DO $$
DECLARE target_fact uuid;
BEGIN
  IF (SELECT count(*) FROM harness.posting_race_results) <> 2 OR (SELECT count(DISTINCT receipt) FROM harness.posting_race_results) <> 1 THEN RAISE EXCEPTION 'concurrent receipts differ'; END IF;
  IF (SELECT count(*) FROM public.financial_facts WHERE operation_id='00000000-0000-0000-0000-000000000099') <> 1 THEN RAISE EXCEPTION 'concurrent duplicate fact'; END IF;
  SELECT id INTO target_fact FROM public.financial_facts WHERE operation_id='00000000-0000-0000-0000-000000000099';
  IF (SELECT count(*) FROM public.financial_audit WHERE fact_id=target_fact) <> 1 OR (SELECT count(*) FROM public.financial_receipts WHERE fact_id=target_fact) <> 1 OR (SELECT count(*) FROM public.financial_effects WHERE fact_id=target_fact) <> 1 THEN RAISE EXCEPTION 'concurrent partial or duplicate effect/audit/receipt'; END IF;
  RAISE NOTICE 'PASS concurrent same-key posting: real lock contention and one immutable outcome';
END $$;
