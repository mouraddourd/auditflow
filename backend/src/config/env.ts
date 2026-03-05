import { z } from 'zod';
import dotenv from 'dotenv';

dotenv.config();

const envSchema = z.object({
  // Required
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  
  // Optional with defaults
  PORT: z.string().optional().default('3000'),
  NODE_ENV: z.enum(['development', 'production', 'test']).optional().default('development'),
  
  // Optional - Firebase (notifications work without these)
  FIREBASE_PROJECT_ID: z.string().optional(),
  FIREBASE_PRIVATE_KEY: z.string().optional(),
  FIREBASE_CLIENT_EMAIL: z.string().optional(),
  
  // Optional - PowerSync
  POWERSYNC_URL: z.string().optional(),
});

function validateEnv() {
  const result = envSchema.safeParse(process.env);
  
  if (!result.success) {
    console.error('❌ Invalid environment variables:');
    result.error.issues.forEach((issue) => {
      console.error(`   - ${issue.path.join('.')}: ${issue.message}`);
    });
    process.exit(1);
  }
  
  return result.data;
}

export const env = validateEnv();

console.log('✅ Environment variables validated');
console.log(`   NODE_ENV: ${env.NODE_ENV}`);
console.log(`   PORT: ${env.PORT}`);
