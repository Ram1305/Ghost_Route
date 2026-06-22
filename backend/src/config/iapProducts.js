/** Store product ID → plan index (0–1). Must match lib/config/iap_products.dart */
export const PLAN_INDEX_BY_PRODUCT_ID = {
  'com.yencode.ghostroute.platinum.monthly': 0,
  'com.yencode.ghostroute.platinum.yearly': 1,
  // Legacy products (restore purchases)
  'com.yencode.ghostroute.platinum.weekly': 0,
  'com.yencode.ghostroute.platinumplus.weekly': 0,
  'com.yencode.ghostroute.platinumplus.monthly': 0,
  'com.yencode.ghostroute.platinumplus.yearly': 1,
};

export function planIndexForProductId(productId) {
  if (!productId) return null;
  const idx = PLAN_INDEX_BY_PRODUCT_ID[String(productId).trim()];
  return idx === undefined ? null : idx;
}
