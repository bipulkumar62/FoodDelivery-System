import { Request, Response, NextFunction } from 'express';
import { HTTP_STATUS } from '../constants';
import { config } from '../config';
import { AppError } from '../utils/AppError';

export function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
  const statusCode = err instanceof AppError
    ? err.statusCode
    : HTTP_STATUS.INTERNAL_SERVER_ERROR;

  const message = err.message || 'Internal server error';

  if (err.name === 'ValidationError') {
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: 'Database validation error',
      ...(config.isDev && { error: err.message }),
    });
    return;
  }

  if ((err as any).code === 11000) {
    res.status(HTTP_STATUS.CONFLICT || 409).json({
      success: false,
      message: 'Duplicate entry',
    });
    return;
  }

  if (err.name === 'CastError') {
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: 'Invalid ID format',
    });
    return;
  }

  res.status(statusCode).json({
    success: false,
    message,
    ...(config.isDev && { stack: err.stack }),
  });
}
