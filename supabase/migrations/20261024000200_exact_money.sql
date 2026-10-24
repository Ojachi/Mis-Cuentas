CREATE FUNCTION public.money_cop(value text, positive boolean DEFAULT false)
RETURNS bigint LANGUAGE plpgsql IMMUTABLE SET search_path = pg_catalog AS $$
DECLARE amount numeric;
BEGIN
  IF value IS NULL OR value !~ '^(0|-?[1-9][0-9]*)$' OR value ~ '[[:space:]]' THEN
    RAISE EXCEPTION 'expected canonical whole COP' USING ERRCODE = '22023';
  END IF;
  amount := value::numeric;
  IF amount < -9223372036854775808 OR amount > 9223372036854775807 THEN
    RAISE EXCEPTION 'COP overflow' USING ERRCODE = '22003';
  END IF;
  IF positive IS NULL OR (positive AND amount <= 0) THEN
    RAISE EXCEPTION 'expected positive COP' USING ERRCODE = '22023';
  END IF;
  RETURN amount::bigint;
END $$;

CREATE FUNCTION public.money_add(left_value text, right_value text)
RETURNS bigint LANGUAGE sql IMMUTABLE SET search_path = pg_catalog, public AS $$
  SELECT public.money_cop((public.money_cop(left_value)::numeric + public.money_cop(right_value)::numeric)::text);
$$;

CREATE FUNCTION public.money_inverse(value text)
RETURNS bigint LANGUAGE sql IMMUTABLE SET search_path = pg_catalog, public AS $$
  SELECT public.money_cop((-public.money_cop(value)::numeric)::text);
$$;

CREATE FUNCTION public.money_line_total(quantity text, price text, measure text)
RETURNS bigint LANGUAGE plpgsql IMMUTABLE SET search_path = pg_catalog, public AS $$
DECLARE product numeric;
BEGIN
  IF quantity IS NULL OR measure IS NULL OR measure NOT IN ('unit', 'weight', 'volume')
    OR quantity ~ '[[:space:]]'
    OR (measure = 'unit' AND quantity !~ '^[1-9][0-9]*$')
    OR (measure <> 'unit' AND quantity !~ '^(0|[1-9][0-9]*)(\.[0-9]{1,3})?$') THEN
    RAISE EXCEPTION 'unsupported quantity' USING ERRCODE = '22023';
  END IF;
  IF quantity::numeric <= 0 THEN
    RAISE EXCEPTION 'expected positive quantity' USING ERRCODE = '22023';
  END IF;
  product := quantity::numeric * public.money_cop(price, true)::numeric;
  IF product <> trunc(product) THEN
    RAISE EXCEPTION 'fractional COP line total' USING ERRCODE = '22023';
  END IF;
  RETURN public.money_cop(trunc(product)::text);
END $$;

CREATE FUNCTION public.money_effects(kind text, amount text, account text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql IMMUTABLE SET search_path = pg_catalog, public AS $$
DECLARE
  value bigint := public.money_cop(amount, true);
  cash bigint := 0;
  bank bigint := 0;
  profit bigint := 0;
  delta bigint;
BEGIN
  IF kind IN ('cash_to_bank', 'bank_to_cash') THEN
    IF account IS NOT NULL THEN
      RAISE EXCEPTION 'transfer accounts are fixed' USING ERRCODE = '22023';
    END IF;
    cash := CASE WHEN kind = 'cash_to_bank' THEN -value ELSE value END;
    bank := -cash;
  ELSE
    IF kind IS NULL OR kind NOT IN ('sale', 'purchase', 'expense', 'contribution', 'withdrawal')
      OR account IS NULL OR account NOT IN ('cash', 'bank') THEN
      RAISE EXCEPTION 'unsupported operation or account' USING ERRCODE = '22023';
    END IF;
    delta := CASE WHEN kind IN ('purchase', 'expense', 'withdrawal') THEN -value ELSE value END;
    IF account = 'cash' THEN cash := delta; ELSE bank := delta; END IF;
    IF kind IN ('sale', 'purchase', 'expense') THEN profit := delta; END IF;
  END IF;
  RETURN jsonb_build_object('cash', cash::text, 'bank', bank::text, 'profit', profit::text,
    'flow', public.money_add(cash::text, bank::text)::text);
END $$;

CREATE FUNCTION public.money_opening(cash text, bank text, effective_date text, source text)
RETURNS jsonb LANGUAGE plpgsql IMMUTABLE SET search_path = pg_catalog, public AS $$
BEGIN
  IF effective_date IS NULL OR effective_date !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
    OR source IS NULL OR source NOT IN ('manual', 'import') THEN
    RAISE EXCEPTION 'expected dated manual or imported opening balances' USING ERRCODE = '22023';
  END IF;
  PERFORM effective_date::date;
  RETURN jsonb_build_object('cash', public.money_cop(cash)::text, 'bank', public.money_cop(bank)::text,
    'effectiveDate', effective_date, 'source', source);
END $$;

REVOKE ALL ON FUNCTION public.money_cop(text, boolean), public.money_add(text, text),
  public.money_inverse(text), public.money_line_total(text, text, text),
  public.money_effects(text, text, text), public.money_opening(text, text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.money_cop(text, boolean), public.money_add(text, text),
  public.money_inverse(text), public.money_line_total(text, text, text),
  public.money_effects(text, text, text), public.money_opening(text, text, text, text) TO authenticated;
