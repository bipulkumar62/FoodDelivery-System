import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config';
import { AppError } from '../utils/AppError';
import { HTTP_STATUS } from '../constants';

export interface RiderAuthRequest extends Request {
  rider?: { id: string };
}

export const RIDER_ROLE = 'rider';

export function authenticateRider(
  req: RiderAuthRequest,
  res: Response,
  next: NextFunction,
): void {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(new AppError('No token provided', HTTP_STATUS.UNAUTHORIZED));
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, config.jwtSecret) as {
      id: string;
      role?: string;
    };
    if (decoded.role !== RIDER_ROLE) {
      return next(
        new AppError('Rider authentication required', HTTP_STATUS.UNAUTHORIZED),
      );
    }
    req.rider = { id: decoded.id };
    next();
  } catch (error) {
    return next(
      new AppError('Invalid or expired token', HTTP_STATUS.UNAUTHORIZED),
    );
  }
}