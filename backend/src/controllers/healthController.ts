import { Request, Response } from 'express';
import { HTTP_STATUS } from '../constants';

export function getHealth(_req: Request, res: Response): void {
  res.status(HTTP_STATUS.OK).json({
    status: 'OK',
    message: 'Backend Running',
    timestamp: new Date().toISOString(),
  });
}
