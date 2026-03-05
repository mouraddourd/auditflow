import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { z } from 'zod';

const prisma = new PrismaClient();

// Validation schemas
const registerSchema = z.object({
  email: z.string().email('Email invalide'),
  password: z.string().min(6, 'Le mot de passe doit contenir au moins 6 caractères'),
  name: z.string().min(1, 'Le nom est requis').optional(),
});

const loginSchema = z.object({
  email: z.string().email('Email invalide'),
  password: z.string().min(1, 'Le mot de passe est requis'),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;

export interface AuthResponse {
  success: boolean;
  data?: {
    user: {
      id: string;
      email: string;
      name: string | null;
    };
    token: string;
  };
  error?: string;
}

const JWT_SECRET = process.env.JWT_SECRET || 'dev-jwt-secret-not-for-production';
const JWT_EXPIRES_IN = '7d';

export class AuthService {
  /**
   * Register a new user
   */
  static async register(input: RegisterInput): Promise<AuthResponse> {
    try {
      const validated = registerSchema.parse(input);

      // Check if user already exists
      const existingUser = await prisma.user.findUnique({
        where: { email: validated.email },
      });

      if (existingUser) {
        return {
          success: false,
          error: 'Un utilisateur avec cet email existe déjà',
        };
      }

      // Hash password
      const hashedPassword = await bcrypt.hash(validated.password, 10);

      // Create user
      const user = await prisma.user.create({
        data: {
          email: validated.email,
          password: hashedPassword,
          name: validated.name || null,
        },
      });

      // Generate JWT
      const token = jwt.sign(
        { userId: user.id, email: user.email },
        JWT_SECRET,
        { expiresIn: JWT_EXPIRES_IN }
      );

      return {
        success: true,
        data: {
          user: {
            id: user.id,
            email: user.email,
            name: user.name,
          },
          token,
        },
      };
    } catch (error) {
      if (error instanceof z.ZodError) {
        return {
          success: false,
          error: error.issues[0].message,
        };
      }
      console.error('Register error:', error);
      return {
        success: false,
        error: 'Erreur lors de l\'inscription',
      };
    }
  }

  /**
   * Login an existing user
   */
  static async login(input: LoginInput): Promise<AuthResponse> {
    try {
      const validated = loginSchema.parse(input);

      // Find user
      const user = await prisma.user.findUnique({
        where: { email: validated.email },
      });

      if (!user) {
        return {
          success: false,
          error: 'Email ou mot de passe incorrect',
        };
      }

      // Verify password
      const isValidPassword = await bcrypt.compare(validated.password, user.password);

      if (!isValidPassword) {
        return {
          success: false,
          error: 'Email ou mot de passe incorrect',
        };
      }

      // Generate JWT
      const token = jwt.sign(
        { userId: user.id, email: user.email },
        JWT_SECRET,
        { expiresIn: JWT_EXPIRES_IN }
      );

      return {
        success: true,
        data: {
          user: {
            id: user.id,
            email: user.email,
            name: user.name,
          },
          token,
        },
      };
    } catch (error) {
      if (error instanceof z.ZodError) {
        return {
          success: false,
          error: error.issues[0].message,
        };
      }
      console.error('Login error:', error);
      return {
        success: false,
        error: 'Erreur lors de la connexion',
      };
    }
  }

  /**
   * Verify a JWT token and return the user ID
   */
  static verifyToken(token: string): { userId: string; email: string } | null {
    try {
      const decoded = jwt.verify(token, JWT_SECRET) as { userId: string; email: string };
      return decoded;
    } catch {
      return null;
    }
  }

  /**
   * Get user by ID
   */
  static async getUserById(userId: string) {
    return prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }
}
