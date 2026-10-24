CREATE TYPE public.business_role AS ENUM ('Administrator', 'Operator');

CREATE TABLE public.businesses (
  id uuid PRIMARY KEY,
  name text NOT NULL CHECK (char_length(name) BETWEEN 1 AND 120),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.business_memberships (
  business_id uuid NOT NULL REFERENCES public.businesses(id),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  role public.business_role NOT NULL,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, user_id),
  UNIQUE (user_id)
);

CREATE OR REPLACE FUNCTION public.has_active_business_membership(
  target_business_id uuid,
  target_user_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.business_memberships
    WHERE business_id = target_business_id
      AND user_id = target_user_id
      AND target_user_id = auth.uid()
      AND auth.uid() IS NOT NULL
      AND active
  );
$$;

CREATE OR REPLACE FUNCTION public.is_active_administrator(
  target_business_id uuid,
  target_user_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.business_memberships
    WHERE business_id = target_business_id
      AND user_id = target_user_id
      AND target_user_id = auth.uid()
      AND auth.uid() IS NOT NULL
      AND role = 'Administrator'
      AND active
  );
$$;

CREATE OR REPLACE FUNCTION public.protect_last_active_administrator()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF OLD.role = 'Administrator'
    AND OLD.active
    AND (TG_OP = 'DELETE' OR NEW.role <> 'Administrator' OR NOT NEW.active) THEN
    PERFORM 1 FROM public.businesses WHERE id = OLD.business_id FOR UPDATE;
    IF (
      SELECT count(*)
      FROM public.business_memberships
      WHERE business_id = OLD.business_id
        AND role = 'Administrator'
        AND active
    ) <= 1 THEN
      RAISE EXCEPTION 'a business must retain one active Administrator'
        USING ERRCODE = '23514';
    END IF;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER protect_last_active_administrator
BEFORE UPDATE OR DELETE ON public.business_memberships
FOR EACH ROW EXECUTE FUNCTION public.protect_last_active_administrator();

CREATE OR REPLACE FUNCTION public.create_business_member(
  target_business_id uuid,
  target_user_id uuid,
  target_role public.business_role
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF auth.uid() IS NULL
    OR NOT public.is_active_administrator(target_business_id, auth.uid()) THEN
    RAISE EXCEPTION 'Administrator role is required for membership administration'
      USING ERRCODE = '42501';
  END IF;
  INSERT INTO public.business_memberships (business_id, user_id, role)
  VALUES (target_business_id, target_user_id, target_role);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_business_member_role(
  target_business_id uuid,
  target_user_id uuid,
  target_role public.business_role
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF auth.uid() IS NULL
    OR NOT public.is_active_administrator(target_business_id, auth.uid()) THEN
    RAISE EXCEPTION 'Administrator role is required for membership administration'
      USING ERRCODE = '42501';
  END IF;
  UPDATE public.business_memberships
  SET role = target_role
  WHERE business_id = target_business_id AND user_id = target_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'business membership not found' USING ERRCODE = 'P0002';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.deactivate_business_member(
  target_business_id uuid,
  target_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF auth.uid() IS NULL
    OR NOT public.is_active_administrator(target_business_id, auth.uid()) THEN
    RAISE EXCEPTION 'Administrator role is required for membership administration'
      USING ERRCODE = '42501';
  END IF;
  UPDATE public.business_memberships
  SET active = false
  WHERE business_id = target_business_id AND user_id = target_user_id AND active;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'active business membership not found' USING ERRCODE = 'P0002';
  END IF;
END;
$$;

ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_memberships ENABLE ROW LEVEL SECURITY;

CREATE POLICY active_members_read_their_business ON public.businesses
FOR SELECT TO authenticated
USING (public.has_active_business_membership(id, auth.uid()));

CREATE POLICY members_read_themselves_or_admins_read_tenant ON public.business_memberships
FOR SELECT TO authenticated
USING (
  (user_id = auth.uid() AND active)
  OR public.is_active_administrator(business_id, auth.uid())
);

REVOKE ALL ON public.businesses, public.business_memberships FROM anon, authenticated;
GRANT SELECT ON public.businesses, public.business_memberships TO authenticated;
REVOKE ALL ON FUNCTION public.has_active_business_membership(uuid, uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_active_administrator(uuid, uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.create_business_member(uuid, uuid, public.business_role) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.update_business_member_role(uuid, uuid, public.business_role) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.deactivate_business_member(uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.has_active_business_membership(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_active_administrator(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_business_member(uuid, uuid, public.business_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_business_member_role(uuid, uuid, public.business_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.deactivate_business_member(uuid, uuid) TO authenticated;
