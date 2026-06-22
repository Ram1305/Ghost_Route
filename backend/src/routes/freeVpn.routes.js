import { Router } from 'express';
import {
  getFreeVpnStatus,
  markFreeVpnSessionUsed,
} from '../controllers/freeVpn.controller.js';

const router = Router();

router.get('/status', getFreeVpnStatus);
router.post('/mark-used', markFreeVpnSessionUsed);

export default router;
