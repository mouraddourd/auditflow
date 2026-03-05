import express from 'express';
import cors from 'cors';
import notificationRoutes from './notifications/notification.routes';
import auditRoutes from './audits/audit.routes';
import powerSyncRoutes from './powersync/powersync.routes';
import organizationRoutes from './organizations/organization.routes';
import './config/env'; // Validate environment variables at startup

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// API Routes
app.use('/notifications', notificationRoutes);
app.use('/audits', auditRoutes);
app.use('/powersync', powerSyncRoutes);
app.use('/organizations', organizationRoutes);

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});

export default app;
