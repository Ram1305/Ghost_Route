/**
 * PremiumPlan index (0-5) → duration in days.
 * 0: platinumWeekly, 1: platinumMonthly, 2: platinumYearly,
 * 3: platinumPlusWeekly, 4: platinumPlusMonthly, 5: platinumPlusYearly
 */
export const planDurationDays = {
  0: 7,
  1: 30,
  2: 365,
  3: 7,
  4: 30,
  5: 365,
};

export function getPlanDurationDays(planIndex) {
  const days = planDurationDays[planIndex];
  if (days == null) return null;
  return days;
}

/** Plan index (0-5) → { name, amount, currency } for invoice email. */
export const planInvoiceInfo = {
  0: { name: 'Platinum Weekly (3 devices)', amount: '₹4.99', currency: 'INR' },
  1: { name: 'Platinum Monthly (5 devices)', amount: '₹9.99', currency: 'INR' },
  2: { name: 'Platinum Yearly (5 devices)', amount: '₹39.99', currency: 'INR' },
  3: { name: 'Platinum+ Weekly (5 devices)', amount: '₹6.99', currency: 'INR' },
  4: { name: 'Platinum+ Monthly (10 devices)', amount: '₹14.99', currency: 'INR' },
  5: { name: 'Platinum+ Yearly (10 devices)', amount: '₹59.99', currency: 'INR' },
};

export function getPlanInvoiceInfo(planIndex) {
  return planInvoiceInfo[planIndex] || { name: `Plan ${planIndex}`, amount: 'N/A', currency: 'INR' };
}
