/**
 * PremiumPlan index (0-1) → duration in days.
 * 0: platinumMonthly, 1: platinumYearly
 */
export const planDurationDays = {
  0: 30,
  1: 365,
};

/** Legacy indices (old 2-5 scheme) → current plan index. Indices 0-1 pass through. */
export function normalizePlanIndex(planIndex) {
  const idx = Number(planIndex);
  if (idx >= 0 && idx <= 1) return idx;
  switch (idx) {
    case 2:
    case 5:
      return 1;
    case 3:
    case 4:
      return 0;
    default:
      return idx;
  }
}

/** One-time migration for users still on old 0-5 plan indices. */
export function migrateLegacyPlanIndex(planIndex) {
  switch (Number(planIndex)) {
    case 0:
    case 1:
    case 3:
    case 4:
      return 0;
    case 2:
    case 5:
      return 1;
    default:
      return normalizePlanIndex(planIndex);
  }
}

export function getPlanDurationDays(planIndex) {
  const normalized = normalizePlanIndex(planIndex);
  const days = planDurationDays[normalized];
  if (days == null) return null;
  return days;
}

/** Plan index (0-1) → { name, amount, currency } for invoice email. */
export const planInvoiceInfo = {
  0: { name: 'Platinum Monthly (5 devices)', amount: '$5.00', currency: 'USD' },
  1: { name: 'Platinum Yearly (5 devices)', amount: '$35.00', currency: 'USD' },
};

export function getPlanInvoiceInfo(planIndex) {
  const normalized = normalizePlanIndex(planIndex);
  return planInvoiceInfo[normalized] || { name: `Plan ${planIndex}`, amount: 'N/A', currency: 'USD' };
}
