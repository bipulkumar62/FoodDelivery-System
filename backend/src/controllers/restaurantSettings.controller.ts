import { Request, Response, NextFunction } from 'express';
import * as restaurantSettingsService from '../services/restaurantSettings.service';
import { AppError } from '../utils/AppError';
import { HTTP_STATUS } from '../constants';

const ALLOWED_UPDATE_FIELDS = ['restaurantName', 'deliveryRatePerKm', 'acceptingOrders'];

export async function getPublicSettings(
  _req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const settings = await restaurantSettingsService.getSettingsOrCreate();
    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: {
        restaurantName: settings.restaurantName,
        deliveryRatePerKm: settings.deliveryRatePerKm,
        acceptingOrders: settings.acceptingOrders,
      },
    });
  } catch (error) {
    next(error);
  }
}

export async function getAdminSettings(
  _req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const settings = await restaurantSettingsService.getSettingsOrCreate();
    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: settings,
    });
  } catch (error) {
    next(error);
  }
}

export async function updateSettings(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const unknownFields = Object.keys(req.body).filter(
      (key) => !ALLOWED_UPDATE_FIELDS.includes(key),
    );
    if (unknownFields.length > 0) {
      throw new AppError(
        `Unknown fields not allowed: ${unknownFields.join(', ')}`,
        HTTP_STATUS.BAD_REQUEST,
      );
    }

    const settings = await restaurantSettingsService.updateSettings(req.body);
    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Restaurant settings updated successfully',
      data: settings,
    });
  } catch (error) {
    next(error);
  }
}
