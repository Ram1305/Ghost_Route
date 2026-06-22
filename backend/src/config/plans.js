/**
 * PremiumPlan index (0-1) → duration in days.
 * 0: platinumMonthly, 1: platinumYearly
 */
export const planDurationDays = {
  0: 30,
  1: 365,
};

/** Clamp plan index to valid range (0 = monthly, 1 = yearly). */
export function normalizePlanIndex(planIndex) {
  const idx = Number(planIndex);
  if (idx === 0 || idx === 1) return idx;
  return idx > 1 ? 1 : 0;
}

export function getPlanDurationDays(planIndex) {
  const normalized = normalizePlanIndex(planIndex);
  const days = planDurationDays[normalized];
  if (days == null) return null;
  return days;
}

/** Plan index (0-1) → { name, amount, currency } for invoice email. */
export const planInvoiceInfo = {
  0: { name: 'Platinum Monthly', amount: '$5.00', currency: 'USD' },
  1: { name: 'Platinum Yearly', amount: '$35.00', currency: 'USD' },
};

export function getPlanInvoiceInfo(planIndex) {
  const normalized = normalizePlanIndex(planIndex);
  return planInvoiceInfo[normalized] || { name: `Plan ${planIndex}`, amount: 'N/A', currency: 'USD' };
}
