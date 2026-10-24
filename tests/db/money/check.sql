DO $$
DECLARE
  fixtures jsonb := __MONEY_FIXTURES__;
  fixture jsonb;
  value text;
  field text;
  rejected boolean;
  effect jsonb;
  profit bigint := 0;
  flow bigint := 0;
BEGIN
  EXECUTE 'SET LOCAL ROLE authenticated';
  rejected := false;
  BEGIN PERFORM public.money_cop(NULL);
  EXCEPTION WHEN invalid_parameter_value THEN rejected := true; END;
  IF NOT rejected THEN RAISE EXCEPTION 'NULL COP accepted'; END IF;
  FOR value IN SELECT jsonb_array_elements_text(fixtures->'invalidCop') LOOP
    rejected := false;
    BEGIN PERFORM public.money_cop(value);
    EXCEPTION WHEN invalid_parameter_value OR numeric_value_out_of_range THEN rejected := true; END;
    IF NOT rejected THEN RAISE EXCEPTION 'accepted invalid COP: %', value; END IF;
  END LOOP;
  FOR value IN SELECT jsonb_array_elements_text(fixtures->'validCop') LOOP
    IF public.money_cop(value)::text <> value THEN RAISE EXCEPTION 'COP changed: %', value; END IF;
  END LOOP;
  FOR fixture IN SELECT jsonb_array_elements(fixtures->'lines') LOOP
    rejected := false;
    BEGIN
      value := public.money_line_total(fixture->>'quantity', fixture->>'price', fixture->>'measure')::text;
    EXCEPTION WHEN invalid_parameter_value OR numeric_value_out_of_range THEN rejected := true; END;
    IF fixture->>'total' IS NULL THEN
      IF NOT rejected THEN RAISE EXCEPTION 'accepted invalid line: %', fixture; END IF;
    ELSIF rejected OR value <> fixture->>'total' THEN
      RAISE EXCEPTION 'line total mismatch: %', fixture;
    END IF;
  END LOOP;
  FOR fixture IN SELECT jsonb_array_elements(fixtures->'operations') LOOP
    effect := public.money_effects(fixture->>'kind', fixture->>'amount', fixture->>'account');
    FOREACH field IN ARRAY ARRAY['cash','bank','profit','flow'] LOOP
      IF effect->>field <> fixture->>field THEN RAISE EXCEPTION 'effect mismatch: %', fixture; END IF;
    END LOOP;
    profit := public.money_add(profit::text, effect->>'profit');
    flow := public.money_add(flow::text, effect->>'flow');
  END LOOP;
  IF profit <> 21000 OR flow <> 27000 THEN RAISE EXCEPTION 'combined profit/flow mismatch'; END IF;
  rejected := false;
  BEGIN PERFORM public.money_inverse('-9223372036854775808');
  EXCEPTION WHEN numeric_value_out_of_range THEN rejected := true; END;
  IF NOT rejected THEN RAISE EXCEPTION 'inverse overflow accepted'; END IF;
  rejected := false;
  BEGIN PERFORM public.money_add('9223372036854775807', '1');
  EXCEPTION WHEN numeric_value_out_of_range THEN rejected := true; END;
  IF NOT rejected THEN RAISE EXCEPTION 'sum overflow accepted'; END IF;
  FOREACH value IN ARRAY ARRAY['manual', 'import'] LOOP
    effect := public.money_opening('10000', '-2000', '2026-10-24', value);
    IF effect->>'bank' <> '-2000' OR effect ? 'profit' THEN RAISE EXCEPTION 'opening effects changed'; END IF;
  END LOOP;
  IF public.money_add('10000','-12000') <> -2000 THEN RAISE EXCEPTION 'negative balances blocked'; END IF;
  rejected := false;
  BEGIN PERFORM public.money_opening('0','0','2026-02-30','manual');
  EXCEPTION WHEN datetime_field_overflow OR invalid_datetime_format THEN rejected := true; END;
  IF NOT rejected THEN RAISE EXCEPTION 'invalid date accepted'; END IF;
  EXECUTE 'RESET ROLE';
  RAISE NOTICE 'PASS money: shared exact COP/quantity/effects, boundaries, inverse/sum overflow and opening balances';
END $$;
