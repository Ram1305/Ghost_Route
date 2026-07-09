import { Router } from 'express';
import { listWireguardPremiumServers } from '../controllers/wireguardServers.controller.js';

const router = Router();

// Display-only premium WireGuard servers list.
router.get('/premium-servers/wireguard', listWireguardPremiumServers);

export default router;

