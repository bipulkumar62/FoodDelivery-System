import { Request, Response, NextFunction } from 'express';
import { RiderAuthRequest } from '../middlewares/authenticateRider';
import { trackingService } from '../services/tracking.instance';
import { HTTP_STATUS } from '../constants';

/** POST /api/v1/tracking/:orderId/start – rider starts delivery manually. */
export async function startTracking(
  req: RiderAuthRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { orderId } = req.params;
    const riderId = req.rider!.id;
    const data = await trackingService.startTracking(orderId, riderId);
    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Delivery tracking started',
      data,
    });
  } catch (error) {
    next(error);
  }
}

/** PUT /api/v1/tracking/:orderId/location – rider location ping. */
export async function updateLocation(
  req: RiderAuthRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { orderId } = req.params;
    const { latitude, longitude, accuracy } = req.body;
    const riderId = req.rider!.id;
    const location = await trackingService.updateLocation({
      orderId,
      riderId,
      latitude,
      longitude,
      accuracy,
    });
    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: location,
    });
  } catch (error) {
    next(error);
  }
}

/** POST /api/v1/tracking/:orderId/stop – rider ends delivery (idempotent). */
export async function stopTracking(
  req: RiderAuthRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { orderId } = req.params;
    const data = await trackingService.stopTracking(orderId, 'rider_ended');
    res.status(HTTP_STATUS.OK).json({
      success: true,
      data,
    });
  } catch (error) {
    next(error);
  }
}

/** GET /api/v1/tracking/:orderId/location?phone=… – customer read. */
export async function getLocationForCustomer(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { orderId } = req.params;
    const phone = String(req.query.phone ?? '');
    const data = await trackingService.getLocationForCustomer(orderId, phone);
    res.status(HTTP_STATUS.OK).json({
      success: true,
      data,
    });
  } catch (error) {
    next(error);
  }
}