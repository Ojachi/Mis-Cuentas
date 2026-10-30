import { addCop, invertCop, type MoneyCop } from './money-effects';

export type FinancialEffects = {
  cash: MoneyCop;
  bank: MoneyCop;
  profit: MoneyCop;
  flow: MoneyCop;
};

export function correctionEffects(
  original: FinancialEffects,
  replacement?: FinancialEffects,
): FinancialEffects {
  return {
    cash: addCop(invertCop(original.cash), replacement?.cash ?? 0n),
    bank: addCop(invertCop(original.bank), replacement?.bank ?? 0n),
    profit: addCop(invertCop(original.profit), replacement?.profit ?? 0n),
    flow: addCop(invertCop(original.flow), replacement?.flow ?? 0n),
  };
}
