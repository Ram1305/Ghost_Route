import { Router } from 'express';
import * as userController from '../controllers/user.controller.js';
import { authenticate, requireSelfOrAdmin } from '../middleware/auth.middleware.js';
import { requireAdmin } from '../middleware/admin.middleware.js';

const router = Router();

// Self-service: register this device's FCM token / toggle push on-off.
router.post('/me/fcm-token', authenticate, userController.registerFcmToken);
router.post('/me/push-preference', authenticate, userController.setPushPreference);

// Listing/creating/updating arbitrary users is admin-only; a user may still
// fetch their own record. All of this previously had no auth check at all.
router.get('/', authenticate, requireAdmin, userController.getAllUsers);
router.get('/:id', authenticate, requireSelfOrAdmin, userController.getUserById);
router.post('/', authenticate, requireAdmin, userController.createUser);
router.put('/:id', authenticate, requireAdmin, userController.updateUser);
// Account deletion is only via POST /api/auth/delete-account (self-service).

export default router;
