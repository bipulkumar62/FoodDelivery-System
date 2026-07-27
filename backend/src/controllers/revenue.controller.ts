import { Request, Response, NextFunction } from 'express';
import * as revenueService from '../services/revenue.service';
import { HTTP_STATUS } from '../constants';

export async function getRevenue(
  _req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    await revenueService.calculateTodaysRevenue();
    const revenue = await revenueService.getTodaysRevenue();

    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: revenue || {
        totalAmount: 0,
        deliveredOrderCount: 0,
      },
    });
  } catch (error) {
    next(error);
  }
}

export async function deleteRevenue(
  _req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    await revenueService.deleteTodaysRevenue();
    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: "Today's revenue has been reset",
    });
  } catch (error) {
    next(error);
  }
}

export async function getRevenueHistory(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const limit = parseInt(req.query.limit as string) || 30;
    const history = await revenueService.getRevenueHistory(limit);
    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: history,
    });
  } catch (error) {
    next(error);
  }
}