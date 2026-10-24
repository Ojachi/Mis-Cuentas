DO $$
DECLARE
  membership_visible boolean;
  administrator_visible boolean;
  orphan_created boolean;
BEGIN
  EXECUTE 'SET LOCAL ROLE authenticated';
  PERFORM set_config('request.jwt.claim.sub', '99999999-9999-9999-9999-999999999999', true);
  membership_visible := public.has_active_business_membership(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '11111111-1111-1111-1111-111111111111'
  );
  administrator_visible := public.is_active_administrator(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '11111111-1111-1111-1111-111111111111'
  );

  PERFORM set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
  BEGIN
    PERFORM public.create_business_member(
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'abababab-abab-abab-abab-abababababab',
      'Operator'
    );
    RAISE EXCEPTION 'orphan membership creation unexpectedly succeeded';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;

  EXECUTE 'RESET ROLE';
  orphan_created := EXISTS (
    SELECT 1 FROM public.business_memberships
    WHERE user_id = 'abababab-abab-abab-abab-abababababab'
  );

  IF membership_visible OR administrator_visible OR orphan_created THEN
    RAISE EXCEPTION
      'bypass: foreign_membership=%, foreign_administrator=%, orphan_membership=%',
      membership_visible, administrator_visible, orphan_created;
  END IF;
END $$;
