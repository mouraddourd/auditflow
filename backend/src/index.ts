import express from 'express';
import cors from 'cors';
import organizationRoutes from './organizations/organization.routes';
import authRoutes from './auth/auth.routes';
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
app.use('/auth', authRoutes);
app.use('/organizations', organizationRoutes);

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});

export default app;
