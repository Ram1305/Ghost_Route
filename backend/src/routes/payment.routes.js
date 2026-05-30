import { Router } from 'express';
import {
  createOrder,
  verifyPayment,
  getKeyId,
  activateSubscription,
  getPlans,
} from '../controllers/payment.controller.js';

const router = Router();

router.get('/plans', getPlans);
router.get('/key', getKeyId);
router.post('/create-order', createOrder);
router.post('/verify', verifyPayment);
router.post('/activate-subscription', activateSubscription);

export default router;
