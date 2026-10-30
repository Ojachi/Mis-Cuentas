DO $$
DECLARE target uuid;
BEGIN
  SELECT id INTO target FROM public.financial_facts WHERE operation_id='00000000-0000-0000-0000-000000000200';
  IF (SELECT count(*) FROM harness.correction_race_results) <> 2
    OR (SELECT count(*) FROM harness.correction_race_results WHERE result->>'status'='accepted') <> 1
    OR (SELECT count(*) FROM harness.correction_race_results WHERE result->>'status'='attention' AND result->>'code'='target_already_corrected') <> 1
    OR (SELECT count(*) FROM public.financial_corrections WHERE target_fact_id=target) <> 1
    OR (SELECT count(*) FROM public.financial_facts WHERE payload->>'kind'='correction_inverse' AND occurred_at=(SELECT occurred_at FROM public.financial_facts WHERE id=target)) <> 1 THEN
    RAISE EXCEPTION 'concurrent corrections did not produce exactly one group and explicit loser';
  END IF;
END $$;
