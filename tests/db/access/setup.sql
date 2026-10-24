DO $$
DECLARE
  admin_a uuid := '11111111-1111-1111-1111-111111111111';
  operator_a uuid := '22222222-2222-2222-2222-222222222222';
  business_a uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  business_b uuid := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  business_c uuid := 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  business_d uuid := 'dddddddd-dddd-dddd-dddd-dddddddddddd';
  business_e uuid := 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';
  added_member uuid := '77777777-7777-7777-7777-777777777777';
BEGIN
  INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  )
  SELECT
    id,
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    id::text || '@access.test',
    '$2a$10$7EqJtq98hPqEX7fNZaFWoO.VaLcjxYwP6B8Zx4B8nbh2yB01uE4mK',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  FROM unnest(ARRAY[
    '11111111-1111-1111-1111-111111111111'::uuid,
    '12111111-1111-1111-1111-111111111111'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid,
    '44444444-4444-4444-4444-444444444444'::uuid,
    '55555555-5555-5555-5555-555555555555'::uuid,
    '66666666-6666-6666-6666-666666666666'::uuid,
    '77777777-7777-7777-7777-777777777777'::uuid,
    'aaaaaaaa-1111-1111-1111-111111111111'::uuid,
    'bbbbbbbb-1111-1111-1111-111111111111'::uuid
  ]) AS identities(id);

  INSERT INTO public.businesses (id, name)
  VALUES
    (business_a, 'Access fixture A'),
    (business_b, 'Access fixture B'),
    (business_c, 'Access fixture C'),
    (business_d, 'Access fixture D'),
    (business_e, 'Access fixture E');

  INSERT INTO public.business_memberships (business_id, user_id, role)
  VALUES
    (business_a, '11111111-1111-1111-1111-111111111111', 'Administrator'),
    (business_a, '12111111-1111-1111-1111-111111111111', 'Administrator'),
    (business_a, '22222222-2222-2222-2222-222222222222', 'Operator'),
    (business_b, '33333333-3333-3333-3333-333333333333', 'Administrator'),
    (business_c, '44444444-4444-4444-4444-444444444444', 'Administrator'),
    (business_d, '55555555-5555-5555-5555-555555555555', 'Administrator'),
    (business_d, '66666666-6666-6666-6666-666666666666', 'Administrator'),
    (business_e, 'aaaaaaaa-1111-1111-1111-111111111111', 'Administrator'),
    (business_e, 'bbbbbbbb-1111-1111-1111-111111111111', 'Administrator');

  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub', admin_a::text, true);

  IF (SELECT count(*) FROM public.businesses) <> 1 THEN
    RAISE EXCEPTION 'administrator can read a foreign tenant';
  END IF;

  PERFORM public.create_business_member(business_a, added_member, 'Operator');
  IF NOT EXISTS (
    SELECT 1 FROM public.business_memberships
    WHERE business_id = business_a AND user_id = added_member AND role = 'Operator'
  ) THEN
    RAISE EXCEPTION 'administrator could not create a same-tenant Operator';
  END IF;
  PERFORM public.update_business_member_role(business_a, added_member, 'Administrator');
  IF NOT EXISTS (
    SELECT 1 FROM public.business_memberships
    WHERE business_id = business_a AND user_id = added_member AND role = 'Administrator'
  ) THEN
    RAISE EXCEPTION 'administrator could not update a same-tenant role';
  END IF;

  BEGIN
    PERFORM public.create_business_member(business_b, '88888888-8888-8888-8888-888888888888', 'Operator');
    RAISE EXCEPTION 'foreign tenant RPC unexpectedly succeeded';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  EXECUTE 'RESET ROLE';
  IF EXISTS (
    SELECT 1 FROM public.business_memberships
    WHERE user_id IN ('88888888-8888-8888-8888-888888888888', '99999999-9999-9999-9999-999999999999')
  ) THEN
    RAISE EXCEPTION 'rejected membership mutation changed data';
  END IF;
  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub', operator_a::text, true);
  IF (SELECT count(*) FROM public.business_memberships) <> 1 THEN
    RAISE EXCEPTION 'operator can read other memberships';
  END IF;

  BEGIN
    PERFORM public.create_business_member(business_a, '99999999-9999-9999-9999-999999999999', 'Operator');
    RAISE EXCEPTION 'operator membership RPC unexpectedly succeeded';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  BEGIN
    INSERT INTO public.business_memberships (business_id, user_id, role)
    VALUES (business_a, '99999999-9999-9999-9999-999999999999', 'Operator');
    RAISE EXCEPTION 'direct membership insert unexpectedly succeeded';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  EXECUTE 'RESET ROLE';
  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub', '44444444-4444-4444-4444-444444444444', true);
  BEGIN
    PERFORM public.deactivate_business_member(business_c, '44444444-4444-4444-4444-444444444444');
    RAISE EXCEPTION 'last Administrator deactivation unexpectedly succeeded';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  IF NOT EXISTS (
    SELECT 1 FROM public.business_memberships
    WHERE business_id = business_c AND user_id = '44444444-4444-4444-4444-444444444444' AND active
  ) THEN
    RAISE EXCEPTION 'rejected last Administrator mutation changed data';
  END IF;
END $$;
