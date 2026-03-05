import { Request, Response, NextFunction } from 'express';
import { AuthService } from './auth.service';

// Extend Express Request type to include user
declare global {
  namespace Express {
    interface Request {
      userId?: string;
      userEmail?: string;
    }
  }
}

export interface AuthMiddlewareResult {
  success: boolean;
  error?: string;
  userId?: string;
  userEmail?: string;
}

/**
 * Middleware to require authentication
 * Validates JWT token from Authorization header
 * Sets req.userId and req.userEmail for use in protected routes
 */
export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      error: 'Token d\'authentification requis',
    });
  }

  const token = authHeader.substring(7);
  const decoded = AuthService.verifyToken(token);

  if (!decoded) {
    return res.status(401).json({
      success: false,
      error: 'Token invalide ou expiré',
    });
  }

  // Attach user info to request
  req.userId = decoded.userId;
  req.userEmail = decoded.email;

  next();
}

/**
 * Optional auth middleware
 * Sets userId if token is valid, but doesn't reject if missing
 */
export function optionalAuth(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;

  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7);
    const decoded = AuthService.verifyToken(token);

    if (decoded) {
      req.userId = decoded.userId;
      req.userEmail = decoded.email;
    }
  }

  next();
}
