import express from 'express';
import cors from 'cors';
import organizationRoutes from './organizations/organization.routes';
import authRoutes from './auth/auth.routes';
import templateRoutes from './templates/template.routes';
import auditRoutes from './audits/audit.routes';
import categoryRoutes from './categories/category.routes';
import aiRoutes from './ai/ai.routes';
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
app.use('/templates', templateRoutes);
app.use('/audits', auditRoutes);
app.use('/categories', categoryRoutes);
app.use('/ai', aiRoutes);

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});

export default app;
