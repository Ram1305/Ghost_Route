import { Router } from 'express';
import { listServers } from '../controllers/server.controller.js';

const router = Router();

router.get('/', listServers);

export default router;
