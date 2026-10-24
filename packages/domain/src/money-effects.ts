export type MoneyCop = bigint;
const MIN_COP = -9223372036854775808n;
const MAX_COP = 9223372036854775807n;

function checkedCop(value: bigint): MoneyCop {
  if (value < MIN_COP || value > MAX_COP) throw new RangeError('COP overflow');
  return value;
}

export function parseCop(value: unknown, positive = false): MoneyCop {
  if (
    typeof value !== 'string' ||
    value.match(/^(?:0|-?[1-9][0-9]*)$/)?.[0] !== value
  ) {
    throw new TypeError('Expected canonical whole COP');
  }
  const amount = checkedCop(BigInt(value));
  if (positive && amount <= 0n) throw new RangeError('Expected positive COP');
  return amount;
}

export function addCop(left: MoneyCop, right: MoneyCop): MoneyCop {
  return checkedCop(checkedCop(left) + checkedCop(right));
}

export function invertCop(value: MoneyCop): MoneyCop {
  return checkedCop(-checkedCop(value));
}

export function lineTotal(
  quantity: unknown,
  price: unknown,
  measure: string,
): MoneyCop {
  const pattern =
    measure === 'unit'
      ? /^[1-9][0-9]*$/
      : /^(?:0|[1-9][0-9]*)(?:\.[0-9]{1,3})?$/;
  if (
    !['unit', 'weight', 'volume'].includes(measure) ||
    typeof quantity !== 'string' ||
    quantity.match(pattern)?.[0] !== quantity
  ) {
    throw new TypeError('Unsupported quantity');
  }
  const [whole, fraction = ''] = quantity.split('.');
  const thousandths = BigInt(whole) * 1000n + BigInt(fraction.padEnd(3, '0'));
  if (thousandths <= 0n) throw new RangeError('Expected positive quantity');
  const product = thousandths * parseCop(price, true);
  if (product % 1000n !== 0n) throw new RangeError('Fractional COP line total');
  return checkedCop(product / 1000n);
}

export function operationEffects(
  kind: string,
  amount: unknown,
  account: string | null,
) {
  const value = parseCop(amount, true);
  let cash = 0n;
  let bank = 0n;
  let profit = 0n;
  if (kind === 'cash_to_bank' || kind === 'bank_to_cash') {
    if (account !== null) throw new TypeError('Transfer accounts are fixed');
    cash = kind === 'cash_to_bank' ? -value : value;
    bank = -cash;
  } else {
    if (
      !['sale', 'purchase', 'expense', 'contribution', 'withdrawal'].includes(
        kind,
      ) ||
      !['cash', 'bank'].includes(account ?? '')
    ) {
      throw new TypeError('Unsupported operation or account');
    }
    const delta = ['purchase', 'expense', 'withdrawal'].includes(kind)
      ? -value
      : value;
    if (account === 'cash') cash = delta;
    else bank = delta;
    if (['sale', 'purchase', 'expense'].includes(kind)) profit = delta;
  }
  return { cash, bank, profit, flow: addCop(cash, bank) };
}

export function openingBalances(
  cash: unknown,
  bank: unknown,
  effectiveDate: string,
  source: string,
) {
  if (
    !/^\d{4}-\d{2}-\d{2}$/.test(effectiveDate) ||
    !['manual', 'import'].includes(source)
  ) {
    throw new TypeError('Expected dated manual or imported opening balances');
  }
  const date = new Date(`${effectiveDate}T00:00:00.000Z`);
  if (
    !Number.isFinite(date.getTime()) ||
    date.toISOString().slice(0, 10) !== effectiveDate
  )
    throw new TypeError('Invalid opening date');
  return { cash: parseCop(cash), bank: parseCop(bank), effectiveDate, source };
}

export function balanceAfter(opening: MoneyCop, deltas: MoneyCop[]) {
  const amount = deltas.reduce(addCop, checkedCop(opening));
  return { amount, negative: amount < 0n };
}
