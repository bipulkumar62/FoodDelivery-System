import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config';
import { AppError } from '../utils/AppError';
import { HTTP_STATUS } from '../constants';

export interface AuthRequest extends Request {
  admin?: { id: string };
}

export function authenticate(req: AuthRequest, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(new AppError('No token provided', HTTP_STATUS.UNAUTHORIZED));
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, config.jwtSecret) as { id: string };
    req.admin = { id: decoded.id };
    next();
  } catch (error) {
    return next(new AppError('Invalid or expired token', HTTP_STATUS.UNAUTHORIZED));
  }
}