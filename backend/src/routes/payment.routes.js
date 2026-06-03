import { Router } from 'express';
import {
  createOrder,
  verifyPayment,
  getKeyId,
  activateSubscription,
  getPlans,
} from '../controllers/payment.controller.js';
import {
  verifyAndActivateStorePurchase,
  appleWebhook,
  googleWebhook,
} from '../controllers/store.controller.js';

const router = Router();

router.get('/plans', getPlans);
router.get('/key', getKeyId);
router.post('/create-order', createOrder);
router.post('/verify', verifyPayment);
router.post('/activate-subscription', activateSubscription);
router.post('/store/verify', verifyAndActivateStorePurchase);
router.post('/webhooks/apple', appleWebhook);
router.post('/webhooks/google', googleWebhook);

export default router;
