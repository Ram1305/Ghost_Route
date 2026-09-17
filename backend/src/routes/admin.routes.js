import { Router } from 'express';
import * as adminController from '../controllers/admin.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { requireAdmin } from '../middleware/admin.middleware.js';

const router = Router();

router.use(authenticate, requireAdmin);

router.get('/stats', adminController.getStats);
router.get('/subscriptions/recent', adminController.getRecentSubscriptions);
router.get('/notifications', adminController.getNotifications);
router.post('/notifications/read-all', adminController.markAllNotificationsRead);
router.post('/notifications/:id/read', adminController.markNotificationRead);

export default router;
