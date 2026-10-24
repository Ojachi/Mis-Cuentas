CREATE SCHEMA IF NOT EXISTS harness;

CREATE TABLE IF NOT EXISTS harness.seeded_identities (
  id uuid PRIMARY KEY,
  label text NOT NULL UNIQUE
);

INSERT INTO harness.seeded_identities (id, label)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'synthetic-admin'),
  ('22222222-2222-2222-2222-222222222222', 'synthetic-operator')
ON CONFLICT (id) DO NOTHING;
