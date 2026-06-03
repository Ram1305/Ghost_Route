/** Store product ID → plan index (0–5). Must match lib/config/iap_products.dart */
export const PLAN_INDEX_BY_PRODUCT_ID = {
  'com.yencode.ghostroute.platinum.weekly': 0,
  'com.yencode.ghostroute.platinum.monthly': 1,
  'com.yencode.ghostroute.platinum.yearly': 2,
  'com.yencode.ghostroute.platinumplus.weekly': 3,
  'com.yencode.ghostroute.platinumplus.monthly': 4,
  'com.yencode.ghostroute.platinumplus.yearly': 5,
};

export function planIndexForProductId(productId) {
  if (!productId) return null;
  const idx = PLAN_INDEX_BY_PRODUCT_ID[String(productId).trim()];
  return idx === undefined ? null : idx;
}
