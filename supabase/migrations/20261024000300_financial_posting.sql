CREATE TABLE public.financial_facts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), business_id uuid NOT NULL REFERENCES public.businesses(id), operation_id uuid NOT NULL,
  actor_id uuid NOT NULL REFERENCES auth.users(id), kind text NOT NULL, payload jsonb NOT NULL, payload_hash text NOT NULL,
  occurred_at timestamptz NOT NULL, client_created_at timestamptz NOT NULL, accepted_at timestamptz NOT NULL DEFAULT now(), UNIQUE (business_id, operation_id)
);
CREATE TABLE public.financial_effects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), fact_id uuid NOT NULL REFERENCES public.financial_facts(id), business_id uuid NOT NULL REFERENCES public.businesses(id),
  account text NOT NULL CHECK (account IN ('cash','bank','profit')), amount bigint NOT NULL, created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(fact_id, account)
);
CREATE TABLE public.financial_audit (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), business_id uuid NOT NULL REFERENCES public.businesses(id), fact_id uuid NOT NULL REFERENCES public.financial_facts(id), actor_id uuid NOT NULL REFERENCES auth.users(id), event text NOT NULL CHECK (event = 'posted'), payload_hash text NOT NULL, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.financial_receipts (
  business_id uuid NOT NULL REFERENCES public.businesses(id), operation_id uuid NOT NULL, fact_id uuid NOT NULL REFERENCES public.financial_facts(id), payload_hash text NOT NULL, accepted_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY (business_id, operation_id)
);

CREATE FUNCTION public.canonical_posting(input jsonb) RETURNS text LANGUAGE plpgsql IMMUTABLE SET search_path=pg_catalog AS $$
DECLARE key text; result text := ''; item jsonb;
BEGIN
  IF jsonb_typeof(input)='string' THEN RETURN input::text; END IF;
  IF jsonb_typeof(input)='array' THEN SELECT '[' || coalesce(string_agg(public.canonical_posting(value), ', ' ORDER BY ordinal),'') || ']' INTO result FROM jsonb_array_elements(input) WITH ORDINALITY AS items(value,ordinal); RETURN result; END IF;
  IF jsonb_typeof(input)='object' THEN FOR key,item IN SELECT entry.key,entry.value FROM jsonb_each(input) AS entry(key,value) ORDER BY convert_to(entry.key,'UTF8') LOOP result := result || CASE WHEN result='' THEN '' ELSE ', ' END || to_json(key)::text || ': ' || public.canonical_posting(item); END LOOP; RETURN '{' || result || '}'; END IF;
  RAISE EXCEPTION 'unsupported canonical JSON scalar' USING ERRCODE='22023';
END $$;
CREATE FUNCTION public.post_financial_operation(target_business_id uuid, target_operation_id uuid, input_payload jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE actor uuid := auth.uid(); canonical text; digest text; existing public.financial_receipts%ROWTYPE; fact_id uuid; kind text; amount text; effects jsonb; field text; line jsonb; total bigint := 0; occurred_at timestamptz; client_created_at timestamptz;
BEGIN
  IF actor IS NULL OR NOT public.has_active_business_membership(target_business_id, actor) THEN RAISE EXCEPTION 'active membership is required' USING ERRCODE='42501'; END IF;
  IF input_payload IS NULL OR jsonb_typeof(input_payload) IS DISTINCT FROM 'object' OR input_payload ?| ARRAY(SELECT key FROM jsonb_object_keys(input_payload) AS keys(key) WHERE key NOT IN ('version','kind','account','amount','lines','supplier','description','occurredAt','clientCreatedAt')) THEN RAISE EXCEPTION 'unknown or malformed payload' USING ERRCODE='22023'; END IF;
  IF jsonb_typeof(input_payload->'version') IS DISTINCT FROM 'string' OR input_payload->>'version' <> '1' OR jsonb_typeof(input_payload->'kind') IS DISTINCT FROM 'string' OR input_payload->>'kind' NOT IN ('sale','purchase','expense','contribution','withdrawal','cash_to_bank','bank_to_cash') OR jsonb_typeof(input_payload->'occurredAt') IS DISTINCT FROM 'string' OR jsonb_typeof(input_payload->'clientCreatedAt') IS DISTINCT FROM 'string' OR input_payload->>'occurredAt' !~ 'T.*(Z|[+-][0-9]{2}:[0-9]{2})$' OR input_payload->>'clientCreatedAt' !~ 'T.*(Z|[+-][0-9]{2}:[0-9]{2})$' THEN RAISE EXCEPTION 'unsupported posting version, kind or timestamp' USING ERRCODE='22023'; END IF;
  BEGIN occurred_at := (input_payload->>'occurredAt')::timestamptz; client_created_at := (input_payload->>'clientCreatedAt')::timestamptz; EXCEPTION WHEN invalid_datetime_format OR datetime_field_overflow THEN RAISE EXCEPTION 'invalid timestamp' USING ERRCODE='22023'; END;
  kind := input_payload->>'kind'; canonical := public.canonical_posting(input_payload); digest := encode(sha256(convert_to(canonical,'UTF8')),'hex');
  PERFORM 1 FROM public.business_memberships WHERE business_id=target_business_id AND user_id=actor AND active FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'active membership is required' USING ERRCODE='42501'; END IF;
  PERFORM 1 FROM public.businesses WHERE id=target_business_id FOR UPDATE;
  SELECT * INTO existing FROM public.financial_receipts WHERE business_id=target_business_id AND operation_id=target_operation_id;
  IF FOUND THEN IF existing.payload_hash <> digest THEN RAISE EXCEPTION 'operation hash mismatch' USING ERRCODE='23505'; END IF; RETURN jsonb_build_object('operationId',target_operation_id::text,'factId',existing.fact_id::text,'hash',digest,'acceptedAt',existing.accepted_at); END IF;
  IF kind IN ('sale','purchase') THEN
    IF jsonb_typeof(input_payload->'lines') IS DISTINCT FROM 'array' OR jsonb_array_length(input_payload->'lines') = 0 THEN RAISE EXCEPTION 'itemized lines required' USING ERRCODE='22023'; END IF;
    FOR line IN SELECT value FROM jsonb_array_elements(input_payload->'lines') LOOP
      IF jsonb_typeof(line) IS DISTINCT FROM 'object'
        OR line ?| ARRAY(SELECT key FROM jsonb_object_keys(line) AS keys(key) WHERE key NOT IN ('name','quantity','unitPrice','total','measure'))
        OR jsonb_typeof(line->'name') IS DISTINCT FROM 'string' OR btrim(line->>'name')=''
        OR jsonb_typeof(line->'quantity') IS DISTINCT FROM 'string'
        OR jsonb_typeof(line->'unitPrice') IS DISTINCT FROM 'string'
        OR jsonb_typeof(line->'total') IS DISTINCT FROM 'string'
        OR (line ? 'measure' AND (jsonb_typeof(line->'measure') IS DISTINCT FROM 'string' OR line->>'measure' NOT IN ('unit','weight','volume')))
        OR (kind='sale' AND line ? 'measure' AND line->>'measure' <> 'unit')
        OR public.money_line_total(line->>'quantity',line->>'unitPrice',coalesce(line->>'measure','unit')) <> public.money_cop(line->>'total',true)
      THEN RAISE EXCEPTION 'invalid item snapshot' USING ERRCODE='22023'; END IF;
      total := public.money_add(total::text,(line->>'total'));
    END LOOP;
    IF jsonb_typeof(input_payload->'amount') IS DISTINCT FROM 'string' OR input_payload->>'amount' <> total::text THEN RAISE EXCEPTION 'itemized amount must equal snapshots' USING ERRCODE='22023'; END IF;
    IF kind = 'purchase' AND (jsonb_typeof(input_payload->'supplier') IS DISTINCT FROM 'string' OR btrim(input_payload->>'supplier')='') THEN RAISE EXCEPTION 'purchase supplier required' USING ERRCODE='22023'; END IF;
    amount := total::text;
  ELSE
    IF jsonb_typeof(input_payload->'amount') IS DISTINCT FROM 'string' THEN RAISE EXCEPTION 'amount must be a string' USING ERRCODE='22023'; END IF; amount := input_payload->>'amount'; PERFORM public.money_cop(amount,true);
  END IF;
  IF kind IN ('sale','purchase','expense','contribution','withdrawal') AND (jsonb_typeof(input_payload->'account') IS DISTINCT FROM 'string' OR input_payload->>'account' NOT IN ('cash','bank')) THEN RAISE EXCEPTION 'known account required' USING ERRCODE='22023'; END IF;
  IF kind IN ('cash_to_bank','bank_to_cash') AND (input_payload ? 'account' OR input_payload ? 'lines' OR input_payload ? 'supplier' OR input_payload ? 'description') THEN RAISE EXCEPTION 'transfer fields are fixed' USING ERRCODE='22023'; END IF;
  IF kind='expense' AND (jsonb_typeof(input_payload->'description') IS DISTINCT FROM 'string' OR btrim(input_payload->>'description')='') THEN RAISE EXCEPTION 'expense description required' USING ERRCODE='22023'; END IF;
  IF (input_payload ? 'lines' AND kind NOT IN ('sale','purchase'))
    OR (input_payload ? 'supplier' AND kind <> 'purchase')
    OR (input_payload ? 'description' AND kind <> 'expense')
  THEN RAISE EXCEPTION 'fields do not apply to this operation kind' USING ERRCODE='22023'; END IF;
  effects := public.money_effects(kind,amount,CASE WHEN kind IN ('cash_to_bank','bank_to_cash') THEN NULL ELSE input_payload->>'account' END);
  INSERT INTO public.financial_facts(business_id,operation_id,actor_id,kind,payload,payload_hash,occurred_at,client_created_at) VALUES(target_business_id,target_operation_id,actor,kind,input_payload,digest,occurred_at,client_created_at) RETURNING id INTO fact_id;
  FOREACH field IN ARRAY ARRAY['cash','bank','profit'] LOOP IF (effects->>field)::bigint <> 0 THEN INSERT INTO public.financial_effects(fact_id,business_id,account,amount) VALUES(fact_id,target_business_id,field,(effects->>field)::bigint); END IF; END LOOP;
  INSERT INTO public.financial_audit(business_id,fact_id,actor_id,event,payload_hash) VALUES(target_business_id,fact_id,actor,'posted',digest);
  INSERT INTO public.financial_receipts(business_id,operation_id,fact_id,payload_hash) VALUES(target_business_id,target_operation_id,fact_id,digest);
  RETURN jsonb_build_object('operationId',target_operation_id::text,'factId',fact_id::text,'hash',digest,'acceptedAt',now());
END $$;
ALTER TABLE public.financial_facts ENABLE ROW LEVEL SECURITY; ALTER TABLE public.financial_effects ENABLE ROW LEVEL SECURITY; ALTER TABLE public.financial_audit ENABLE ROW LEVEL SECURITY; ALTER TABLE public.financial_receipts ENABLE ROW LEVEL SECURITY;
CREATE POLICY financial_facts_read ON public.financial_facts FOR SELECT TO authenticated USING (public.has_active_business_membership(business_id,auth.uid()));
CREATE POLICY financial_effects_read ON public.financial_effects FOR SELECT TO authenticated USING (public.has_active_business_membership(business_id,auth.uid()));
CREATE POLICY financial_audit_read ON public.financial_audit FOR SELECT TO authenticated USING (public.has_active_business_membership(business_id,auth.uid()));
CREATE POLICY financial_receipts_read ON public.financial_receipts FOR SELECT TO authenticated USING (public.has_active_business_membership(business_id,auth.uid()));
REVOKE ALL ON public.financial_facts, public.financial_effects, public.financial_audit, public.financial_receipts FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.financial_facts, public.financial_effects, public.financial_audit, public.financial_receipts TO authenticated;
REVOKE ALL ON FUNCTION public.post_financial_operation(uuid,uuid,jsonb) FROM PUBLIC, anon; GRANT EXECUTE ON FUNCTION public.post_financial_operation(uuid,uuid,jsonb) TO authenticated;
REVOKE ALL ON FUNCTION public.canonical_posting(jsonb) FROM PUBLIC, anon, authenticated;
