import { Router } from 'express';
import userRoutes from './user.routes.js';
import paymentRoutes from './payment.routes.js';
import authRoutes from './auth.routes.js';
import serverRoutes from './server.routes.js';
import freeVpnRoutes from './freeVpn.routes.js';

const router = Router();

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/payments', paymentRoutes);
router.use('/servers', serverRoutes);
router.use('/free-vpn', freeVpnRoutes);

router.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

export default router;
