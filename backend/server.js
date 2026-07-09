import 'dotenv/config';
import cron from 'node-cron';
import app from './src/app.js';
import { connectDB } from './src/config/db.js';
import { expireSubscriptions } from './src/jobs/expireSubscriptions.js';
import { ensurePlansSeeded } from './src/services/plansSeed.service.js';
import { ensureWireguardServersSeeded } from './src/services/wireguardServersSeed.service.js';
import { seedReviewAccount } from './src/scripts/seedReviewAccount.js';

const PORT = Number(process.env.PORT) || 2626;

async function start() {
  await connectDB();
  await ensurePlansSeeded();
  await ensureWireguardServersSeeded();
  await seedReviewAccount();
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });

  // Daily at 00:01 UTC: mark expired subscriptions (activePlan = null)
  cron.schedule('1 0 * * *', async () => {
    try {
      await expireSubscriptions();
    } catch (err) {
      console.error('[expireSubscriptions] Error:', err);
    }
  });
}

start().catch((err) => {
  console.error('Failed to start:', err);
  process.exit(1);
});
