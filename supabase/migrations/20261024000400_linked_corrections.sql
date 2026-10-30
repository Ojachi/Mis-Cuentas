CREATE TABLE public.financial_corrections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id),
  operation_id uuid NOT NULL,
  target_fact_id uuid NOT NULL REFERENCES public.financial_facts(id),
  inverse_fact_id uuid REFERENCES public.financial_facts(id),
  replacement_fact_id uuid REFERENCES public.financial_facts(id),
  actor_id uuid NOT NULL REFERENCES auth.users(id),
  reason text NOT NULL CHECK (btrim(reason) <> ''),
  action text NOT NULL CHECK (action IN ('void', 'replace')),
  request_hash text NOT NULL,
  original_occurred_at timestamptz NOT NULL,
  corrected_at timestamptz NOT NULL DEFAULT now(),
  CHECK (action <> 'void' OR replacement_fact_id IS NULL),
  UNIQUE (business_id, operation_id),
  UNIQUE (target_fact_id)
);

CREATE TABLE public.financial_correction_audit (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id),
  target_fact_id uuid REFERENCES public.financial_facts(id),
  actor_id uuid NOT NULL REFERENCES auth.users(id),
  correction_id uuid REFERENCES public.financial_corrections(id),
  event text NOT NULL CHECK (event IN ('accepted', 'denied')),
  reason text,
  request_hash text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.financial_audit DROP CONSTRAINT financial_audit_event_check;
ALTER TABLE public.financial_audit ADD CONSTRAINT financial_audit_event_check
  CHECK (event IN ('posted', 'correction_inverse', 'correction_replacement'));

CREATE OR REPLACE FUNCTION public.canonical_correction(input jsonb)
RETURNS text LANGUAGE plpgsql IMMUTABLE SET search_path = pg_catalog, public AS $$
DECLARE action text; reason text; replacement jsonb;
BEGIN
  IF input IS NULL OR jsonb_typeof(input) <> 'object'
    OR input ?| ARRAY(SELECT key FROM jsonb_object_keys(input) AS keys(key) WHERE key NOT IN ('version', 'action', 'reason', 'replacement'))
    OR jsonb_typeof(input->'version') IS DISTINCT FROM 'string' OR input->>'version' <> '1'
    OR jsonb_typeof(input->'action') IS DISTINCT FROM 'string' OR input->>'action' NOT IN ('void', 'replace')
    OR jsonb_typeof(input->'reason') IS DISTINCT FROM 'string' OR btrim(input->>'reason') = '' THEN
    RAISE EXCEPTION 'unknown or malformed correction request' USING ERRCODE = '22023';
  END IF;
  action := input->>'action'; reason := input->>'reason'; replacement := input->'replacement';
  IF (action = 'void' AND input ? 'replacement')
    OR (action = 'replace' AND jsonb_typeof(replacement) IS DISTINCT FROM 'object') THEN
    RAISE EXCEPTION 'invalid correction replacement' USING ERRCODE = '22023';
  END IF;
  RETURN '{"action": ' || to_json(action)::text || ', "reason": ' || to_json(reason)::text
    || ', "replacement": ' || CASE WHEN replacement IS NULL THEN 'null' ELSE public.canonical_posting(replacement) END
    || ', "version": "1"}';
END $$;

CREATE OR REPLACE FUNCTION public.correct_financial_operation(
  target_business_id uuid,
  target_operation_id uuid,
  correction_operation_id uuid,
  request jsonb
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE
  actor uuid := auth.uid(); membership_role public.business_role; canonical text; digest text;
  existing public.financial_corrections%ROWTYPE; target public.financial_facts%ROWTYPE;
  correction_id uuid; inverse_id uuid; replacement_id uuid; replacement_receipt jsonb;
  effect record; inverse_payload jsonb; inverse_hash text; replacement_occurred_at timestamptz;
BEGIN
  IF actor IS NULL THEN
    RAISE EXCEPTION 'active membership is required' USING ERRCODE = '42501';
  END IF;
  SELECT role INTO membership_role FROM public.business_memberships
  WHERE business_id = target_business_id AND user_id = actor AND active FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'active membership is required' USING ERRCODE = '42501'; END IF;
  PERFORM 1 FROM public.businesses WHERE id = target_business_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'active membership is required' USING ERRCODE = '42501'; END IF;
  canonical := public.canonical_correction(request);
  digest := encode(sha256(convert_to(canonical, 'UTF8')), 'hex');
  IF membership_role <> 'Administrator' THEN
    INSERT INTO public.financial_correction_audit(business_id, actor_id, event, reason, request_hash)
    VALUES (target_business_id, actor, 'denied', 'Administrator role is required', digest);
    RETURN jsonb_build_object('status', 'denied', 'code', 'administrator_required');
  END IF;
  SELECT * INTO target FROM public.financial_facts
  WHERE business_id = target_business_id AND operation_id = target_operation_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'posted target not found' USING ERRCODE = 'P0002'; END IF;
  IF target.payload->>'kind' = 'correction_inverse'
    OR EXISTS (SELECT 1 FROM public.financial_corrections WHERE inverse_fact_id = target.id) THEN
    RAISE EXCEPTION 'correction artifacts cannot be targeted' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO existing FROM public.financial_corrections
  WHERE business_id = target_business_id AND operation_id = correction_operation_id;
  IF FOUND THEN
    IF existing.request_hash <> digest OR existing.target_fact_id <> target.id THEN
      RAISE EXCEPTION 'correction identity mismatch' USING ERRCODE = '23505';
    END IF;
    RETURN jsonb_build_object('status', 'accepted', 'correctionId', existing.id::text,
      'inverseFactId', existing.inverse_fact_id::text, 'replacementFactId', existing.replacement_fact_id::text,
      'correctedAt', existing.corrected_at);
  END IF;
  IF EXISTS (SELECT 1 FROM public.financial_corrections WHERE target_fact_id = target.id) THEN
    INSERT INTO public.financial_correction_audit(business_id, target_fact_id, actor_id, event, reason, request_hash)
    VALUES (target_business_id, target.id, actor, 'denied', 'target revision already corrected', digest);
    RETURN jsonb_build_object('status', 'attention', 'code', 'target_already_corrected');
  END IF;
  IF request->>'action' = 'replace' THEN
    BEGIN
      replacement_occurred_at := (request->'replacement'->>'occurredAt')::timestamptz;
    EXCEPTION WHEN invalid_datetime_format OR datetime_field_overflow THEN
      RAISE EXCEPTION 'invalid replacement occurrence instant' USING ERRCODE = '22023';
    END;
    IF replacement_occurred_at IS DISTINCT FROM target.occurred_at THEN
      RAISE EXCEPTION 'replacement must retain original occurrence instant' USING ERRCODE = '22023';
    END IF;
  END IF;
  INSERT INTO public.financial_corrections(business_id, operation_id, target_fact_id, actor_id, reason, action, request_hash, original_occurred_at)
  VALUES (target_business_id, correction_operation_id, target.id, actor, request->>'reason', request->>'action', digest, target.occurred_at)
  RETURNING id INTO correction_id;
  inverse_payload := jsonb_build_object('version', '1', 'kind', 'correction_inverse', 'targetFactId', target.id::text);
  inverse_hash := encode(sha256(convert_to(public.canonical_posting(inverse_payload), 'UTF8')), 'hex');
  INSERT INTO public.financial_facts(business_id, operation_id, actor_id, kind, payload, payload_hash, occurred_at, client_created_at)
  VALUES (target_business_id, gen_random_uuid(), actor, target.kind, inverse_payload,
    inverse_hash,
    target.occurred_at, target.client_created_at)
  RETURNING id INTO inverse_id;
  FOR effect IN SELECT account, amount FROM public.financial_effects WHERE fact_id = target.id LOOP
    INSERT INTO public.financial_effects(fact_id, business_id, account, amount)
    VALUES (inverse_id, target_business_id, effect.account, public.money_inverse(effect.amount::text));
  END LOOP;
  INSERT INTO public.financial_audit(business_id, fact_id, actor_id, event, payload_hash)
  VALUES (target_business_id, inverse_id, actor, 'correction_inverse', inverse_hash);
  IF request->>'action' = 'replace' THEN
    replacement_receipt := public.post_financial_operation(target_business_id, gen_random_uuid(), request->'replacement');
    replacement_id := (replacement_receipt->>'factId')::uuid;
    UPDATE public.financial_audit SET event = 'correction_replacement'
    WHERE fact_id = replacement_id AND event = 'posted';
  END IF;
  UPDATE public.financial_corrections SET inverse_fact_id = inverse_id, replacement_fact_id = replacement_id
  WHERE id = correction_id;
  INSERT INTO public.financial_correction_audit(business_id, target_fact_id, actor_id, correction_id, event, reason, request_hash)
  VALUES (target_business_id, target.id, actor, correction_id, 'accepted', request->>'reason', digest);
  RETURN jsonb_build_object('status', 'accepted', 'correctionId', correction_id::text,
    'inverseFactId', inverse_id::text, 'replacementFactId', replacement_id::text, 'correctedAt', now());
END $$;

ALTER TABLE public.financial_corrections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_correction_audit ENABLE ROW LEVEL SECURITY;
CREATE POLICY financial_corrections_read ON public.financial_corrections FOR SELECT TO authenticated
  USING (public.has_active_business_membership(business_id, auth.uid()));
CREATE POLICY financial_correction_audit_read ON public.financial_correction_audit FOR SELECT TO authenticated
  USING (public.has_active_business_membership(business_id, auth.uid()));
REVOKE ALL ON public.financial_corrections, public.financial_correction_audit FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.financial_corrections, public.financial_correction_audit TO authenticated;
REVOKE ALL ON FUNCTION public.canonical_correction(jsonb), public.correct_financial_operation(uuid,uuid,uuid,jsonb) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.canonical_correction(jsonb) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.correct_financial_operation(uuid,uuid,uuid,jsonb) TO authenticated;
