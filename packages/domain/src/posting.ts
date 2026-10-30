const scalarFields = new Set([
  'version',
  'kind',
  'account',
  'amount',
  'supplier',
  'description',
  'occurredAt',
  'clientCreatedAt',
]);
const lineFields = new Set([
  'name',
  'quantity',
  'unitPrice',
  'total',
  'measure',
]);

function canonical(value: unknown, fields?: Set<string>): string {
  if (value === null || typeof value === 'number' || typeof value === 'boolean')
    throw new TypeError(
      'Posting payload values must be strings, objects, or arrays',
    );
  if (typeof value === 'string') return JSON.stringify(value);
  if (Array.isArray(value))
    return `[${value.map((item) => canonical(item, lineFields)).join(', ')}]`;
  if (!value || typeof value !== 'object')
    throw new TypeError('Invalid posting payload');
  const entries = Object.entries(value).sort(([a], [b]) =>
    a < b ? -1 : a > b ? 1 : 0,
  );
  for (const [key, item] of entries) {
    if (!(fields ?? scalarFields).has(key))
      throw new TypeError(`Unknown posting field: ${key}`);
    if (key === 'lines') {
      if (!Array.isArray(item)) throw new TypeError('lines must be an array');
    } else if (typeof item !== 'string')
      throw new TypeError(`${key} must be a string`);
  }
  return `{${entries.map(([key, item]) => `${JSON.stringify(key)}: ${key === 'lines' ? canonical(item, lineFields) : canonical(item)}`).join(', ')}}`;
}

export function canonicalPosting(payload: unknown): string {
  return canonical(payload, new Set([...scalarFields, 'lines']));
}
